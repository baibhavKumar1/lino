import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../models/saved_recipe.dart';
import '../models/pantry_item.dart';
import '../models/meal_calendar_event.dart';
import '../services/neon_db_service.dart';
import '../services/auth_service.dart';
import '../screens/meal_planner_screen.dart';
import '../screens/meal_calendar_screen.dart';
import '../screens/pantry_inventory_screen.dart';
import '../screens/saved_recipes_screen.dart';
import '../screens/shop_catalog_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/openrouter_service.dart';
import '../services/ingredient_sanitizer.dart';
import '../widgets/shopping_list_drawer.dart';
// import '../widgets/saved_recipes_modal.dart';
// import '../widgets/pantry_inventory_modal.dart';
import '../widgets/user_profile_modal.dart';
import '../widgets/receipt_importer_modal.dart';
// import '../widgets/tactile_tap.dart';
import '../widgets/lino_logo.dart';
import '../widgets/textured_background.dart';
import '../widgets/home_dashboard_view.dart';
import '../services/reviewer_demo_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTabIndex = 0; // 0: Home Dashboard, 1: Meal Calendar, 2: Kitchen Pantry, 3: Saved Recipes, 4: Shop

  List<GroceryItem> _allItems = GroceryCatalog.getInitialItems();
  List<SavedListTemplate> _savedTemplates = [];
  List<SavedRecipe> _savedRecipes = [];
  List<PantryItem> _pantryItems = [];
  List<MealCalendarEvent> _calendarEvents = [];
  Map<String, String?> _userProfile = {};

  bool _isPantryLoading = true;
  bool _initializedOnboarding = false;

  // Shop Tab State (Left Sidebar Category & Search)
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
        // User explicitly completed or skipped onboarding: respect exact list (even if empty)
        setState(() {
          _pantryItems = onboardingItems ?? [];
          _isPantryLoading = false;
        });
        Future.microtask(() => NeonDbService.syncPantryToCloud(_pantryItems));
      }
    }
  }

  // Previous sequential blocking sync logic commented out below:
  // Future<void> _initCloudDatabase() async {
  //   await NeonDbService.seedGlobalInventoryIfEmpty(_allItems);
  //   await NeonDbService.syncInventoryToCloud(_allItems, userId: activeId);
  //   final cloudSavedRecipes = await NeonDbService.fetchSavedRecipesFromCloud(userId: activeId);
  //   final cloudPantryItems = await NeonDbService.fetchPantryFromCloud(userId: activeId);
  // }

  Future<void> _initCloudDatabase() async {
    try {
      final session = await AuthService.getActiveUserSession();
      // final userId = session['id'];
      if (mounted) {
        setState(() {
          _userProfile = session;
        });
      }

      await NeonDbService.initDatabase();

      final activeId = session['id'] ?? 'user_lino_primary';
      final activeEmail = session['email'] ?? 'user@lino.app';
      final activeFullName = session['fullName'] ?? 'User';
      final activeHousehold = session['householdName'] ?? 'My Kitchen';
      final activeDiet = session['dietPreference'] ?? 'Veg';
      final activeSize = session['householdSize'] ?? '2';
      final activeAppliances = session['appliances'] ?? 'Gas Stove,Kadai / Pan';
      final activeExclusions = session['exclusions'] ?? '';

      // Fetch user profile from database
      final dbUser = await NeonDbService.fetchUserByEmail(activeEmail);
      if (dbUser != null) {
        session['fullName'] = dbUser['fullName'] ?? activeFullName;
        session['householdName'] = dbUser['householdName'] ?? activeHousehold;
        session['photoUrl'] = dbUser['photoUrl'] ?? session['photoUrl'];
        session['dietPreference'] = dbUser['dietPreference'] ?? activeDiet;
        session['householdSize'] = dbUser['householdSize'] ?? activeSize;
        session['appliances'] = dbUser['appliances'] ?? activeAppliances;
        session['exclusions'] = dbUser['exclusions'] ?? activeExclusions;
        await NeonDbService.updateUserLastLogin(activeEmail);
      } else {
        // Self-healing: Register active user profile in Neon users table immediately
        await NeonDbService.registerUserInCloud(
          id: activeId,
          email: activeEmail,
          fullName: activeFullName,
          photoUrl: session['photoUrl'],
          householdName: activeHousehold,
          dietPreference: activeDiet,
          householdSize: activeSize,
          appliances: activeAppliances,
          exclusions: activeExclusions,
        );
      }

      // Fast Parallel Fetch: Get user recipes, pantry, and calendar concurrently
      final results = await Future.wait([
        NeonDbService.fetchSavedRecipesFromCloud(userId: activeId),
        NeonDbService.fetchPantryFromCloud(userId: activeId),
        MealCalendarDbService.fetchMealCalendarEvents(userId: activeId),
      ]);

      final cloudSavedRecipes = results[0] as List<SavedRecipe>;
      final cloudPantryItems = results[1] as List<PantryItem>;
      final cloudEvents = results[2] as List<MealCalendarEvent>;

      if (mounted) {
        setState(() {
          _savedRecipes = cloudSavedRecipes;
          if (cloudPantryItems.isNotEmpty || _pantryItems.isEmpty) {
            _pantryItems = cloudPantryItems;
          }
          if (activeId == ReviewerDemoService.reviewerUserId && _pantryItems.isEmpty) {
            _pantryItems = ReviewerDemoService.getDemoPantry();
          }
          _calendarEvents = cloudEvents;
          if (activeId == ReviewerDemoService.reviewerUserId && _calendarEvents.isEmpty) {
            _calendarEvents = ReviewerDemoService.getDemoEvents();
          }
          _userProfile = session;
          _isPantryLoading = false;
        });
      }

      // Run background catalog seeding & sync non-blockingly
      Future.microtask(() async {
        await NeonDbService.seedGlobalInventoryIfEmpty(_allItems);
        await NeonDbService.syncInventoryToCloud(_allItems, userId: activeId);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPantryLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _shopSearchController.dispose();
    super.dispose();
  }

  int get _totalShoppingListCount => _allItems.where((item) => item.isAdded).length;

  // Note: Category and search filtering for Shop is delegated to ShopCatalogScreen

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

  void _updateItemUnit(GroceryItem item, String newUnit) {
    setState(() {
      final idx = _allItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _allItems[idx] = _allItems[idx].copyWith(selectedUnit: newUnit);
      }
    });
    NeonDbService.syncInventoryToCloud(_allItems);
  }


  void _addMissingRecipeItemsToShoppingList(List<String> missingItems) {
    if (missingItems.isEmpty) return;

    int addedCount = 0;
    setState(() {
      for (final rawMissing in missingItems) {
        // 1. Filter out limitless household items (water, ice)
        if (IngredientSanitizer.isUniversalFreeItem(rawMissing)) {
          continue;
        }

        // 2. Clean culinary text to get pure ingredient name
        final cleanName = IngredientSanitizer.cleanIngredientName(rawMissing);
        if (cleanName.isEmpty) continue;

        // 3. Multi-tier precision catalog matching
        int matchIdx = IngredientSanitizer.findMatchingItemIndex(cleanName, _allItems);

        if (matchIdx != -1) {
          _allItems[matchIdx] = _allItems[matchIdx].copyWith(
            isAdded: true,
            quantity: _allItems[matchIdx].isAdded && _allItems[matchIdx].quantity > 0 ? _allItems[matchIdx].quantity : 1,
          );
          addedCount++;
        } else {
          // 4. Create a clean, perfectly categorized grocery item
          final defaultUnit = IngredientSanitizer.guessDefaultUnit(cleanName);
          final category = IngredientSanitizer.guessCategory(cleanName);

          _allItems.add(
            GroceryItem(
              id: 'missing_${DateTime.now().millisecondsSinceEpoch}_${cleanName.hashCode}',
              nameEn: cleanName,
              nameHi: cleanName,
              category: category,
              availableUnits: [defaultUnit, '500 g', '1 kg'],
              selectedUnit: defaultUnit,
              isAdded: true,
              quantity: 1,
            ),
          );
          addedCount++;
        }
      }
    });

    if (addedCount > 0) {
      NeonDbService.syncInventoryToCloud(_allItems);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $addedCount missing ingredient${addedCount > 1 ? 's' : ''} to your Shop Cart!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _stockPurchasedItemsToPantry(List<GroceryItem> purchasedItems) {
    if (purchasedItems.isEmpty) return;

    final userId = _userProfile['id'];

    setState(() {
      for (final item in purchasedItems) {
        // 1. Match with existing items in pantry by name or ID
        final existingPantryIdx = _pantryItems.indexWhere((p) =>
            p.name.trim().toLowerCase() == item.nameEn.trim().toLowerCase() ||
            p.name.trim().toLowerCase() == item.nameHi.trim().toLowerCase() ||
            p.id == item.id);

        if (existingPantryIdx != -1) {
          _pantryItems[existingPantryIdx].quantity += item.quantity > 0 ? item.quantity : 1;
          _pantryItems[existingPantryIdx].isLowStock = false;
          NeonDbService.upsertPantryItemInCloud(_pantryItems[existingPantryIdx], userId: userId);
        } else {
          final newPantry = PantryItem(
            id: 'pantry_${DateTime.now().microsecondsSinceEpoch}_${item.id}_${_pantryItems.length}',
            name: item.nameEn,
            category: item.category,
            unit: item.selectedUnit.isNotEmpty ? item.selectedUnit : '1 Pack',
            quantity: item.quantity > 0 ? item.quantity : 1,
            isLowStock: false,
          );
          _pantryItems.insert(0, newPantry);
          NeonDbService.upsertPantryItemInCloud(newPantry, userId: userId);
        }

        // 2. Clear item from active shopping cart in _allItems
        final allIdx = _allItems.indexWhere((i) => i.id == item.id);
        if (allIdx != -1) {
          _allItems[allIdx] = _allItems[allIdx].copyWith(isAdded: false, isChecked: false, quantity: 1);
        }
      }
    });

    NeonDbService.syncInventoryToCloud(_allItems, userId: userId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Stocked ${purchasedItems.length} purchased items to your Kitchen Pantry!',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ShoppingListDrawer(
          items: _allItems,
          onToggleCheck: (item) {
            setState(() {
              final idx = _allItems.indexWhere((i) => i.id == item.id);
              if (idx != -1) {
                _allItems[idx] = _allItems[idx].copyWith(isChecked: !_allItems[idx].isChecked);
              }
            });
            NeonDbService.syncInventoryToCloud(_allItems);
          },
          onUpdateQuantity: _updateItemQuantity,
          onRemove: (item) {
            setState(() {
              final idx = _allItems.indexWhere((i) => i.id == item.id);
              if (idx != -1) {
                _allItems[idx] = _allItems[idx].copyWith(isAdded: false, isChecked: false);
              }
            });
            NeonDbService.syncInventoryToCloud(_allItems);
          },
          onClearAll: () {
            setState(() {
              for (var i = 0; i < _allItems.length; i++) {
                if (_allItems[i].isAdded) {
                  _allItems[i] = _allItems[i].copyWith(isAdded: false, isChecked: false, quantity: 1);
                }
              }
            });
            NeonDbService.syncInventoryToCloud(_allItems);
          },
          onSaveAsTemplate: (name) {
            final added = _allItems.where((i) => i.isAdded).toList();
            final newTemplate = SavedListTemplate(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              createdAt: DateTime.now(),
              items: added.map((i) => ItemSnapshot(id: i.id, nameEn: i.nameEn, nameHi: i.nameHi, category: i.category, selectedUnit: i.selectedUnit, quantity: i.quantity)).toList(),
            );
            setState(() => _savedTemplates.add(newTemplate));
            NeonDbService.syncTemplateToCloud(newTemplate);
          },
          onConfirmPurchaseAndStock: _stockPurchasedItemsToPantry,
        ),
      ),
    );
  }

  void _showReceiptImporterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptImporterModal(
        inventory: _allItems,
        onImportItems: (importedItems) {
          setState(() {
            for (final item in importedItems) {
              final existingPantryIdx = _pantryItems.indexWhere(
                (p) => p.name.toLowerCase() == item.nameEn.toLowerCase() || p.id == item.id,
              );
              if (existingPantryIdx != -1) {
                _pantryItems[existingPantryIdx].quantity += item.quantity > 0 ? item.quantity : 1;
                NeonDbService.upsertPantryItemInCloud(_pantryItems[existingPantryIdx]);
              } else {
                final newPantry = PantryItem(
                  id: 'pantry_${DateTime.now().microsecondsSinceEpoch}_${item.id}_${_pantryItems.length}',
                  name: item.nameEn,
                  category: item.category,
                  unit: item.selectedUnit,
                  quantity: item.quantity > 0 ? item.quantity : 1,
                );
                _pantryItems.insert(0, newPantry);
                NeonDbService.upsertPantryItemInCloud(newPantry);
              }
            }
          });
        },
      ),
    );
  }

  void _showUserProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => UserProfileModal(
        userProfile: _userProfile,
        inStockCount: _pantryItems.length,
        savedRecipesCount: _savedRecipes.length,
        onProfileUpdated: (updated) {
          setState(() {
            _userProfile = updated;
          });
        },
      ),
    );
  }

  String get _currentAppBarTitle {
    switch (_activeTabIndex) {
      case 0:
        return 'Lino';
      case 1:
        return 'Meal Calendar';
      case 2:
        return 'Kitchen Inventory';
      case 3:
        return 'Saved Recipes';
      case 4:
        return 'Grocery Catalog';
      default:
        return 'Lino';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
      */
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const LinoLogo(
              size: 32,
              withContainer: true,
            ),
            const SizedBox(width: 10),
            Text(
              _currentAppBarTitle,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Multi-Session AI Chef Chat Icon beside Profile
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 24),
            tooltip: 'AI Chef Assistant',
            onPressed: _openChefAssistantModal,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: AppColors.primary, size: 26),
            tooltip: 'My Profile',
            onPressed: _showUserProfileModal,
          ),
          const SizedBox(width: 6),
        ],
      ),
      /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
      body: Stack(
      */
      body: TexturedBackground(
        child: Stack(
        children: [
          IndexedStack(
            index: _activeTabIndex,
            children: [
              _buildHomeDashboardTab(),
              _buildCalendarTab(),
              _buildPantryTab(),
              _buildSavedRecipesTab(),
              _buildShopTab(),
            ],
          ),
          // Global Floating Cart Banner (Visible across all tabs when items exist)
          if (_totalShoppingListCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: _showCartSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.lg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        /* PREVIOUS GREEN CART BADGE - COMMENTED OUT AS PER RULE
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        */
                        decoration: const BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_totalShoppingListCount Items in Cart',
                              style: const TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Tap to view restock list & export',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'VIEW CART ➔',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
          ],
        ),
        bottomNavigationBar: Container(
          */
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.7)),
        ),
        child: BottomNavigationBar(
          currentIndex: _activeTabIndex,
          backgroundColor: AppColors.surface,
          onTap: (index) => setState(() => _activeTabIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10.5),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('${_pantryItems.length}'),
                isLabelVisible: _pantryItems.isNotEmpty,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.kitchen_rounded),
              ),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('${_savedRecipes.length}'),
                isLabelVisible: _savedRecipes.isNotEmpty,
                backgroundColor: AppColors.warning,
                child: const Icon(Icons.bookmark_rounded),
              ),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('$_totalShoppingListCount'),
                isLabelVisible: _totalShoppingListCount > 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              label: 'Shop',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB: 📅 MEAL CALENDAR
  // ==========================================
  Widget _buildCalendarTab() {
    return MealCalendarScreen(
      pantryItems: _pantryItems,
      allCatalogItems: _allItems,
      savedRecipes: _savedRecipes,
      onAddMissingToCart: _addMissingRecipeItemsToShoppingList,
      onMealCooked: (recipe) {
        _stockCookedRecipeDepletion(recipe);
      },
    );
  }

  // Legacy simple name matching commented out:
  // void _stockCookedRecipeDepletion(MealRecipe recipe) {
  //   for (final ing in recipe.ingredientsWithQuantities) { ... }
  // }

  void _stockCookedRecipeDepletion(MealRecipe recipe) {
    final List<String> deductedNames = [];

    setState(() {
      final targetIngredients = <String>{};

      // 1. Collect clean ingredient names from usedInventory
      for (final used in recipe.usedInventory) {
        if (used.trim().isNotEmpty) {
          targetIngredients.add(used.toLowerCase().trim());
        }
      }

      // 2. Collect clean ingredient names from ingredientsWithQuantities
      for (final ing in recipe.ingredientsWithQuantities) {
        final clean = IngredientSanitizer.cleanIngredientName(ing).toLowerCase().trim();
        if (clean.isNotEmpty && !IngredientSanitizer.isUniversalFreeItem(clean)) {
          targetIngredients.add(clean);
        }
      }

      // 3. Deduct stock for all matched pantry items
      for (final targetName in targetIngredients) {
        final targetCanonical = CanonicalItemMatcher.getCanonicalKey(targetName);

        final matchIdx = _pantryItems.indexWhere((p) {
          final pName = p.name.toLowerCase().trim();
          final pCanonical = CanonicalItemMatcher.getCanonicalKey(pName);
          return pName == targetName ||
              pName.contains(targetName) ||
              targetName.contains(pName) ||
              (pCanonical.isNotEmpty && pCanonical == targetCanonical);
        });

        if (matchIdx != -1) {
          final item = _pantryItems[matchIdx];
          final newQty = item.quantity > 1 ? item.quantity - 1 : 0;
          final updatedItem = item.copyWith(
            quantity: newQty,
            isLowStock: newQty <= 1,
          );
          _pantryItems[matchIdx] = updatedItem;
          deductedNames.add(item.name);
          Future.microtask(() => NeonDbService.upsertPantryItemInCloud(updatedItem));
        }
      }
    });

    if (mounted && deductedNames.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '🍳 Cooked "${recipe.dishName}"! Deducted stock for: ${deductedNames.take(3).join(", ")}',
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      );
    }
  }

  void _openChefAssistantModal() {
    final stockedPantryGroceryItems = _pantryItems.map((p) => GroceryItem(
      id: p.id,
      nameEn: p.name,
      nameHi: p.name,
      category: p.category,
      availableUnits: [p.unit],
      selectedUnit: p.unit,
      quantity: p.quantity,
      isAdded: true,
    )).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: AppColors.primary),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(
              'Lino AI Chef',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          body: MealPlannerScreen(
            inventory: stockedPantryGroceryItems,
            onAddMissingItemsToList: _addMissingRecipeItemsToShoppingList,
            onViewSavedPresets: () {
              Navigator.pop(ctx);
              setState(() => _activeTabIndex = 3);
            },
            onMealCooked: (recipe) => _stockCookedRecipeDepletion(recipe),
            onSaveRecipe: (recipe) {
              setState(() {
                _savedRecipes.add(recipe);
              });
              Future.microtask(() => NeonDbService.syncSavedRecipeToCloud(recipe));
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: 🏠 HOME DASHBOARD (NEXT MEAL & DISCOVERY)
  // ==========================================
  Widget _buildHomeDashboardTab() {
    return HomeDashboardView(
      calendarEvents: _calendarEvents,
      pantryItems: _pantryItems,
      allCatalogItems: _allItems,
      savedRecipes: _savedRecipes,
      userProfile: _userProfile,
      onOpenChatAssistant: _openChefAssistantModal,
      onOpenCart: _showCartSheet,
      onOpenCalendar: () => setState(() => _activeTabIndex = 1),
      onOpenShop: () => setState(() => _activeTabIndex = 4),
      onMealCooked: (recipe) => _stockCookedRecipeDepletion(recipe),
      onAddMissingToCart: (missingItems) => _addMissingRecipeItemsToShoppingList(missingItems),
      onScheduleRecipe: (event) {
        setState(() {
          _calendarEvents.add(event);
        });
        NeonDbService.syncMealEventToCloud(event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            // content: Text('Scheduled "${event.dishName}" for ${event.mealSlot.displayName}!'),
            content: Text('Scheduled "${event.dishName}" for ${event.mealSlot.label}!'),
          ),
        );
      },
      onToggleCartItem: (item) => _toggleItemAdded(item),
    );
  }

  /* PREVIOUS TAB 1 INLINE MEAL PLANNER - COMMENTED OUT AS PER RULE
  Widget _buildMealPlannerTab() {
    final stockedPantryGroceryItems = _pantryItems.map((p) => GroceryItem(
      id: p.id,
      nameEn: p.name,
      nameHi: p.name,
      category: p.category,
      availableUnits: [p.unit],
      selectedUnit: p.unit,
      quantity: p.quantity,
      isAdded: true,
    )).toList();

    return MealPlannerScreen(
      inventory: stockedPantryGroceryItems,
      onAddMissingItemsToList: _addMissingRecipeItemsToShoppingList,
      onViewSavedPresets: () => setState(() => _activeTabIndex = 2),
      onMealCooked: (recipe) => _stockCookedRecipeDepletion(recipe),
      onSaveRecipe: (recipe) {
        setState(() {
          _savedRecipes.add(recipe);
        });
        Future.microtask(() => NeonDbService.syncSavedRecipeToCloud(recipe));
      },
    );
  }
  */

  // ==========================================
  // TAB 2: 📦 KITCHEN PANTRY (DEDICATED SCREEN)
  // ==========================================
  Widget _buildPantryTab() {
    return PantryInventoryScreen(
      pantryItems: _pantryItems,
      isLoading: _isPantryLoading,
      onOpenReceiptScanner: _showReceiptImporterSheet,
      onAddPantryItem: (newItem) {
        setState(() => _pantryItems.insert(0, newItem));
        NeonDbService.upsertPantryItemInCloud(newItem);
      },
      onUpdatePantryItem: (updatedItem) {
        setState(() {
          final idx = _pantryItems.indexWhere((p) => p.id == updatedItem.id);
          if (idx != -1) {
            _pantryItems[idx] = updatedItem;
          }
        });
        NeonDbService.upsertPantryItemInCloud(updatedItem);
      },
      onUpdatePantryQuantity: (item, newQty) {
        setState(() {
          final idx = _pantryItems.indexWhere((p) => p.id == item.id);
          if (idx != -1) {
            if (newQty <= 0) {
              _pantryItems.removeAt(idx);
              NeonDbService.deletePantryItemFromCloud(item.id);
            } else {
              _pantryItems[idx].quantity = newQty;
              NeonDbService.upsertPantryItemInCloud(_pantryItems[idx]);
            }
          }
        });
      },
      onDeletePantryItem: (item) {
        setState(() => _pantryItems.removeWhere((p) => p.id == item.id));
        NeonDbService.deletePantryItemFromCloud(item.id);
      },
      onPushToRestockList: (item) {
        setState(() {
          final matchIdx = IngredientSanitizer.findMatchingItemIndex(item.name, _allItems);
          if (matchIdx != -1) {
            _allItems[matchIdx] = _allItems[matchIdx].copyWith(
              isAdded: true,
              quantity: _allItems[matchIdx].isAdded && _allItems[matchIdx].quantity > 0 ? _allItems[matchIdx].quantity : 1,
            );
          } else {
            _allItems.add(
              GroceryItem(
                id: 'pantry_restock_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
                nameEn: item.name,
                nameHi: item.name,
                category: item.category,
                availableUnits: [item.unit.isNotEmpty ? item.unit : '1 Pack', '1 kg', '500 g'],
                selectedUnit: item.unit.isNotEmpty ? item.unit : '1 Pack',
                isAdded: true,
                quantity: 1,
              ),
            );
          }
        });
        NeonDbService.syncInventoryToCloud(_allItems);
      },
    );
  }

  // ==========================================
  // TAB 3: 📖 SAVED RECIPES & COOKBOOKS (DEDICATED SCREEN)
  // ==========================================
  Widget _buildSavedRecipesTab() {
    return SavedRecipesScreen(
      initialRecipes: _savedRecipes,
      onDeleteRecipe: (recipe) {
        setState(() => _savedRecipes.removeWhere((r) => r.id == recipe.id));
      },
      onDeductCookedIngredients: (recipe) {
        _stockCookedRecipeDepletion(recipe.toMealRecipe);
      },
      onAddMissingItemsToCart: (missingItems) {
        _addMissingRecipeItemsToShoppingList(missingItems);
      },
      onExploreMealPlanner: () {
        setState(() => _activeTabIndex = 0);
      },
    );
  }

  // ==========================================
  // TAB 4: 🛒 SHOP TAB (DEDICATED SCREEN IN lib/screens/shop_catalog_screen.dart)
  // ==========================================
  Widget _buildShopTab() {
    return ShopCatalogScreen(
      allCatalogItems: _allItems,
      onToggleItemAdded: _toggleItemAdded,
      onUpdateItemQuantity: _updateItemQuantity,
      onUpdateItemUnit: _updateItemUnit,
      onOpenCart: _showCartSheet,
    );
  }
}
