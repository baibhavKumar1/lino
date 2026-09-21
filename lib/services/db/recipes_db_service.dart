import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../../models/saved_recipe.dart';
import '../../models/grocery_item.dart';
import '../auth_service.dart';
import 'neon_connection.dart';

class RecipesDbService {
  static Future<bool> syncTemplateToCloud(SavedListTemplate template, {String? userId}) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final itemsJson = jsonEncode(
      template.items.map((i) => {
        'id': i.id,
        'nameEn': i.nameEn,
        'nameHi': i.nameHi,
        'category': i.category.name,
        'selectedUnit': i.selectedUnit,
        'quantity': i.quantity,
      }).toList(),
    );

    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'INSERT INTO saved_templates (id, user_id, name, items_json, created_at) '
          'VALUES (@id, @user_id, @name, @items, CURRENT_TIMESTAMP) '
          'ON CONFLICT (id) DO NOTHING;',
        ),
        parameters: {
          'id': template.id,
          'user_id': effectiveUserId,
          'name': template.name,
          'items': itemsJson,
        },
      );
      return true;
    });
    return res ?? false;
  }

  static Future<bool> syncSavedRecipeToCloud(SavedRecipe recipe, {String? userId}) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final recipeJson = jsonEncode(recipe.toJson());

    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'INSERT INTO saved_recipes (id, user_id, dish_name, prep_time, recipe_json, created_at) '
          'VALUES (@id, @user_id, @dish_name, @prep_time, @json, CURRENT_TIMESTAMP) '
          'ON CONFLICT (id) DO UPDATE SET '
          'user_id = COALESCE(EXCLUDED.user_id, saved_recipes.user_id), '
          'recipe_json = EXCLUDED.recipe_json;',
        ),
        parameters: {
          'id': recipe.id,
          'user_id': effectiveUserId,
          'dish_name': recipe.dishName,
          'prep_time': recipe.prepTime,
          'json': recipeJson,
        },
      );
      return true;
    });
    return res ?? false;
  }

  static Future<bool> deleteSavedRecipeFromCloud(String recipeId, {String? userId}) async {
    final res = await NeonConnection.runQuery((conn) async {
      if (userId != null && userId.isNotEmpty) {
        await conn.execute(
          Sql.named('DELETE FROM saved_recipes WHERE id = @id AND user_id = @user_id;'),
          parameters: {'id': recipeId, 'user_id': userId},
        );
      } else {
        await conn.execute(
          Sql.named('DELETE FROM saved_recipes WHERE id = @id;'),
          parameters: {'id': recipeId},
        );
      }
      return true;
    });
    return res ?? false;
  }

  static Future<List<SavedRecipe>> fetchSavedRecipesFromCloud({String? userId}) async {
    final res = await NeonConnection.runQuery((conn) async {
      final results = (userId != null && userId.isNotEmpty)
          ? await conn.execute(
              Sql.named(
                'SELECT recipe_json FROM saved_recipes WHERE user_id = @user_id ORDER BY created_at DESC;',
              ),
              parameters: {'user_id': userId},
            ).timeout(const Duration(seconds: 4))
          : await conn.execute(
              'SELECT recipe_json FROM saved_recipes ORDER BY created_at DESC;'
            ).timeout(const Duration(seconds: 4));

      if (results.isNotEmpty) {
        final List<SavedRecipe> cloudRecipes = [];
        for (final row in results) {
          final jsonStr = row[0] as String?;
          if (jsonStr != null) {
            final jsonMap = jsonDecode(jsonStr);
            cloudRecipes.add(SavedRecipe.fromJson(jsonMap));
          }
        }
        return cloudRecipes;
      }
      return <SavedRecipe>[];
    });
    return res ?? [];
  }
}
