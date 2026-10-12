import 'package:flutter/material.dart';

enum ItemCategory {
  all('All Items', Icons.grid_view_rounded),
  singleSpices('Single Spices', Icons.spa_rounded),
  masalaBlends('Masala Blends', Icons.blender_rounded),
  freshProduce('Produce & Herbs', Icons.eco_rounded),
  riceGrains('Rice & Grains', Icons.rice_bowl_rounded),
  pulsesLentils('Dals & Pulses', Icons.grain_rounded),
  dryFruitsNuts('Dry Fruits & Nuts', Icons.breakfast_dining_rounded),
  readyToCook('Ready to Cook', Icons.soup_kitchen_rounded),
  floursBaking('Flours & Baking', Icons.bakery_dining_rounded),
  kitchenStaples('Staples & Dairy', Icons.kitchen_rounded);

  final String label;
  final IconData icon;
  const ItemCategory(this.label, this.icon);
}

class GroceryItem {
  final String id;
  final String nameEn;
  final String nameHi;
  final ItemCategory category;
  final List<String> availableUnits;
  String selectedUnit;
  int quantity;
  bool isAdded;
  bool isChecked;
  final Color accentColor;
  final String? imagePath;

  GroceryItem({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.category,
    required this.availableUnits,
    required this.selectedUnit,
    this.quantity = 1,
    this.isAdded = false,
    this.isChecked = false,
    /* PREVIOUS GREEN ACCENT - COMMENTED OUT AS PER RULE
    this.accentColor = const Color(0xFF10B981),
    */
    this.accentColor = const Color(0xFF0066FF),
    this.imagePath,
  });

  GroceryItem copyWith({
    String? id,
    String? nameEn,
    String? nameHi,
    ItemCategory? category,
    List<String>? availableUnits,
    String? selectedUnit,
    int? quantity,
    bool? isAdded,
    bool? isChecked,
    Color? accentColor,
    String? imagePath,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      category: category ?? this.category,
      availableUnits: availableUnits ?? this.availableUnits,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      quantity: quantity ?? this.quantity,
      isAdded: isAdded ?? this.isAdded,
      isChecked: isChecked ?? this.isChecked,
      accentColor: accentColor ?? this.accentColor,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class ItemSnapshot {
  final String id;
  final String nameEn;
  final String nameHi;
  final ItemCategory category;
  final String selectedUnit;
  final int quantity;

  ItemSnapshot({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.category,
    required this.selectedUnit,
    required this.quantity,
  });
}

class SavedListTemplate {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<ItemSnapshot> items;

  SavedListTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
  });
}

class GroceryCatalog {
  static const List<String> defaultProduceUnits = ['1 Pc', '100 g', '250 g', '1 kg', '1 Bunch'];
  static const List<String> defaultSpiceUnits = ['50 g', '100 g', '250 g', '1 kg', '1 Pack'];
  static const List<String> defaultGrainUnits = ['1 kg', '5 kg', '10 kg', '500 g'];
  static const List<String> defaultPulseUnits = ['500 g', '1 kg', '2 kg'];
  static const List<String> defaultDairyUnits = ['1 L', '500 ml', '200 g', '1 Pack'];
  static const List<String> defaultNutUnits = ['100 g', '250 g', '500 g', '1 kg', '1 Pack'];
  static const List<String> defaultReadyUnits = ['1 Pack', '200 g', '500 g', '1 Pc'];
  static const List<String> defaultFlourUnits = ['1 kg', '5 kg', '500 g', '1 Pack'];

  static List<GroceryItem> getInitialItems() {
    return [
      // ==========================================
      // 1. RICE & SPECIALTY GRAINS (35 Items)
      // ==========================================
      GroceryItem(id: 'r1', nameEn: 'Basmati Rice (Classic)', nameHi: 'Basmati Chawal', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF0284C7), imagePath: 'assets/images/rice.png'),
      GroceryItem(id: 'r2', nameEn: '1121 XL Basmati Rice', nameHi: 'Extra Long Basmati', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF0369A1), imagePath: 'assets/images/rice.png'),
      GroceryItem(id: 'r3', nameEn: 'Sona Masoori Rice', nameHi: 'Sona Masoori', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF0284C7), imagePath: 'assets/images/rice.png'),
      GroceryItem(id: 'r4', nameEn: 'Wada Kolam Rice', nameHi: 'Kolam Chawal', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF0D9488), imagePath: 'assets/images/rice.png'),
      GroceryItem(id: 'r5', nameEn: 'Ponni Rice (Raw)', nameHi: 'Raw Ponni', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF059669)),
      GroceryItem(id: 'r6', nameEn: 'Ponni Rice (Parboiled)', nameHi: 'Ukda Chawal', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF059669)),
      GroceryItem(id: 'r7', nameEn: 'Kerala Matta Rice', nameHi: 'Palakkadan Matta', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFB91C1C)),
      GroceryItem(id: 'r8', nameEn: 'Gobindobhog Rice', nameHi: 'Aromatic Bengali Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'r9', nameEn: 'Ambemohar Rice', nameHi: 'Mango Blossom Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'r10', nameEn: 'Seeraga Samba / Jeera Rice', nameHi: 'Biryani Short Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'r11', nameEn: 'Idli Rice (Short Parboiled)', nameHi: 'Dosa & Idli Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF475569)),
      GroceryItem(id: 'r12', nameEn: 'Brown Rice (Whole Grain)', nameHi: 'Brown Chawal', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'r13', nameEn: 'Black Rice (Chak-hao)', nameHi: 'Forbidden Black Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFF1E293B)),
      GroceryItem(id: 'r14', nameEn: 'Red Rice (Himalayan)', nameHi: 'Red Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'r15', nameEn: 'Jasmine Rice', nameHi: 'Thai Fragrant Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF0EA5E9)),
      GroceryItem(id: 'r16', nameEn: 'Sushi Rice (Short Grain)', nameHi: 'Japanese Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'r17', nameEn: 'Arborio Rice', nameHi: 'Risotto Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFF0284C7)),
      GroceryItem(id: 'r18', nameEn: 'Wild Rice', nameHi: 'Wild Rice Blend', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFF334155)),
      GroceryItem(id: 'r19', nameEn: 'Thick Poha', nameHi: 'Mota Poha', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'r20', nameEn: 'Thin Poha / Paper Poha', nameHi: 'Patla Poha', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'r21', nameEn: 'Red Rice Poha', nameHi: 'Lal Poha', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'r22', nameEn: 'Puffed Rice', nameHi: 'Murmura / Kurmura', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '250 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'r23', nameEn: 'Bamboo Rice', nameHi: 'Moongil Arisi', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '250 g', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'r24', nameEn: 'Kalanamak Rice', nameHi: 'Buddha Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF334155)),
      GroceryItem(id: 'r25', nameEn: 'Indrayani Rice', nameHi: 'Sticky Maharashtrian Rice', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF0284C7)),
      GroceryItem(id: 'r26', nameEn: 'Barnyard Millet', nameHi: 'Sanwa / Samak', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'r27', nameEn: 'Foxtail Millet', nameHi: 'Kangni', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'r28', nameEn: 'Kodo Millet', nameHi: 'Kodon', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'r29', nameEn: 'Little Millet', nameHi: 'Kutki', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '500 g', accentColor: const Color(0xFF854D0E)),
      GroceryItem(id: 'r30', nameEn: 'Pearl Millet Grains', nameHi: 'Bajra Whole', category: ItemCategory.riceGrains, availableUnits: defaultGrainUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFB45309)),

      // ==========================================
      // 2. DALS, PULSES & BEANS (30 Items)
      // ==========================================
      GroceryItem(id: 'd1', nameEn: 'Toor Dal / Arhar Dal', nameHi: 'Split Pigeon Pea', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'd2', nameEn: 'Yellow Moong Dal', nameHi: 'Split Yellow Moong', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'd3', nameEn: 'Whole Green Moong', nameHi: 'Sabut Moong', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'd4', nameEn: 'Chana Dal', nameHi: 'Split Bengal Gram', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'd5', nameEn: 'Urad Dal (Split White)', nameHi: 'Dhuli Urad', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'd6', nameEn: 'Urad Dal (Whole Black)', nameHi: 'Sabut Urad (Dal Makhani)', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF334155)),
      GroceryItem(id: 'd7', nameEn: 'Urad Dal (Split Black)', nameHi: 'Chilka Urad', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF475569)),
      GroceryItem(id: 'd8', nameEn: 'Masoor Dal (Pink Split)', nameHi: 'Lal Masoor', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFEF4444)),
      GroceryItem(id: 'd9', nameEn: 'Whole Masoor Dal', nameHi: 'Kali Masoor', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'd10', nameEn: 'Rajma (Chitra / Spotted)', nameHi: 'Chitra Rajma', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFB91C1C)),
      GroceryItem(id: 'd11', nameEn: 'Rajma (Jammu Red)', nameHi: 'Dark Red Rajma', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'd12', nameEn: 'Kabuli Chana (Chole)', nameHi: 'White Chickpeas', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'd13', nameEn: 'Kala Chana', nameHi: 'Black Chickpeas', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'd14', nameEn: 'White Matar (Dry)', nameHi: 'Safed Matar', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'd15', nameEn: 'Green Matar (Dry)', nameHi: 'Sookha Hara Matar', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'd16', nameEn: 'Lobia (Black Eyed Peas)', nameHi: 'Chawli / Lobia', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'd17', nameEn: 'Horse Gram', nameHi: 'Kulthi Dal', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '500 g', accentColor: const Color(0xFF92400E)),
      GroceryItem(id: 'd18', nameEn: 'Moth Beans', nameHi: 'Matki', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '500 g', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'd19', nameEn: 'Fried Gram / Roasted Chana', nameHi: 'Bhuna Chana / Daria', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '500 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'd20', nameEn: 'Soybeans (Dry Whole)', nameHi: 'Soyabean Dana', category: ItemCategory.pulsesLentils, availableUnits: defaultPulseUnits, selectedUnit: '500 g', accentColor: const Color(0xFF65A30D)),

      // ==========================================
      // 3. SINGLE SPICES & HERBS (45 Items)
      // ==========================================
      GroceryItem(id: 's1', nameEn: 'Cumin Seeds', nameHi: 'Jeera', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 's2', nameEn: 'Shahi Jeera (Black Cumin)', nameHi: 'Shahi Jeera', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 's3', nameEn: 'Coriander Seeds', nameHi: 'Dhania Sabut', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 's4', nameEn: 'Coriander Powder', nameHi: 'Dhania Powder', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF4D7C0F)),
      GroceryItem(id: 's5', nameEn: 'Turmeric Powder', nameHi: 'Haldi', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 's6', nameEn: 'Whole Turmeric Sticks', nameHi: 'Sabut Haldi', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 's7', nameEn: 'Red Chili Powder', nameHi: 'Teekhi Laal Mirch', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFDC2626)),
      GroceryItem(id: 's8', nameEn: 'Kashmiri Red Chili', nameHi: 'Kashmiri Mirch', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFB91C1C)),
      GroceryItem(id: 's9', nameEn: 'Deggi Mirch', nameHi: 'Deggi Mirch Powder', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFEF4444)),
      GroceryItem(id: 's10', nameEn: 'Black Mustard Seeds', nameHi: 'Rai / Kaali Sarson', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 's11', nameEn: 'Yellow Mustard Seeds', nameHi: 'Peeli Sarson', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 's12', nameEn: 'Fenugreek Seeds', nameHi: 'Methi Dana', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 's13', nameEn: 'Kasuri Methi', nameHi: 'Dried Fenugreek Leaves', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 's14', nameEn: 'Black Pepper (Whole)', nameHi: 'Kaali Mirch Sabut', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF334155)),
      GroceryItem(id: 's15', nameEn: 'Black Pepper Powder', nameHi: 'Kaali Mirch Powder', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF1E293B)),
      GroceryItem(id: 's16', nameEn: 'White Pepper Powder', nameHi: 'Safed Mirch', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 's17', nameEn: 'Green Cardamom', nameHi: 'Hari Elaichi', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 's18', nameEn: 'Black Cardamom', nameHi: 'Badi Elaichi', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF475569)),
      GroceryItem(id: 's19', nameEn: 'Cinnamon Sticks', nameHi: 'Dalchini', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF92400E)),
      GroceryItem(id: 's20', nameEn: 'Cloves', nameHi: 'Laung', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 's21', nameEn: 'Bay Leaf', nameHi: 'Tej Patta', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF4D7C0F)),
      GroceryItem(id: 's22', nameEn: 'Fennel Seeds', nameHi: 'Saunf', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 's23', nameEn: 'Carom Seeds', nameHi: 'Ajwain', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF854D0E)),
      GroceryItem(id: 's24', nameEn: 'Asafoetida (Hing)', nameHi: 'Hing Powder', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 's25', nameEn: 'Dry Mango Powder', nameHi: 'Amchur', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 's26', nameEn: 'Pomegranate Powder', nameHi: 'Anardana Powder', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 's27', nameEn: 'Nigella Seeds', nameHi: 'Kalonji', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF1E293B)),
      GroceryItem(id: 's28', nameEn: 'Dried Parsley Flakes', nameHi: 'Parsley Flakes', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 's29', nameEn: 'Garlic Powder', nameHi: 'Lehsun Powder', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 's30', nameEn: 'Onion Powder', nameHi: 'Pyaaz Powder', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFFA855F7)),
      GroceryItem(id: 's31', nameEn: 'Star Anise', nameHi: 'Chakri Phool', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 's32', nameEn: 'Nutmeg', nameHi: 'Jaiphal', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF92400E)),
      GroceryItem(id: 's33', nameEn: 'Mace', nameHi: 'Javitri', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '25 g', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 's34', nameEn: 'Saffron (Kesar)', nameHi: 'Kesar Strands', category: ItemCategory.singleSpices, availableUnits: ['1 g', '2 g', '5 g'], selectedUnit: '1 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 's35', nameEn: 'Poppy Seeds', nameHi: 'Khus Khus', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 's36', nameEn: 'White Sesame Seeds', nameHi: 'Safed Til', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 's37', nameEn: 'Black Sesame Seeds', nameHi: 'Kala Til', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF1E293B)),
      GroceryItem(id: 's38', nameEn: 'Black Salt', nameHi: 'Kala Namak', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 's39', nameEn: 'Rock Salt / Pink Salt', nameHi: 'Sendha Namak', category: ItemCategory.singleSpices, availableUnits: defaultSpiceUnits, selectedUnit: '500 g', accentColor: const Color(0xFFF43F5E)),

      // ==========================================
      // 4. MASALA BLENDS & SEASONINGS (45 Items)
      // ==========================================
      GroceryItem(id: 'b1', nameEn: 'Garam Masala', nameHi: 'Special Garam Masala', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'b2', nameEn: 'Sambar Masala', nameHi: 'South Sambar Powder', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFC2410C)),
      GroceryItem(id: 'b3', nameEn: 'Rasam Powder', nameHi: 'Peppery Rasam Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFDC2626)),
      GroceryItem(id: 'b4', nameEn: 'Chaat Masala', nameHi: 'Tangy Chaat Masala', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'b5', nameEn: 'Pav Bhaji Masala', nameHi: 'Mumbai Pav Bhaji Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'b6', nameEn: 'Biryani Masala', nameHi: 'Shahi Biryani Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF7C2D12)),
      GroceryItem(id: 'b7', nameEn: 'Kitchen King Masala', nameHi: 'All Purpose Sabzi Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF059669)),
      GroceryItem(id: 'b8', nameEn: 'Chana Masala', nameHi: 'Chole Masala', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'b9', nameEn: 'Rajma Masala', nameHi: 'Special Rajma Powder', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'b10', nameEn: 'Paneer Butter Masala Powder', nameHi: 'Paneer Spice Mix', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFEF4444)),
      GroceryItem(id: 'b11', nameEn: 'Fish Curry Masala', nameHi: 'Machhli Masala', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFC2410C)),
      GroceryItem(id: 'b12', nameEn: 'Chicken Curry Masala', nameHi: 'Chicken Masala', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFB91C1C)),
      GroceryItem(id: 'b13', nameEn: 'Mutton Masala', nameHi: 'Meat Masala', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'b14', nameEn: 'Tandoori Masala', nameHi: 'Tikka Tandoori Powder', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFDC2626)),
      GroceryItem(id: 'b15', nameEn: 'Pani Puri Masala', nameHi: 'Golgappa Water Mix', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'b16', nameEn: 'Tea / Chai Masala', nameHi: 'Spiced Tea Masala', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF92400E)),
      GroceryItem(id: 'b17', nameEn: 'Gunpowder / Idli Podi', nameHi: 'Milagai Podi', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFC2410C)),
      GroceryItem(id: 'b18', nameEn: 'Bisi Bele Bath Powder', nameHi: 'Karnataka Rice Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'b19', nameEn: 'Vada Pav Masala', nameHi: 'Dry Garlic Chutney Mix', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFFB91C1C)),
      GroceryItem(id: 'b20', nameEn: 'Goda Masala', nameHi: 'Maharashtrian Goda Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF334155)),
      GroceryItem(id: 'b21', nameEn: 'Panch Phoron', nameHi: 'Bengali 5-Spice Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF475569)),
      GroceryItem(id: 'b22', nameEn: 'Mexican Masala', nameHi: 'Tex-Mex Seasoning', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFDC2626)),
      GroceryItem(id: 'b23', nameEn: 'Taco Seasoning', nameHi: 'Taco Seasoning Mix', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'b24', nameEn: 'Fajita Seasoning', nameHi: 'Mexican Fajita Mix', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFFC2410C)),
      GroceryItem(id: 'b25', nameEn: 'Chipotle Powder', nameHi: 'Smoky Chipotle Pepper', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'b26', nameEn: 'Smoked Paprika', nameHi: 'Smoky Red Paprika', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFB91C1C)),
      GroceryItem(id: 'b27', nameEn: 'Peri Peri Seasoning', nameHi: 'Spicy African Peri Peri', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFE11D48)),
      GroceryItem(id: 'b28', nameEn: 'Italian Seasoning', nameHi: 'Mixed Italian Herbs', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFF059669)),
      GroceryItem(id: 'b29', nameEn: 'Chili Flakes (Red)', nameHi: 'Kuti Mirch Flakes', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFDC2626)),
      GroceryItem(id: 'b30', nameEn: 'Pizza & Pasta Seasoning', nameHi: 'Herb & Garlic Sprinkle', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'b31', nameEn: 'Cajun Seasoning', nameHi: 'Spicy Cajun Blend', category: ItemCategory.masalaBlends, availableUnits: defaultSpiceUnits, selectedUnit: '50 g', accentColor: const Color(0xFFC2410C)),

      // ==========================================
      // 5. VEGETABLES, GOURDS & GREENS (70 Items)
      // ==========================================
      GroceryItem(id: 'v1', nameEn: 'Red Onion', nameHi: 'Pyaaz', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFA855F7)),
      GroceryItem(id: 'v2', nameEn: 'White Onion', nameHi: 'Safed Pyaaz', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'v3', nameEn: 'Shallots / Sambar Onion', nameHi: 'Chota Pyaaz', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF9333EA)),
      GroceryItem(id: 'v4', nameEn: 'Tomato', nameHi: 'Tamatar', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFEF4444)),
      GroceryItem(id: 'v5', nameEn: 'Cherry Tomatoes', nameHi: 'Chota Tamatar', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFFF43F5E)),
      GroceryItem(id: 'v6', nameEn: 'Potato', nameHi: 'Aloo', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'v7', nameEn: 'Sweet Potato', nameHi: 'Shakarkandi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'v8', nameEn: 'Fresh Ginger', nameHi: 'Adrak', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '100 g', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'v9', nameEn: 'Fresh Garlic', nameHi: 'Lehsun', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'v10', nameEn: 'Green Chili', nameHi: 'Hari Mirch', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '100 g', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v11', nameEn: 'Lemon / Lime', nameHi: 'Nimbu', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'v12', nameEn: 'Raw Mango', nameHi: 'Kaccha Aam / Kairi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'v13', nameEn: 'Spinach', nameHi: 'Palak', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v14', nameEn: 'Fresh Fenugreek', nameHi: 'Methi Leaves', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v15', nameEn: 'Fresh Coriander', nameHi: 'Hara Dhania', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF22C55E)),
      GroceryItem(id: 'v16', nameEn: 'Fresh Mint', nameHi: 'Pudina', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF10B981)),
      GroceryItem(id: 'v17', nameEn: 'Curry Leaves', nameHi: 'Kadi Patta', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v18', nameEn: 'Sarson Saag', nameHi: 'Mustard Leaves', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF4D7C0F)),
      GroceryItem(id: 'v19', nameEn: 'Spring Onion', nameHi: 'Hara Pyaaz', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v20', nameEn: 'Bottle Gourd', nameHi: 'Lauki / Doodhi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'v21', nameEn: 'Bitter Gourd', nameHi: 'Karela', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v22', nameEn: 'Ridge Gourd', nameHi: 'Turai / Dodka', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v23', nameEn: 'Pointed Gourd', nameHi: 'Parwal', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF4D7C0F)),
      GroceryItem(id: 'v24', nameEn: 'Ivy Gourd', nameHi: 'Tindora / Kundru', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v25', nameEn: 'Round Gourd', nameHi: 'Tinda', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'v26', nameEn: 'Ash Gourd', nameHi: 'Pethakaddu / Safed Kaddu', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'v27', nameEn: 'Snake Gourd', nameHi: 'Chichinda / Padwal', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v28', nameEn: 'Okra / Ladyfinger', nameHi: 'Bhindi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v29', nameEn: 'Eggplant (Large)', nameHi: 'Bhartaa Baingan', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFFA855F7)),
      GroceryItem(id: 'v30', nameEn: 'Small Brinjal', nameHi: 'Chota Baingan', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF9333EA)),
      GroceryItem(id: 'v31', nameEn: 'Cauliflower', nameHi: 'Phool Gobhi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'v32', nameEn: 'Cabbage', nameHi: 'Patta Gobhi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'v33', nameEn: 'Broccoli', nameHi: 'Hari Gobhi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v34', nameEn: 'Orange Carrot', nameHi: 'Gajar', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '500 g', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'v35', nameEn: 'Red Delhi Carrot', nameHi: 'Laal Gajar', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '500 g', accentColor: const Color(0xFFDC2626)),
      GroceryItem(id: 'v36', nameEn: 'White Radish', nameHi: 'Mooli', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF94A3B8)),
      GroceryItem(id: 'v37', nameEn: 'Beetroot', nameHi: 'Chukandar', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF991B1B)),
      GroceryItem(id: 'v38', nameEn: 'Arbi / Colocasia Root', nameHi: 'Arbi', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'v39', nameEn: 'Elephant Yam', nameHi: 'Jimikand / Suran', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '500 g', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'v40', nameEn: 'Green Capsicum', nameHi: 'Shimla Mirch', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v41', nameEn: 'Red & Yellow Bell Peppers', nameHi: 'Color Shimla Mirch', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'v42', nameEn: 'Cucumber', nameHi: 'Kheera', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF22C55E)),
      GroceryItem(id: 'v43', nameEn: 'Green Peas (Fresh)', nameHi: 'Matar', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v44', nameEn: 'French Beans', nameHi: 'Beans', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v45', nameEn: 'Cluster Beans', nameHi: 'Gwar Phali', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFF4D7C0F)),
      GroceryItem(id: 'v46', nameEn: 'Drumstick', nameHi: 'Sahjan / Moringa', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v47', nameEn: 'Yellow Pumpkin', nameHi: 'Kaddu', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '500 g', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'v48', nameEn: 'Button Mushrooms', nameHi: 'Kukurmutta Pack', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'v49', nameEn: 'Sweet Corn Cobs', nameHi: 'Bhutta', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'v50', nameEn: 'Raw Jackfruit', nameHi: 'Kaccha Kathal', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '250 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'v51', nameEn: 'Fresh Parsley (Flat)', nameHi: 'Italian Parsley', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'v52', nameEn: 'Fresh Parsley (Curly)', nameHi: 'Curly Parsley', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF15803D)),
      GroceryItem(id: 'v53', nameEn: 'Fresh Basil', nameHi: 'Sweet Basil', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF059669)),
      GroceryItem(id: 'v54', nameEn: 'Tulsi Leaves', nameHi: 'Holy Basil', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Bunch', accentColor: const Color(0xFF047857)),
      GroceryItem(id: 'v55', nameEn: 'Fresh Brown Coconut', nameHi: 'Pani Wala Nariyal', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'v56', nameEn: 'Tender Green Coconut', nameHi: 'Nariyal Pani', category: ItemCategory.freshProduce, availableUnits: defaultProduceUnits, selectedUnit: '1 Pc', accentColor: const Color(0xFF16A34A)),

      // ==========================================
      // 6. DRY FRUITS, NUTS & SEEDS (25 Items)
      // ==========================================
      GroceryItem(id: 'df1', nameEn: 'Almonds (California)', nameHi: 'Badam Giri', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '250 g', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'df2', nameEn: 'Cashew Nuts (Whole)', nameHi: 'Sabut Kaju', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '250 g', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'df3', nameEn: 'Pistachios (Salted)', nameHi: 'Namkeen Pista', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '100 g', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'df4', nameEn: 'Walnuts (Akhrot Giri)', nameHi: 'Akhrot', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '250 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'df5', nameEn: 'Raisins (Green Kishmish)', nameHi: 'Kishmish', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '250 g', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'df6', nameEn: 'Dates (Kimia Soft)', nameHi: 'Khajoor', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '500 g', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'df7', nameEn: 'Dried Figs', nameHi: 'Anjeer', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '250 g', accentColor: const Color(0xFF92400E)),
      GroceryItem(id: 'df8', nameEn: 'Makhana (Foxnuts)', nameHi: 'Phool Makhana', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '100 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'df9', nameEn: 'Pumpkin Seeds', nameHi: 'Kaddu Ke Beej', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '100 g', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'df10', nameEn: 'Chia Seeds', nameHi: 'Chia Seeds', category: ItemCategory.dryFruitsNuts, availableUnits: defaultNutUnits, selectedUnit: '100 g', accentColor: const Color(0xFF1E293B)),

      // ==========================================
      // 7. READY TO COOK & INSTANT (35 Items)
      // ==========================================
      GroceryItem(id: 'rtc1', nameEn: 'Fresh Dosa & Idli Batter', nameHi: 'Idli Dosa Peeth', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFF0284C7)),
      GroceryItem(id: 'rtc2', nameEn: 'Malabar Parota (Ready Toast)', nameHi: 'Ready Paratha', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'rtc3', nameEn: 'Whole Wheat Chapati / Phulka', nameHi: 'Ready Roti Pack', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'rtc4', nameEn: 'Garlic Tandoori Naan', nameHi: 'Frozen Garlic Naan', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'rtc5', nameEn: 'Soya Chunks / Soya Vadi', nameHi: 'Nutrela Soya Vadi', category: ItemCategory.readyToCook, availableUnits: ['200 g', '500 g', '1 Pack'], selectedUnit: '200 g', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'rtc6', nameEn: 'Frozen Green Peas', nameHi: 'Frozen Matar', category: ItemCategory.readyToCook, availableUnits: ['500 g', '1 kg', '1 Pack'], selectedUnit: '500 g', accentColor: const Color(0xFF16A34A)),
      GroceryItem(id: 'rtc7', nameEn: 'Frozen Sweet Corn', nameHi: 'Frozen Corn Kernels', category: ItemCategory.readyToCook, availableUnits: ['500 g', '1 kg', '1 Pack'], selectedUnit: '500 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'rtc8', nameEn: 'Frozen French Fries', nameHi: 'Potato Fries', category: ItemCategory.readyToCook, availableUnits: ['500 g', '1 kg', '1 Pack'], selectedUnit: '500 g', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'rtc9', nameEn: 'Paneer Butter Masala Gravy Base', nameHi: 'Makhani Gravy Base', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFFDC2626)),
      GroceryItem(id: 'rtc10', nameEn: 'Biryani Gravy Paste', nameHi: 'Biryani Cook Paste', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFF7C2D12)),
      GroceryItem(id: 'rtc11', nameEn: 'Schezwan Sauce / Chutney', nameHi: 'Spicy Schezwan Sauce', category: ItemCategory.readyToCook, availableUnits: ['200 g', '500 g', '1 Pack'], selectedUnit: '200 g', accentColor: const Color(0xFFB91C1C)),
      GroceryItem(id: 'rtc12', nameEn: 'Instant Noodles (Maggi)', nameHi: 'Noodles 4-Pack', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'rtc13', nameEn: 'Instant Poha Mix', nameHi: 'Ready Poha Mix', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'rtc14', nameEn: 'Instant Upma / Rava Mix', nameHi: 'Ready Upma Mix', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'rtc15', nameEn: 'Instant Gulab Jamun Mix', nameHi: 'Gulab Jamun Mix', category: ItemCategory.readyToCook, availableUnits: defaultReadyUnits, selectedUnit: '1 Pack', accentColor: const Color(0xFF991B1B)),

      // ==========================================
      // 8. FLOURS & BAKING (20 Items)
      // ==========================================
      GroceryItem(id: 'fl1', nameEn: 'Whole Wheat Atta', nameHi: 'Gehun Ka Atta', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '5 kg', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'fl2', nameEn: 'Maida (All Purpose Flour)', nameHi: 'Safed Maida', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF64748B)),
      GroceryItem(id: 'fl3', nameEn: 'Besan (Gram Flour)', nameHi: 'Chana Besan', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'fl4', nameEn: 'Sooji / Rava (Coarse)', nameHi: 'Suji / Rawa', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '1 kg', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'fl5', nameEn: 'Dalia (Broken Wheat)', nameHi: 'Wheat Dalia', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '500 g', accentColor: const Color(0xFFB45309)),
      GroceryItem(id: 'fl6', nameEn: 'Bajra Atta', nameHi: 'Pearl Millet Flour', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF78350F)),
      GroceryItem(id: 'fl7', nameEn: 'Jowar Atta', nameHi: 'Sorghum Flour', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF854D0E)),
      GroceryItem(id: 'fl8', nameEn: 'Ragi Atta', nameHi: 'Finger Millet Flour', category: ItemCategory.floursBaking, availableUnits: defaultFlourUnits, selectedUnit: '1 kg', accentColor: const Color(0xFF991B1B)),

      // ==========================================
      // 9. OILS, GHEE, DAIRY & PANTRY (20 Items)
      // ==========================================
      GroceryItem(id: 'k1', nameEn: 'Pure Cow Desi Ghee', nameHi: 'Ghee', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '1 L', accentColor: const Color(0xFFEA580C)),
      GroceryItem(id: 'k2', nameEn: 'Fresh Milk', nameHi: 'Doodh', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '1 L', accentColor: const Color(0xFF0284C7)),
      GroceryItem(id: 'k3', nameEn: 'Paneer (Cottage Cheese)', nameHi: 'Paneer Block', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '200 g', accentColor: const Color(0xFF059669)),
      GroceryItem(id: 'k4', nameEn: 'Tofu (Soya Paneer)', nameHi: 'Tofu', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '200 g', accentColor: const Color(0xFF65A30D)),
      GroceryItem(id: 'k5', nameEn: 'Dahi / Fresh Curd', nameHi: 'Dahi Container', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '500 g', accentColor: const Color(0xFF0EA5E9)),
      GroceryItem(id: 'k6', nameEn: 'Butter (Salted)', nameHi: 'Makhan', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '200 g', accentColor: const Color(0xFFEAB308)),
      GroceryItem(id: 'k7', nameEn: 'Mustard Oil (Kachi Ghani)', nameHi: 'Sarson Tel', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '1 L', accentColor: const Color(0xFFCA8A04)),
      GroceryItem(id: 'k8', nameEn: 'Cold-Pressed Coconut Oil', nameHi: 'Nariyal Tel', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '500 ml', accentColor: const Color(0xFF059669)),
      GroceryItem(id: 'k9', nameEn: 'Sunflower Cooking Oil', nameHi: 'Refined Oil', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '1 L', accentColor: const Color(0xFFD97706)),
      GroceryItem(id: 'k10', nameEn: 'Groundnut Oil', nameHi: 'Moongphali Tel', category: ItemCategory.kitchenStaples, availableUnits: defaultDairyUnits, selectedUnit: '1 L', accentColor: const Color(0xFFB45309)),
    ];
  }

  static List<SavedListTemplate> getInitialSavedTemplates() {
    return [
      SavedListTemplate(
        id: 'tmpl_1',
        name: 'Weekly Spices & Rice Restock',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        items: [
          ItemSnapshot(id: 's1', nameEn: 'Cumin Seeds', nameHi: 'Jeera', category: ItemCategory.singleSpices, selectedUnit: '100 g', quantity: 2),
          ItemSnapshot(id: 'r1', nameEn: 'Basmati Rice (Classic)', nameHi: 'Basmati Chawal', category: ItemCategory.riceGrains, selectedUnit: '1 kg', quantity: 5),
          ItemSnapshot(id: 's5', nameEn: 'Turmeric Powder', nameHi: 'Haldi', category: ItemCategory.singleSpices, selectedUnit: '100 g', quantity: 1),
          ItemSnapshot(id: 'b22', nameEn: 'Mexican Masala', nameHi: 'Tex-Mex Seasoning', category: ItemCategory.masalaBlends, selectedUnit: '100 g', quantity: 1),
        ],
      ),
      SavedListTemplate(
        id: 'tmpl_2',
        name: 'Sunday Fresh Produce & Batter',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          ItemSnapshot(id: 'v1', nameEn: 'Red Onion', nameHi: 'Pyaaz', category: ItemCategory.freshProduce, selectedUnit: '1 kg', quantity: 2),
          ItemSnapshot(id: 'v4', nameEn: 'Tomato', nameHi: 'Tamatar', category: ItemCategory.freshProduce, selectedUnit: '1 kg', quantity: 1),
          ItemSnapshot(id: 'rtc1', nameEn: 'Fresh Dosa & Idli Batter', nameHi: 'Idli Dosa Peeth', category: ItemCategory.readyToCook, selectedUnit: '1 Pack', quantity: 2),
          ItemSnapshot(id: 'df1', nameEn: 'Almonds (California)', nameHi: 'Badam Giri', category: ItemCategory.dryFruitsNuts, selectedUnit: '250 g', quantity: 1),
        ],
      ),
    ];
  }
}
