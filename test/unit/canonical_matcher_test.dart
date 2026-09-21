import 'package:flutter_test/flutter_test.dart';
import 'package:kichook/screens/onboarding_screen.dart';

void main() {
  group('CanonicalItemMatcher Tests', () {
    test('matches Hindi and English aliases to same canonical key', () {
      expect(CanonicalItemMatcher.getCanonicalKey('Jeera'), 'cumin_seeds');
      expect(CanonicalItemMatcher.getCanonicalKey('Cumin Seeds'), 'cumin_seeds');
      expect(CanonicalItemMatcher.getCanonicalKey('Haldi'), 'turmeric_powder');
      expect(CanonicalItemMatcher.getCanonicalKey('Turmeric Powder'), 'turmeric_powder');
      expect(CanonicalItemMatcher.getCanonicalKey('Aloo'), 'potato');
      expect(CanonicalItemMatcher.getCanonicalKey('Potato'), 'potato');
      expect(CanonicalItemMatcher.getCanonicalKey('Pyaaz'), 'onion');
      expect(CanonicalItemMatcher.getCanonicalKey('Red Onion'), 'onion');
    });

    test('strips parentheses and modifiers', () {
      expect(CanonicalItemMatcher.getCanonicalKey('Jeera (Cumin Seeds)'), 'cumin_seeds');
      expect(CanonicalItemMatcher.getCanonicalKey('Fresh Curd / Dahi'), 'curd');
      expect(CanonicalItemMatcher.getCanonicalKey('Desi Ghee'), 'ghee');
    });
  });
}
