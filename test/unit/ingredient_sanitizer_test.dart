import 'package:flutter_test/flutter_test.dart';
import 'package:kichook/models/grocery_item.dart';
import 'package:kichook/services/ingredient_sanitizer.dart';

void main() {
  group('IngredientSanitizer Tests', () {
    test('cleans quantities, fractions, units and cooking prep verbs', () {
      expect(IngredientSanitizer.cleanIngredientName('2 tbsp Fresh Coriander Leaves (finely chopped)'), 'Coriander Leaves');
      expect(IngredientSanitizer.cleanIngredientName('200g Fresh Paneer (cubed)'), 'Paneer');
      expect(IngredientSanitizer.cleanIngredientName('1/2 tsp Turmeric Powder (Haldi)'), 'Turmeric Powder');
      expect(IngredientSanitizer.cleanIngredientName('2 Green Chillies (slit lengthwise)'), 'Green Chillies');
      expect(IngredientSanitizer.cleanIngredientName('1 cup Basmati Rice'), 'Basmati Rice');
      expect(IngredientSanitizer.cleanIngredientName('2 tbsp Desi Ghee for tempering'), 'Desi Ghee');
      expect(IngredientSanitizer.cleanIngredientName('1 Onion (sliced)'), 'Onion');
      expect(IngredientSanitizer.cleanIngredientName('Salt to taste'), 'Salt');
    });

    test('detects universal free household essentials', () {
      expect(IngredientSanitizer.isUniversalFreeItem('water'), isTrue);
      expect(IngredientSanitizer.isUniversalFreeItem('Tap Water'), isTrue);
      expect(IngredientSanitizer.isUniversalFreeItem('Drinking Water'), isTrue);
      expect(IngredientSanitizer.isUniversalFreeItem('Ice'), isTrue);
      expect(IngredientSanitizer.isUniversalFreeItem('Warm Water'), isTrue);
      expect(IngredientSanitizer.isUniversalFreeItem('Paneer'), isFalse);
      expect(IngredientSanitizer.isUniversalFreeItem('Coriander'), isFalse);
    });

    test('matches raw recipe missing strings to existing catalog items', () {
      final catalog = [
        GroceryItem(
          id: 'item_1',
          nameEn: 'Fresh Coriander (Dhaniya)',
          nameHi: 'धनिया',
          category: ItemCategory.freshProduce,
          availableUnits: ['1 Bunch'],
          selectedUnit: '1 Bunch',
        ),
        GroceryItem(
          id: 'item_2',
          nameEn: 'Fresh Malai Paneer 200g',
          nameHi: 'पनीर',
          category: ItemCategory.kitchenStaples,
          availableUnits: ['200 g'],
          selectedUnit: '200 g',
        ),
        GroceryItem(
          id: 'item_3',
          nameEn: 'Turmeric Powder (Haldi)',
          nameHi: 'हल्दी पाउडर',
          category: ItemCategory.singleSpices,
          availableUnits: ['100 g', '200 g'],
          selectedUnit: '100 g',
        ),
      ];

      // Missing string from recipe: "2 tbsp Fresh Coriander Leaves (finely chopped)"
      final match1 = IngredientSanitizer.findMatchingItemIndex('2 tbsp Fresh Coriander Leaves (finely chopped)', catalog);
      expect(match1, 0); // Matches Fresh Coriander

      // Missing string from recipe: "200g Paneer (cubed)"
      final match2 = IngredientSanitizer.findMatchingItemIndex('200g Paneer (cubed)', catalog);
      expect(match2, 1); // Matches Fresh Malai Paneer

      // Missing string from recipe: "1/2 tsp Haldi"
      final match3 = IngredientSanitizer.findMatchingItemIndex('1/2 tsp Haldi', catalog);
      expect(match3, 2); // Matches Turmeric Powder (Haldi)
    });
  });
}
