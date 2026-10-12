import 'package:flutter_test/flutter_test.dart';
// import 'package:kichook/models/user_preferences.dart';
import 'package:lino/models/user_preferences.dart';

void main() {
  group('UserPreferences Domain Tests', () {
    test('DietPreference parses all variations correctly', () {
      expect(DietPreference.fromString('Veg'), DietPreference.veg);
      expect(DietPreference.fromString('Pure Vegetarian'), DietPreference.veg);
      expect(DietPreference.fromString('North Indian / General'), DietPreference.veg);
      expect(DietPreference.fromString('Egg & Vegetarian'), DietPreference.eggetarian);
      expect(DietPreference.fromString('Eggetarian'), DietPreference.eggetarian);
      expect(DietPreference.fromString('Non-Vegetarian'), DietPreference.nonVeg);
      expect(DietPreference.fromString('Non-Veg'), DietPreference.nonVeg);
      expect(DietPreference.fromString('Jain (No Root Veg)'), DietPreference.jain);
      expect(DietPreference.fromString('Jain'), DietPreference.jain);
      expect(DietPreference.fromString('Vegan & Plant-Based'), DietPreference.vegan);
      expect(DietPreference.fromString('Vegan'), DietPreference.vegan);
    });

    test('HouseholdSizeOption parses all string options and counts accurately', () {
      expect(HouseholdSizeOption.fromString('Single / Solo'), HouseholdSizeOption.solo);
      expect(HouseholdSizeOption.fromString('1'), HouseholdSizeOption.solo);
      expect(HouseholdSizeOption.fromString('Couple (2 members)'), HouseholdSizeOption.couple);
      expect(HouseholdSizeOption.fromString('2'), HouseholdSizeOption.couple);
      expect(HouseholdSizeOption.fromString('Family (3-4 members)'), HouseholdSizeOption.family);
      expect(HouseholdSizeOption.fromString('4'), HouseholdSizeOption.family);
      expect(HouseholdSizeOption.fromString('Large Family (5+ members)'), HouseholdSizeOption.largeFamily);
      expect(HouseholdSizeOption.fromString('6'), HouseholdSizeOption.largeFamily);

      expect(HouseholdSizeOption.solo.count, 1);
      expect(HouseholdSizeOption.solo.servingLabel, '1 Person');
      expect(HouseholdSizeOption.couple.count, 2);
      expect(HouseholdSizeOption.couple.servingLabel, '2 People');
      expect(HouseholdSizeOption.family.count, 4);
      expect(HouseholdSizeOption.family.servingLabel, '4 People');
    });

    test('KitchenAppliance parses comma-separated lists and converts to CSV', () {
      final list = KitchenAppliance.parseList('Gas Stove,Kadai / Pan,Air Fryer');
      expect(list.contains(KitchenAppliance.gasStove), isTrue);
      expect(list.contains(KitchenAppliance.kadai), isTrue);
      expect(list.contains(KitchenAppliance.airFryer), isTrue);
      expect(list.contains(KitchenAppliance.oven), isFalse);

      final csv = KitchenAppliance.toCsv(list);
      expect(csv, 'Gas Stove,Kadai / Pan,Air Fryer');
    });
  });
}
