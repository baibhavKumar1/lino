import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../../models/meal_calendar_event.dart';
import '../openrouter/meal_recipe.dart';
import '../auth_service.dart';
import 'neon_connection.dart';

class MealCalendarDbService {
  static Future<bool> syncMealEventToCloud(MealCalendarEvent event, {String? userId}) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final dateStr = event.eventDate.toIso8601String().split('T').first;
    final recipeJson = event.recipe != null ? jsonEncode(event.recipe!.toJson()) : null;

    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'INSERT INTO meal_calendar_events '
          '(id, user_id, event_date, meal_slot, dish_name, recipe_id, recipe_json, servings, is_cooked, notes, updated_at) '
          'VALUES (@id, @user_id, @event_date::date, @meal_slot, @dish_name, @recipe_id, @recipe_json, @servings, @is_cooked, @notes, CURRENT_TIMESTAMP) '
          'ON CONFLICT (id) DO UPDATE SET '
          'user_id = COALESCE(EXCLUDED.user_id, meal_calendar_events.user_id), '
          'event_date = EXCLUDED.event_date, '
          'meal_slot = EXCLUDED.meal_slot, '
          'dish_name = EXCLUDED.dish_name, '
          'recipe_id = EXCLUDED.recipe_id, '
          'recipe_json = EXCLUDED.recipe_json, '
          'servings = EXCLUDED.servings, '
          'is_cooked = EXCLUDED.is_cooked, '
          'notes = EXCLUDED.notes, '
          'updated_at = CURRENT_TIMESTAMP;',
        ),
        parameters: {
          'id': event.id,
          'user_id': effectiveUserId,
          'event_date': dateStr,
          'meal_slot': event.mealSlot.name,
          'dish_name': event.dishName,
          'recipe_id': event.recipeId,
          'recipe_json': recipeJson,
          'servings': event.servings,
          'is_cooked': event.isCooked,
          'notes': event.notes,
        },
      );
      return true;
    });
    return res ?? false;
  }

  static Future<bool> deleteMealEventFromCloud(String eventId, {String? userId}) async {
    final res = await NeonConnection.runQuery((conn) async {
      if (userId != null && userId.isNotEmpty) {
        await conn.execute(
          Sql.named('DELETE FROM meal_calendar_events WHERE id = @id AND user_id = @user_id;'),
          parameters: {'id': eventId, 'user_id': userId},
        );
      } else {
        await conn.execute(
          Sql.named('DELETE FROM meal_calendar_events WHERE id = @id;'),
          parameters: {'id': eventId},
        );
      }
      return true;
    });
    return res ?? false;
  }

  static Future<bool> markMealEventAsCooked(String eventId, bool isCooked, {String? userId}) async {
    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named('UPDATE meal_calendar_events SET is_cooked = @cooked, updated_at = CURRENT_TIMESTAMP WHERE id = @id;'),
        parameters: {'id': eventId, 'cooked': isCooked},
      );
      return true;
    });
    return res ?? false;
  }

  static Future<List<MealCalendarEvent>> fetchMealCalendarEvents({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final start = (startDate ?? DateTime.now().subtract(const Duration(days: 7))).toIso8601String().split('T').first;
    final end = (endDate ?? DateTime.now().add(const Duration(days: 21))).toIso8601String().split('T').first;

    final res = await NeonConnection.runQuery((conn) async {
      final results = (effectiveUserId != null && effectiveUserId.isNotEmpty)
          ? await conn.execute(
              Sql.named(
                'SELECT id, user_id, event_date, meal_slot, dish_name, recipe_id, recipe_json, servings, is_cooked, notes, created_at '
                'FROM meal_calendar_events '
                'WHERE user_id = @user_id AND event_date >= @start::date AND event_date <= @end::date '
                'ORDER BY event_date ASC, created_at ASC;',
              ),
              parameters: {'user_id': effectiveUserId, 'start': start, 'end': end},
            ).timeout(const Duration(seconds: 6))
          : await conn.execute(
              Sql.named(
                'SELECT id, user_id, event_date, meal_slot, dish_name, recipe_id, recipe_json, servings, is_cooked, notes, created_at '
                'FROM meal_calendar_events '
                'WHERE event_date >= @start::date AND event_date <= @end::date '
                'ORDER BY event_date ASC, created_at ASC;',
              ),
              parameters: {'start': start, 'end': end},
            ).timeout(const Duration(seconds: 6));

      if (results.isNotEmpty) {
        final List<MealCalendarEvent> list = [];
        for (final row in results) {
          list.add(MealCalendarEvent(
            id: row[0] as String,
            // PREVIOUS DEFAULT USER ID: user_kichook_primary
            userId: row[1] as String? ?? 'user_lino_primary',
            eventDate: row[2] is DateTime ? row[2] as DateTime : DateTime.parse(row[2].toString()),
            mealSlot: CalendarMealSlot.fromString(row[3] as String? ?? 'dinner'),
            dishName: row[4] as String? ?? 'Planned Meal',
            recipeId: row[5] as String?,
            recipe: (row[6] != null && row[6].toString().isNotEmpty)
                ? MealRecipe.fromJson(jsonDecode(row[6].toString()) as Map<String, dynamic>)
                : null,
            servings: (row[7] as num?)?.toInt() ?? 2,
            isCooked: row[8] == true,
            notes: row[9] as String?,
            createdAt: row[10] is DateTime ? row[10] as DateTime : DateTime.now(),
          ));
        }
        return list;
      }
      return <MealCalendarEvent>[];
    });
    return res ?? [];
  }
}
