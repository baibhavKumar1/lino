import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grocery_item.dart';

class ShoppingListDrawer extends StatelessWidget {
  final List<GroceryItem> items;
  final Function(GroceryItem) onToggleCheck;
  final Function(GroceryItem, int) onUpdateQuantity;
  final Function(GroceryItem) onRemove;
  final VoidCallback onClearAll;
  final Function(String templateName) onSaveAsTemplate;

  const ShoppingListDrawer({
    super.key,
    required this.items,
    required this.onToggleCheck,
    required this.onUpdateQuantity,
    required this.onRemove,
    required this.onClearAll,
    required this.onSaveAsTemplate,
  });

  void _showSaveTemplateDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'My Restock List');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Save List as Template',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: TextField(
            controller: nameController,
            style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Template Name',
              labelStyle: GoogleFonts.spaceGrotesk(fontSize: 13, color: const Color(0xFF64748B)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  onSaveAsTemplate(name);
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Save Template',
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
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        final addedItems = items.where((item) => item.isAdded).toList();
        final checkedCount = addedItems.where((item) => item.isChecked).length;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Drawer Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY KITCHEN LIST',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addedItems.isEmpty
                                ? 'No items added yet'
                                : '$checkedCount of ${addedItems.length} items checked (Locked)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13, // >= 12px
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (addedItems.isNotEmpty) ...[
                      IconButton(
                        tooltip: 'Save as Template',
                        icon: const Icon(Icons.bookmark_add_outlined, size: 22, color: Color(0xFF059669)),
                        onPressed: () => _showSaveTemplateDialog(context),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          onClearAll();
                          setSheetState(() {});
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        label: Text(
                          'Clear',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Items List
              Flexible(
                child: addedItems.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_basket_outlined,
                              size: 56,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your list is empty',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + on any spice or produce card to build your list',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shrinkWrap: true,
                        itemCount: addedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = addedItems[index];
                          final isLocked = item.isChecked;

                          return Container(
                            decoration: BoxDecoration(
                              color: isLocked ? const Color(0xFFF1F5F9) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLocked
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  onToggleCheck(item);
                                  setSheetState(() {});
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isLocked
                                        ? const Color(0xFF10B981)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isLocked
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF94A3B8),
                                      width: 2,
                                    ),
                                  ),
                                  child: isLocked
                                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                      : null,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.nameEn,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF0F172A),
                                        decoration: isLocked ? TextDecoration.lineThrough : null,
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
                                          const SizedBox(width: 4),
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
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                isLocked
                                    ? '${item.nameHi} • ${item.selectedUnit} (Uncheck to edit)'
                                    : '${item.nameHi} • ${item.selectedUnit}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12, // >= 12px
                                  color: isLocked
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Quantity Stepper (DISABLED IF LOCKED)
                                  Opacity(
                                    opacity: isLocked ? 0.5 : 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isLocked ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            iconSize: 18,
                                            icon: const Icon(Icons.remove, color: Color(0xFF475569)),
                                            onPressed: isLocked
                                                ? null
                                                : () {
                                                    onUpdateQuantity(item, item.quantity - 1);
                                                    setSheetState(() {});
                                                  },
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            iconSize: 18,
                                            icon: const Icon(Icons.add, color: Color(0xFF475569)),
                                            onPressed: isLocked
                                                ? null
                                                : () {
                                                    onUpdateQuantity(item, item.quantity + 1);
                                                    setSheetState(() {});
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    iconSize: 20,
                                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      onRemove(item);
                                      setSheetState(() {});
                                    },
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
        );
      },
    );
  }
}
