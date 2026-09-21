// BACKUP OF ORIGINAL HOME SCREEN (PRESERVED AS PER USER REQUEST)
// ignore_for_file: unused_element, unused_import, unused_field
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../models/saved_recipe.dart';
import '../models/pantry_item.dart';
import '../services/neon_db_service.dart';
import '../services/auth_service.dart';
import '../screens/meal_planner_screen.dart';
import '../screens/onboarding_screen.dart';
import '../widgets/shopping_list_drawer.dart';
import '../widgets/saved_recipes_modal.dart';
import '../widgets/pantry_inventory_modal.dart';
import '../widgets/receipt_importer_modal.dart';
import '../widgets/tactile_tap.dart';

class HomeScreenBackup extends StatefulWidget {
  const HomeScreenBackup({super.key});

  @override
  State<HomeScreenBackup> createState() => _HomeScreenBackupState();
}

class _HomeScreenBackupState extends State<HomeScreenBackup> {
  int _activeTabIndex = 0;

  List<GroceryItem> _allItems = GroceryCatalog.getInitialItems();
  List<SavedListTemplate> _savedTemplates = [];
  List<SavedRecipe> _savedRecipes = [];
  List<PantryItem> _pantryItems = [];
  Map<String, String?> _userProfile = {};

  bool _initializedOnboarding = false;

  ItemCategory _selectedShopCategory = ItemCategory.all;
  String _shopSearchQuery = '';
  final TextEditingController _shopSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initCloudDatabase());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedOnboarding) {
      _initializedOnboarding = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('initialPantryItems')) {
        final List<PantryItem>? onboardingItems = args['initialPantryItems'] as List<PantryItem>?;
        setState(() {
          _pantryItems = onboardingItems ?? [];
        });
        Future.microtask(() => NeonDbService.syncPantryToCloud(_pantryItems));
      }
    }
  }

  Future<void> _initCloudDatabase() async {
    try {
      final session = await AuthService.getActiveUserSession();
      final userId = session['id'];
      if (mounted) {
        setState(() {
          _userProfile = session;
        });
      }

      await NeonDbService.initDatabase();

      if (session['email'] != null && session['email']!.isNotEmpty) {
        final dbUser = await NeonDbService.fetchUserByEmail(session['email']!);
        if (dbUser != null) {
          session['fullName'] = dbUser['fullName'] ?? session['fullName'];
          session['householdName'] = dbUser['householdName'] ?? session['householdName'];
          session['photoUrl'] = dbUser['photoUrl'] ?? session['photoUrl'];
          session['dietPreference'] = dbUser['dietPreference'] ?? session['dietPreference'];
          session['householdSize'] = dbUser['householdSize'] ?? session['householdSize'];
          session['appliances'] = dbUser['appliances'] ?? session['appliances'];
          session['exclusions'] = dbUser['exclusions'] ?? session['exclusions'];
        }
      }

      await NeonDbService.syncInventoryToCloud(_allItems, userId: userId);
      final cloudSavedRecipes = await NeonDbService.fetchSavedRecipesFromCloud(userId: userId);
      final cloudPantryItems = await NeonDbService.fetchPantryFromCloud(userId: userId);

      if (mounted) {
        setState(() {
          _savedRecipes = cloudSavedRecipes;
          if (cloudPantryItems.isNotEmpty) {
            _pantryItems = cloudPantryItems;
          }
          _userProfile = session;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _shopSearchController.dispose();
    NeonDbService.closeConnection();
    super.dispose();
  }

  int get _totalShoppingListCount => _allItems.where((item) => item.isAdded).length;

  List<GroceryItem> get _filteredShopItems {
    final q = _shopSearchQuery.toLowerCase().trim();
    final canonicalQuery = q.isNotEmpty ? CanonicalItemMatcher.getCanonicalKey(q) : '';

    return _allItems.where((item) {
      final matchesCat = _selectedShopCategory == ItemCategory.all || item.category == _selectedShopCategory;
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

  void _toggleItemAdded(GroceryItem item) {
    setState(() {
      final idx = _allItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _allItems[idx] = _allItems[idx].copyWith(
          isAdded: !_allItems[idx].isAdded,
          quantity: 1,
        );
      }
    });
    NeonDbService.syncInventoryToCloud(_allItems);
  }

  void _updateItemQuantity(GroceryItem item, int newQty) {
    setState(() {
      final idx = _allItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        if (newQty <= 0) {
          _allItems[idx] = _allItems[idx].copyWith(isAdded: false, quantity: 1);
        } else {
          _allItems[idx] = _allItems[idx].copyWith(quantity: newQty);
        }
      }
    });
    NeonDbService.syncInventoryToCloud(_allItems);
  }

  int _findMatchingGroceryItemIndex(String query) {
    final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[\(\)\,\-]'), ' ').trim();
    final queryWords = cleanQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    for (int i = 0; i < _allItems.length; i++) {
      final nameEn = _allItems[i].nameEn.toLowerCase();
      final nameHi = _allItems[i].nameHi.toLowerCase();
      if (nameEn == cleanQuery || nameHi == cleanQuery) return i;
      if (nameEn.contains(cleanQuery) || cleanQuery.contains(nameEn)) return i;
      if (nameHi.contains(cleanQuery) || cleanQuery.contains(nameHi)) return i;
    }

    for (int i = 0; i < _allItems.length; i++) {
      final nameEn = _allItems[i].nameEn.toLowerCase();
      final nameHi = _allItems[i].nameHi.toLowerCase();
      for (final word in queryWords) {
        if (nameEn.contains(word) || nameHi.contains(word)) return i;
      }
    }

    return -1;
  }

  void _addMissingRecipeItemsToShoppingList(List<String> missingItems) {
    setState(() {
      for (final missingName in missingItems) {
        final matchIdx = _findMatchingGroceryItemIndex(missingName);
        if (matchIdx != -1) {
          _allItems[matchIdx] = _allItems[matchIdx].copyWith(
            isAdded: true,
            quantity: _allItems[matchIdx].isAdded && _allItems[matchIdx].quantity > 0 ? _allItems[matchIdx].quantity : 1,
          );
        } else {
          _allItems.add(
            GroceryItem(
              id: 'missing_${DateTime.now().millisecondsSinceEpoch}_${missingName.hashCode}',
              nameEn: missingName,
              nameHi: missingName,
              category: ItemCategory.kitchenStaples,
              availableUnits: ['1 Pack', '500 g', '1 kg'],
              selectedUnit: '1 Pack',
              isAdded: true,
              quantity: 1,
            ),
          );
        }
      }
    });
    NeonDbService.syncInventoryToCloud(_allItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Kichook (Archived Backup)'),
      ),
      body: Center(
        child: Text('Archived HomeScreen Backup. Active Tab: $_activeTabIndex'),
      ),
    );
  }
}
