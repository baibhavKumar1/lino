import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';
import 'tactile_tap.dart';

class ShoppingListDrawer extends StatelessWidget {
  final List<GroceryItem> items;
  final Function(GroceryItem) onToggleCheck;
  final Function(GroceryItem, int) onUpdateQuantity;
  final Function(GroceryItem) onRemove;
  final VoidCallback onClearAll;
  final Function(String templateName) onSaveAsTemplate;
  final Function(List<GroceryItem> purchasedItems) onConfirmPurchaseAndStock;

  const ShoppingListDrawer({
    super.key,
    required this.items,
    required this.onToggleCheck,
    required this.onUpdateQuantity,
    required this.onRemove,
    required this.onClearAll,
    required this.onSaveAsTemplate,
    required this.onConfirmPurchaseAndStock,
  });

  Future<void> _shareShoppingListViaWhatsApp(BuildContext context, List<GroceryItem> addedItems) async {
    if (addedItems.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🛒 LINO RESTOCK LIST (${addedItems.length} Items):');
    for (var item in addedItems) {
      /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
      buffer.writeln('- ${item.nameEn} (${item.nameHi}) — ${item.quantity} ${item.selectedUnit}');
      */
      final formattedQty = PantryItem.formatQuantityAndUnit(item.quantity, item.selectedUnit);
      buffer.writeln('- ${item.nameEn} (${item.nameHi}) — $formattedQty');
    }

    final message = buffer.toString();
    final encodedMsg = Uri.encodeComponent(message);

    final appUrl = Uri.parse('whatsapp://send?text=$encodedMsg');
    final webUrl = Uri.parse('https://api.whatsapp.com/send?text=$encodedMsg');
    final waMeUrl = Uri.parse('https://wa.me/?text=$encodedMsg');

    bool launched = false;

    // 1. Try native WhatsApp app scheme
    try {
      launched = await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } catch (_) {}

    // 2. Try api.whatsapp.com scheme
    if (!launched) {
      try {
        launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    // 3. Try wa.me scheme
    if (!launched) {
      try {
        launched = await launchUrl(waMeUrl, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    // 4. Fallback to Clipboard
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Copied Restock List to Clipboard! Ready to paste into WhatsApp.',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _showSaveTemplateDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'My Restock List');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlBorder),
          title: Text(
            'Save List as Template',
            style: AppTypography.displaySmall(fontSize: 18),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Template Name',
              border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  onSaveAsTemplate(name);
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Save Template',
                style: TextStyle(
                  fontSize: 13,
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
          /* PREVIOUS FLAT DECORATION - COMMENTED OUT AS PER RULE
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          */
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: AppShadows.modal,
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
                  decoration: const BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),

              // Drawer Header (Compact Flex Layout)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.primaryDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'My Restock List',
                              maxLines: 1,
                              style: AppTypography.displaySmall(fontSize: 17),
                            ),
                          ),
                          Text(
                            '${addedItems.length} items | $checkedCount purchased',
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                    // COMPACT ACTION ICON ROW
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TactileTap(
                          onTap: () => _shareShoppingListViaWhatsApp(context, addedItems),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 22),
                          ),
                        ),
                        if (addedItems.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          TactileTap(
                            onTap: () => _showSaveTemplateDialog(context),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.bookmark_add_outlined, color: AppColors.primary, size: 22),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        TactileTap(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Item List
              addedItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: AppColors.borderDark,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your Restock List is Empty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add items from the kitchen catalog to shop',
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ),
                    )
                  : Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shrinkWrap: true,
                        itemCount: addedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = addedItems[index];
                          final isChecked = item.isChecked;

                          return Container(
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? AppColors.surfaceMuted
                                  : AppColors.surface,
                              borderRadius: AppRadii.lgBorder,
                              border: Border.all(
                                color: isChecked
                                    ? AppColors.border
                                    : AppColors.borderDark,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: (_) {
                                    onToggleCheck(item);
                                    setSheetState(() {});
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nameEn,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isChecked
                                              ? AppColors.textMuted
                                              : AppColors.textPrimary,
                                          decoration: isChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        '${item.nameHi} | ${item.selectedUnit}',
                                        style: AppTypography.bodySmall(),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Stepper (Disabled if locked/checked)
                                Opacity(
                                  opacity: isChecked ? 0.4 : 1.0,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: isChecked
                                            ? null
                                            : () {
                                                if (item.quantity > 1) {
                                                  onUpdateQuantity(
                                                    item,
                                                    item.quantity - 1,
                                                  );
                                                  setSheetState(() {});
                                                }
                                              },
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: isChecked
                                            ? null
                                            : () {
                                                onUpdateQuantity(
                                                  item,
                                                  item.quantity + 1,
                                                );
                                                setSheetState(() {});
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: () {
                                    onRemove(item);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

              // Drawer Footer Actions
              if (addedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PRIMARY CTA: CONFIRM PURCHASE & STOCK TO PANTRY
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: TactileTap(
                          onTap: () {
                            final itemsToStock = checkedCount > 0
                                ? addedItems.where((i) => i.isChecked).toList()
                                : addedItems;
                            onConfirmPurchaseAndStock(itemsToStock);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadii.mdBorder,
                              boxShadow: AppShadows.card,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  checkedCount > 0
                                      ? 'Stock $checkedCount Purchased Items to Pantry'
                                      : 'Stock All (${addedItems.length}) to Pantry',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.danger),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.mdBorder,
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_sweep_outlined,
                                color: AppColors.danger,
                                size: 16,
                              ),
                              label: const Text(
                                'Clear List',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              onPressed: () {
                                onClearAll();
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.mdBorder,
                                ),
                              ),
                              icon: const Icon(Icons.share, color: Colors.white, size: 16),
                              label: const Text(
                                'WhatsApp Share',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              onPressed: () => _shareShoppingListViaWhatsApp(context, addedItems),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
