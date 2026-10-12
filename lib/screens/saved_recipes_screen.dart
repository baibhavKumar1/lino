import 'package:flutter/material.dart';
import '../models/saved_recipe.dart';
import '../widgets/saved_recipes_modal.dart';

export '../widgets/saved_recipes_modal.dart';

/// First-class screen wrapper for Saved Recipes & Cookbooks in Lino
class SavedRecipesScreen extends StatelessWidget {
  final List<SavedRecipe> initialRecipes;
  final Function(SavedRecipe recipe) onDeleteRecipe;
  final Function(SavedRecipe recipe) onDeductCookedIngredients;
  final Function(List<String> missingItems)? onAddMissingItemsToCart;
  final VoidCallback? onExploreMealPlanner;

  const SavedRecipesScreen({
    super.key,
    required this.initialRecipes,
    required this.onDeleteRecipe,
    required this.onDeductCookedIngredients,
    this.onAddMissingItemsToCart,
    this.onExploreMealPlanner,
  });

  @override
  Widget build(BuildContext context) {
    return SavedRecipesModal(
      initialRecipes: initialRecipes,
      onDeleteRecipe: onDeleteRecipe,
      onDeductCookedIngredients: onDeductCookedIngredients,
      onAddMissingItemsToCart: onAddMissingItemsToCart,
      onExploreMealPlanner: onExploreMealPlanner,
    );
  }
}
