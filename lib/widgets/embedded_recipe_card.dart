import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/openrouter_service.dart';
import 'tactile_tap.dart';
import 'schedule_recipe_modal.dart';
import 'markdown_text.dart';

class EmbeddedRecipeCard extends StatelessWidget {
  final MealRecipe recipe;
  final String uniqueKey;
  final bool isSaved;
  final bool isCooked;
  final VoidCallback onSave;
  final VoidCallback onCooked;
  final Function(List<String>) onAddMissingItems;

  const EmbeddedRecipeCard({
    Key? key,
    required this.recipe,
    required this.uniqueKey,
    required this.isSaved,
    required this.isCooked,
    required this.onSave,
    required this.onCooked,
    required this.onAddMissingItems,
  }) : super(key: key);

  Widget _buildMacroChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xlBorder,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Dish Name + Prep Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  recipe.dishName,
                  style: AppTypography.displayMedium(fontSize: 17),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recipe.prepTime,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Macros row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroChip('Calories', recipe.macros.calories, AppColors.warningDark),
                _buildMacroChip('Protein', recipe.macros.protein, AppColors.primaryDark),
                _buildMacroChip('Carbs', recipe.macros.carbs, AppColors.accentBlue),
                _buildMacroChip('Fat', recipe.macros.fat, AppColors.danger),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Ingredients Wrap
          Text('INGREDIENTS', style: AppTypography.label(letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: recipe.ingredientsWithQuantities.map((ing) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  ing,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              );
            }).toList(),
          ),

          // Missing ingredients box if quick delivery is used
          if (recipe.missingItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Missing Ingredients (${recipe.missingItems.length})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                      ),
                      TactileTap(
                        onTap: () {
                          onAddMissingItems(recipe.missingItems);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_shopping_cart_rounded, size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text('1-Tap Add to Cart', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: recipe.missingItems.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Caveman Steps
          Text('COOKING STEPS', style: AppTypography.label(letterSpacing: 0.8)),
          const SizedBox(height: 6),
          ...recipe.cavemanSteps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.25),
                    ),
                    */
                    child: MarkdownText(
                      entry.value,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.25),
                      boldStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (recipe.chefTip.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.warningDark),
                  const SizedBox(width: 6),
                  Expanded(
                    /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                    child: Text(
                      'Chef Tip: ${recipe.chefTip}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                    */
                    child: MarkdownText(
                      'Chef Tip: ${recipe.chefTip}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      boldStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF78350F)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons: Save, Schedule & Cooked
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TactileTap(
                  onTap: onSave,
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSaved ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSaved ? AppColors.primaryDark : AppColors.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                          size: 13,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSaved ? 'Saved' : 'Save',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TactileTap(
                  onTap: () => ScheduleRecipeModal.show(context, recipe),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 13, color: AppColors.textPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Schedule',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TactileTap(
                  onTap: onCooked,
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: isCooked ? AppColors.surfaceMuted : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.soup_kitchen_rounded,
                          size: 13,
                          color: isCooked ? AppColors.textSecondary : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCooked ? 'Cooked!' : 'Cook',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCooked ? AppColors.textSecondary : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
