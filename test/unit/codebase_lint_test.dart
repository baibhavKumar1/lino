import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Codebase Lint & Architectural Constraints Tests', () {
    test('enforces that services, db, openrouter and auth modules have no files > 700 LOC', () {
      final libDir = Directory('lib/services');
      expect(libDir.existsSync(), isTrue, reason: 'lib/services directory must exist');

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync().length;
        if (lines > 700) {
          violations.add('${file.path}: $lines lines (max allowed is 700)');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'The following service files exceed the 700-line modular limit:\n${violations.join('\n')}',
      );
    });

    test('validates that domain models and services have dedicated sub-folders', () {
      final dbDir = Directory('lib/services/db');
      final openrouterDir = Directory('lib/services/openrouter');
      final authDir = Directory('lib/services/auth');

      expect(dbDir.existsSync(), isTrue, reason: 'db/ folder must exist');
      expect(openrouterDir.existsSync(), isTrue, reason: 'openrouter/ folder must exist');
      expect(authDir.existsSync(), isTrue, reason: 'auth/ folder must exist');

      expect(File('lib/services/db/neon_connection.dart').existsSync(), isTrue);
      expect(File('lib/services/db/inventory_db_service.dart').existsSync(), isTrue);
      expect(File('lib/services/db/recipes_db_service.dart').existsSync(), isTrue);
      expect(File('lib/services/db/chat_history_db_service.dart').existsSync(), isTrue);
      expect(File('lib/services/db/meal_calendar_db_service.dart').existsSync(), isTrue);

      expect(File('lib/services/openrouter/openrouter_client.dart').existsSync(), isTrue);
      expect(File('lib/services/openrouter/chef_agent_service.dart').existsSync(), isTrue);
      expect(File('lib/services/openrouter/receipt_ocr_service.dart').existsSync(), isTrue);

      expect(File('lib/services/auth/auth_service.dart').existsSync(), isTrue);
    });
  });
}
