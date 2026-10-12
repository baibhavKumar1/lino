import 'package:flutter_test/flutter_test.dart';
// import 'package:kichook/models/grocery_item.dart';
// import 'package:kichook/services/openrouter/chef_agent_service.dart';
import 'package:lino/models/grocery_item.dart';
import 'package:lino/services/openrouter/chef_agent_service.dart';

void main() {
  group('Lino Chef Agent Live Functional Evaluations (100% Free Models)', () {
    
    test('Guarantee: Zero-Restock In-Pantry Lock (missingItems == [])', () async {
      final inventory = [
        // GroceryItem(id: '1', nameEn: 'Fresh Spinach (Palak)', nameHi: 'पालक', categoryKey: 'freshProduce', isAdded: true, quantity: 1, selectedUnit: '250 g'),
        GroceryItem(id: '1', nameEn: 'Fresh Spinach (Palak)', nameHi: 'पालक', category: ItemCategory.freshProduce, availableUnits: const ['250 g'], isAdded: true, quantity: 1, selectedUnit: '250 g'),
        // GroceryItem(id: '2', nameEn: 'Fresh Bhindi (Ladyfinger)', nameHi: 'भिंडी', categoryKey: 'freshProduce', isAdded: true, quantity: 1, selectedUnit: '250 g'),
        GroceryItem(id: '2', nameEn: 'Fresh Bhindi (Ladyfinger)', nameHi: 'भिंडी', category: ItemCategory.freshProduce, availableUnits: const ['250 g'], isAdded: true, quantity: 1, selectedUnit: '250 g'),
        // GroceryItem(id: '3', nameEn: 'Paneer', nameHi: 'पनीर', categoryKey: 'kitchenStaples', isAdded: true, quantity: 1, selectedUnit: '200 g'),
        GroceryItem(id: '3', nameEn: 'Paneer', nameHi: 'पनीर', category: ItemCategory.kitchenStaples, availableUnits: const ['200 g'], isAdded: true, quantity: 1, selectedUnit: '200 g'),
        // GroceryItem(id: '4', nameEn: 'Green Capsicum', nameHi: 'शिमला मिर्च', categoryKey: 'freshProduce', isAdded: true, quantity: 2, selectedUnit: 'piece'),
        GroceryItem(id: '4', nameEn: 'Green Capsicum', nameHi: 'शिमला मिर्च', category: ItemCategory.freshProduce, availableUnits: const ['piece'], isAdded: true, quantity: 2, selectedUnit: 'piece'),
        // GroceryItem(id: '5', nameEn: 'Tomatoes', nameHi: 'टमाटर', categoryKey: 'freshProduce', isAdded: true, quantity: 3, selectedUnit: 'piece'),
        GroceryItem(id: '5', nameEn: 'Tomatoes', nameHi: 'टमाटर', category: ItemCategory.freshProduce, availableUnits: const ['piece'], isAdded: true, quantity: 3, selectedUnit: 'piece'),
        // GroceryItem(id: '6', nameEn: 'Basmati Rice', nameHi: 'चावल', categoryKey: 'riceGrains', isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        GroceryItem(id: '6', nameEn: 'Basmati Rice', nameHi: 'चावल', category: ItemCategory.riceGrains, availableUnits: const ['1 kg'], isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        // GroceryItem(id: '7', nameEn: 'Toor Dal', nameHi: 'तूर दाल', categoryKey: 'pulsesLentils', isAdded: true, quantity: 1, selectedUnit: '500 g'),
        GroceryItem(id: '7', nameEn: 'Toor Dal', nameHi: 'तूर दाल', category: ItemCategory.pulsesLentils, availableUnits: const ['500 g'], isAdded: true, quantity: 1, selectedUnit: '500 g'),
        // GroceryItem(id: '8', nameEn: 'Desi Ghee', nameHi: 'घी', categoryKey: 'kitchenStaples', isAdded: true, quantity: 1, selectedUnit: '500 ml'),
        GroceryItem(id: '8', nameEn: 'Desi Ghee', nameHi: 'घी', category: ItemCategory.kitchenStaples, availableUnits: const ['500 ml'], isAdded: true, quantity: 1, selectedUnit: '500 ml'),
        // GroceryItem(id: '9', nameEn: 'Cumin Seeds (Jeera)', nameHi: 'जीरा', categoryKey: 'singleSpices', isAdded: true, quantity: 1, selectedUnit: '100 g'),
        GroceryItem(id: '9', nameEn: 'Cumin Seeds (Jeera)', nameHi: 'जीरा', category: ItemCategory.singleSpices, availableUnits: const ['100 g'], isAdded: true, quantity: 1, selectedUnit: '100 g'),
        // GroceryItem(id: '10', nameEn: 'Salt', nameHi: 'नमक', categoryKey: 'kitchenStaples', isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        GroceryItem(id: '10', nameEn: 'Salt', nameHi: 'नमक', category: ItemCategory.kitchenStaples, availableUnits: const ['1 kg'], isAdded: true, quantity: 1, selectedUnit: '1 kg'),
      ];

      final recipes = await ChefAgentService.ideateMeals(
        inventory: inventory,
        mealTime: 'Lunch',
        maxCookTimeMinutes: 25,
        numPeople: 2,
        restockTimeMinutes: 0, // Strict In-Stock
        dietType: 'Veg',
        exclusions: [],
      );

      expect(recipes.isNotEmpty, isTrue, reason: 'Must return at least 1-3 recipes');
      for (final recipe in recipes) {
        expect(recipe.dishName.isNotEmpty, isTrue);
        expect(recipe.cavemanSteps.isNotEmpty, isTrue, reason: 'Must include cooking steps');
        expect(recipe.missingItems.isEmpty, isTrue, reason: 'Zero-restock lock violated: found missingItems ${recipe.missingItems}');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Guarantee: Universal Water and Ice are Never in missingItems', () async {
      final inventory = [
        // GroceryItem(id: '1', nameEn: 'Raw Rice', nameHi: 'चावल', categoryKey: 'riceGrains', isAdded: true, quantity: 1, selectedUnit: '500 g'),
        GroceryItem(id: '1', nameEn: 'Raw Rice', nameHi: 'चावल', category: ItemCategory.riceGrains, availableUnits: const ['500 g'], isAdded: true, quantity: 1, selectedUnit: '500 g'),
        // GroceryItem(id: '2', nameEn: 'Salt', nameHi: 'नमक', categoryKey: 'kitchenStaples', isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        GroceryItem(id: '2', nameEn: 'Salt', nameHi: 'नमक', category: ItemCategory.kitchenStaples, availableUnits: const ['1 kg'], isAdded: true, quantity: 1, selectedUnit: '1 kg'),
      ];

      final recipes = await ChefAgentService.ideateMeals(
        inventory: inventory,
        mealTime: 'Dinner',
        maxCookTimeMinutes: 20,
        numPeople: 2,
        restockTimeMinutes: 15,
        dietType: 'Veg',
        exclusions: [],
      );

      final forbidden = {'water', 'drinking water', 'tap water', 'ice', 'ice cubes'};
      for (final recipe in recipes) {
        for (final item in recipe.missingItems) {
          expect(forbidden.contains(item.toLowerCase().trim()), isFalse, 
            reason: 'Universal water lock violated: "$item" found in missingItems');
        }
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Guarantee: Chat Co-Pilot Mode A Ideation ("what can I cook?" -> recipes: [])', () async {
      final inventory = [
        // GroceryItem(id: '1', nameEn: 'Basmati Rice', nameHi: 'चावल', categoryKey: 'riceGrains', isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        GroceryItem(id: '1', nameEn: 'Basmati Rice', nameHi: 'चावल', category: ItemCategory.riceGrains, availableUnits: const ['1 kg'], isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        // GroceryItem(id: '2', nameEn: 'Desi Ghee', nameHi: 'घी', categoryKey: 'kitchenStaples', isAdded: true, quantity: 1, selectedUnit: '500 ml'),
        GroceryItem(id: '2', nameEn: 'Desi Ghee', nameHi: 'घी', category: ItemCategory.kitchenStaples, availableUnits: const ['500 ml'], isAdded: true, quantity: 1, selectedUnit: '500 ml'),
        // GroceryItem(id: '3', nameEn: 'Cumin Seeds (Jeera)', nameHi: 'जीरा', categoryKey: 'singleSpices', isAdded: true, quantity: 1, selectedUnit: '100 g'),
        GroceryItem(id: '3', nameEn: 'Cumin Seeds (Jeera)', nameHi: 'जीरा', category: ItemCategory.singleSpices, availableUnits: const ['100 g'], isAdded: true, quantity: 1, selectedUnit: '100 g'),
      ];

      final response = await ChefAgentService.chatWithChefAgent(
        conversationHistory: [],
        inventory: inventory,
        userProfile: {'dietPreference': 'Veg', 'householdSize': '2'},
        currentPrompt: 'What can I cook for dinner tonight with what I have?',
      );

      expect(response.recipes.isEmpty, isTrue, reason: 'Mode A must NOT dump recipe cards (recipes must be empty)');
      expect(response.content.length > 20, isTrue, reason: 'Must provide conversational ideas');
      expect(response.suggestions.length >= 2, isTrue, reason: 'Must provide interactive suggestion chips');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Guarantee: Chat Co-Pilot Mode B Explicit Recipe ("give recipe for X" -> exactly 1 recipe)', () async {
      final inventory = [
        // GroceryItem(id: '1', nameEn: 'Basmati Rice', nameHi: 'चावल', categoryKey: 'riceGrains', isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        GroceryItem(id: '1', nameEn: 'Basmati Rice', nameHi: 'चावल', category: ItemCategory.riceGrains, availableUnits: const ['1 kg'], isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        // GroceryItem(id: '2', nameEn: 'Desi Ghee', nameHi: 'घी', categoryKey: 'kitchenStaples', isAdded: true, quantity: 1, selectedUnit: '500 ml'),
        GroceryItem(id: '2', nameEn: 'Desi Ghee', nameHi: 'घी', category: ItemCategory.kitchenStaples, availableUnits: const ['500 ml'], isAdded: true, quantity: 1, selectedUnit: '500 ml'),
        // GroceryItem(id: '3', nameEn: 'Cumin Seeds (Jeera)', nameHi: 'जीरा', categoryKey: 'singleSpices', isAdded: true, quantity: 1, selectedUnit: '100 g'),
        GroceryItem(id: '3', nameEn: 'Cumin Seeds (Jeera)', nameHi: 'जीरा', category: ItemCategory.singleSpices, availableUnits: const ['100 g'], isAdded: true, quantity: 1, selectedUnit: '100 g'),
        // GroceryItem(id: '4', nameEn: 'Salt', nameHi: 'नमक', categoryKey: 'kitchenStaples', isAdded: true, quantity: 1, selectedUnit: '1 kg'),
        GroceryItem(id: '4', nameEn: 'Salt', nameHi: 'नमक', category: ItemCategory.kitchenStaples, availableUnits: const ['1 kg'], isAdded: true, quantity: 1, selectedUnit: '1 kg'),
      ];

      final response = await ChefAgentService.chatWithChefAgent(
        conversationHistory: [],
        inventory: inventory,
        userProfile: {'dietPreference': 'Veg', 'householdSize': '2'},
        currentPrompt: 'Please give me the full recipe for Jeera Rice.',
      );

      expect(response.recipes.length, equals(1), reason: 'Mode B must output exactly 1 structured recipe');
      final recipe = response.recipes.first;
      expect(recipe.dishName.toLowerCase().contains('rice'), isTrue);
      expect(recipe.cavemanSteps.isNotEmpty, isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
