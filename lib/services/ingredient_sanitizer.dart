import '../models/grocery_item.dart';
import '../screens/onboarding_screen.dart';
import 'jev_classification_service.dart';

/// Production-grade culinary ingredient sanitizer & catalog matcher
class IngredientSanitizer {
  /// Universal items that should never be added to a paid grocery cart
  static final Set<String> _universalFreeItems = {
    'water',
    'tap water',
    'drinking water',
    'ice',
    'warm water',
    'hot water',
    'cold water',
    'boiling water',
    'air',
  };

  /// Common culinary measurement units
  static final RegExp _unitsRegex = RegExp(
    r'\b(\d+/\d+|\d+\.\d+|\d+)?\s*(tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|cup|cups|pinch|pinches|clove|cloves|bunch|bunches|handful|handfuls|piece|pieces|pcs|pc|gram|grams|gm|gms|g|kilogram|kilograms|kg|kgs|ml|liter|liters|litre|litres|l|packet|packets|pack|packs|slab|can|bottle|dollop|drop|drops|slice|slices)\b',
    caseSensitive: false,
  );

  /// Preparation methods and culinary action verbs
  static final RegExp _prepVerbsRegex = RegExp(
    r'\b(finely chopped|roughly chopped|chopped|diced|sliced|slit|grated|pureed|paste|crushed|minced|boiled|fried|deep fried|roasted|toasted|soaked|warm|hot|cold|fresh|dried|dry|powdered|ground|julienned|melted|shredded|cubed|to taste|for frying|for tempering|for garnishing|for tadka|as needed|optional)\b',
    caseSensitive: false,
  );

  /// Numerics, fractions, and ranges like "1-2", "200-250", "1/2"
  static final RegExp _numbersRegex = RegExp(r'^\s*(\d+/\d+|\d+\s*-\s*\d+|\d+\.\d+|\d+)\s*');

  /// Returns true if this is an infinite free household staple (water, ice)
  static bool isUniversalFreeItem(String rawText) {
    final clean = rawText.toLowerCase().trim();
    if (_universalFreeItems.contains(clean)) return true;
    for (final freeItem in _universalFreeItems) {
      if (clean == freeItem || clean.startsWith('$freeItem ') || clean.endsWith(' $freeItem')) {
        return true;
      }
    }
    return false;
  }

  /// Cleans a raw recipe ingredient string into a pure, clean ingredient name
  /// Example: "2 tbsp Fresh Coriander Leaves (finely chopped)" -> "Coriander Leaves"
  /// Example: "200g Fresh Paneer (cubed)" -> "Paneer"
  /// Example: "1/2 tsp Turmeric Powder (Haldi)" -> "Turmeric Powder"
  static String cleanIngredientName(String rawText) {
    if (rawText.trim().isEmpty) return '';

    String text = rawText.trim();

    // 1. If text has a secondary Hindi name inside parentheses, capture it
    String alias = '';
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(text);
    if (parenMatch != null) {
      final inside = parenMatch.group(1)!.trim();
      // If inside parentheses is a name (not a quantity like 200g or prep like chopped)
      if (!inside.contains(RegExp(r'\d')) && !_prepVerbsRegex.hasMatch(inside)) {
        alias = inside;
      }
      text = text.replaceAll(RegExp(r'\([^)]*\)'), ' ').trim();
    }

    // 2. Strip leading numbers/fractions
    text = text.replaceAll(_numbersRegex, ' ');

    // 3. Strip measurement units
    text = text.replaceAll(_unitsRegex, ' ');

    // 4. Strip prep verbs & descriptor phrases
    text = text.replaceAll(_prepVerbsRegex, ' ');

    // 5. Clean up noise characters and whitespace
    text = text
        .replaceAll(RegExp(r'[\,\:\;\*\-\_\/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 6. If result became too short but we had a valid alias inside parentheses, use alias
    if (text.length < 2 && alias.isNotEmpty) {
      text = alias;
    }

    // 7. Title-case words for clean presentation
    if (text.isEmpty) return rawText.trim();

    return text
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w.length > 1 ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w.toUpperCase())
        .join(' ');
  }

  /// Finds the best matching grocery item in the inventory/catalog with multi-tier precision
  static int findMatchingItemIndex(String rawQuery, List<GroceryItem> allItems) {
    if (rawQuery.trim().isEmpty || allItems.isEmpty) return -1;

    final cleanedQuery = cleanIngredientName(rawQuery).toLowerCase().trim();
    if (cleanedQuery.isEmpty) return -1;

    final queryCanonical = CanonicalItemMatcher.getCanonicalKey(cleanedQuery);

    // Tier 1: Exact Canonical Match
    for (int i = 0; i < allItems.length; i++) {
      final item = allItems[i];
      final itemCanonicalEn = CanonicalItemMatcher.getCanonicalKey(item.nameEn);
      final itemCanonicalHi = CanonicalItemMatcher.getCanonicalKey(item.nameHi);

      if (queryCanonical == itemCanonicalEn || queryCanonical == itemCanonicalHi) {
        return i;
      }
    }

    // Tier 2: Exact Name Match (case-insensitive)
    for (int i = 0; i < allItems.length; i++) {
      final item = allItems[i];
      final nameEnLower = item.nameEn.toLowerCase().trim();
      final nameHiLower = item.nameHi.toLowerCase().trim();

      if (nameEnLower == cleanedQuery || nameHiLower == cleanedQuery) {
        return i;
      }
    }

    // Tier 3: Substring / Primary Name Match — with length proximity guard
    // Prevents short names like "Oil" (3 chars) from matching inside "Sunflower Oil"
    for (int i = 0; i < allItems.length; i++) {
      final item = allItems[i];
      final primaryEn = item.nameEn.toLowerCase().split('(').first.trim();
      final primaryHi = item.nameHi.toLowerCase().split('(').first.trim();

      // Exact primary name match
      if (primaryEn == cleanedQuery || primaryHi == cleanedQuery) {
        return i;
      }

      // Substring match ONLY if the shorter string is at least 60% of the longer string length
      // This prevents "Oil" matching inside "Sunflower Oil" or "Dal" matching "Toor Dal"
      final lenQuery = cleanedQuery.length;
      final lenEn = primaryEn.length;
      final lenHi = primaryHi.length;

      if (primaryEn.contains(cleanedQuery) && lenQuery >= (lenEn * 0.6)) {
        return i;
      }
      if (cleanedQuery.contains(primaryEn) && lenEn >= (lenQuery * 0.6)) {
        return i;
      }
      if (primaryHi.isNotEmpty) {
        if (primaryHi.contains(cleanedQuery) && lenQuery >= (lenHi * 0.6)) {
          return i;
        }
        if (cleanedQuery.contains(primaryHi) && lenHi >= (lenQuery * 0.6)) {
          return i;
        }
      }
    }

    // Tier 4: Core Tokens Match — using Word Boundaries
    // Only filter out truly generic filler words, not distinguishing suffixes
    final genericFillers = {'the', 'and', 'for', 'with', 'in', 'of'};
    final queryTokens = cleanedQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2 && !genericFillers.contains(t))
        .toList();

    if (queryTokens.isNotEmpty) {
      for (int i = 0; i < allItems.length; i++) {
        final item = allItems[i];
        final itemText = '${item.nameEn} ${item.nameHi}'.toLowerCase();
        
        bool allMatch = true;
        for (final t in queryTokens) {
          // Use word boundary to ensure "soy" doesn't match inside "soya"
          if (!RegExp('\\b$t\\b').hasMatch(itemText)) {
            allMatch = false;
            break;
          }
        }
        
        if (allMatch) {
          return i;
        }
      }
    }

    return -1;
  }

  /// JEV AI-POWERED ASYNC CLASSIFICATION (System One Decision Layer)
  static Future<ItemCategory> classifyCategoryWithJev(String ingredientName) async {
    return JevClassificationService.classifyGroceryCategory(ingredientName);
  }

  /// JEV AI-POWERED DEFAULT PACKAGING UNIT PREDICTION
  static Future<String> classifyDefaultUnitWithJev(String ingredientName) async {
    return JevClassificationService.classifyDefaultUnit(ingredientName);
  }

  /// Synchronous fallback classification using heuristic patterns
  static ItemCategory guessCategory(String ingredientName) {
    // PREVIOUS HEURISTIC LOGIC COMMENTED OUT FOR PRESERVATION:
    /*
    final lower = ingredientName.toLowerCase();
    if (lower.contains('milk') || lower.contains('paneer') || lower.contains('curd') || lower.contains('dahi') || lower.contains('cheese') || lower.contains('butter') || lower.contains('cream') || lower.contains('oil') || lower.contains('ghee') || lower.contains('sugar')) {
      return ItemCategory.kitchenStaples;
    }
    if (lower.contains('masala') || lower.contains('blend') || lower.contains('garam')) {
      return ItemCategory.masalaBlends;
    }
    if (lower.contains('powder') || lower.contains('haldi') || lower.contains('jeera') || lower.contains('turmeric') || lower.contains('cumin') || lower.contains('chili') || lower.contains('mirch') || lower.contains('salt') || lower.contains('hing') || lower.contains('clove') || lower.contains('cardamom') || lower.contains('cinnamon') || lower.contains('pepper') || lower.contains('mustard')) {
      return ItemCategory.singleSpices;
    }
    if (lower.contains('dal') || lower.contains('chana') || lower.contains('rajma') || lower.contains('pulse') || lower.contains('lentil')) {
      return ItemCategory.pulsesLentils;
    }
    if (lower.contains('rice') || lower.contains('poha') || lower.contains('grain') || lower.contains('quinoa')) {
      return ItemCategory.riceGrains;
    }
    if (lower.contains('atta') || lower.contains('flour') || lower.contains('suji') || lower.contains('rava') || lower.contains('maida') || lower.contains('besan') || lower.contains('baking')) {
      return ItemCategory.floursBaking;
    }
    return ItemCategory.freshProduce;
    */

    final lower = ingredientName.toLowerCase();
    if (lower.contains('milk') ||
        lower.contains('paneer') ||
        lower.contains('curd') ||
        lower.contains('dahi') ||
        lower.contains('cheese') ||
        lower.contains('butter') ||
        lower.contains('cream') ||
        lower.contains('oil') ||
        lower.contains('ghee') ||
        lower.contains('sugar')) {
      return ItemCategory.kitchenStaples;
    }
    if (lower.contains('masala') || lower.contains('blend') || lower.contains('garam')) {
      return ItemCategory.masalaBlends;
    }
    if (lower.contains('powder') ||
        lower.contains('haldi') ||
        lower.contains('jeera') ||
        lower.contains('turmeric') ||
        lower.contains('cumin') ||
        lower.contains('chili') ||
        lower.contains('mirch') ||
        lower.contains('salt') ||
        lower.contains('hing') ||
        lower.contains('clove') ||
        lower.contains('cardamom') ||
        lower.contains('cinnamon') ||
        lower.contains('pepper') ||
        lower.contains('mustard')) {
      return ItemCategory.singleSpices;
    }
    if (lower.contains('dal') || lower.contains('chana') || lower.contains('rajma') || lower.contains('pulse') || lower.contains('lentil')) {
      return ItemCategory.pulsesLentils;
    }
    if (lower.contains('rice') || lower.contains('poha') || lower.contains('grain') || lower.contains('quinoa')) {
      return ItemCategory.riceGrains;
    }
    if (lower.contains('atta') || lower.contains('flour') || lower.contains('suji') || lower.contains('rava') || lower.contains('maida') || lower.contains('besan') || lower.contains('baking')) {
      return ItemCategory.floursBaking;
    }
    return ItemCategory.freshProduce;
  }

  /// Intelligently assigns default packaging/unit
  static String guessDefaultUnit(String ingredientName) {
    final lower = ingredientName.toLowerCase();
    if (lower.contains('coriander') || lower.contains('mint') || lower.contains('spinach') || lower.contains('palak') || lower.contains('methi')) {
      return '1 Bunch';
    }
    if (lower.contains('milk') || lower.contains('oil') || lower.contains('ghee')) {
      return '1 L';
    }
    if (lower.contains('paneer') || lower.contains('butter') || lower.contains('cheese')) {
      return '200 g';
    }
    if (lower.contains('atta') || lower.contains('rice') || lower.contains('dal') || lower.contains('flour') || lower.contains('sugar')) {
      return '1 kg';
    }
    if (lower.contains('chili') || lower.contains('lemon') || lower.contains('egg')) {
      return '4 Pcs';
    }
    return '1 Pack';
  }
}
