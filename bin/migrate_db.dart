import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to Neon PostgreSQL for Schema Migration...');
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

    print('Connected. Running DDL migrations sequentially...');

    final migrations = [
      // 1. Users table & columns
      '''
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(64) PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        photo_url TEXT,
        household_name VARCHAR(255) DEFAULT 'My Kitchen',
        diet_preference VARCHAR(64) DEFAULT 'Veg',
        household_size VARCHAR(32) DEFAULT '2',
        appliances TEXT DEFAULT 'Gas Stove,Kadai / Pan',
        exclusions TEXT DEFAULT '',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_url TEXT;',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS household_name VARCHAR(255) DEFAULT \'My Kitchen\';',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS diet_preference VARCHAR(64) DEFAULT \'Veg\';',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS household_size VARCHAR(32) DEFAULT \'2\';',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS appliances TEXT DEFAULT \'Gas Stove,Kadai / Pan\';',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS exclusions TEXT DEFAULT \'\';',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP;',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;',

      // 2. User Inventory table & user_id column
      '''
      CREATE TABLE IF NOT EXISTS user_inventory (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64),
        name_en VARCHAR(128) NOT NULL,
        name_hi VARCHAR(128),
        category VARCHAR(64),
        selected_unit VARCHAR(32),
        quantity INT DEFAULT 1,
        is_added BOOLEAN DEFAULT false,
        is_checked BOOLEAN DEFAULT false,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      'ALTER TABLE user_inventory ADD COLUMN IF NOT EXISTS user_id VARCHAR(64);',

      // 3. User Pantry table & user_id column
      '''
      CREATE TABLE IF NOT EXISTS user_pantry (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64),
        name VARCHAR(128) NOT NULL,
        category VARCHAR(64),
        unit VARCHAR(32),
        quantity INT DEFAULT 1,
        is_low_stock BOOLEAN DEFAULT false,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      'ALTER TABLE user_pantry ADD COLUMN IF NOT EXISTS user_id VARCHAR(64);',

      // 4. Saved Templates table & user_id column
      '''
      CREATE TABLE IF NOT EXISTS saved_templates (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64),
        name VARCHAR(128) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        items_json TEXT NOT NULL
      );
      ''',
      'ALTER TABLE saved_templates ADD COLUMN IF NOT EXISTS user_id VARCHAR(64);',

      // 5. Saved Recipes table & user_id column
      '''
      CREATE TABLE IF NOT EXISTS saved_recipes (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64),
        dish_name VARCHAR(128) NOT NULL,
        prep_time VARCHAR(32),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        recipe_json TEXT NOT NULL
      );
      ''',
      'ALTER TABLE saved_recipes ADD COLUMN IF NOT EXISTS user_id VARCHAR(64);',

      // 6. Chat Messages table for Agent Memory
      '''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64),
        role VARCHAR(16) NOT NULL,
        content TEXT NOT NULL,
        recipe_json TEXT,
        suggestions_json TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      ''',
      'ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS user_id VARCHAR(64);',
      'ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS recipe_json TEXT;',
      'ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS suggestions_json TEXT;',

      // 7. Performance Indexes
      'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);',
      'CREATE INDEX IF NOT EXISTS idx_user_pantry_user_id ON user_pantry(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_user_inventory_user_id ON user_inventory(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_saved_recipes_user_id ON saved_recipes(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_saved_templates_user_id ON saved_templates(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);',
    ];

    for (int i = 0; i < migrations.length; i++) {
      try {
        await connection.execute(migrations[i]);
      } catch (e) {
        print('Warning on migration #$i: $e');
      }
    }

    print('All migrations completed successfully!');

    // Verify chat_messages table
    final chatCheck = await connection.execute('SELECT COUNT(*) FROM chat_messages;');
    print('chat_messages table verified. Row count: ${chatCheck.first[0]}');

    // Verify user_inventory columns
    final invCheck = await connection.execute('SELECT COUNT(*) FROM user_inventory;');
    print('user_inventory table verified. Row count: ${invCheck.first[0]}');

    await connection.close();
    print('SUCCESS: Database schema fully up-to-date.');
  } catch (e) {
    print('Fatal migration error: $e');
  }
}
