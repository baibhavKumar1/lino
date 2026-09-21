import '../ingredient_sanitizer.dart';

class MealMacroSummary {
  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  MealMacroSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MealMacroSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MealMacroSummary(
        calories: '350 kcal',
        protein: '18g',
        carbs: '42g',
        fat: '10g',
      );
    }

    String formatMacro(dynamic val, String fallback, String suffix) {
      if (val == null) return fallback;
      final str = val.toString().trim();
      if (str.isEmpty) return fallback;
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(str)) {
        return '$str$suffix';
      }
      return str;
    }

    return MealMacroSummary(
      calories: formatMacro(json['calories'], '350 kcal', ' kcal'),
      protein: formatMacro(json['protein'], '18g', 'g'),
      carbs: formatMacro(json['carbs'], '42g', 'g'),
      fat: formatMacro(json['fat'], '10g', 'g'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class MealRecipe {
  final String dishName;
  final String prepTime;
  final String servings;
  final String dietType;
  final List<String> ingredientsWithQuantities;
  final List<String> usedInventory;
  final List<String> missingItems;
  final List<String> substitutions;
  final List<String> cavemanSteps;
  final String chefTip;
  final MealMacroSummary macros;

  MealRecipe({
    required this.dishName,
    required this.prepTime,
    required this.servings,
    required this.dietType,
    required this.ingredientsWithQuantities,
    required this.usedInventory,
    required this.missingItems,
    required this.substitutions,
    required this.cavemanSteps,
    required this.chefTip,
    required this.macros,
  });

  factory MealRecipe.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      } else if (val is String && val.trim().isNotEmpty) {
        return [val.trim()];
      }
      return [];
    }

    final rawMacros = json['macros'];
    final macrosMap = (rawMacros is Map) ? Map<String, dynamic>.from(rawMacros) : null;

    final dish = json['dishName']?.toString() ?? json['name']?.toString() ?? 'Quick Kitchen Specialty';
    final time = json['prepTime']?.toString() ?? json['time']?.toString() ?? '15 Mins';
    final serv = json['servings']?.toString() ?? '2 People';
    final diet = json['dietType']?.toString() ?? 'Veg';
    final tip = json['chefTip']?.toString() ?? json['tip']?.toString() ?? 'Garnish with fresh herbs before serving.';

    final rawUsed = parseStringList(json['usedInventory'] ?? json['used_inventory']);
    final cleanUsed = rawUsed
        .map((item) => IngredientSanitizer.cleanIngredientName(item))
        .where((item) => item.isNotEmpty && !IngredientSanitizer.isUniversalFreeItem(item))
        .toSet()
        .toList();

    final rawMissing = parseStringList(json['missingItems'] ?? json['missing_items'] ?? json['missing']);
    final cleanMissing = rawMissing
        .map((item) => IngredientSanitizer.cleanIngredientName(item))
        .where((item) => item.isNotEmpty && !IngredientSanitizer.isUniversalFreeItem(item))
        .toSet()
        .toList();

    return MealRecipe(
      dishName: dish,
      prepTime: time,
      servings: serv,
      dietType: diet,
      ingredientsWithQuantities: parseStringList(json['ingredientsWithQuantities'] ?? json['ingredients'] ?? json['usedInventory']),
      usedInventory: cleanUsed.isNotEmpty ? cleanUsed : rawUsed,
      missingItems: cleanMissing,
      substitutions: parseStringList(json['substitutions']),
      cavemanSteps: parseStringList(json['cavemanSteps'] ?? json['steps'] ?? json['instructions']),
      chefTip: tip,
      macros: MealMacroSummary.fromJson(macrosMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dishName': dishName,
      'prepTime': prepTime,
      'servings': servings,
      'dietType': dietType,
      'ingredientsWithQuantities': ingredientsWithQuantities,
      'usedInventory': usedInventory,
      'missingItems': missingItems,
      'substitutions': substitutions,
      'cavemanSteps': cavemanSteps,
      'chefTip': chefTip,
      'macros': macros.toJson(),
    };
  }
}
