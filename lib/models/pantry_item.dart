import 'grocery_item.dart';

class PantryItem {
  final String id;
  final String name;
  final ItemCategory category;
  final String unit;
  int quantity;
  final DateTime addedDate;
  bool isLowStock;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
    DateTime? addedDate,
    this.isLowStock = false,
  }) : addedDate = addedDate ?? DateTime.now();

  PantryItem copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    String? unit,
    int? quantity,
    DateTime? addedDate,
    bool? isLowStock,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      addedDate: addedDate ?? this.addedDate,
      isLowStock: isLowStock ?? this.isLowStock,
    );
  }

  /// Clean, readable display stock that prevents awkward combinations like "2 1 kg" or "1 1 L".
  String get displayStock => formatQuantityAndUnit(quantity, unit);

  /// Production-grade formatter for inventory quantity and units.
  /// Solves unit-doubling glitches ("2 1 kg" -> "2 kg", "1 1 kg" -> "1 kg", "2 1 L" -> "2 L", "2 500 g" -> "1 kg").
  static String formatQuantityAndUnit(int qty, String rawUnit) {
    final trimmed = rawUnit.trim();
    if (trimmed.isEmpty) return '$qty';

    // Matches leading number in unit string e.g. "1 kg", "1 L", "500 g", "1.5 kg", "250g"
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(trimmed);

    if (match != null) {
      final packNum = double.tryParse(match.group(1)!) ?? 1.0;
      final baseUnit = match.group(2)!.trim();

      // If unit is "1 kg", "1 L", "1 Pc", "1 Pack", "1 Bunch"
      if (packNum == 1.0) {
        if (baseUnit.isEmpty) return '$qty';
        // Pluralize discrete countable packaging if qty > 1
        if (qty > 1) {
          final lower = baseUnit.toLowerCase();
          if (lower == 'pc') return '$qty Pcs';
          if (lower == 'pack') return '$qty Packs';
          if (lower == 'bunch') return '$qty Bunches';
          if (lower == 'box') return '$qty Boxes';
          if (lower == 'bottle') return '$qty Bottles';
        }
        return '$qty $baseUnit';
      } else {
        // If pack size is > 1 (e.g. "500 g", "250 g", "5 kg")
        if (qty == 1) {
          return trimmed;
        } else {
          final totalWeight = packNum * qty;
          final baseLower = baseUnit.toLowerCase();
          if (baseLower == 'g' || baseLower == 'gm' || baseLower == 'gms') {
            if (totalWeight >= 1000 && totalWeight % 1000 == 0) {
              return '${(totalWeight / 1000).toInt()} kg';
            } else if (totalWeight >= 1000) {
              return '${(totalWeight / 1000).toStringAsFixed(1)} kg';
            }
            return '${totalWeight.toInt()} g';
          } else if (baseLower == 'ml') {
            if (totalWeight >= 1000 && totalWeight % 1000 == 0) {
              return '${(totalWeight / 1000).toInt()} L';
            } else if (totalWeight >= 1000) {
              return '${(totalWeight / 1000).toStringAsFixed(1)} L';
            }
            return '${totalWeight.toInt()} ml';
          } else if (baseLower == 'kg' || baseLower == 'l') {
            final formatted = totalWeight % 1 == 0 ? totalWeight.toInt().toString() : totalWeight.toString();
            return '$formatted $baseUnit';
          }
          return '$qty × $trimmed';
        }
      }
    }

    // Unit does not start with a number (e.g. "kg", "g", "L", "Pcs")
    if (qty > 1) {
      final lower = trimmed.toLowerCase();
      if (lower == 'pc') return '$qty Pcs';
      if (lower == 'pack') return '$qty Packs';
      if (lower == 'bunch') return '$qty Bunches';
    }
    return '$qty $trimmed';
  }

  static List<PantryItem> getInitialPantryItems() {
    return [
      PantryItem(
        id: 'pantry_1',
        name: 'Jeera (Cumin Seeds)',
        category: ItemCategory.singleSpices,
        unit: 'g',
        quantity: 250,
      ),
      PantryItem(
        id: 'pantry_2',
        name: 'Whole Wheat Atta',
        category: ItemCategory.floursBaking,
        unit: 'kg',
        quantity: 5,
      ),
      PantryItem(
        id: 'pantry_3',
        name: 'Turmeric Powder (Haldi)',
        category: ItemCategory.singleSpices,
        unit: 'g',
        quantity: 100,
      ),
      PantryItem(
        id: 'pantry_4',
        name: 'Mustard Oil',
        category: ItemCategory.kitchenStaples,
        unit: 'L',
        quantity: 1,
      ),
      PantryItem(
        id: 'pantry_5',
        name: 'Toor Dal',
        category: ItemCategory.pulsesLentils,
        unit: 'kg',
        quantity: 2,
      ),
    ];
  }
}
