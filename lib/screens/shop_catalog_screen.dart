import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../screens/onboarding_screen.dart';
import '../services/ingredient_sanitizer.dart';
import '../widgets/tactile_tap.dart';

class ShopCatalogScreen extends StatefulWidget {
  final List<GroceryItem> allCatalogItems;
  final Function(GroceryItem) onToggleItemAdded;
  final Function(GroceryItem, int) onUpdateItemQuantity;
  final Function(GroceryItem, String) onUpdateItemUnit;
  final VoidCallback onOpenCart;

  const ShopCatalogScreen({
    super.key,
    required this.allCatalogItems,
    required this.onToggleItemAdded,
    required this.onUpdateItemQuantity,
    required this.onUpdateItemUnit,
    required this.onOpenCart,
  });

  @override
  State<ShopCatalogScreen> createState() => _ShopCatalogScreenState();
}

class _ShopCatalogScreenState extends State<ShopCatalogScreen> {
  ItemCategory _selectedCategory = ItemCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryItem> get _filteredItems {
    final q = _searchQuery.toLowerCase().trim();
    final canonicalQuery = q.isNotEmpty ? CanonicalItemMatcher.getCanonicalKey(q) : '';

    return widget.allCatalogItems.where((item) {
      final matchesCat = _selectedCategory == ItemCategory.all || item.category == _selectedCategory;
      if (!matchesCat) return false;
      if (q.isEmpty) return true;

      final nameEn = item.nameEn.toLowerCase();
      final nameHi = item.nameHi.toLowerCase();

      if (nameEn.contains(q) || nameHi.contains(q)) return true;

      if (canonicalQuery.isNotEmpty) {
        final itemCanonicalEn = CanonicalItemMatcher.getCanonicalKey(item.nameEn);
        final itemCanonicalHi = CanonicalItemMatcher.getCanonicalKey(item.nameHi);
        if (itemCanonicalEn == canonicalQuery || itemCanonicalHi == canonicalQuery) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shopItems = _filteredItems;

    return Column(
      children: [
        // 1. Top Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search items in Shop (such as Rice, Haldi, Milk)',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.mdBorder,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadii.mdBorder,
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // 2. Main Body: Left Category Sidebar + Right 2-Column Product Grid
        Expanded(
          child: Row(
            children: [
              // Left Category Sidebar
              Container(
                width: 82,
                color: AppColors.surface,
                child: ListView.builder(
                  itemCount: ItemCategory.values.length,
                  itemBuilder: (context, index) {
                    final cat = ItemCategory.values[index];
                    final isSelected = _selectedCategory == cat;

                    return TactileTap(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 3.5,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 18,
                              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              cat.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const VerticalDivider(width: 1, color: AppColors.border),

              // Right 2-Column Product Grid
              Expanded(
                child: shopItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text('No items found in category', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: shopItems.length,
                        itemBuilder: (context, index) {
                          final item = shopItems[index];
                          return _buildAirbnbShopCard(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAirbnbShopCard(GroceryItem item) {
    final availableUnits = item.availableUnits.toSet().toList();
    final currentUnit = availableUnits.contains(item.selectedUnit)
        ? item.selectedUnit
        : (availableUnits.isNotEmpty ? availableUnits.first : '1 Pack');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(color: item.isAdded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Media Area (Image or Category Icon + In-Cart Badge)
          Container(
            height: 76,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.accentColor.withValues(alpha: 0.12),
              borderRadius: AppRadii.mdBorder,
            ),
            child: Stack(
              children: [
                Center(
                  child: item.imagePath != null
                      ? ClipRRect(
                          borderRadius: AppRadii.mdBorder,
                          child: Image.asset(
                            item.imagePath!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => _buildCardPlaceholder(item),
                          ),
                        )
                      : _buildCardPlaceholder(item),
                ),
                if (item.isAdded)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Text(
                        '${item.quantity} in list',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Titles & Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.nameHi.isNotEmpty && item.nameHi != item.nameEn ? item.nameHi : item.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 3. Bottom Row: Safe Unit Selector Pill + Add / Stepper Button
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Row(
              children: [
                // Left: Unit selector pill (cycles safely through units with zero assert errors)
                Expanded(
                  flex: 5,
                  child: TactileTap(
                    onTap: () {
                      if (availableUnits.isNotEmpty) {
                        final currentIdx = availableUnits.indexOf(currentUnit);
                        final nextIdx = (currentIdx + 1) % availableUnits.length;
                        widget.onUpdateItemUnit(item, availableUnits[nextIdx]);
                      }
                    },
                    child: Container(
                      height: 27,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              currentUnit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.unfold_more_rounded, size: 11, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 5),

                // Right: Add or Quantity Counter
                Expanded(
                  flex: 5,
                  child: !item.isAdded
                      ? SizedBox(
                          height: 27,
                          child: TactileTap(
                            onTap: () => widget.onToggleItemAdded(item),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: AppShadows.soft,
                              ),
                              child: const Text(
                                '+ ADD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 27,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TactileTap(
                                onTap: () => widget.onUpdateItemQuantity(item, item.quantity - 1),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                                  child: Icon(Icons.remove_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TactileTap(
                                onTap: () => widget.onUpdateItemQuantity(item, item.quantity + 1),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                                  child: Icon(Icons.add_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPlaceholder(GroceryItem item) {
    return Center(
      child: Icon(item.category.icon, color: item.accentColor, size: 28),
    );
  }

  /* PREVIOUS VERTICAL STACKED CARD - COMMENTED OUT AS PER RULE
  Widget _buildAirbnbShopCard_Legacy(GroceryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(color: item.isAdded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text(item.nameEn),
        ],
      ),
    );
  }
  */
}
