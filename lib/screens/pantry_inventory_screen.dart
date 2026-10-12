import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../widgets/pantry_inventory_modal.dart';

export '../widgets/pantry_inventory_modal.dart';

/// First-class screen wrapper for Kitchen Inventory in Lino
class PantryInventoryScreen extends StatelessWidget {
  final List<PantryItem> pantryItems;
  final Function(PantryItem) onAddPantryItem;
  final Function(PantryItem) onUpdatePantryItem;
  final Function(PantryItem, int) onUpdatePantryQuantity;
  final Function(PantryItem) onDeletePantryItem;
  final Function(PantryItem) onPushToRestockList;
  final VoidCallback? onOpenReceiptScanner;
  final bool isLoading;

  const PantryInventoryScreen({
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
  Widget build(BuildContext context) {
    return PantryInventoryModal(
      pantryItems: pantryItems,
      onAddPantryItem: onAddPantryItem,
      onUpdatePantryItem: onUpdatePantryItem,
      onUpdatePantryQuantity: onUpdatePantryQuantity,
      onDeletePantryItem: onDeletePantryItem,
      onPushToRestockList: onPushToRestockList,
      onOpenReceiptScanner: onOpenReceiptScanner,
      isLoading: isLoading,
    );
  }
}
