import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../../models/chat_message.dart';
import '../openrouter/meal_recipe.dart';
import '../auth_service.dart';
import 'neon_connection.dart';

class ChatHistoryDbService {
  static Future<bool> saveChatMessage(ChatMessage message, {String? userId}) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final recipeJson = message.recipes.isNotEmpty
        ? jsonEncode(message.recipes.map((r) => r.toJson()).toList())
        : null;
    final suggestionsJson = message.suggestions.isNotEmpty
        ? jsonEncode(message.suggestions)
        : null;

    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'INSERT INTO chat_messages (id, user_id, role, content, recipe_json, suggestions_json, created_at) '
          'VALUES (@id, @user_id, @role, @content, @recipe_json, @suggestions_json, @created_at) '
          'ON CONFLICT (id) DO NOTHING;',
        ),
        parameters: {
          'id': message.id,
          'user_id': effectiveUserId,
          'role': message.role.role,
          'content': message.content,
          'recipe_json': recipeJson,
          'suggestions_json': suggestionsJson,
          'created_at': message.createdAt,
        },
      );
      return true;
    });
    return res ?? false;
  }

  static Future<List<ChatMessage>> fetchChatHistory({String? userId, int limit = 40}) async {
    final res = await NeonConnection.runQuery((conn) async {
      final results = (userId != null && userId.isNotEmpty)
          ? await conn.execute(
              Sql.named(
                'SELECT id, role, content, recipe_json, suggestions_json, created_at '
                'FROM chat_messages WHERE user_id = @user_id '
                'ORDER BY created_at ASC LIMIT @limit;',
              ),
              parameters: {'user_id': userId, 'limit': limit},
            ).timeout(const Duration(seconds: 12))
          : await conn.execute(
              'SELECT id, role, content, recipe_json, suggestions_json, created_at FROM chat_messages ORDER BY created_at ASC LIMIT $limit;'
            ).timeout(const Duration(seconds: 12));

      if (results.isNotEmpty) {
        final List<ChatMessage> list = [];
        for (final row in results) {
          final id = row[0] as String;
          final roleStr = row[1] as String? ?? 'assistant';
          final content = row[2] as String? ?? '';
          final recipeJsonStr = row[3] as String?;
          final suggestionsJsonStr = row[4] as String?;
          final createdAt = row[5] is DateTime ? row[5] as DateTime : DateTime.now();

          List<MealRecipe> recipes = [];
          if (recipeJsonStr != null && recipeJsonStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(recipeJsonStr);
              if (decoded is List) {
                for (final r in decoded) {
                  if (r is Map) {
                    recipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(r)));
                  }
                }
              } else if (decoded is Map) {
                recipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(decoded)));
              }
            } catch (_) {}
          }

          List<String> suggestions = [];
          if (suggestionsJsonStr != null && suggestionsJsonStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(suggestionsJsonStr);
              if (decoded is List) {
                suggestions = List<String>.from(decoded);
              }
            } catch (_) {}
          }

          // Auto-healing for historical rows where JSON was stored in content
          String finalContent = content;
          if (recipes.isEmpty && content.contains('{') && content.contains('}')) {
            try {
              final firstBrace = content.indexOf('{');
              final lastBrace = content.lastIndexOf('}');
              if (firstBrace != -1 && lastBrace > firstBrace) {
                final jsonSnippet = content.substring(firstBrace, lastBrace + 1);
                final decoded = jsonDecode(jsonSnippet);
                if (decoded is Map) {
                  final decodedMap = Map<String, dynamic>.from(decoded);
                  if (decodedMap['recipes'] is List) {
                    for (final r in decodedMap['recipes'] as List) {
                      if (r is Map) {
                        recipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(r)));
                      }
                    }
                  } else if (decodedMap['dishName'] != null) {
                    recipes.add(MealRecipe.fromJson(decodedMap));
                  }

                  if (suggestions.isEmpty && decodedMap['suggestions'] is List) {
                    suggestions = (decodedMap['suggestions'] as List)
                        .map((s) => s.toString().trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                  }

                  final cleanMessage = decodedMap['message']?.toString().trim();
                  if (cleanMessage != null && cleanMessage.isNotEmpty) {
                    finalContent = cleanMessage;
                  } else if (firstBrace > 0) {
                    finalContent = content.substring(0, firstBrace).trim();
                  }

                  if (recipes.isNotEmpty) {
                    conn.execute(
                      Sql.named('UPDATE chat_messages SET content = @c, recipe_json = @rj, suggestions_json = @sj WHERE id = @id;'),
                      parameters: {
                        'id': id,
                        'c': finalContent,
                        'rj': jsonEncode(recipes.map((r) => r.toJson()).toList()),
                        'sj': jsonEncode(suggestions),
                      },
                    );
                  }
                }
              }
            } catch (_) {}
          }

          if (recipes.isEmpty && content.contains('[') && content.contains(']')) {
            try {
              final firstBracket = content.indexOf('[');
              final lastBracket = content.lastIndexOf(']');
              if (firstBracket != -1 && lastBracket > firstBracket) {
                final jsonSnippet = content.substring(firstBracket, lastBracket + 1);
                final decoded = jsonDecode(jsonSnippet);
                if (decoded is List) {
                  for (final r in decoded) {
                    if (r is Map && (r['dishName'] != null || r['name'] != null)) {
                      recipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(r)));
                    }
                  }
                  if (recipes.isNotEmpty && (finalContent.startsWith('[') || finalContent.contains(jsonSnippet))) {
                    finalContent = 'Here are your chef recommendations:';
                  }
                }
              }
            } catch (_) {}
          }

          final role = MessageRole.values.firstWhere(
            (r) => r.role == roleStr,
            orElse: () => MessageRole.assistant,
          );

          list.add(ChatMessage(
            id: id,
            role: role,
            content: finalContent,
            recipes: recipes,
            suggestions: suggestions,
            createdAt: createdAt,
          ));
        }
        return list;
      }
      return <ChatMessage>[];
    });
    return res ?? [];
  }

  static Future<bool> clearChatHistory({String? userId}) async {
    final res = await NeonConnection.runQuery((conn) async {
      if (userId != null && userId.isNotEmpty) {
        await conn.execute(
          Sql.named('DELETE FROM chat_messages WHERE user_id = @user_id;'),
          parameters: {'user_id': userId},
        );
      } else {
        await conn.execute('DELETE FROM chat_messages;');
      }
      return true;
    });
    return res ?? false;
  }

  static Future<List<String>> fetchRecentlyCookedDishes({
    int days = 30,
    String? userId,
  }) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final startDate = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T').first;

    final res = await NeonConnection.runQuery((conn) async {
      final results = (effectiveUserId != null && effectiveUserId.isNotEmpty)
          ? await conn.execute(
              Sql.named(
                'SELECT DISTINCT dish_name '
                'FROM meal_calendar_events '
                'WHERE user_id = @user_id AND event_date >= @start::date '
                'ORDER BY dish_name ASC;',
              ),
              parameters: {'user_id': effectiveUserId, 'start': startDate},
            ).timeout(const Duration(seconds: 6))
          : await conn.execute(
              Sql.named(
                'SELECT DISTINCT dish_name '
                'FROM meal_calendar_events '
                'WHERE event_date >= @start::date '
                'ORDER BY dish_name ASC;',
              ),
              parameters: {'start': startDate},
            ).timeout(const Duration(seconds: 6));

      if (results.isNotEmpty) {
        return results.map((row) => row[0].toString().trim()).where((name) => name.isNotEmpty).toList();
      }
      return <String>[];
    });

    return res ?? <String>[];
  }

  static Future<bool> recordCookedDish({
    required String dishName,
    String? recipeId,
    String? userId,
  }) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'] ?? 'user_kichook_primary';
    }

    final today = DateTime.now().toIso8601String().split('T').first;
    final eventId = 'cooked_${DateTime.now().microsecondsSinceEpoch}';

    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'INSERT INTO meal_calendar_events (id, user_id, event_date, meal_slot, dish_name, recipe_id, is_cooked, updated_at) '
          'VALUES (@id, @user_id, @event_date::date, @meal_slot, @dish_name, @recipe_id, true, CURRENT_TIMESTAMP);',
        ),
        parameters: {
          'id': eventId,
          'user_id': effectiveUserId,
          'event_date': today,
          'meal_slot': 'Any',
          'dish_name': dishName,
          'recipe_id': recipeId ?? dishName,
        },
      );
      return true;
    });
    return res ?? false;
  }
}
