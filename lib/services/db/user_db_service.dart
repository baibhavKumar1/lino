import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'neon_connection.dart';

class UserDbService {
  static Future<Map<String, dynamic>?> fetchUserByEmail(String email) async {
    final res = await NeonConnection.runQuery((conn) async {
      final results = await conn.execute(
        Sql.named(
          'SELECT id, email, full_name, photo_url, household_name, '
          'diet_preference, household_size, appliances, exclusions '
          'FROM users WHERE LOWER(email) = LOWER(@email);'
        ),
        parameters: {'email': email.trim().toLowerCase()},
      ).timeout(const Duration(seconds: 12));

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'id': row[0] as String,
          'email': row[1] as String,
          'fullName': row[2] as String,
          'photoUrl': row[3] as String?,
          'householdName': row[4] as String? ?? 'My Kitchen',
          'dietPreference': row[5] as String? ?? 'Veg',
          'householdSize': row[6] as String? ?? '2',
          'appliances': row[7] as String? ?? 'Gas Stove,Kadai / Pan',
          'exclusions': row[8] as String? ?? '',
        };
      }
      return null;
    });
    return res;
  }

  static Future<void> registerUserInCloud({
    required String id,
    required String email,
    required String fullName,
    String? photoUrl,
    required String householdName,
    String dietPreference = 'Veg',
    String householdSize = '2',
    String appliances = 'Gas Stove,Kadai / Pan',
    String exclusions = '',
  }) async {
    await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'INSERT INTO users (id, email, full_name, photo_url, household_name, diet_preference, household_size, appliances, exclusions, last_login, updated_at) '
          'VALUES (@id, @email, @full_name, @photo_url, @household_name, @diet, @size, @appliances, @exclusions, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) '
          'ON CONFLICT (email) DO UPDATE SET '
          'full_name = EXCLUDED.full_name, '
          'photo_url = COALESCE(EXCLUDED.photo_url, users.photo_url), '
          'household_name = COALESCE(EXCLUDED.household_name, users.household_name), '
          'diet_preference = COALESCE(EXCLUDED.diet_preference, users.diet_preference), '
          'household_size = COALESCE(EXCLUDED.household_size, users.household_size), '
          'appliances = COALESCE(EXCLUDED.appliances, users.appliances), '
          'exclusions = COALESCE(EXCLUDED.exclusions, users.exclusions), '
          'last_login = CURRENT_TIMESTAMP, '
          'updated_at = CURRENT_TIMESTAMP;',
        ),
        parameters: {
          'id': id,
          'email': email.trim().toLowerCase(),
          'full_name': fullName.trim(),
          'photo_url': photoUrl,
          'household_name': householdName.trim(),
          'diet': dietPreference,
          'size': householdSize,
          'appliances': appliances,
          'exclusions': exclusions,
        },
      ).timeout(const Duration(seconds: 12));
    });
  }

  static Future<void> updateUserProfileInCloud({
    required String email,
    String? fullName,
    String? householdName,
    String? dietPreference,
    String? householdSize,
    String? appliances,
    String? exclusions,
  }) async {
    await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'UPDATE users SET '
          'full_name = COALESCE(@full_name, full_name), '
          'household_name = COALESCE(@household_name, household_name), '
          'diet_preference = COALESCE(@diet, diet_preference), '
          'household_size = COALESCE(@size, household_size), '
          'appliances = COALESCE(@appliances, appliances), '
          'exclusions = COALESCE(@exclusions, exclusions), '
          'updated_at = CURRENT_TIMESTAMP '
          'WHERE LOWER(email) = LOWER(@email);',
        ),
        parameters: {
          'email': email.trim().toLowerCase(),
          'full_name': fullName,
          'household_name': householdName,
          'diet': dietPreference,
          'size': householdSize,
          'appliances': appliances,
          'exclusions': exclusions,
        },
      ).timeout(const Duration(seconds: 12));
    });
  }

  static Future<void> updateUserLastLogin(String emailOrUserId) async {
    await NeonConnection.runQuery((conn) async {
      await conn.execute(
        Sql.named(
          'UPDATE users SET last_login = CURRENT_TIMESTAMP '
          'WHERE LOWER(email) = LOWER(@id) OR id = @id;',
        ),
        parameters: {'id': emailOrUserId.trim()},
      ).timeout(const Duration(seconds: 12));
    });
  }

  static Future<bool> cleanUserDataForFreshStart() async {
    final res = await NeonConnection.runQuery((conn) async {
      await conn.execute('''
        TRUNCATE TABLE user_pantry, saved_recipes, saved_templates, chat_messages, users CASCADE;
      ''').timeout(const Duration(seconds: 8));
      debugPrint('[UserDbService] Fresh start cleanup completed. Master inventory preserved.');
      return true;
    });
    return res ?? false;
  }
}
