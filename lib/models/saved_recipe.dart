import '../services/openrouter_service.dart';

class SavedRecipe {
  final String id;
  final String dishName;
  final String prepTime;
  final String servings;
  final String dietType;
  final List<String> ingredientsWithQuantities;
  final List<String> usedInventory;
  final List<String> cavemanSteps;
  final String chefTip;
  final MealMacroSummary macros;
  final DateTime createdAt;

  SavedRecipe({
    required this.id,
    required this.dishName,
    required this.prepTime,
    required this.servings,
    required this.dietType,
    required this.ingredientsWithQuantities,
    required this.usedInventory,
    required this.cavemanSteps,
    required this.chefTip,
    required this.macros,
    required this.createdAt,
  });

  MealRecipe get toMealRecipe => MealRecipe(
    dishName: dishName,
    prepTime: prepTime,
    servings: servings,
    dietType: dietType,
    macros: macros,
    ingredientsWithQuantities: ingredientsWithQuantities,
    usedInventory: usedInventory,
    missingItems: const [],
    substitutions: const [],
    cavemanSteps: cavemanSteps,
    chefTip: chefTip,
  );

  MealRecipe get recipe => toMealRecipe;

  factory SavedRecipe.fromMealRecipe(MealRecipe recipe) {
    return SavedRecipe(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      dishName: recipe.dishName,
      prepTime: recipe.prepTime,
      servings: recipe.servings,
      dietType: recipe.dietType,
      ingredientsWithQuantities: recipe.ingredientsWithQuantities,
      usedInventory: recipe.usedInventory,
      cavemanSteps: recipe.cavemanSteps,
      chefTip: recipe.chefTip,
      macros: recipe.macros,
      createdAt: DateTime.now(),
    );
  }

  factory SavedRecipe.fromJson(Map<String, dynamic> json) {
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

    return SavedRecipe(
      id: json['id']?.toString() ?? 'rec_${DateTime.now().microsecondsSinceEpoch}',
      dishName: json['dishName']?.toString() ?? json['name']?.toString() ?? 'Kitchen Recipe',
      prepTime: json['prepTime']?.toString() ?? '15 Mins',
      servings: json['servings']?.toString() ?? '2 People',
      dietType: json['dietType']?.toString() ?? 'Veg',
      ingredientsWithQuantities: parseStringList(json['ingredientsWithQuantities'] ?? json['ingredients'] ?? json['usedInventory']),
      usedInventory: parseStringList(json['usedInventory']),
      cavemanSteps: parseStringList(json['cavemanSteps'] ?? json['steps']),
      chefTip: json['chefTip']?.toString() ?? 'Serve fresh.',
      macros: MealMacroSummary.fromJson(macrosMap),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dishName': dishName,
      'prepTime': prepTime,
      'servings': servings,
      'dietType': dietType,
      'ingredientsWithQuantities': ingredientsWithQuantities,
      'usedInventory': usedInventory,
      'cavemanSteps': cavemanSteps,
      'chefTip': chefTip,
      'macros': macros.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<SavedRecipe> getInitialRecipes() {
    return const [];
  }
}
