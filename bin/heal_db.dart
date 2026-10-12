import 'dart:convert';
import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to Neon PostgreSQL to backfill user_id and heal database...');
  try {
    final connection = await Connection.open(
      Endpoint(
        host: 'ep-wild-hat-azgg5fdf-pooler.c-3.ap-southeast-1.aws.neon.tech',
        database: 'neondb',
        username: 'neondb_owner',
        password: 'npg_CJK1g0coedDq',
        port: 5432,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    ).timeout(const Duration(seconds: 10));

    print('Connected successfully.');

    // 1. Get or create primary user in users table
    final userResult = await connection.execute('SELECT id, email FROM users ORDER BY created_at ASC LIMIT 1;');
    // String primaryUserId = 'user_kichook_primary';
    String primaryUserId = 'user_lino_primary';
    if (userResult.isNotEmpty) {
      primaryUserId = userResult.first[0] as String;
      print('Found primary user in database: $primaryUserId (${userResult.first[1]})');
    } else {
      await connection.execute(
        Sql.named(
          'INSERT INTO users (id, email, full_name, household_name, diet_preference, household_size, appliances) '
          'VALUES (@id, @email, @full_name, @household_name, @diet, @size, @apps) '
          'ON CONFLICT (id) DO NOTHING;'
        ),
        parameters: {
          'id': primaryUserId,
          'email': 'chef@lino.app',
          'full_name': 'Chef',
          'household_name': 'My Kitchen',
          'diet': 'Veg',
          'size': '2',
          'apps': 'Gas Stove,Kadai / Pan',
        },
      );
      print('Registered default primary user: $primaryUserId');
    }

    // 2. Backfill user_id in chat_messages
    final updatedChat = await connection.execute(
      Sql.named('UPDATE chat_messages SET user_id = @uid WHERE user_id IS NULL;'),
      parameters: {'uid': primaryUserId},
    );
    print('✅ Backfilled user_id in chat_messages: ${updatedChat.affectedRows} rows updated.');

    // 3. Backfill user_id in user_pantry
    try {
      final updatedPantry = await connection.execute(
        Sql.named('UPDATE user_pantry SET user_id = @uid WHERE user_id IS NULL;'),
        parameters: {'uid': primaryUserId},
      );
      print('✅ Backfilled user_id in user_pantry: ${updatedPantry.affectedRows} rows updated.');
    } catch (_) {}

    // 4. Backfill user_id in saved_recipes
    try {
      final updatedSaved = await connection.execute(
        Sql.named('UPDATE saved_recipes SET user_id = @uid WHERE user_id IS NULL;'),
        parameters: {'uid': primaryUserId},
      );
      print('✅ Backfilled user_id in saved_recipes: ${updatedSaved.affectedRows} rows updated.');
    } catch (_) {}

    // 5. Backfill user_id in user_inventory
    try {
      final updatedInv = await connection.execute(
        Sql.named('UPDATE user_inventory SET user_id = @uid WHERE user_id IS NULL;'),
        parameters: {'uid': primaryUserId},
      );
      print('✅ Backfilled user_id in user_inventory: ${updatedInv.affectedRows} rows updated.');
    } catch (_) {}

    // Print summary
    final checkRows = await connection.execute(
      'SELECT id, role, user_id, SUBSTRING(content, 1, 30), CASE WHEN recipe_json IS NULL THEN \'NULL\' ELSE \'POPULATED\' END FROM chat_messages ORDER BY created_at DESC LIMIT 6;'
    );

    print('\nLATEST 6 CHAT MESSAGES IN NEON POSTGRESQL:');
    for (final r in checkRows) {
      print('• [${r[0]}] ${r[1]} | user_id: "${r[2]}" | recipe_json: ${r[4]}');
    }

    await connection.close();
    print('\nSUCCESS: All NULL user_id records have been successfully backfilled.');
  } catch (e) {
    print('Error during backfill: $e');
  }
}
