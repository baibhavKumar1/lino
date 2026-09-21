import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/saved_recipe.dart';
import '../services/neon_db_service.dart';
import 'tactile_tap.dart';
import 'markdown_text.dart';

class SavedRecipesModal extends StatefulWidget {
  final List<SavedRecipe> initialRecipes;
  final Function(SavedRecipe recipe) onDeleteRecipe;
  final Function(SavedRecipe recipe) onDeductCookedIngredients;
  final Function(List<String> missingItems)? onAddMissingItemsToCart;
  final VoidCallback? onExploreMealPlanner;

  const SavedRecipesModal({
    super.key,
    required this.initialRecipes,
    required this.onDeleteRecipe,
    required this.onDeductCookedIngredients,
    this.onAddMissingItemsToCart,
    this.onExploreMealPlanner,
  });

  @override
  State<SavedRecipesModal> createState() => _SavedRecipesModalState();
}

class _SavedRecipesModalState extends State<SavedRecipesModal> {
  late List<SavedRecipe> _recipes;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Quick (<30m)', 'Vegetarian', 'High Protein'];

  @override
  void initState() {
    super.initState();
    _recipes = List.from(widget.initialRecipes);
  }

  @override
  void didUpdateWidget(covariant SavedRecipesModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _recipes = List.from(widget.initialRecipes);
    });
  }

  List<SavedRecipe> get _filteredRecipes {
    return _recipes.where((recipe) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          recipe.dishName.toLowerCase().contains(query) ||
          recipe.dietType.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'Quick (<30m)') {
        final timeStr = recipe.prepTime.replaceAll(RegExp(r'[^0-9]'), '');
        final mins = int.tryParse(timeStr) ?? 30;
        return mins <= 30;
      } else if (_selectedFilter == 'Vegetarian') {
        final lower = '${recipe.dishName} ${recipe.dietType}'.toLowerCase();
        return !lower.contains('chicken') && !lower.contains('mutton') && !lower.contains('egg') && !lower.contains('fish');
      } else if (_selectedFilter == 'High Protein') {
        final lower = '${recipe.dishName} ${recipe.macros.protein}'.toLowerCase();
        return lower.contains('paneer') || lower.contains('dal') || lower.contains('protein') || lower.contains('soya') || lower.contains('2') || lower.contains('3');
      }
      return true;
    }).toList();
  }

  void _removeRecipe(SavedRecipe recipe) {
    setState(() {
      _recipes.removeWhere((r) => r.id == recipe.id);
    });
    widget.onDeleteRecipe(recipe);
    NeonDbService.deleteSavedRecipeFromCloud(recipe.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Removed "${recipe.dishName}" from saved vault',
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  void _showRecipeDetails(BuildContext context, SavedRecipe recipe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlBorder),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  recipe.dishName,
                  style: AppTypography.displaySmall(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recipe.prepTime,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Macros Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadii.mdBorder,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroItem('Calories', recipe.macros.calories, AppColors.warningDark),
                      _buildMacroItem('Protein', recipe.macros.protein, AppColors.accentBlue),
                      _buildMacroItem('Carbs', recipe.macros.carbs, AppColors.primaryDark),
                      _buildMacroItem('Fats', recipe.macros.fat, AppColors.danger),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ingredients
                Text(
                  'REQUIRED INGREDIENTS (${recipe.ingredientsWithQuantities.length})',
                  style: AppTypography.label(letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                ...recipe.ingredientsWithQuantities.map((ing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ing,
                            style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Instructions
                Text(
                  'COOKING INSTRUCTIONS',
                  style: AppTypography.label(letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                ...recipe.cavemanSteps.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                          child: Text(
                            step,
                            style: AppTypography.bodySmall(color: AppColors.textPrimary),
                          ),
                          */
                          child: MarkdownText(
                            step,
                            style: AppTypography.bodySmall(color: AppColors.textPrimary),
                            boldStyle: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (recipe.chefTip.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: AppRadii.mdBorder,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warningDark),
                        const SizedBox(width: 6),
                        Expanded(
                          /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                          child: Text(
                            recipe.chefTip,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.3),
                          ),
                          */
                          child: MarkdownText(
                            recipe.chefTip,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.3),
                            boldStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF78350F), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
              ),
              icon: const Icon(Icons.soup_kitchen_rounded, size: 16, color: AppColors.textWhite),
              label: const Text('Cook Meal', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textWhite)),
              onPressed: () {
                widget.onDeductCookedIngredients(recipe);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Bon appetit! Enjoy cooking ${recipe.dishName}.',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMacroItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecipes;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. HERO EDITORIAL VAULT HEADER
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.lgBorder,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: AppColors.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Recipes',
                          style: AppTypography.displayMedium(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_recipes.length} curated recipes saved for cooking',
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_recipes.length} Saved',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // 2. SEARCH & QUICK FILTER PILLS
            // ==========================================
            SizedBox(
              height: 42,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search saved recipes or cuisines...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.mdBorder,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.mdBorder,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Filter Chips (Concentric 8px radii, 32px height)
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final f = _filters[index];
                  final isSelected = _selectedFilter == f;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TactileTap(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          boxShadow: isSelected ? AppShadows.soft : null,
                        ),
                        child: Center(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 3. RECIPE VAULT LIST / CARDS
            // ==========================================
            if (_recipes.isEmpty) ...[
              _buildEmptyState(),
            ] else if (filtered.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.lgBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No recipes matching your search',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final recipe = filtered[index];
                  return _buildRecipeCard(recipe);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(SavedRecipe recipe) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Cuisine tag + Time + Options Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipe.dietType.isNotEmpty ? recipe.dietType : 'Indian Kitchen',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⏱️ ${recipe.prepTime}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              // 44pt Touch hit area menu button
              SizedBox(
                width: 36,
                height: 36,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
                  onSelected: (val) {
                    if (val == 'view') {
                      _showRecipeDetails(context, recipe);
                    } else if (val == 'delete') {
                      _removeRecipe(recipe);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('View Recipe', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Remove Recipe', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dish Name in Warm Fraunces
          Text(
            recipe.dishName,
            style: AppTypography.displaySmall(fontSize: 17),
          ),

          const SizedBox(height: 6),

          // Macros summary
          Row(
            children: [
              Text(
                '${recipe.macros.calories} | ${recipe.macros.protein} Protein | ${recipe.ingredientsWithQuantities.length} Ingredients',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),

          // Action Buttons: Cook & View + Add Missing to Cart with scale(0.96) feedback
          Row(
            children: [
              Expanded(
                child: TactileTap(
                  onTap: () => _showRecipeDetails(context, recipe),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.soup_kitchen_rounded, size: 16, color: AppColors.primaryDark),
                        SizedBox(width: 6),
                        Text(
                          'Cook Meal',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.onAddMissingItemsToCart != null) ...[
                const SizedBox(width: 8),
                TactileTap(
                  onTap: () {
                    widget.onAddMissingItemsToCart!(recipe.ingredientsWithQuantities);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added ingredients for "${recipe.dishName}" to your Shop Cart',
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: AppColors.textPrimary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: AppColors.accentBlue),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xlBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded, size: 36, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Text(
            'No Saved Recipes Yet',
            style: AppTypography.displaySmall(fontSize: 17),
          ),
          const SizedBox(height: 4),
          const Text(
            'Save delicious meals and customized curries from the Meal Planner tab to cook them anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.onExploreMealPlanner != null)
            TactileTap(
              onTap: widget.onExploreMealPlanner,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows.soft,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu_rounded, color: AppColors.textWhite, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Explore Meal Planner',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textWhite),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
