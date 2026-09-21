import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to Neon PostgreSQL database...');
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
    print('Cleaning user_pantry, saved_recipes, saved_templates, and users tables...');
    print('PRESERVING user_inventory (Master Grocery Catalog)...');

    await connection.execute('''
      TRUNCATE TABLE user_pantry, saved_recipes, saved_templates, users CASCADE;
    ''');

    print('Checking count of user_inventory...');
    final inventoryCount = await connection.execute('SELECT COUNT(*) FROM user_inventory;');
    final count = inventoryCount.first[0];
    print('Master Inventory items preserved: $count items.');

    await connection.close();
    print('SUCCESS: Fresh start cleanup completed cleanly.');
  } catch (e) {
    print('Error executing cleanup: $e');
  }
}
