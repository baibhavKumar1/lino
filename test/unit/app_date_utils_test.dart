import 'package:flutter_test/flutter_test.dart';
// import 'package:kichook/theme/app_theme.dart';
import 'package:lino/theme/app_theme.dart';

void main() {
  group('AppDateUtils Tests', () {
    test('formats month and year correctly', () {
      final date = DateTime(2026, 8, 25);
      expect(AppDateUtils.formatMonthYear(date), 'August 2026');
    });

    test('formats full date correctly', () {
      final date = DateTime(2026, 8, 25); // Tuesday
      expect(AppDateUtils.formatFullDate(date), 'Tuesday, Aug 25');
    });

    test('formats short date correctly', () {
      final date = DateTime(2026, 8, 25); // Tuesday
      expect(AppDateUtils.formatShortDate(date), 'Tue, Aug 25');
    });

    test('formats short weekday in uppercase correctly', () {
      final date = DateTime(2026, 8, 25); // Tuesday
      expect(AppDateUtils.formatShortWeekday(date), 'TUE');
    });
  });
}
