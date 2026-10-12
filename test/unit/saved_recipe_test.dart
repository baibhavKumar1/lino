import 'package:flutter_test/flutter_test.dart';
// import 'package:kichook/models/saved_recipe.dart';
// import 'package:kichook/services/openrouter_service.dart';
import 'package:lino/models/saved_recipe.dart';
import 'package:lino/services/openrouter_service.dart';

void main() {
  group('SavedRecipe Tests', () {
    test('converts MealRecipe to SavedRecipe and back via toMealRecipe', () {
      final recipe = MealRecipe(
        dishName: 'Dal Tadka',
        prepTime: '20 Mins',
        servings: '2 People',
        dietType: 'Veg',
        ingredientsWithQuantities: ['1 cup Toor Dal', '1 tsp Jeera', '2 Ghee'],
        usedInventory: ['Toor Dal', 'Jeera', 'Ghee'],
        missingItems: [],
        substitutions: [],
        cavemanSteps: ['Pressure cook dal', 'Prepare jeera tadka', 'Mix and enjoy'],
        chefTip: 'Use fresh desi ghee for tadka aroma.',
        macros: MealMacroSummary(
          calories: '280 kcal',
          protein: '14g',
          carbs: '38g',
          fat: '8g',
        ),
      );

      final saved = SavedRecipe.fromMealRecipe(recipe);
      expect(saved.dishName, 'Dal Tadka');
      expect(saved.prepTime, '20 Mins');

      final convertedBack = saved.toMealRecipe;
      expect(convertedBack.dishName, 'Dal Tadka');
      expect(convertedBack.macros.protein, '14g');
      expect(convertedBack.cavemanSteps.length, 3);
      expect(saved.recipe.dishName, 'Dal Tadka');
    });

    test('serializes and deserializes SavedRecipe JSON correctly', () {
      final saved = SavedRecipe(
        id: 'rec_101',
        dishName: 'Poha',
        prepTime: '10 Mins',
        servings: '2',
        dietType: 'Veg',
        ingredientsWithQuantities: ['1 cup Poha', '1/2 tsp Haldi', 'Peanuts'],
        usedInventory: ['Poha', 'Haldi'],
        cavemanSteps: ['Wash poha', 'Saute peanuts', 'Toss with haldi and poha'],
        chefTip: 'Squeeze fresh lemon before serving.',
        macros: MealMacroSummary(
          calories: '250 kcal',
          protein: '6g',
          carbs: '45g',
          fat: '5g',
        ),
        createdAt: DateTime(2026, 8, 25),
      );

      final json = saved.toJson();
      expect(json['id'], 'rec_101');
      expect(json['dishName'], 'Poha');

      final restored = SavedRecipe.fromJson(json);
      expect(restored.id, 'rec_101');
      expect(restored.dishName, 'Poha');
      expect(restored.chefTip, 'Squeeze fresh lemon before serving.');
    });
  });
}
