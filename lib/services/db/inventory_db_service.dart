import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import '../../models/grocery_item.dart';
import '../../models/pantry_item.dart';
import '../auth_service.dart';
import 'neon_connection.dart';

class InventoryDbService {
  static Future<bool> syncPantryToCloud(List<PantryItem> items, {String? userId}) async {
    try {
      await NeonConnection.ensureConnected();
      for (final item in items) {
        await upsertPantryItemInCloud(item, userId: userId);
      }
      return true;
    } catch (e) {
      debugPrint('[InventoryDbService] syncPantryToCloud error: $e');
      return false;
    }
  }

  static Future<bool> upsertPantryItemInCloud(PantryItem item, {String? userId}) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'INSERT INTO user_pantry (id, user_id, name, category, unit, quantity, is_low_stock, updated_at) '
          'VALUES (@id, @user_id, @name, @category, @unit, @qty, @low, CURRENT_TIMESTAMP) '
          'ON CONFLICT (id) DO UPDATE SET '
          'user_id = COALESCE(EXCLUDED.user_id, user_pantry.user_id), '
          'name = EXCLUDED.name, '
          'category = EXCLUDED.category, '
          'unit = EXCLUDED.unit, '
          'quantity = EXCLUDED.quantity, '
          'is_low_stock = EXCLUDED.is_low_stock, '
          'updated_at = CURRENT_TIMESTAMP;',
        ),
        parameters: {
          'id': item.id,
          'user_id': effectiveUserId,
          'name': item.name,
          'category': item.category.name,
          'unit': item.unit,
          'qty': item.quantity,
          'low': item.isLowStock,
        },
      );
      return true;
    });
    return res ?? false;
  }

  static Future<bool> deletePantryItemFromCloud(String id, {String? userId}) async {
    final res = await NeonConnection.runQuery((conn) async {
      if (userId != null && userId.isNotEmpty) {
        await conn.execute(
          Sql.named('DELETE FROM user_pantry WHERE id = @id AND user_id = @user_id;'),
          parameters: {'id': id, 'user_id': userId},
        );
      } else {
        await conn.execute(
          Sql.named('DELETE FROM user_pantry WHERE id = @id;'),
          parameters: {'id': id},
        );
      }
      return true;
    });
    return res ?? false;
  }

  static Future<List<PantryItem>> fetchPantryFromCloud({String? userId}) async {
    final res = await NeonConnection.runQuery((conn) async {
      final results = (userId != null && userId.isNotEmpty)
          ? await conn.execute(
              Sql.named(
                'SELECT id, name, category, unit, quantity, is_low_stock, updated_at '
                'FROM user_pantry WHERE user_id = @user_id '
                'ORDER BY updated_at DESC;',
              ),
              parameters: {'user_id': userId},
            ).timeout(const Duration(seconds: 6))
          : await conn.execute(
              'SELECT id, name, category, unit, quantity, is_low_stock, updated_at FROM user_pantry ORDER BY updated_at DESC;'
            ).timeout(const Duration(seconds: 6));

      if (results.isNotEmpty) {
        final List<PantryItem> items = [];
        for (final row in results) {
          final id = row[0] as String;
          final name = row[1] as String;
          final catName = row[2] as String? ?? 'kitchenStaples';
          final unit = row[3] as String? ?? 'kg';
          final qty = row[4] as int? ?? 1;
          final isLow = row[5] as bool? ?? false;
          final date = row[6] is DateTime ? row[6] as DateTime : DateTime.now();

          final category = ItemCategory.values.firstWhere(
            (c) => c.name == catName,
            orElse: () => ItemCategory.kitchenStaples,
          );

          items.add(PantryItem(
            id: id,
            name: name,
            category: category,
            unit: unit,
            quantity: qty,
            addedDate: date,
            isLowStock: isLow,
          ));
        }
        return items;
      }
      return <PantryItem>[];
    });
    return res ?? [];
  }

  static Future<bool> syncInventoryToCloud(List<GroceryItem> items, {String? userId}) async {
    String? effectiveUserId = userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final session = await AuthService.getActiveUserSession();
      effectiveUserId = session['id'];
    }

    final addedItems = items.where((i) => i.isAdded || i.quantity > 0).toList();

    final res = await NeonConnection.runQuery((conn) async {
      for (final item in addedItems) {
        await conn.execute(
          Sql.named(
            'INSERT INTO user_inventory (id, user_id, name_en, name_hi, category, selected_unit, quantity, is_added, is_checked, updated_at) '
            'VALUES (@id, @user_id, @name_en, @name_hi, @category, @unit, @qty, @is_added, @is_checked, CURRENT_TIMESTAMP) '
            'ON CONFLICT (id) DO UPDATE SET '
            'user_id = COALESCE(EXCLUDED.user_id, user_inventory.user_id), '
            'selected_unit = EXCLUDED.selected_unit, '
            'quantity = EXCLUDED.quantity, '
            'is_added = EXCLUDED.is_added, '
            'is_checked = EXCLUDED.is_checked, '
            'updated_at = CURRENT_TIMESTAMP;',
          ),
          parameters: {
            'id': item.id,
            'user_id': effectiveUserId,
            'name_en': item.nameEn,
            'name_hi': item.nameHi,
            'category': item.category.name,
            'unit': item.selectedUnit,
            'qty': item.quantity,
            'is_added': item.isAdded,
            'is_checked': item.isChecked,
          },
        );
      }
      return true;
    });
    return res ?? false;
  }

  // Legacy sequential 100+ query loop commented out for performance:
  // static Future<bool> seedGlobalInventoryIfEmpty(List<GroceryItem> defaultCatalog) async {
  //   for (final item in defaultCatalog) { await conn.execute(...); }
  // }

  static Future<bool> seedGlobalInventoryIfEmpty(List<GroceryItem> defaultCatalog) async {
    final res = await NeonConnection.runQuery((conn) async {
      // 1. Fast Check: If table is already seeded, exit in 0ms without running 150 inserts
      final checkRows = await conn.execute('SELECT 1 FROM global_inventory LIMIT 1;').timeout(const Duration(seconds: 4));
      if (checkRows.isNotEmpty) {
        return true;
      }

      // 2. Batched Seeding (Executed only once on initial fresh database setup)
      for (int i = 0; i < defaultCatalog.length; i += 40) {
        final chunk = defaultCatalog.sublist(i, (i + 40 > defaultCatalog.length) ? defaultCatalog.length : i + 40);
        final valuesClauses = <String>[];
        final Map<String, dynamic> params = {};

        for (int j = 0; j < chunk.length; j++) {
          final item = chunk[j];
          final suffix = '_${i}_$j';
          valuesClauses.add('(@id$suffix, @name_en$suffix, @name_hi$suffix, @category$suffix, @units$suffix, @unit$suffix, CURRENT_TIMESTAMP)');
          params['id$suffix'] = item.id;
          params['name_en$suffix'] = item.nameEn;
          params['name_hi$suffix'] = item.nameHi;
          params['category$suffix'] = item.category.name;
          params['units$suffix'] = item.availableUnits.join(',');
          params['unit$suffix'] = item.selectedUnit;
        }

        if (valuesClauses.isNotEmpty) {
          final sql = 'INSERT INTO global_inventory (id, name_en, name_hi, category, available_units, default_unit, created_at) '
              'VALUES ${valuesClauses.join(', ')} ON CONFLICT (id) DO NOTHING;';
          await conn.execute(Sql.named(sql), parameters: params);
        }
      }
      return true;
    });
    return res ?? false;
  }

  static Future<List<GroceryItem>> fetchGlobalInventory() async {
    final res = await NeonConnection.runQuery((conn) async {
      final rows = await conn.execute(
        'SELECT id, name_en, name_hi, category, available_units, default_unit FROM global_inventory ORDER BY category, name_en ASC;',
      );
      if (rows.isNotEmpty) {
        final List<GroceryItem> items = [];
        for (final row in rows) {
          final id = row[0] as String;
          final nameEn = row[1] as String;
          final nameHi = row[2] as String? ?? '';
          final categoryStr = row[3] as String? ?? 'kitchenStaples';
          final unitsCsv = row[4] as String? ?? 'piece';
          final defaultUnit = row[5] as String? ?? 'piece';

          ItemCategory cat = ItemCategory.kitchenStaples;
          for (final c in ItemCategory.values) {
            if (c.name == categoryStr) {
              cat = c;
              break;
            }
          }

          items.add(GroceryItem(
            id: id,
            nameEn: nameEn,
            nameHi: nameHi,
            category: cat,
            availableUnits: unitsCsv.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).toList(),
            selectedUnit: defaultUnit,
          ));
        }
        return items;
      }
      return <GroceryItem>[];
    });
    return res ?? [];
  }
}
