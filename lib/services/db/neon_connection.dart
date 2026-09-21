import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

class NeonConnection {
  static const String _host = String.fromEnvironment(
    'NEON_DB_HOST',
    defaultValue: 'ep-wild-hat-azgg5fdf-pooler.c-3.ap-southeast-1.aws.neon.tech',
  );
  static const String _database = String.fromEnvironment(
    'NEON_DB_DATABASE',
    defaultValue: 'neondb',
  );
  static const String _username = String.fromEnvironment(
    'NEON_DB_USER',
    defaultValue: 'neondb_owner',
  );
  static const String _password = String.fromEnvironment(
    'NEON_DB_PASSWORD',
    defaultValue: 'npg_CJK1g0coedDq',
  );
  static const int _port = int.fromEnvironment('NEON_DB_PORT', defaultValue: 5432);

  static Connection? _connection;
  static Future<void>? _connectingFuture;

  static Future<void> initDatabase() async {
    if (_connection != null && _connection!.isOpen) {
      return;
    }
    try {
      _connection = await Connection.open(
        Endpoint(
          host: _host,
          database: _database,
          username: _username,
          password: _password,
          port: _port,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.require,
        ),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Neon DB connection timeout'),
      );

      final ddlStatements = [
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

        '''
        CREATE TABLE IF NOT EXISTS global_inventory (
          id VARCHAR(64) PRIMARY KEY,
          name_en VARCHAR(128) NOT NULL,
          name_hi VARCHAR(128),
          category VARCHAR(64),
          available_units TEXT,
          default_unit VARCHAR(32),
          image_url TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        ''',

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

        'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);',
        'CREATE INDEX IF NOT EXISTS idx_user_pantry_user_id ON user_pantry(user_id);',
        'CREATE INDEX IF NOT EXISTS idx_user_inventory_user_id ON user_inventory(user_id);',
        'CREATE INDEX IF NOT EXISTS idx_saved_recipes_user_id ON saved_recipes(user_id);',
        'CREATE INDEX IF NOT EXISTS idx_saved_templates_user_id ON saved_templates(user_id);',
        'CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);',

        '''
        CREATE TABLE IF NOT EXISTS meal_calendar_events (
          id VARCHAR(64) PRIMARY KEY,
          user_id VARCHAR(64) NOT NULL,
          event_date DATE NOT NULL,
          meal_slot VARCHAR(32) NOT NULL,
          dish_name VARCHAR(128) NOT NULL,
          recipe_id VARCHAR(64),
          recipe_json TEXT,
          servings INT DEFAULT 2,
          is_cooked BOOLEAN DEFAULT false,
          notes TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        ''',
        'CREATE INDEX IF NOT EXISTS idx_calendar_user_date ON meal_calendar_events(user_id, event_date);',
      ];

      for (final stmt in ddlStatements) {
        try {
          await _connection?.execute(stmt);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<void> ensureConnected() async {
    if (_connection != null && _connection!.isOpen) {
      return;
    }
    if (_connectingFuture != null) {
      await _connectingFuture;
      return;
    }
    _connectingFuture = initDatabase();
    try {
      await _connectingFuture;
    } finally {
      _connectingFuture = null;
    }
  }

  static Future<T?> runQuery<T>(Future<T> Function(Connection conn) queryAction) async {
    await ensureConnected();
    if (_connection == null || !_connection!.isOpen) {
      await initDatabase();
      if (_connection == null || !_connection!.isOpen) return null;
    }

    try {
      return await queryAction(_connection!);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connection is not open') ||
          errStr.contains('closed') ||
          errStr.contains('broken pipe') ||
          errStr.contains('socketexception') ||
          errStr.contains('timeout')) {
        debugPrint('[NeonConnection] Auto-healing connection due to socket reset: $e');
        _connection = null;
        await initDatabase();
        if (_connection != null && _connection!.isOpen) {
          try {
            return await queryAction(_connection!);
          } catch (retryErr) {
            debugPrint('[NeonConnection] Resilient retry failed: $retryErr');
          }
        }
      } else {
        debugPrint('[NeonConnection] Execution error: $e');
      }
      return null;
    }
  }

  static Future<void> closeConnection() async {
    await _connection?.close();
    _connection = null;
  }
}
