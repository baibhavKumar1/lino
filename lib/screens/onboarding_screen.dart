import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';
import '../models/user_preferences.dart';
import '../services/neon_db_service.dart';
import '../services/auth_service.dart';
import '../widgets/lino_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class QuickStockPantryPack {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final List<PantryItem> items;

  QuickStockPantryPack({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.items,
  });
}

/// Canonical matcher to detect similar items, Hindi/English aliases, and prevent duplicates
class CanonicalItemMatcher {
  static final Map<String, String> _aliasMap = {
    // Cumin
    'jeera': 'cumin_seeds',
    'cumin': 'cumin_seeds',
    'cumin seeds': 'cumin_seeds',
    'jeera powder': 'cumin_powder',
    'cumin powder': 'cumin_powder',
    // Turmeric
    'haldi': 'turmeric_powder',
    'turmeric': 'turmeric_powder',
    'turmeric powder': 'turmeric_powder',
    // Chili
    'laal mirch': 'red_chili_powder',
    'red chili': 'red_chili',
    'red chili powder': 'red_chili_powder',
    'kashmiri mirch': 'red_chili_powder',
    // Coriander
    'dhania': 'coriander_leaves',
    'coriander': 'coriander_leaves',
    'coriander leaves': 'coriander_leaves',
    'dhania powder': 'coriander_powder',
    'coriander powder': 'coriander_powder',
    'coriander seeds': 'coriander_seeds',
    // Other
    'garam masala': 'garam_masala',
    'atta': 'wheat_flour',
    'whole wheat atta': 'wheat_flour',
    'wheat flour': 'wheat_flour',
    'rice': 'basmati_rice',
    'basmati rice': 'basmati_rice',
    'basmati chawal': 'basmati_rice',
    'toor dal': 'toor_dal',
    'arhar dal': 'toor_dal',
    'moong dal': 'moong_dal',
    'yellow moong dal': 'moong_dal',
    'poha': 'poha',
    'thick poha': 'poha',
    'milk': 'milk',
    'full cream milk': 'milk',
    'curd': 'curd',
    'dahi': 'curd',
    'curd / dahi': 'curd',
    'butter': 'butter',
    'table butter': 'butter',
    'onion': 'onion',
    'red onion': 'onion',
    'pyaaz': 'onion',
    'potato': 'potato',
    'aloo': 'potato',
    'mustard oil': 'mustard_oil',
    'sunflower oil': 'sunflower_oil',
    'oil': 'cooking_oil',
    'ghee': 'ghee',
    'desi ghee': 'ghee',
    'salt': 'salt',
    'iodized salt': 'salt',
    'namak': 'salt',
    'sugar': 'sugar',
    'refined sugar': 'sugar',
    'cheeni': 'sugar',
    'paneer': 'paneer',
    'fresh paneer': 'paneer',
    'ginger': 'ginger',
    'adrak': 'ginger',
    'garlic': 'garlic',
    'lehsun': 'garlic',
    'tomato': 'tomato',
    'tamatar': 'tomato',
  };

  static String getCanonicalKey(String name) {
    String clean = name.toLowerCase().trim();
    // Remove content inside parentheses e.g. "Jeera (Cumin Seeds)" -> "Jeera"
    clean = clean.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    // Remove noise words — BUT keep type-differentiators: powder, seeds, leaves
    clean = clean.replaceAll(RegExp(r'\b(fresh|whole|refined|iodized|table|full cream|desi|split|classic|special)\b', caseSensitive: false), '').trim();
    clean = clean.replaceAll(RegExp(r'\s+'), ' ');

    // 1. Check for exact alias map match
    if (_aliasMap.containsKey(clean)) {
      return _aliasMap[clean]!;
    }
    
    // 2. We DO NOT use a .contains() loop here! That incorrectly collapsed "coriander powder" into "coriander".
    // If not found in the alias map, return the clean string itself so it can be matched precisely.
    return clean.isEmpty ? name.toLowerCase().trim() : clean;
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Household Profile State
  DietPreference _selectedDiet = DietPreference.veg;
  HouseholdSizeOption _householdSize = HouseholdSizeOption.family;
  String _householdName = 'My Kitchen';
  final TextEditingController _householdNameController = TextEditingController(text: 'My Kitchen');

  // Selected Pantry Items across onboarding (Keyed by canonical key for zero duplicate cards)
  final Map<String, PantryItem> _configuredInventory = {};

  // Selected Quick Stock Packs
  final Set<String> _selectedPackIds = {'spices', 'staples'};

  // Granular set of item IDs selected in Step 2
  final Set<String> _selectedPackItemIds = {
    'ob_sp1', 'ob_sp2', 'ob_sp3', 'ob_sp4', 'ob_sp5',
    'ob_st1', 'ob_st2', 'ob_st3', 'ob_st4', 'ob_st5',
  };

  late final List<QuickStockPantryPack> _quickStockPacks;

  // Step 3 Smart Search, Custom Add, & Batch Selection State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<GroceryItem> _allCatalogItems = GroceryCatalog.getInitialItems();
  final Set<String> _selectedItemNames = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _initPacks();
    _syncPacksToInventory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _householdNameController.dispose();
    super.dispose();
  }

  void _initPacks() {
    _quickStockPacks = [
      QuickStockPantryPack(
        id: 'spices',
        title: 'Essential Indian Spices',
        emoji: '🌶️',
        description: 'Jeera, Haldi, Red Chili, Dhania, Garam Masala',
        items: [
          PantryItem(id: 'ob_sp1', name: 'Jeera (Cumin Seeds)', category: ItemCategory.singleSpices, unit: 'g', quantity: 250),
          PantryItem(id: 'ob_sp2', name: 'Turmeric Powder (Haldi)', category: ItemCategory.singleSpices, unit: 'g', quantity: 200),
          PantryItem(id: 'ob_sp3', name: 'Red Chili Powder', category: ItemCategory.singleSpices, unit: 'g', quantity: 200),
          PantryItem(id: 'ob_sp4', name: 'Coriander Powder (Dhania)', category: ItemCategory.singleSpices, unit: 'g', quantity: 250),
          PantryItem(id: 'ob_sp5', name: 'Garam Masala', category: ItemCategory.masalaBlends, unit: 'g', quantity: 100),
        ],
      ),
      QuickStockPantryPack(
        id: 'staples',
        title: 'Staples & Grains Pack',
        emoji: '🌾',
        description: 'Atta, Basmati Rice, Toor Dal, Moong Dal, Poha',
        items: [
          PantryItem(id: 'ob_st1', name: 'Whole Wheat Atta', category: ItemCategory.floursBaking, unit: 'kg', quantity: 5),
          PantryItem(id: 'ob_st2', name: 'Basmati Rice', category: ItemCategory.riceGrains, unit: 'kg', quantity: 5),
          PantryItem(id: 'ob_st3', name: 'Toor Dal (Arhar Dal)', category: ItemCategory.pulsesLentils, unit: 'kg', quantity: 2),
          PantryItem(id: 'ob_st4', name: 'Yellow Moong Dal', category: ItemCategory.pulsesLentils, unit: 'kg', quantity: 1),
          PantryItem(id: 'ob_st5', name: 'Thick Poha', category: ItemCategory.riceGrains, unit: 'g', quantity: 500),
        ],
      ),
      QuickStockPantryPack(
        id: 'dairy_fresh',
        title: 'Dairy & Fresh Essentials',
        emoji: '🥛',
        description: 'Milk, Curd, Butter, Paneer, Onions, Potatoes',
        items: [
          PantryItem(id: 'ob_df1', name: 'Full Cream Milk', category: ItemCategory.kitchenStaples, unit: 'L', quantity: 1),
          PantryItem(id: 'ob_df2', name: 'Fresh Curd / Dahi', category: ItemCategory.kitchenStaples, unit: 'g', quantity: 400),
          PantryItem(id: 'ob_df3', name: 'Table Butter', category: ItemCategory.kitchenStaples, unit: 'g', quantity: 100),
          PantryItem(id: 'ob_df4', name: 'Red Onion', category: ItemCategory.freshProduce, unit: 'kg', quantity: 2),
          PantryItem(id: 'ob_df5', name: 'Potato', category: ItemCategory.freshProduce, unit: 'kg', quantity: 2),
        ],
      ),
      QuickStockPantryPack(
        id: 'oils_condiments',
        title: 'Oils & Cooking Basics',
        emoji: '🛢️',
        description: 'Mustard Oil, Sunflower Oil, Ghee, Salt, Sugar',
        items: [
          PantryItem(id: 'ob_oc1', name: 'Mustard Oil', category: ItemCategory.kitchenStaples, unit: 'L', quantity: 1),
          PantryItem(id: 'ob_oc2', name: 'Sunflower Oil', category: ItemCategory.kitchenStaples, unit: 'L', quantity: 2),
          PantryItem(id: 'ob_oc3', name: 'Desi Ghee', category: ItemCategory.kitchenStaples, unit: 'g', quantity: 500),
          PantryItem(id: 'ob_oc4', name: 'Iodized Salt', category: ItemCategory.singleSpices, unit: 'kg', quantity: 1),
          PantryItem(id: 'ob_oc5', name: 'Refined Sugar', category: ItemCategory.kitchenStaples, unit: 'kg', quantity: 1),
        ],
      ),
    ];
  }

  void _syncPacksToInventory() {
    for (final pack in _quickStockPacks) {
      final isPackSelected = _selectedPackIds.contains(pack.id);
      for (final item in pack.items) {
        final canonicalKey = CanonicalItemMatcher.getCanonicalKey(item.name);
        final isItemSelected = isPackSelected || _selectedPackItemIds.contains(item.id);

        if (isItemSelected) {
          _selectedPackItemIds.add(item.id);
          if (!_configuredInventory.containsKey(canonicalKey)) {
            _configuredInventory[canonicalKey] = item;
          }
        } else if (!isPackSelected && !_selectedPackItemIds.contains(item.id)) {
          // Only remove if this exact item was from this pack and not customized
          if (_configuredInventory[canonicalKey]?.id == item.id) {
            _configuredInventory.remove(canonicalKey);
          }
        }
      }
    }
  }

  void _togglePack(String packId) {
    setState(() {
      final pack = _quickStockPacks.firstWhere((p) => p.id == packId);
      if (_selectedPackIds.contains(packId)) {
        _selectedPackIds.remove(packId);
        for (final item in pack.items) {
          _selectedPackItemIds.remove(item.id);
          final canonicalKey = CanonicalItemMatcher.getCanonicalKey(item.name);
          if (_configuredInventory[canonicalKey]?.id == item.id) {
            _configuredInventory.remove(canonicalKey);
          }
        }
      } else {
        _selectedPackIds.add(packId);
        for (final item in pack.items) {
          _selectedPackItemIds.add(item.id);
          final canonicalKey = CanonicalItemMatcher.getCanonicalKey(item.name);
          if (!_configuredInventory.containsKey(canonicalKey)) {
            _configuredInventory[canonicalKey] = item;
          }
        }
      }
    });
  }

  void _togglePackItem(QuickStockPantryPack pack, PantryItem item) {
    setState(() {
      final canonicalKey = CanonicalItemMatcher.getCanonicalKey(item.name);
      if (_selectedPackItemIds.contains(item.id)) {
        _selectedPackItemIds.remove(item.id);
        _configuredInventory.remove(canonicalKey);
        // If not all items in pack are selected, remove whole-pack check
        _selectedPackIds.remove(pack.id);
      } else {
        _selectedPackItemIds.add(item.id);
        if (_configuredInventory.containsKey(canonicalKey)) {
          // Increment / Merge quantity
          _configuredInventory[canonicalKey]!.quantity += item.quantity;
        } else {
          _configuredInventory[canonicalKey] = item;
        }
        // Check if all items in pack are now selected
        final allSelected = pack.items.every((i) => _selectedPackItemIds.contains(i.id));
        if (allSelected) {
          _selectedPackIds.add(pack.id);
        }
      }
    });
  }

  PantryItem? _findExistingPantryItem(String name) {
    final canonicalKey = CanonicalItemMatcher.getCanonicalKey(name);
    return _configuredInventory[canonicalKey];
  }

  List<GroceryItem> _getSmartCatalogMatches(String query) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return [];

    return _allCatalogItems.where((item) {
      final en = item.nameEn.toLowerCase();
      final hi = item.nameHi.toLowerCase();
      return en.contains(cleanQuery) || hi.contains(cleanQuery);
    }).take(4).toList();
  }

  void _addCatalogItemToInventory(GroceryItem catalogItem) {
    setState(() {
      final unitStr = catalogItem.selectedUnit.replaceAll(RegExp(r'[0-9\s]'), '');
      final defaultUnit = unitStr.isNotEmpty ? unitStr : 'kg';
      final canonicalKey = CanonicalItemMatcher.getCanonicalKey(catalogItem.nameEn);

      if (_configuredInventory.containsKey(canonicalKey)) {
        // Smart merge: Increment quantity instead of creating a second card!
        _configuredInventory[canonicalKey]!.quantity += 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
            content: Text('Updated ${_configuredInventory[canonicalKey]!.name} to ${_configuredInventory[canonicalKey]!.quantity} ${_configuredInventory[canonicalKey]!.unit}'),
            */
            content: Text('Updated ${_configuredInventory[canonicalKey]!.name} to ${_configuredInventory[canonicalKey]!.displayStock}'),
            backgroundColor: AppColors.primaryDark,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final newItem = PantryItem(
          id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
          name: catalogItem.nameEn,
          category: catalogItem.category,
          unit: defaultUnit,
          quantity: 1,
        );
        _configuredInventory[canonicalKey] = newItem;
      }
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _showAddCustomItemDialog(String initialName) {
    final nameCtrl = TextEditingController(text: initialName);
    final qtyCtrl = TextEditingController(text: '1');
    String selectedUnit = 'kg';
    ItemCategory selectedCat = ItemCategory.kitchenStaples;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlBorder),
          title: Text(
            'Add Unlisted Kitchen Item',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Organic Honey, Matcha Powder',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
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
                          border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
                        ),
                        items: ['g', 'kg', 'ml', 'L', 'Pcs', 'Packets', 'Boxes']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ItemCategory>(
                  value: selectedCat,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
                  ),
                  items: ItemCategory.values
                      .where((c) => c != ItemCategory.all)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCat = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                if (name.isNotEmpty) {
                  final canonicalKey = CanonicalItemMatcher.getCanonicalKey(name);
                  if (_configuredInventory.containsKey(canonicalKey)) {
                    setState(() {
                      _configuredInventory[canonicalKey]!.quantity += qty;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  } else {
                    final newItem = PantryItem(
                      id: 'pantry_${DateTime.now().microsecondsSinceEpoch}_${_configuredInventory.length}',
                      name: name,
                      category: selectedCat,
                      unit: selectedUnit,
                      quantity: qty,
                    );
                    setState(() {
                      _configuredInventory[canonicalKey] = newItem;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add to Kitchen', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuantityDialog(PantryItem item) {
    final qtyCtrl = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlBorder),
        title: Text(
          'Enter Quantity for ${item.name}',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          /* PREVIOUS FUNNEL DISPLAY STYLE - COMMENTED OUT AS PER RULE
          style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 18, fontWeight: FontWeight.w700),
          */
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: 'Quantity (${item.unit})',
            hintText: 'Enter quantity',
            border: const OutlineInputBorder(borderRadius: AppRadii.mdBorder),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
            ),
            onPressed: () {
              final newQty = int.tryParse(qtyCtrl.text.trim());
              if (newQty != null) {
                final canonicalKey = CanonicalItemMatcher.getCanonicalKey(item.name);
                setState(() {
                  if (newQty > 0) {
                    item.quantity = newQty;
                  } else {
                    _configuredInventory.remove(canonicalKey);
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final pantryList = _configuredInventory.values.toList();
    _householdName = _householdNameController.text.trim().isNotEmpty
        ? _householdNameController.text.trim()
        : 'My Kitchen';

    final args = ModalRoute.of(context)?.settings.arguments;
    String googleEmail = 'user@gmail.com';
    String googleName = _householdName;
    String? googlePhotoUrl;

    if (args is Map<String, dynamic>) {
      googleEmail = args['googleEmail'] as String? ?? 'user@gmail.com';
      googleName = args['googleName'] as String? ?? _householdName;
      googlePhotoUrl = args['googlePhotoUrl'] as String?;
    }

    final userId = 'user_${DateTime.now().microsecondsSinceEpoch}';

    await NeonDbService.registerUserInCloud(
      id: userId,
      email: googleEmail,
      fullName: googleName,
      photoUrl: googlePhotoUrl,
      householdName: _householdName,
      dietPreference: _selectedDiet.key,
      householdSize: '${_householdSize.count}',
    );

    await AuthService.saveSession(
      id: userId,
      email: googleEmail,
      fullName: googleName,
      photoUrl: googlePhotoUrl,
      householdName: _householdName,
      dietPreference: _selectedDiet.key,
      householdSize: '${_householdSize.count}',
    );

    // Sync all selected onboarding pantry items to cloud DB with user association
    for (final item in pantryList) {
      await NeonDbService.upsertPantryItemInCloud(item, userId: userId);
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home', arguments: {
        'initialPantryItems': pantryList,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    /* PREVIOUS SCAFFOLD - COMMENTED OUT AS PER RULE
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(...),
    );
    */
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
            // ==========================================
            // TOP WAYFINDING PROGRESS BAR (Zero Dots)
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: AppRadii.smBorder,
                            ),
                            child: const Icon(Icons.kitchen_rounded, color: AppColors.primaryDark, size: 18),
                          ),
                          */
                          const LinoLogo(
                            size: 26,
                            withContainer: true,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LINO ONBOARDING',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: AppRadii.smBorder,
                        ),
                        child: Text(
                          'Step ${_currentStep + 1} of 4',
                          style: const TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Segmented Smooth Bars
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // ==========================================
            // PAGE VIEW STEPS
            // ==========================================
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildStep1HouseholdProfile(),
                  _buildStep2QuickStockEssentials(),
                  _buildStep3CustomInventoryBuilder(),
                  _buildStep4SummaryReady(),
                ],
              ),
            ),

            // ==========================================
            // BOTTOM ERGONOMIC 48PT NAVIGATION BAR
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
                      elevation: 0,
                    ),
                    onPressed: _nextPage,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentStep == 3 ? 'Start Cooking' : 'Next Step',
                          style: const TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentStep == 3 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.textWhite,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  // ==========================================
  // STEP 1: Household & Kitchen Profile
  // ==========================================
  Widget _buildStep1HouseholdProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadii.mdBorder,
            ),
            child: const Icon(Icons.home_work_rounded, color: AppColors.primaryDark, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Setup Your Kitchen Profile',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Personalize your cuisine preferences so Lino can recommend relevant pantry items.',
            style: TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Kitchen Name Input
          const Text(
            'KITCHEN / HOUSEHOLD NAME',
            style: TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _householdNameController,
            style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'e.g. Baibhav\'s Kitchen',
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: AppRadii.mdBorder,
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'PRIMARY CUISINE & DIET',
            style: TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: DietPreference.values.map((diet) {
              final isSelected = _selectedDiet == diet;
              return ChoiceChip(
                label: Text(
                  diet.label,
                  style: TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.textWhite : const Color(0xFF334155),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedDiet = diet);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          const Text(
            'HOUSEHOLD SIZE',
            style: TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: HouseholdSizeOption.values.map((size) {
              final isSelected = _householdSize == size;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.mdBorder,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: RadioListTile<HouseholdSizeOption>(
                  dense: true,
                  value: size,
                  groupValue: _householdSize,
                  activeColor: AppColors.primary,
                  title: Text(
                    size.label,
                    style: TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    size.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) setState(() => _householdSize = val);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: Quick-Stock Pantry Essentials Checklist (With Granular Item Chips)
  // ==========================================
  Widget _buildStep2QuickStockEssentials() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: AppRadii.mdBorder,
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppColors.warningDark, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Quick-Stock Pantry Essentials',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a card to toggle the whole pack, or tap individual item chips below to customize items in each pack.',
            style: TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickStockPacks.length,
            itemBuilder: (context, index) {
              final pack = _quickStockPacks[index];
              final isFullySelected = _selectedPackIds.contains(pack.id);
              final activeCount = pack.items.where((i) => _selectedPackItemIds.contains(i.id)).length;
              final isPartiallySelected = activeCount > 0 && activeCount < pack.items.length;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.lgBorder,
                  border: Border.all(
                    color: isFullySelected
                        ? AppColors.primary
                        : isPartiallySelected
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.border,
                    width: isFullySelected ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isFullySelected || isPartiallySelected)
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : AppColors.textPrimary.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Header Row (Toggles entire pack)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _togglePack(pack.id),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              pack.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      pack.title,
                                      style: const TextStyle(
                                        fontFamily: 'Funnel Display',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: activeCount > 0 ? AppColors.primaryLight : AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$activeCount/${pack.items.length}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: activeCount > 0 ? AppColors.primaryDark : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pack.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Funnel Display',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFullySelected
                                  ? AppColors.primary
                                  : isPartiallySelected
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : Colors.transparent,
                              border: Border.all(
                                color: (isFullySelected || isPartiallySelected)
                                    ? AppColors.primary
                                    : AppColors.borderDark,
                                width: 1.8,
                              ),
                            ),
                            child: isFullySelected
                                ? const Icon(Icons.check_rounded, color: AppColors.textWhite, size: 16)
                                : isPartiallySelected
                                    ? const Icon(Icons.remove_rounded, color: AppColors.primaryDark, size: 14)
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 8),

                    // Granular Interactive Item Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: pack.items.map((item) {
                        final isItemActive = _selectedPackItemIds.contains(item.id);
                        return InkWell(
                          onTap: () => _togglePackItem(pack, item),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isItemActive ? AppColors.primaryLight : AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isItemActive ? AppColors.primary : AppColors.border,
                                width: isItemActive ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isItemActive ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  size: 13,
                                  color: isItemActive ? AppColors.primaryDark : AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                                Text(
                                  '${item.name} (${item.quantity}${item.unit})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isItemActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isItemActive ? AppColors.primaryDark : AppColors.textSecondary,
                                  ),
                                ),
                                */
                                Text(
                                  '${item.name} (${item.displayStock})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isItemActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isItemActive ? AppColors.primaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: Staged Pantry Review & Smart Search (With Batch Selection & Zero Duplicates)
  // ==========================================
  Widget _buildStep3CustomInventoryBuilder() {
    final configuredList = _configuredInventory.values.toList();
    final catalogMatches = _getSmartCatalogMatches(_searchQuery);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: AppRadii.mdBorder,
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.accentBlue, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Refine Kitchen Stock',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap or select any item to adjust quantities or batch delete. Items from Step 2 are automatically merged.',
            style: TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search or add item (e.g. Atta, Honey)...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
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
              border: const OutlineInputBorder(
                borderRadius: AppRadii.mdBorder,
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),

          // Matches Dropdown (With In-Stock Detection to prevent 2 duplicate cards)
          if (_searchQuery.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.mdBorder,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  ...catalogMatches.map((catItem) {
                    final existing = _findExistingPantryItem(catItem.nameEn);
                    final isAlreadyStocked = existing != null;

                    return ListTile(
                      dense: true,
                      leading: Icon(catItem.category.icon, color: AppColors.primary, size: 18),
                      title: Text(
                        catItem.nameEn,
                        style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: isAlreadyStocked
                          ? Text(
                              'In Stock: ${existing.quantity} ${existing.unit}',
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                            )
                          : null,
                      trailing: isAlreadyStocked
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  iconSize: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                      final canonicalKey = CanonicalItemMatcher.getCanonicalKey(catItem.nameEn);
                                      if (existing.quantity > 1) {
                                        existing.quantity--;
                                      } else {
                                        _configuredInventory.remove(canonicalKey);
                                      }
                                    });
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '${existing.quantity}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton(
                                  iconSize: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                  onPressed: () {
                                    setState(() {
                                      existing.quantity++;
                                    });
                                  },
                                ),
                              ],
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(0, 28),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _addCatalogItemToInventory(catItem),
                              child: const Text('Add', style: TextStyle(fontSize: 11, color: AppColors.textWhite, fontWeight: FontWeight.w700)),
                            ),
                    );
                  }),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentBlue, size: 20),
                    title: Text(
                      'Add "${_searchQuery.trim()}" as Custom Item',
                      style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentBlue),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.accentBlue),
                    onTap: () => _showAddCustomItemDialog(_searchQuery.trim()),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // CONTEXTUAL BATCH ACTION HEADER
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: AppRadii.mdBorder,
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedItemNames.length} Selected',
                    style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Spacer(),
                  // Select All / Deselect All
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () {
                      setState(() {
                        if (_selectedItemNames.length == configuredList.length) {
                          _selectedItemNames.clear();
                        } else {
                          _selectedItemNames.addAll(configuredList.map((i) => i.name));
                        }
                      });
                    },
                    child: Text(
                      _selectedItemNames.length == configuredList.length ? 'Deselect All' : 'Select All',
                      style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Batch Delete Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: Text(
                      'Delete (${_selectedItemNames.length})',
                      style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _selectedItemNames.isEmpty
                        ? null
                        : () {
                            setState(() {
                              for (final name in _selectedItemNames) {
                                final canonicalKey = CanonicalItemMatcher.getCanonicalKey(name);
                                _configuredInventory.remove(canonicalKey);
                              }
                              _selectedItemNames.clear();
                              _isSelectionMode = false;
                            });
                          },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _selectedItemNames.clear();
                        _isSelectionMode = false;
                      });
                    },
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YOUR STAGED STOCK (${configuredList.length})',
                  style: const TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (configuredList.isNotEmpty) ...[
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isSelectionMode = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.checklist_rounded, size: 14, color: AppColors.textSecondary),
                              SizedBox(width: 2),
                              Text(
                                'Select',
                                style: TextStyle(fontFamily: 'Funnel Display', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    InkWell(
                      onTap: () => _showAddCustomItemDialog(''),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: AppColors.primaryDark),
                            SizedBox(width: 2),
                            Text(
                              'Custom Item',
                              style: TextStyle(fontFamily: 'Funnel Display', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 8),

          if (configuredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.lgBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No items in staging. Use search above or select essentials in Step 2.',
                  style: TextStyle(fontFamily: 'Funnel Display', fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: configuredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = configuredList[index];
                final isSelected = _selectedItemNames.contains(item.name);

                return GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedItemNames.remove(item.name);
                          if (_selectedItemNames.isEmpty) _isSelectionMode = false;
                        } else {
                          _selectedItemNames.add(item.name);
                        }
                      });
                    } else {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedItemNames.add(item.name);
                      });
                    }
                  },
                  onLongPress: () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedItemNames.add(item.name);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : AppColors.surface,
                      borderRadius: AppRadii.mdBorder,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox when selection mode is active
                        if (_isSelectionMode) ...[
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.textMuted,
                                width: 1.8,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: AppColors.textWhite, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 8),
                        ],

                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.category.icon, color: AppColors.primaryDark, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Funnel Display',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${item.category.label} | Staged',
                                style: const TextStyle(
                                  fontFamily: 'Funnel Display',
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stepper with Direct Tap Number Dialog
                        if (!_isSelectionMode) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                iconSize: 16,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(3),
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                                onPressed: () {
                                  setState(() {
                                    final canonicalKey = CanonicalItemMatcher.getCanonicalKey(item.name);
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      _configuredInventory.remove(canonicalKey);
                                    }
                                  });
                                },
                              ),
                              InkWell(
                                onTap: () => _showEditQuantityDialog(item),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                                  child: Text(
                                    '${item.quantity} ${item.unit}',
                                    style: const TextStyle(
                                      fontFamily: 'Funnel Display',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  */
                                  child: Text(
                                    item.displayStock,
                                    style: const TextStyle(
                                      fontFamily: 'Funnel Display',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                iconSize: 16,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(3),
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                onPressed: () {
                                  setState(() {
                                    item.quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4: Kitchen Activation & Summary
  // ==========================================
  Widget _buildStep4SummaryReady() {
    final itemCount = _configuredInventory.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Kitchen is Ready!',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configured $itemCount pantry items ready to sync with your meal planner and shopping cart.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          _buildFeatureCard(
            icon: Icons.notifications_active_rounded,
            color: AppColors.warning,
            title: 'Low Stock Reminders',
            description: 'Lino automatically alerts you when essentials run low.',
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            icon: Icons.shopping_cart_rounded,
            color: AppColors.primary,
            title: 'Restock Cart',
            description: 'Add missing ingredients directly into your shopping cart.',
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            icon: Icons.restaurant_menu_rounded,
            color: AppColors.accentBlue,
            title: 'Smart Recipe Match',
            description: 'Cook delicious recipes with ingredients you already own.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
