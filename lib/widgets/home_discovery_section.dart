import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/pantry_item.dart';
import '../models/meal_calendar_event.dart';
import '../services/openrouter/meal_recipe.dart';
import '../services/ingredient_sanitizer.dart';
import 'tactile_tap.dart';

class HomeDiscoverySection extends StatefulWidget {
  final List<PantryItem> pantryItems;
  final Map<String, String?> userProfile;
  final VoidCallback onOpenChatAssistant;
  final Function(List<String> missingItems) onAddMissingToCart;
  final Function(MealCalendarEvent event) onScheduleRecipe;

  const HomeDiscoverySection({
    super.key,
    required this.pantryItems,
    required this.userProfile,
    required this.onOpenChatAssistant,
    required this.onAddMissingToCart,
    required this.onScheduleRecipe,
  });

  @override
  State<HomeDiscoverySection> createState() => _HomeDiscoverySectionState();
}

class _HomeDiscoverySectionState extends State<HomeDiscoverySection> {
  String _selectedDiscoveryFilter = 'All';

  final List<String> _discoveryFilters = const [
    'All',
    'Pantry Matched',
    'Quick 15-Min',
    'High Protein',
    'Comfort Bowls',
  ];

  final List<Map<String, dynamic>> _curatedDiscoveryDishes = const [
    {
      'title': 'Palak Paneer with Jeera Rice',
      'category': 'Pantry Matched',
      'prepTime': '20 mins',
      'servings': 2,
      'difficulty': 'Easy',
      'ingredients': ['Paneer', 'Spinach', 'Jeera', 'Rice', 'Garlic', 'Onion'],
      'image': 'assets/images/rice.png',
      'diet': 'Veg',
      'calories': '380 kcal',
    },
    {
      'title': 'Crispy Masala Aloo Roast',
      'category': 'Quick 15-Min',
      'prepTime': '15 mins',
      'servings': 2,
      'difficulty': 'Quick',
      'ingredients': ['Potato', 'Mustard Seeds', 'Turmeric', 'Chilli Powder', 'Curry Leaves'],
      'image': 'assets/images/logo.png',
      'diet': 'Veg',
      'calories': '240 kcal',
    },
    {
      'title': 'Dal Tadka with Steamed Basmati',
      'category': 'Comfort Bowls',
      'prepTime': '25 mins',
      'servings': 3,
      'difficulty': 'Classic',
      'ingredients': ['Toor Dal', 'Ghee', 'Jeera', 'Tomato', 'Garlic', 'Hing'],
      'image': 'assets/images/rice.png',
      'diet': 'Veg',
      'calories': '310 kcal',
    },
    {
      'title': 'High-Protein Egg Bhurji Roll',
      'category': 'High Protein',
      'prepTime': '12 mins',
      'servings': 1,
      'difficulty': 'Quick',
      'ingredients': ['Eggs', 'Onion', 'Tomato', 'Green Chilli', 'Atta Roti'],
      'image': 'assets/images/logo.png',
      'diet': 'Eggetarian',
      'calories': '350 kcal',
    },
    {
      'title': 'Homestyle Yellow Moong Khichdi',
      'category': 'Comfort Bowls',
      'prepTime': '20 mins',
      'servings': 2,
      'difficulty': 'Gentle',
      'ingredients': ['Moong Dal', 'Rice', 'Ghee', 'Jeera', 'Turmeric', 'Ginger'],
      'image': 'assets/images/rice.png',
      'diet': 'Veg',
      'calories': '290 kcal',
    },
  ];

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDiscoveryHeader(),
        const SizedBox(height: 12),
        _buildFilterPills(),
        const SizedBox(height: 14),
        _buildDiscoveryCards(),
      ],
    );
  }

  Widget _buildDiscoveryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kitchen Discovery',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                letterSpacing: -0.2,
              ),
            ),
            TactileTap(
              onTap: widget.onOpenChatAssistant,
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accentBlue),
                  SizedBox(width: 4),
                  Text(
                    'AI Inspos',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // const Text('Pinterest-style inspirations tailored to your pantry & tastes', ...)
        const Text(
          'Fresh meal inspirations tailored to your pantry & tastes',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPills() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _discoveryFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _discoveryFilters[index];
          final isSelected = _selectedDiscoveryFilter == filter;
          return TactileTap(
            onTap: () => setState(() => _selectedDiscoveryFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoveryCards() {
    var list = _curatedDiscoveryDishes;
    if (_selectedDiscoveryFilter != 'All') {
      list = list.where((d) => d['category'] == _selectedDiscoveryFilter).toList();
      if (list.isEmpty) list = _curatedDiscoveryDishes;
    }

    return Column(
      children: list.map((dish) {
        final ingredients = (dish['ingredients'] as List).cast<String>();
        final missing = _getMissingIngredients(ingredients);
        final matchCount = ingredients.length - missing.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.lgBorder,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          dish['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dish['diet'],
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${dish['prepTime']} / ${dish['calories']}',
                                style: const TextStyle(
                                  fontFamily: 'Funnel Display',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dish['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$matchCount of ${ingredients.length} in pantry',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: missing.isEmpty ? AppColors.success : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.borderLight),

              // Card Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TactileTap(
                      onTap: () {
                        // final recipe = MealRecipe(
                        //   dishName: dish['title'],
                        //   prepTime: dish['prepTime'],
                        //   servings: dish['servings'],
                        //   description: 'Curated kitchen discovery recipe',
                        //   ingredientsWithQuantities: ingredients,
                        //   instructions: ['Prepare ingredients', 'Cook on medium heat', 'Serve hot'],
                        //   usedInventory: ingredients.where((i) => !missing.contains(i)).toList(),
                        //   missingItems: missing,
                        // );
                        final recipe = MealRecipe(
                          dishName: dish['title'],
                          prepTime: dish['prepTime'],
                          servings: '${dish['servings']} People',
                          dietType: dish['diet'] ?? 'Veg',
                          ingredientsWithQuantities: ingredients,
                          usedInventory: ingredients.where((i) => !missing.contains(i)).toList(),
                          missingItems: missing,
                          substitutions: const [],
                          cavemanSteps: const ['Prepare ingredients', 'Cook on medium heat', 'Serve hot'],
                          chefTip: 'Garnish with fresh coriander or herbs before serving.',
                          macros: MealMacroSummary(
                            calories: dish['calories'] ?? '350 kcal',
                            protein: '15g',
                            carbs: '40g',
                            fat: '10g',
                          ),
                        );
                        final event = MealCalendarEvent(
                          id: 'disc_${DateTime.now().microsecondsSinceEpoch}',
                          userId: widget.userProfile['id'] ?? 'user_lino_primary',
                          eventDate: DateTime.now(),
                          mealSlot: CalendarMealSlot.dinner,
                          dishName: dish['title'],
                          recipe: recipe,
                          servings: dish['servings'],
                        );
                        widget.onScheduleRecipe(event);
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.accentBlue),
                          SizedBox(width: 4),
                          Text(
                            'Schedule',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (missing.isNotEmpty)
                      TactileTap(
                        onTap: () => widget.onAddMissingToCart(missing),
                        child: const Row(
                          children: [
                            Icon(Icons.add_shopping_cart_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Add Missing',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    TactileTap(
                      onTap: widget.onOpenChatAssistant,
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Ask AI Chef',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
