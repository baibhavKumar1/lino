import 'dart:convert';
import '../services/openrouter_service.dart';

enum CalendarMealSlot {
  breakfast('Breakfast', '🌅'),
  lunch('Lunch', '☀️'),
  snacks('Snacks', '☕'),
  dinner('Dinner', '🌙');

  final String label;
  final String icon;
  const CalendarMealSlot(this.label, this.icon);

  static CalendarMealSlot fromString(String str) {
    return CalendarMealSlot.values.firstWhere(
      (s) => s.name.toLowerCase() == str.toLowerCase() || s.label.toLowerCase() == str.toLowerCase(),
      orElse: () => CalendarMealSlot.dinner,
    );
  }
}

class MealCalendarEvent {
  final String id;
  final String userId;
  final DateTime eventDate;
  final CalendarMealSlot mealSlot;
  final String dishName;
  final String? recipeId;
  final MealRecipe? recipe;
  final int servings;
  final bool isCooked;
  final String? notes;
  final DateTime createdAt;

  MealCalendarEvent({
    required this.id,
    required this.userId,
    required this.eventDate,
    required this.mealSlot,
    required this.dishName,
    this.recipeId,
    this.recipe,
    this.servings = 2,
    this.isCooked = false,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  MealCalendarEvent copyWith({
    String? id,
    String? userId,
    DateTime? eventDate,
    CalendarMealSlot? mealSlot,
    String? dishName,
    String? recipeId,
    MealRecipe? recipe,
    int? servings,
    bool? isCooked,
    String? notes,
    DateTime? createdAt,
  }) {
    return MealCalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventDate: eventDate ?? this.eventDate,
      mealSlot: mealSlot ?? this.mealSlot,
      dishName: dishName ?? this.dishName,
      recipeId: recipeId ?? this.recipeId,
      recipe: recipe ?? this.recipe,
      servings: servings ?? this.servings,
      isCooked: isCooked ?? this.isCooked,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_date': eventDate.toIso8601String().split('T').first,
      'meal_slot': mealSlot.name,
      'dish_name': dishName,
      'recipe_id': recipeId,
      'recipe_json': recipe != null ? jsonEncode(recipe!.toJson()) : null,
      'servings': servings,
      'is_cooked': isCooked,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MealCalendarEvent.fromJson(Map<String, dynamic> json) {
    MealRecipe? parsedRecipe;
    if (json['recipe_json'] != null && json['recipe_json'].toString().isNotEmpty) {
      try {
        final decoded = json['recipe_json'] is String
            ? jsonDecode(json['recipe_json'] as String)
            : json['recipe_json'];
        if (decoded is Map<String, dynamic>) {
          parsedRecipe = MealRecipe.fromJson(decoded);
        }
      } catch (_) {}
    } else if (json['recipe'] is Map<String, dynamic>) {
      parsedRecipe = MealRecipe.fromJson(json['recipe'] as Map<String, dynamic>);
    }

    DateTime parsedDate;
    if (json['event_date'] is DateTime) {
      parsedDate = json['event_date'] as DateTime;
    } else if (json['event_date'] is String) {
      parsedDate = DateTime.tryParse(json['event_date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return MealCalendarEvent(
      id: json['id'] as String? ?? 'event_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? 'user_lino_primary',
      eventDate: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      mealSlot: CalendarMealSlot.fromString(json['meal_slot'] as String? ?? 'dinner'),
      dishName: json['dish_name'] as String? ?? 'Planned Meal',
      recipeId: json['recipe_id'] as String?,
      recipe: parsedRecipe,
      servings: (json['servings'] as num?)?.toInt() ?? 2,
      isCooked: json['is_cooked'] == true || json['is_cooked'] == 1,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
