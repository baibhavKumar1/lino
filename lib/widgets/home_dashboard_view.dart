import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';
import '../models/saved_recipe.dart';
import '../models/meal_calendar_event.dart';
import '../services/openrouter/meal_recipe.dart';
import '../services/ingredient_sanitizer.dart';
import 'tactile_tap.dart';
import 'home_discovery_section.dart';
import 'recipe_detail_modal.dart';

enum HomeHeroMode {
  nextMeal,
  cartItems,
}

class HomeDashboardView extends StatefulWidget {
  final List<MealCalendarEvent> calendarEvents;
  final List<PantryItem> pantryItems;
  final List<GroceryItem> allCatalogItems;
  final List<SavedRecipe> savedRecipes;
  final Map<String, String?> userProfile;
  final VoidCallback onOpenChatAssistant;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenShop;
  final Function(MealRecipe recipe) onMealCooked;
  final Function(List<String> missingItems) onAddMissingToCart;
  final Function(MealCalendarEvent event) onScheduleRecipe;
  final Function(GroceryItem item) onToggleCartItem;

  const HomeDashboardView({
    super.key,
    required this.calendarEvents,
    required this.pantryItems,
    required this.allCatalogItems,
    required this.savedRecipes,
    required this.userProfile,
    required this.onOpenChatAssistant,
    required this.onOpenCart,
    required this.onOpenCalendar,
    required this.onOpenShop,
    required this.onMealCooked,
    required this.onAddMissingToCart,
    required this.onScheduleRecipe,
    required this.onToggleCartItem,
  });

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  HomeHeroMode _heroMode = HomeHeroMode.nextMeal;

  MealCalendarEvent? _findNextMeal() {
    if (widget.calendarEvents.isEmpty) return null;

    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T').first;

    // 1. Look for today's uncooked meal
    final todayMeals = widget.calendarEvents.where((e) {
      final eDateStr = e.eventDate.toIso8601String().split('T').first;
      return eDateStr == todayStr && !e.isCooked;
    }).toList();

    if (todayMeals.isNotEmpty) {
      final hour = now.hour;
      if (hour < 11) {
        return todayMeals.firstWhere(
          (e) => e.mealSlot == CalendarMealSlot.breakfast,
          orElse: () => todayMeals.first,
        );
      } else if (hour < 16) {
        return todayMeals.firstWhere(
          (e) => e.mealSlot == CalendarMealSlot.lunch,
          orElse: () => todayMeals.first,
        );
      } else {
        return todayMeals.firstWhere(
          (e) => e.mealSlot == CalendarMealSlot.dinner,
          orElse: () => todayMeals.first,
        );
      }
    }

    // 2. Look for future uncooked meals
    final futureMeals = widget.calendarEvents.where((e) {
      return e.eventDate.isAfter(now.subtract(const Duration(hours: 12))) && !e.isCooked;
    }).toList();

    if (futureMeals.isNotEmpty) {
      futureMeals.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return futureMeals.first;
    }

    return null;
  }

  List<String> _getMissingIngredients(List<String> neededIngredients) {
    final missing = <String>[];
    for (final raw in neededIngredients) {
      if (IngredientSanitizer.isUniversalFreeItem(raw)) continue;
      final clean = IngredientSanitizer.cleanIngredientName(raw);
      if (clean.isEmpty) continue;

      final isAvailable = widget.pantryItems.any((p) {
        final pName = p.name.toLowerCase().trim();
        final cName = clean.toLowerCase().trim();
        return pName == cName || pName.contains(cName) || cName.contains(pName);
      });

      if (!isAvailable) {
        missing.add(clean);
      }
    }
    return missing;
  }

  @override
  Widget build(BuildContext context) {
    final activeCartItems = widget.allCatalogItems.where((i) => i.isAdded).toList();
    final nextMeal = _findNextMeal();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Quick Chef Prompt
          _buildGreetingBanner(),

          const SizedBox(height: 16),

          // Interactive Hero Mode Switcher: [Next Planned Meal] vs [Cart Items]
          _buildHeroModeSwitcher(activeCartItems.length),

          const SizedBox(height: 14),

          // Hero Interactive Card
          if (_heroMode == HomeHeroMode.nextMeal)
            _buildNextMealCard(nextMeal)
          else
            _buildCartItemsCard(activeCartItems),

          const SizedBox(height: 24),

          // Pinterest-Style Discovery Section (Curated Dishes & Inspirations)
          HomeDiscoverySection(
            pantryItems: widget.pantryItems,
            userProfile: widget.userProfile,
            onOpenChatAssistant: widget.onOpenChatAssistant,
            onAddMissingToCart: widget.onAddMissingToCart,
            onScheduleRecipe: widget.onScheduleRecipe,
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner() {
    final fullName = widget.userProfile['fullName'] ?? 'Chef';
    final firstName = fullName.split(' ').first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.pantryItems.length} ingredients in pantry / Smart meal hub',
                  style: const TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TactileTap(
            onTap: widget.onOpenChatAssistant,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.accentBlue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Ask Chef',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroModeSwitcher(int cartCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TactileTap(
              onTap: () => setState(() => _heroMode = HomeHeroMode.nextMeal),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _heroMode == HomeHeroMode.nextMeal ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _heroMode == HomeHeroMode.nextMeal ? AppShadows.card : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 16,
                      color: _heroMode == HomeHeroMode.nextMeal ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Next Planned Meal',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _heroMode == HomeHeroMode.nextMeal ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TactileTap(
              onTap: () => setState(() => _heroMode = HomeHeroMode.cartItems),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _heroMode == HomeHeroMode.cartItems ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _heroMode == HomeHeroMode.cartItems ? AppShadows.card : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: _heroMode == HomeHeroMode.cartItems ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cart Items',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _heroMode == HomeHeroMode.cartItems ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    if (cartCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _heroMode == HomeHeroMode.cartItems ? AppColors.accentBlue : AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMealCard(MealCalendarEvent? nextMeal) {
    if (nextMeal == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.xlBorder,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.soup_kitchen_rounded, color: AppColors.accentBlue, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              'No Meal Planned for Today Yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ask your AI Chef to plan dinner using your in-stock pantry items',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TactileTap(
                    onTap: widget.onOpenChatAssistant,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Plan Meal with AI Chef',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TactileTap(
                  onTap: widget.onOpenCalendar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final rawIngredients = nextMeal.recipe?.usedInventory ?? nextMeal.recipe?.ingredientsWithQuantities ?? [];
    final missingIngredients = _getMissingIngredients(rawIngredients);
    final isReadyToCook = missingIngredients.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xlBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  // nextMeal.mealSlot.displayName.toUpperCase(),
                  nextMeal.mealSlot.label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${nextMeal.servings} Servings / ${nextMeal.recipe?.prepTime ?? "25 mins"}',
                style: const TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TactileTap(
                onTap: widget.onOpenCalendar,
                child: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nextMeal.dishName,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Pantry Readiness Indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isReadyToCook ? AppColors.successLight : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isReadyToCook ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isReadyToCook ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: isReadyToCook ? AppColors.success : AppColors.warningDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isReadyToCook
                        ? 'All ingredients in stock Ready to cook'
                        : '${missingIngredients.length} ingredients missing from pantry',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isReadyToCook ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!isReadyToCook)
                  TactileTap(
                    onTap: () => widget.onAddMissingToCart(missingIngredients),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+ Add to Cart',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Primary Actions
          Row(
            children: [
              Expanded(
                child: TactileTap(
                  onTap: () {
                    if (nextMeal.recipe != null) {
                      widget.onMealCooked(nextMeal.recipe!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.outdoor_grill_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          // 'Cook Now (Deduct Stock)',
                          'Cook Now',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TactileTap(
                // onTap: widget.onOpenChatAssistant,
                onTap: () {
                  final recipeToShow = nextMeal.recipe ??
                      MealRecipe(
                        dishName: nextMeal.dishName,
                        prepTime: '20 mins',
                        servings: '${nextMeal.servings} People',
                        dietType: 'Veg',
                        ingredientsWithQuantities: const ['Pantry Ingredients', 'Seasonings'],
                        usedInventory: const ['Pantry Ingredients'],
                        missingItems: const [],
                        substitutions: const [],
                        cavemanSteps: const ['Prep ingredients', 'Cook till tender and fragrant', 'Serve warm'],
                        chefTip: 'Taste and adjust seasonings before serving.',
                        macros: MealMacroSummary(calories: '350 kcal', protein: '15g', carbs: '40g', fat: '10g'),
                      );

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => RecipeDetailModal(
                      recipe: recipeToShow,
                      onCookMeal: () => widget.onMealCooked(recipeToShow),
                      onAddMissingToCart: (missing) => widget.onAddMissingToCart(missing),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Details',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsCard(List<GroceryItem> activeCartItems) {
    if (activeCartItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.xlBorder,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.shopping_cart_outlined, color: AppColors.accentBlue, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              'Shopping Cart is Clear',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Browse the Shop Catalog or let your AI Chef auto-add missing ingredients',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TactileTap(
              onTap: widget.onOpenShop,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Explore Shop Catalog',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xlBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${activeCartItems.length} Items to Buy',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              TactileTap(
                onTap: widget.onOpenCart,
                child: Text(
                  'OPEN FULL CART ➔',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items preview list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeCartItems.take(4).length,
            separatorBuilder: (_, __) => const Divider(height: 12, color: AppColors.borderLight),
            itemBuilder: (context, index) {
              final item = activeCartItems[index];
              return Row(
                children: [
                  TactileTap(
                    onTap: () => widget.onToggleCartItem(item),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: item.isChecked ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.isChecked ? AppColors.primary : AppColors.borderDark,
                          width: 1.4,
                        ),
                      ),
                      child: item.isChecked
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.nameEn,
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: item.isChecked ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Text(
                    '${item.quantity} ${item.selectedUnit}',
                    style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),

          if (activeCartItems.length > 4) ...[
            const SizedBox(height: 8),
            Text(
              '+ ${activeCartItems.length - 4} more items in list',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],

          const SizedBox(height: 16),
          TactileTap(
            onTap: widget.onOpenCart,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                'View & Restock Cart',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
