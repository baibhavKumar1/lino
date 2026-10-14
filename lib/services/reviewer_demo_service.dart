import '../models/pantry_item.dart';
import '../models/grocery_item.dart';
import '../models/meal_calendar_event.dart';
import '../services/openrouter/meal_recipe.dart';

class ReviewerDemoService {
  static const String reviewerUserId = 'user_play_reviewer';

  static List<PantryItem> getDemoPantry() {
    return [
      PantryItem(
        id: 'rev_p1',
        name: 'Fresh Paneer',
        category: ItemCategory.kitchenStaples,
        unit: 'g',
        quantity: 250,
        isLowStock: false,
      ),
      PantryItem(
        id: 'rev_p2',
        name: 'Basmati Rice',
        category: ItemCategory.riceGrains,
        unit: 'kg',
        quantity: 2,
        isLowStock: false,
      ),
      PantryItem(
        id: 'rev_p3',
        name: 'Toor Dal (Arhar Dal)',
        category: ItemCategory.pulsesLentils,
        unit: 'kg',
        quantity: 1,
        isLowStock: false,
      ),
      PantryItem(
        id: 'rev_p4',
        name: 'Fresh Spinach (Palak)',
        category: ItemCategory.freshProduce,
        unit: 'g',
        quantity: 300,
        isLowStock: false,
      ),
      PantryItem(
        id: 'rev_p5',
        name: 'Desi Ghee',
        category: ItemCategory.kitchenStaples,
        unit: 'g',
        quantity: 500,
        isLowStock: false,
      ),
      PantryItem(
        id: 'rev_p6',
        name: 'Jeera (Cumin Seeds)',
        category: ItemCategory.singleSpices,
        unit: 'g',
        quantity: 150,
        isLowStock: false,
      ),
      PantryItem(
        id: 'rev_p7',
        name: 'Red Onion',
        category: ItemCategory.freshProduce,
        unit: 'kg',
        quantity: 2,
        isLowStock: false,
      ),
      PantryItem(
        id: 'rev_p8',
        name: 'Garlic & Ginger',
        category: ItemCategory.freshProduce,
        unit: 'g',
        quantity: 150,
        isLowStock: false,
      ),
    ];
  }

  static List<MealCalendarEvent> getDemoEvents() {
    return [
      MealCalendarEvent(
        id: 'rev_event_dinner',
        userId: reviewerUserId,
        eventDate: DateTime.now(),
        mealSlot: CalendarMealSlot.dinner,
        dishName: 'Palak Paneer with Jeera Rice',
        servings: 2,
        isCooked: false,
        recipe: MealRecipe(
          dishName: 'Palak Paneer with Jeera Rice',
          prepTime: '20 mins',
          servings: '2 People',
          dietType: 'Veg',
          ingredientsWithQuantities: const [
            'Fresh Paneer 200g',
            'Fresh Spinach 250g',
            'Basmati Rice 1 cup',
            'Jeera 1 tsp',
            'Desi Ghee 2 tbsp',
            'Garlic & Ginger 1 tbsp',
          ],
          usedInventory: const [
            'Fresh Paneer',
            'Fresh Spinach',
            'Basmati Rice',
            'Jeera',
            'Desi Ghee',
            'Garlic & Ginger',
          ],
          missingItems: const [],
          substitutions: const [],
          cavemanSteps: const [
            'Blanch spinach leaves in hot water and blend into a smooth puree',
            'Heat ghee in a pan, crackle cumin seeds, and sauté minced ginger and garlic',
            'Pour in the vibrant spinach puree and simmer gently for 5 minutes',
            'Add soft paneer cubes, season lightly, and cook for another 3 minutes',
            'Serve piping hot alongside freshly steamed, aromatic jeera basmati rice',
          ],
          chefTip: 'Do not overcook spinach to maintain its natural green hue and fresh aroma.',
          macros: MealMacroSummary(
            calories: '380 kcal',
            protein: '18g',
            carbs: '42g',
            fat: '12g',
          ),
        ),
      ),
    ];
  }
}
