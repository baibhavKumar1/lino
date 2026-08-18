import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grocery_item.dart';
import '../widgets/shopping_list_drawer.dart';
import '../widgets/saved_templates_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<GroceryItem> _allItems;
  late List<SavedListTemplate> _savedTemplates;
  ItemCategory _selectedCategory = ItemCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allItems = GroceryCatalog.getInitialItems();
    _savedTemplates = GroceryCatalog.getInitialSavedTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryItem> get _filteredItems {
    return _allItems.where((item) {
      final matchesCategory = _selectedCategory == ItemCategory.all ||
          item.category == _selectedCategory;

      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          item.nameEn.toLowerCase().contains(query) ||
          item.nameHi.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _totalAddedCount {
    return _allItems.where((item) => item.isAdded).length;
  }

  int _getCategoryCount(ItemCategory cat) {
    if (cat == ItemCategory.all) return _totalAddedCount;
    return _allItems.where((i) => i.category == cat && i.isAdded).length;
  }

  void _toggleItemAdded(GroceryItem item) {
    if (item.isChecked) return; // Prevent modifying locked items
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _allItems[index] = _allItems[index].copyWith(
          isAdded: !_allItems[index].isAdded,
          quantity: 1,
        );
      }
    });
  }

  void _updateItemQuantity(GroceryItem item, int newQty) {
    if (item.isChecked) return; // Prevent modifying locked items
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        if (newQty <= 0) {
          _allItems[index] = _allItems[index].copyWith(
            isAdded: false,
            quantity: 1,
          );
        } else {
          _allItems[index] = _allItems[index].copyWith(quantity: newQty);
        }
      }
    });
  }

  void _updateItemUnit(GroceryItem item, String newUnit) {
    if (item.isChecked) return; // Prevent modifying locked items
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _allItems[index] = _allItems[index].copyWith(selectedUnit: newUnit);
      }
    });
  }

  void _toggleCheck(GroceryItem item) {
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _allItems[index] = _allItems[index].copyWith(
          isChecked: !_allItems[index].isChecked,
        );
      }
    });
  }

  void _clearAllList() {
    setState(() {
      for (int i = 0; i < _allItems.length; i++) {
        _allItems[i] = _allItems[i].copyWith(isAdded: false, isChecked: false, quantity: 1);
      }
    });
    Navigator.of(context).pop();
  }

  void _saveCurrentListAsTemplate(String templateName) {
    final added = _allItems.where((i) => i.isAdded).toList();
    if (added.isEmpty) return;

    final snapshots = added.map((item) {
      return ItemSnapshot(
        id: item.id,
        nameEn: item.nameEn,
        nameHi: item.nameHi,
        category: item.category,
        selectedUnit: item.selectedUnit,
        quantity: item.quantity,
      );
    }).toList();

    final newTemplate = SavedListTemplate(
      id: 'tmpl_${DateTime.now().millisecondsSinceEpoch}',
      name: templateName,
      createdAt: DateTime.now(),
      items: snapshots,
    );

    setState(() {
      _savedTemplates.insert(0, newTemplate);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        content: Text(
          'Saved "$templateName" master template',
          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  void _reorderTemplate(SavedListTemplate template) {
    setState(() {
      // Un-add existing items first
      for (int i = 0; i < _allItems.length; i++) {
        _allItems[i] = _allItems[i].copyWith(isAdded: false, isChecked: false, quantity: 1);
      }

      // Reorder fresh copy of template items (Master template is NEVER modified!)
      for (final snap in template.items) {
        final index = _allItems.indexWhere((i) => i.id == snap.id);
        if (index != -1) {
          _allItems[index] = _allItems[index].copyWith(
            isAdded: true,
            isChecked: false,
            quantity: snap.quantity,
            selectedUnit: snap.selectedUnit,
          );
        } else {
          // Custom item from template
          _allItems.insert(
            0,
            GroceryItem(
              id: snap.id,
              nameEn: snap.nameEn,
              nameHi: snap.nameHi,
              category: snap.category,
              availableUnits: [snap.selectedUnit, '100 g', '250 g', '500 g', '1 kg'],
              selectedUnit: snap.selectedUnit,
              quantity: snap.quantity,
              isAdded: true,
              isChecked: false,
            ),
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text(
          'Restock list loaded from "${template.name}"',
          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  void _deleteTemplate(SavedListTemplate template) {
    setState(() {
      _savedTemplates.removeWhere((t) => t.id == template.id);
    });
  }

  void _showAddCustomItemDialog() {
    final nameEnController = TextEditingController();
    final nameHiController = TextEditingController();
    ItemCategory selectedCategory = ItemCategory.singleSpices;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Add Custom Item',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameEnController,
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Item Name (English)',
                        labelStyle: GoogleFonts.spaceGrotesk(fontSize: 13, color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameHiController,
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Hindi / Local Name (Optional)',
                        labelStyle: GoogleFonts.spaceGrotesk(fontSize: 13, color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ItemCategory>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: GoogleFonts.spaceGrotesk(fontSize: 13, color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ItemCategory.values.where((c) => c != ItemCategory.all).map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat.label,
                            style: GoogleFonts.spaceGrotesk(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    final nameEn = nameEnController.text.trim();
                    if (nameEn.isEmpty) return;

                    final newItem = GroceryItem(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      nameEn: nameEn,
                      nameHi: nameHiController.text.trim().isEmpty ? nameEn : nameHiController.text.trim(),
                      category: selectedCategory,
                      availableUnits: ['100 g', '250 g', '500 g', '1 kg', '1 Pack'],
                      selectedUnit: '250 g',
                      isAdded: true,
                    );

                    setState(() {
                      _allItems.insert(0, newItem);
                    });

                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Add to List',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openSavedTemplatesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.80,
          child: SavedTemplatesModal(
            templates: _savedTemplates,
            onUseTemplate: _reorderTemplate,
            onDeleteTemplate: _deleteTemplate,
          ),
        );
      },
    );
  }

  void _openShoppingListDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: ShoppingListDrawer(
            items: _allItems,
            onToggleCheck: _toggleCheck,
            onUpdateQuantity: _updateItemQuantity,
            onRemove: _toggleItemAdded,
            onClearAll: _clearAllList,
            onSaveAsTemplate: _saveCurrentListAsTemplate,
          ),
        );
      },
    );
  }

  Widget _buildItemCard(GroceryItem item) {
    final isLocked = item.isChecked;

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFCBD5E1)
              : (item.isAdded ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          width: item.isAdded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Badge & Lock Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category.label.split(' ').first,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12, // >= 12px
                    fontWeight: FontWeight.w700,
                    color: item.accentColor,
                  ),
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF475569)),
                      const SizedBox(width: 2),
                      Text(
                        'LOCKED',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, // >= 12px
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                )
              else if (item.isAdded)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
            ],
          ),

          const SizedBox(height: 6),

          // English Name (14px)
          Text(
            item.nameEn,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isLocked ? const Color(0xFF64748B) : const Color(0xFF0F172A),
              height: 1.15,
              decoration: isLocked ? TextDecoration.lineThrough : null,
            ),
          ),

          const SizedBox(height: 2),

          // Hindi / Local Name (12px)
          Text(
            item.nameHi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12, // Strictly >= 12px
              fontWeight: FontWeight.w500,
              color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 6),

          // Unit Selector Pill (Disabled if Locked)
          Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: DropdownButton<String>(
                    value: item.availableUnits.contains(item.selectedUnit)
                        ? item.selectedUnit
                        : item.availableUnits.first,
                    isDense: true,
                    isExpanded: false,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, // >= 12px
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                    onChanged: isLocked
                        ? null
                        : (newUnit) {
                            if (newUnit != null) {
                              _updateItemUnit(item, newUnit);
                            }
                          },
                    items: item.availableUnits.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(
                          u,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Action Button / Stepper (Disabled if Locked)
          Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: item.isAdded
                  ? Container(
                      decoration: BoxDecoration(
                        color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              iconSize: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              icon: const Icon(Icons.remove, color: Colors.white),
                              onPressed: isLocked ? null : () => _updateItemQuantity(item, item.quantity - 1),
                            ),
                            Text(
                              '${item.quantity}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              iconSize: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: isLocked ? null : () => _updateItemQuantity(item, item.quantity + 1),
                            ),
                          ],
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.add, size: 18, color: Color(0xFF059669)),
                      label: Text(
                        'ADD',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13, // >= 12px
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      onPressed: isLocked ? null : () => _toggleItemAdded(item),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsToDisplay = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shopping_basket_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'KICHOOK',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          // Saved Templates / Reorder Button
          IconButton(
            tooltip: 'Saved Templates',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_rounded, color: Color(0xFFD97706), size: 22),
                ),
                if (_savedTemplates.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Center(
                        child: Text(
                          '${_savedTemplates.length}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openSavedTemplatesModal,
          ),
          IconButton(
            tooltip: 'Add Custom Item',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF059669), size: 22),
            ),
            onPressed: _showAddCustomItemDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14, // >= 12px
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search Jeera, Haldi, Dhania, Milk...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Main Content: Left Sidebar + Right Item Grid
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT CATEGORY SIDEBAR
                Container(
                  width: 90,
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: ItemCategory.values.length,
                    itemBuilder: (context, index) {
                      final cat = ItemCategory.values[index];
                      final isSelected = _selectedCategory == cat;
                      final count = _getCategoryCount(cat);

                      return InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.08) : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 24,
                                    color: isSelected
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: -8,
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Center(
                                          child: Text(
                                            '$count',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 12, // >= 12px
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12, // Strictly >= 12px
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                // RIGHT PRODUCT CARDS GRID (DYNAMIC INTRINSIC HEIGHT ROWS)
                Expanded(
                  child: itemsToDisplay.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No matching items found',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                label: Text(
                                  'Add Custom Item',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: _showAddCustomItemDialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: (itemsToDisplay.length / 2).ceil(),
                          itemBuilder: (context, rowIndex) {
                            final firstIndex = rowIndex * 2;
                            final secondIndex = firstIndex + 1;
                            final item1 = itemsToDisplay[firstIndex];
                            final hasSecond = secondIndex < itemsToDisplay.length;
                            final item2 = hasSecond ? itemsToDisplay[secondIndex] : null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _buildItemCard(item1)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: hasSecond
                                          ? _buildItemCard(item2!)
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      // BOTTOM FLOATING LIST BAR
      bottomNavigationBar: _totalAddedCount > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
                child: InkWell(
                  onTap: _openShoppingListDrawer,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shopping_basket_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MY LIST ($_totalAddedCount ITEMS)',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14, // >= 12px
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Tap to view checklist & shop',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12, // >= 12px
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'VIEW LIST',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
