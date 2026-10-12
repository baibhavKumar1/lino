import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';
import 'tactile_tap.dart';

class PantryInventoryModal extends StatefulWidget {
  final List<PantryItem> pantryItems;
  final Function(PantryItem) onAddPantryItem;
  final Function(PantryItem) onUpdatePantryItem;
  final Function(PantryItem, int) onUpdatePantryQuantity;
  final Function(PantryItem) onDeletePantryItem;
  final Function(PantryItem) onPushToRestockList;
  final VoidCallback? onOpenReceiptScanner;
  final bool isLoading;

  const PantryInventoryModal({
    super.key,
    required this.pantryItems,
    required this.onAddPantryItem,
    required this.onUpdatePantryItem,
    required this.onUpdatePantryQuantity,
    required this.onDeletePantryItem,
    required this.onPushToRestockList,
    this.onOpenReceiptScanner,
    this.isLoading = false,
  });

  @override
  State<PantryInventoryModal> createState() => _PantryInventoryModalState();
}

class _PantryInventoryModalState extends State<PantryInventoryModal> {
  String _searchQuery = '';
  ItemCategory _selectedCategory = ItemCategory.all;
  bool _showLowStockOnly = false;

  List<PantryItem> get _filteredPantryItems {
    return widget.pantryItems.where((item) {
      final matchesCategory = _selectedCategory == ItemCategory.all ||
          item.category == _selectedCategory;
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty || item.name.toLowerCase().contains(query);
      final matchesLowStock = !_showLowStockOnly || item.isLowStock || item.quantity <= 1;
      return matchesCategory && matchesSearch && matchesLowStock;
    }).toList();
  }

  List<PantryItem> get _lowStockItems {
    return widget.pantryItems.where((i) => i.isLowStock || i.quantity <= 1).toList();
  }

  int get _totalLowStockCount => _lowStockItems.length;

  double get _stockHealthRatio {
    if (widget.pantryItems.isEmpty) return 1.0;
    final healthyCount = widget.pantryItems.where((i) => !i.isLowStock && i.quantity > 1).length;
    return healthyCount / widget.pantryItems.length;
  }

  void _showItemDialog(BuildContext context, {PantryItem? itemToEdit}) {
    final isEditing = itemToEdit != null;
    final nameController = TextEditingController(text: isEditing ? itemToEdit.name : '');
    final qtyController = TextEditingController(text: isEditing ? itemToEdit.quantity.toString() : '1');
    String selectedUnit = isEditing ? itemToEdit.unit : 'kg';
    ItemCategory selectedCategory = isEditing ? itemToEdit.category : ItemCategory.kitchenStaples;
    bool isLowStock = isEditing ? itemToEdit.isLowStock : false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            /* PREVIOUS FLAT DECORATION - COMMENTED OUT AS PER RULE
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            */
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: AppShadows.modal,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                Text(
                  isEditing ? 'Edit Item' : 'Add Item',
                  style: AppTypography.displaySmall(fontSize: 18),
                ),
                const SizedBox(height: 14),

                // Name
                TextField(
                  controller: nameController,
                  autofocus: !isEditing,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Basmati Rice, Cumin Seeds, Milk',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.mdBorder,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quantity and Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.mdBorder,
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.mdBorder,
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                        items: ['g', 'kg', 'ml', 'L', 'Pcs', 'Packets', 'Bottles', 'Boxes']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category
                DropdownButtonFormField<ItemCategory>(
                  value: selectedCategory,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.mdBorder,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: ItemCategory.values
                      .where((c) => c != ItemCategory.all)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 8),

                // Low stock toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Mark as Low Stock',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  activeColor: AppColors.danger,
                  value: isLowStock,
                  onChanged: (val) => setModalState(() => isLowStock = val),
                ),

                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TactileTap(
                    onTap: () {
                      final name = nameController.text.trim();
                      final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                      if (name.isNotEmpty) {
                        if (isEditing) {
                          final updated = itemToEdit.copyWith(
                            name: name,
                            quantity: qty,
                            unit: selectedUnit,
                            category: selectedCategory,
                            isLowStock: isLowStock,
                          );
                          widget.onUpdatePantryItem(updated);
                        } else {
                          final newItem = PantryItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            category: selectedCategory,
                            unit: selectedUnit,
                            quantity: qty,
                            isLowStock: isLowStock,
                          );
                          widget.onAddPantryItem(newItem);
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadii.mdBorder,
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Item',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textWhite),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPantryItems;
    final lowItems = _lowStockItems;
    final healthPercent = (_stockHealthRatio * 100).toInt();

    /* PREVIOUS UNMASKED SCROLL CONTAINER - COMMENTED OUT AS PER RULE
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
        child: Column(
    */
    /* PREVIOUS WEAK DENSITY MASK - COMMENTED OUT AS PER RULE
    return Container(
      color: AppColors.background,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.02, 0.94, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
    */
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Scrollable Content with Exact 10px Spread ShaderMask
          ShaderMask(
            shaderCallback: (Rect bounds) {
              final double h = bounds.height;
              final double topStop = h > 0 ? (10.0 / h).clamp(0.001, 0.08) : 0.01;
              final double bottomStop = h > 0 ? (1.0 - (10.0 / h)).clamp(0.92, 0.999) : 0.99;

              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, topStop, bottomStop, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ==========================================
              // 1. SPACE-EFFICIENT BENTO MICRO HEADER
              // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.lgBorder,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Left stats info (Flexible with no overflow)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.kitchen_rounded, color: AppColors.primaryDark, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.pantryItems.length} In Stock',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$healthPercent% stocked | $_totalLowStockCount low',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Right action capsule buttons (compact, touch-friendly with TactileTap)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Add button
                          TactileTap(
                            onTap: () => _showItemDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: AppShadows.soft,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, color: AppColors.textWhite, size: 16),
                                  SizedBox(width: 2),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (widget.onOpenReceiptScanner != null) ...[
                            const SizedBox(width: 6),
                            TactileTap(
                              onTap: widget.onOpenReceiptScanner,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.borderDark),
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textPrimary, size: 16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Slim 3.5px organic health bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _stockHealthRatio,
                      minHeight: 3.5,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _totalLowStockCount == 0 ? AppColors.primary : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Legacy condition: child: lowItems.isNotEmpty ? ... : const SizedBox.shrink()
            // Updated to ensure filter toggle remains visible and operable if all items are restocked while filter was active:
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              child: (lowItems.isNotEmpty || _showLowStockOnly)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: lowItems.isEmpty ? AppColors.successLight : AppColors.dangerSubtle,
                          borderRadius: AppRadii.lgBorder,
                          border: Border.all(
                            color: lowItems.isEmpty ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              lowItems.isEmpty ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                              color: lowItems.isEmpty ? AppColors.primaryDark : AppColors.dangerDark,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                lowItems.isEmpty
                                    ? 'All items are well stocked'
                                    : '${lowItems.length} items low: ${lowItems.map((i) => i.name).take(2).join(", ")}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: lowItems.isEmpty ? AppColors.primaryDark : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TactileTap(
                              onTap: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
                              child: Text(
                                _showLowStockOnly ? 'Show All' : 'Filter',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _showLowStockOnly ? AppColors.textPrimary : AppColors.dangerDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // 3. COMPACT SEARCH & CATEGORY CHIPS
            // ==========================================
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search ingredients...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            const SizedBox(height: 8),

            // Category Chips with TactileTap
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ItemCategory.values.length,
                itemBuilder: (context, index) {
                  final cat = ItemCategory.values[index];
                  final isSelected = _selectedCategory == cat;
                  final count = cat == ItemCategory.all
                      ? widget.pantryItems.length
                      : widget.pantryItems.where((i) => i.category == cat).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TactileTap(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          boxShadow: isSelected ? AppShadows.soft : null,
                        ),
                        child: Center(
                          child: Text(
                            cat == ItemCategory.all ? 'All ($count)' : '${cat.label} ($count)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Legacy: if (widget.pantryItems.isEmpty) ...[ _buildEmptyState() ]
            if (widget.isLoading && widget.pantryItems.isEmpty) ...[
              _buildLoadingState(),
            ] else if (widget.pantryItems.isEmpty) ...[
              _buildEmptyState(),
            ] else if (filtered.isEmpty) ...[
              _buildNoMatchState(),
            ] else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  /* PREVIOUS SPACING CONFIG - COMMENTED OUT AS PER RULE
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  */
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _buildBentoCard(item);
                },
              ),
            ],
          ],
        ),
      ),
    ),

    // Top Dense Feathered Dissolve Overlay (Exact 10px spread)
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 10,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    ),

    // Bottom Dense Feathered Dissolve Overlay (Exact 10px spread)
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 10,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
),
    );
  }

  // FLAWLESS ARC-STYLED LUXURY INVENTORY CARD (Inspired by Arc Aesthetic in image.png)
  /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
  Widget _buildBentoCard(PantryItem item) {
    final isLow = item.isLowStock || item.quantity <= 1;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(
          color: isLow ? const Color(0xFFFECACA) : AppColors.border,
          width: isLow ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Top row: Icon + More menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isLow
                      ? AppColors.dangerLight
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.category.icon,
                  color: isLow ? AppColors.dangerDark : AppColors.primaryDark,
                  size: 16,
                ),
              ),

              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showItemDialog(context, itemToEdit: item);
                    } else if (val == 'delete') {
                      widget.onDeletePantryItem(item);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 15, color: AppColors.textSecondary),
                          SizedBox(width: 6),
                          Text('Edit', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                          SizedBox(width: 6),
                          Text('Delete', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Title & Category (Clean, 2 lines max)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // 3. Stock Level Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isLow ? AppColors.dangerLight : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isLow ? 'Low: ${item.displayStock}' : item.displayStock,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isLow ? AppColors.dangerDark : AppColors.textSecondary,
              ),
            ),
          ),

          // 4. Grounded Action Bar (Stepper + 1-Tap Cart in one seamless pill with TactileTap)
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Stepper [-]
                TactileTap(
                  onTap: () => widget.onUpdatePantryQuantity(item, item.quantity - 1),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    child: Icon(Icons.remove_rounded, size: 14, color: AppColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                // Stepper [+]
                TactileTap(
                  onTap: () => widget.onUpdatePantryQuantity(item, item.quantity + 1),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    child: Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                  ),
                ),

                // Vertical Divider
                Container(width: 1, height: 18, color: AppColors.border),

                // Restock Button
                TactileTap(
                  onTap: () {
                    widget.onPushToRestockList(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added ${item.name} to cart',
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: AppColors.textPrimary,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(
                      Icons.add_shopping_cart_rounded,
                      size: 14,
                      color: isLow ? AppColors.dangerDark : AppColors.accentBlue,
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
  */

  // EXACT ARC-INSPIRED FLAT SOLID CARD WITH FOOD PHOTOGRAPHY (from image.png)
  /* PREVIOUS GRADIENT LOGIC - COMMENTED OUT AS PER RULE
  Widget _buildBentoCard(PantryItem item) {
    final isLow = item.isLowStock || item.quantity <= 1;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLow
              ? const [Color(0xFF2E1215), Color(0xFF19090B)]
              : const [Color(0xFF0E382A), Color(0xFF071E16)],
        ),
        borderRadius: BorderRadius.circular(22),
        ...
      ),
    );
  }
  */

  // COHESIVE EARTHY ARTISANAL CARD PALETTE (Harmonious Matte Culinary Family)
  /* PREVIOUS RANDOM RAINBOW PALETTE - COMMENTED OUT AS PER RULE
  Color _getSolidArcColor(PantryItem item) {
    if (item.isLowStock || item.quantity <= 1) {
      return const Color(0xFFE11D48); // Solid Coral Red (Low Stock)
    }
    switch (item.category) {
      case ItemCategory.freshProduce:
        return const Color(0xFF16A34A); // Solid Fresh Green
      case ItemCategory.singleSpices:
      case ItemCategory.masalaBlends:
        return const Color(0xFFD97706); // Solid Warm Mustard/Amber
      case ItemCategory.pulsesLentils:
      case ItemCategory.floursBaking:
        return const Color(0xFFEA580C); // Solid Terracotta Orange
      case ItemCategory.riceGrains:
        return const Color(0xFF0D9488); // Solid Deep Teal
      case ItemCategory.dryFruitsNuts:
        return const Color(0xFF854D0E); // Solid Warm Amber
      case ItemCategory.readyToCook:
        return const Color(0xFF6366F1); // Solid Indigo
      case ItemCategory.kitchenStaples:
      case ItemCategory.all:
      default:
        return const Color(0xFF15803D); // Solid Emerald
    }
  }
  */

  // RICH LUMINOUS GOURMET ARTISANAL PALETTE
  /* PREVIOUS DARK MUTED PALETTE - COMMENTED OUT AS PER RULE
  Color _getSolidArcColor(PantryItem item) {
    if (item.isLowStock || item.quantity <= 1) {
      return const Color(0xFF5A2027); // Muted Crimson Ember (Low Stock)
    }
    switch (item.category) {
      case ItemCategory.freshProduce:
        return const Color(0xFF223F2D); // Earthy Forest Moss
      case ItemCategory.singleSpices:
        return const Color(0xFF3B2A1E); // Roasted Cinnamon Umber
      case ItemCategory.masalaBlends:
        return const Color(0xFF442A1E); // Smoked Paprika Terra
      case ItemCategory.pulsesLentils:
        return const Color(0xFF38291F); // Toasted Flax Clay
      case ItemCategory.floursBaking:
        return const Color(0xFF362B21); // Warm Buckwheat Ochre
      case ItemCategory.riceGrains:
        return const Color(0xFF1F3533); // Deep Cedar Slate
      case ItemCategory.dryFruitsNuts:
        return const Color(0xFF3A2B22); // Roasted Walnut Bark
      case ItemCategory.readyToCook:
        return const Color(0xFF262C44); // Deep Indigo Herb
      case ItemCategory.kitchenStaples:
      case ItemCategory.all:
      default:
        return const Color(0xFF1B382B); // Deep Pine Basil
    }
  }
  */

  // NORDIC SAGE & OLIVE STONEWARE PALETTE (Calm, Cohesive Botanical Family)
  /* PREVIOUS RAINBOW & DARK PALETTES - COMMENTED OUT AS PER RULE
  Color _getSolidArcColor(PantryItem item) {
    if (item.isLowStock || item.quantity <= 1) {
      return const Color(0xFFBE123C);
    }
    switch (item.category) {
      case ItemCategory.freshProduce:
        return const Color(0xFF23824E);
      case ItemCategory.singleSpices:
        return const Color(0xFFC77700);
      case ItemCategory.masalaBlends:
        return const Color(0xFFC2522B);
      case ItemCategory.pulsesLentils:
        return const Color(0xFFA86324);
      case ItemCategory.floursBaking:
        return const Color(0xFFB87928);
      case ItemCategory.riceGrains:
        return const Color(0xFF167B82);
      case ItemCategory.dryFruitsNuts:
        return const Color(0xFFA05530);
      case ItemCategory.readyToCook:
        return const Color(0xFF4C5599);
      case ItemCategory.kitchenStaples:
      case ItemCategory.all:
      default:
        return const Color(0xFF1E7558);
    }
  }
  */

  Color _getSolidArcColor(PantryItem item) {
    if (item.isLowStock || item.quantity <= 1) {
      return const Color(0xFF7A3E39); // Smoked Terracotta Clay (Low Stock)
    }
    switch (item.category) {
      case ItemCategory.freshProduce:
        return const Color(0xFF3B5649); // Fresh Thyme Herb
      case ItemCategory.singleSpices:
        return const Color(0xFF455843); // Olive Laurel Clay
      case ItemCategory.masalaBlends:
        return const Color(0xFF4E5642); // Warm Stoneware Umber
      case ItemCategory.pulsesLentils:
        return const Color(0xFF52543F); // Muted Amber Olive
      case ItemCategory.floursBaking:
        return const Color(0xFF3E5047); // Dry Oat Sage
      case ItemCategory.riceGrains:
        return const Color(0xFF2F4C47); // Nordic Spruce Slate
      case ItemCategory.dryFruitsNuts:
        return const Color(0xFF485141); // Warm Bark Olive
      case ItemCategory.readyToCook:
        return const Color(0xFF35484D); // Muted Eucalyptus Slate
      case ItemCategory.kitchenStaples:
      case ItemCategory.all:
      default:
        return const Color(0xFF334E43); // Nordic Celadon Sage
    }
  }

  String _getFoodImageUrl(PantryItem item) {
    final nameLower = item.name.toLowerCase();
    if (nameLower.contains('rice') || nameLower.contains('atta') || nameLower.contains('flour')) {
      return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&auto=format&fit=crop&q=80';
    } else if (nameLower.contains('jeera') || nameLower.contains('cumin') || nameLower.contains('haldi') || nameLower.contains('turmeric') || nameLower.contains('spice') || nameLower.contains('masala')) {
      return 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&auto=format&fit=crop&q=80';
    } else if (nameLower.contains('oil') || nameLower.contains('ghee')) {
      return 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop&q=80';
    } else if (nameLower.contains('dal') || nameLower.contains('lentil') || nameLower.contains('pulse') || nameLower.contains('chana')) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&auto=format&fit=crop&q=80';
    } else if (nameLower.contains('milk') || nameLower.contains('dahi') || nameLower.contains('paneer') || nameLower.contains('cheese')) {
      return 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&auto=format&fit=crop&q=80';
    } else if (nameLower.contains('lemon') || nameLower.contains('fruit') || nameLower.contains('apple')) {
      return 'https://images.unsplash.com/photo-1534483509719-3feaee7c30da?w=400&auto=format&fit=crop&q=80';
    }
    // High-resolution fresh culinary bowl matching the Arc reference in image.png
    return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&auto=format&fit=crop&q=80';
  }

  Widget _buildBentoCard(PantryItem item) {
    final isLow = item.isLowStock || item.quantity <= 1;
    final solidCardColor = _getSolidArcColor(item);
    final imageUrl = _getFoodImageUrl(item);

    // Calculate a rich, darker extrusion color for the 3D button lip effect
    final hsl = HSLColor.fromColor(solidCardColor);
    final darkExtrusionColor = hsl.withLightness((hsl.lightness * 0.60).clamp(0.0, 1.0)).toColor();

    return Container(
      padding: const EdgeInsets.all(9),
      /* PREVIOUS DUAL SHADOW BOX DECORATION - COMMENTED OUT AS PER RULE
      decoration: BoxDecoration(
        color: solidCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // 1. Tonal Ambient Shadow (Harmonized with card's stoneware hue)
          BoxShadow(
            color: solidCardColor.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          ),
          // 2. Crisp Grounding Drop Shadow
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      */
      decoration: BoxDecoration(
        color: solidCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          // 1. Chunky 3D Button Extrusion / Keycap Lip (Zero-blur bottom displacement matching Arc card in image.png)
          BoxShadow(
            color: darkExtrusionColor.withValues(alpha: 0.92),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
          // 2. Tonal Ambient Glow (Harmonized with Nordic stoneware palette)
          BoxShadow(
            color: solidCardColor.withValues(alpha: 0.35),
            offset: const Offset(0, 8),
            blurRadius: 14,
            spreadRadius: -2,
          ),
          // 3. Grounding Contact Shadow
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            offset: const Offset(0, 10),
            blurRadius: 18,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: Title (Italic Serif) + Menu + Stock Badge (Moved above image)
          /* PREVIOUS LOGIC WITH BOTTOM TEXT BADGE - COMMENTED OUT AS PER RULE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fraunces(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Menu trigger
              SizedBox(
                width: 22,
                height: 22,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 15,
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showItemDialog(context, itemToEdit: item);
                    } else if (val == 'delete') {
                      widget.onDeletePantryItem(item);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 15, color: AppColors.textPrimary),
                          SizedBox(width: 6),
                          Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                          SizedBox(width: 6),
                          Text('Delete', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          */
          // 1. Complete Header & Controls Section (Situated Completely Above the Image)
          /* PREVIOUS LOGIC WITH BOTTOM ACTION BAR - COMMENTED OUT AS PER RULE
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fraunces(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: PopupMenuButton<String>(...),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                child: Text(isLow ? 'Low: ${item.displayStock}' : item.displayStock, ...),
              ),
            ],
          ),
          ...
          Container(
            height: 30,
            child: Row(
              children: [
                Stepper,
                Restock Button,
              ],
            ),
          ),
          */
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Item Name + Menu Trigger
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 0.95,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Menu trigger
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 15,
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showItemDialog(context, itemToEdit: item);
                        } else if (val == 'delete') {
                          widget.onDeletePantryItem(item);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 15, color: AppColors.textPrimary),
                              SizedBox(width: 6),
                              Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                              SizedBox(width: 6),
                              Text('Delete', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Row 2: Stock Badge (Left) + Compact Stepper & Restock Button (Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Complete Stock Status / Quantity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLow
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLow ? 'Low: ${item.displayStock}' : item.displayStock,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Right: Compact Stepper [- 1 +] and Restock Button
                  Container(
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stepper [-]
                        TactileTap(
                          onTap: () => widget.onUpdatePantryQuantity(item, item.quantity - 1),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                            child: Icon(Icons.remove_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                        // Quantity Counter
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Stepper [+]
                        TactileTap(
                          onTap: () => widget.onUpdatePantryQuantity(item, item.quantity + 1),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                            child: Icon(Icons.add_rounded, size: 12, color: Colors.white),
                          ),
                        ),

                        // Hairline Divider
                        Container(width: 1, height: 13, color: Colors.white.withValues(alpha: 0.25)),

                        // Restock Button
                        TactileTap(
                          onTap: () {
                            widget.onPushToRestockList(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${item.name} to cart',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                backgroundColor: AppColors.textPrimary,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Food Photograph filling the entire bottom canvas
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white.withValues(alpha: 0.15),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withValues(alpha: 0.18),
                    child: Center(
                      child: Icon(
                        item.category.icon,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xlBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.kitchen_rounded, size: 36, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Inventory is Empty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add kitchen essentials to easily plan recipes and track restocks',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TactileTap(
            onTap: () => _showItemDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppShadows.soft,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: AppColors.textWhite, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'ADD FIRST ITEM',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textWhite),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Syncing your kitchen pantry',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Loading ingredients from cloud storage',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchState() {
    final hasActiveFilter = _showLowStockOnly || _searchQuery.isNotEmpty || _selectedCategory != ItemCategory.all;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No matching ingredients found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasActiveFilter) ...[
            const SizedBox(height: 12),
            TactileTap(
              onTap: () {
                setState(() {
                  _showLowStockOnly = false;
                  _searchQuery = '';
                  _selectedCategory = ItemCategory.all;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Reset Active Filters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
