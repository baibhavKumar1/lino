import 'package:flutter_test/flutter_test.dart';
import 'package:kichook/models/meal_calendar_event.dart';
import 'package:kichook/services/openrouter_service.dart';

void main() {
  group('MealCalendarEvent Tests', () {
    test('serializes and deserializes correctly', () {
      final recipe = MealRecipe(
        dishName: 'Paneer Butter Masala',
        prepTime: '25 Mins',
        servings: '2 People',
        dietType: 'Veg',
        ingredientsWithQuantities: ['200g Paneer', '2 Tomatoes', '1 tbsp Butter'],
        usedInventory: ['Paneer', 'Butter'],
        missingItems: ['Tomatoes'],
        substitutions: [],
        cavemanSteps: ['Cut paneer', 'Cook gravy', 'Simmer and serve'],
        chefTip: 'Add kasuri methi at the end.',
        macros: MealMacroSummary(
          calories: '420 kcal',
          protein: '18g',
          carbs: '22g',
          fat: '28g',
        ),
      );

      final event = MealCalendarEvent(
        id: 'cal_test_1',
        userId: 'user_123',
        eventDate: DateTime(2026, 8, 25),
        mealSlot: CalendarMealSlot.dinner,
        dishName: 'Paneer Butter Masala',
        recipe: recipe,
        servings: 2,
        isCooked: false,
        notes: 'Special dinner',
      );

      final json = event.toJson();
      expect(json['id'], 'cal_test_1');
      expect(json['user_id'], 'user_123');
      expect(json['meal_slot'], 'dinner');
      expect(json['dish_name'], 'Paneer Butter Masala');
      expect(json['servings'], 2);
      expect(json['is_cooked'], false);

      final reconstructed = MealCalendarEvent.fromJson(json);
      expect(reconstructed.id, event.id);
      expect(reconstructed.dishName, event.dishName);
      expect(reconstructed.mealSlot, CalendarMealSlot.dinner);
      expect(reconstructed.recipe?.dishName, 'Paneer Butter Masala');
      expect(reconstructed.recipe?.macros.protein, '18g');
    });

    test('CalendarMealSlot parses strings accurately', () {
      expect(CalendarMealSlot.fromString('breakfast'), CalendarMealSlot.breakfast);
      expect(CalendarMealSlot.fromString('lunch'), CalendarMealSlot.lunch);
      expect(CalendarMealSlot.fromString('snacks'), CalendarMealSlot.snacks);
      expect(CalendarMealSlot.fromString('dinner'), CalendarMealSlot.dinner);
      expect(CalendarMealSlot.fromString('unknown'), CalendarMealSlot.dinner);
    });
  });
}
