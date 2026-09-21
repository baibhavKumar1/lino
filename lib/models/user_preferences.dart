import 'package:flutter/material.dart';

/// Single source of truth for Dietary Preferences across UI, Cloud DB, and AI Prompt Engine
enum DietPreference {
  veg('Veg', 'Pure Vegetarian', '100% vegetarian dishes, lentils, paneer, and vegetables. Strictly excludes meat, fish, and eggs.'),
  eggetarian('Eggetarian', 'Egg & Vegetarian', 'Vegetarian food plus eggs (omelettes, egg curries, boiled eggs). Excludes meat and fish.'),
  nonVeg('Non-Veg', 'Non-Vegetarian', 'Full non-vegetarian recipes including chicken, mutton, fish, seafood, and eggs.'),
  jain('Jain', 'Jain (No Root Veg)', 'Strict Jain cuisine. Excludes meat, fish, eggs, onion, garlic, potato, and root vegetables.'),
  vegan('Vegan', 'Vegan & Plant-Based', '100% plant-based diet. Excludes meat, fish, eggs, dairy, milk, cheese, ghee, and honey.');

  final String key;
  final String label;
  final String description;

  const DietPreference(this.key, this.label, this.description);

  static DietPreference fromString(String? val) {
    if (val == null || val.trim().isEmpty) return DietPreference.veg;
    final lower = val.toLowerCase().trim();
    if (lower.contains('non-veg') || lower.contains('non veg') || lower.contains('meat') || lower.contains('chicken')) {
      return DietPreference.nonVeg;
    }
    if (lower.contains('egg') || lower.contains('anda')) {
      return DietPreference.eggetarian;
    }
    if (lower.contains('jain')) {
      return DietPreference.jain;
    }
    if (lower.contains('vegan') || lower.contains('plant')) {
      return DietPreference.vegan;
    }
    return DietPreference.veg;
  }
}

/// Single source of truth for Household Size options across Onboarding, Tune, and AI Scaling
enum HouseholdSizeOption {
  solo(1, 'Single / Solo', 'Cooking for 1 person'),
  couple(2, 'Couple (2 members)', 'Cooking for 2 people'),
  family(4, 'Family (3-4 members)', 'Cooking for 3-4 people'),
  largeFamily(6, 'Large Family (5+ members)', 'Cooking for 5+ people');

  final int count;
  final String label;
  final String subtitle;

  const HouseholdSizeOption(this.count, this.label, this.subtitle);

  String get servingLabel => count == 1 ? '1 Person' : '$count People';

  static HouseholdSizeOption fromCount(dynamic val) {
    final numVal = val is int ? val : (int.tryParse(val?.toString() ?? '2') ?? 2);
    if (numVal <= 1) return HouseholdSizeOption.solo;
    if (numVal == 2) return HouseholdSizeOption.couple;
    if (numVal <= 4) return HouseholdSizeOption.family;
    return HouseholdSizeOption.largeFamily;
  }

  static HouseholdSizeOption fromString(String? text) {
    if (text == null || text.trim().isEmpty) return HouseholdSizeOption.couple;
    final lower = text.toLowerCase().trim();
    if (lower.contains('single') || lower.contains('solo') || lower == '1' || lower.contains('1 person')) {
      return HouseholdSizeOption.solo;
    }
    if (lower.contains('couple') || lower == '2' || lower.contains('2 people') || lower.contains('2 members')) {
      return HouseholdSizeOption.couple;
    }
    if (lower.contains('3') || lower.contains('4') || lower.contains('family (3-4')) {
      return HouseholdSizeOption.family;
    }
    if (lower.contains('5') || lower.contains('large') || lower.contains('6') || lower.contains('5+')) {
      return HouseholdSizeOption.largeFamily;
    }
    return HouseholdSizeOption.couple;
  }
}

/// Standardized Kitchen Cookware & Appliances
enum KitchenAppliance {
  gasStove('Gas Stove', Icons.local_fire_department_rounded),
  kadai('Kadai / Pan', Icons.soup_kitchen_rounded),
  pressureCooker('Pressure Cooker', Icons.outdoor_grill_rounded),
  airFryer('Air Fryer', Icons.wind_power_rounded),
  microwave('Microwave', Icons.microwave_rounded),
  induction('Induction Cooktop', Icons.bolt_rounded),
  oven('Oven / OTG', Icons.kitchen_rounded);

  final String label;
  final IconData icon;

  const KitchenAppliance(this.label, this.icon);

  static List<KitchenAppliance> parseList(String? appliancesCsv) {
    if (appliancesCsv == null || appliancesCsv.trim().isEmpty) {
      return [KitchenAppliance.gasStove, KitchenAppliance.kadai];
    }
    final rawList = appliancesCsv.split(',').map((s) => s.trim().toLowerCase()).toList();
    final List<KitchenAppliance> result = [];
    for (final app in KitchenAppliance.values) {
      final nameLower = app.label.toLowerCase();
      if (rawList.any((r) => r.contains(nameLower) || nameLower.contains(r))) {
        result.add(app);
      }
    }
    return result.isEmpty ? [KitchenAppliance.gasStove, KitchenAppliance.kadai] : result;
  }

  static String toCsv(List<KitchenAppliance> list) {
    return list.map((a) => a.label).join(',');
  }
}

/// Standardized Delivery & Restock Horizon options
enum DeliveryHorizon {
  inPantry('0m', 'In-Pantry Only', '0 min restock. Must use only in-stock kitchen pantry items.', Icons.lock_outline_rounded),
  quick('15m', '10-15 Mins', 'Quick Commerce (Zepto, Blinkit). 1-2 minor missing fresh items allowed.', Icons.bolt_rounded),
  hyperlocal('45m', '30-45 Mins', 'Standard Hyperlocal Delivery. Standard ingredient restock allowed.', Icons.delivery_dining_rounded),
  flexible('flexible', 'Flexible', 'Ample time for delivery. Open to buying all recipe ingredients.', Icons.inventory_2_outlined);

  final String key;
  final String label;
  final String description;
  final IconData icon;

  const DeliveryHorizon(this.key, this.label, this.description, this.icon);

  static DeliveryHorizon fromKey(String? key) {
    if (key == null || key.trim().isEmpty) return DeliveryHorizon.quick;
    for (final d in DeliveryHorizon.values) {
      if (d.key == key || d.name == key) return d;
    }
    return DeliveryHorizon.quick;
  }
}

/// Meal Variety / Avoid Recents window
enum MealVarietyOption {
  off('off', 'Allow Repeats', 0, Icons.all_inclusive_rounded),
  lastWeek('week', 'Avoid Last 7 Days', 7, Icons.calendar_view_week_rounded),
  lastMonth('month', 'Avoid Last 30 Days', 30, Icons.calendar_month_rounded);

  final String key;
  final String label;
  final int days;
  final IconData icon;

  const MealVarietyOption(this.key, this.label, this.days, this.icon);

  static MealVarietyOption fromKey(String? key) {
    if (key == null || key.trim().isEmpty) return MealVarietyOption.lastWeek;
    for (final v in MealVarietyOption.values) {
      if (v.key == key || v.name == key) return v;
    }
    return MealVarietyOption.lastWeek;
  }
}


