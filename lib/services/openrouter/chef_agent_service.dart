import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/grocery_item.dart';
import '../../models/chat_message.dart';
import '../../models/user_preferences.dart';
import 'openrouter_client.dart';
import 'meal_recipe.dart';

class ChefAgentService {
  static Future<List<MealRecipe>> ideateMeals({
    required List<GroceryItem> inventory,
    required String mealTime,
    required int maxCookTimeMinutes,
    required int numPeople,
    required int restockTimeMinutes,
    required String dietType,
    required List<String> exclusions,
    String? heroCraving,
    bool isPrioritizeExpiring = false,
    String? leftoverNotes,
    List<String>? appliances,
    String? mealVibe,
    bool isOnePotOnly = false,
  }) async {
    final presentItems = inventory
        .where((item) => item.isAdded || item.quantity > 0)
        .map((item) => '${item.nameEn} (${item.quantity} x ${item.selectedUnit})')
        .toList();

    final isStrictInStock = restockTimeMinutes == 0;
    final effectiveOnePot = isOnePotOnly || (appliances != null && appliances.any((a) => a.toLowerCase().contains('one-pot')));

    final cavemanPrompt = '''
YOU ARE KICHOOK KITCHEN CHEF. IDEATE EXACTLY 3 DISTINCT MEAL OPTIONS.

CONTEXT:
- Meal Slot: $mealTime
- Max Cook Time: $maxCookTimeMinutes Mins
- Feed Portion: $numPeople People
- Diet Preference: $dietType
- Meal Vibe / Goal: ${mealVibe ?? 'General'}
- Available Appliances / Cookware: ${appliances == null || appliances.isEmpty ? 'Gas Stove, Kadai / Pan' : appliances.join(', ')}
- One-Pot / One-Pan Cleanup Only: $effectiveOnePot
- Prioritize Perishable & Expiring Items First: $isPrioritizeExpiring
- Time Available to Buy Ingredients: $restockTimeMinutes Mins (Strict In-Stock Lock: $isStrictInStock)
- FORBIDDEN EXCLUSIONS (MUST NOT ADD): ${exclusions.isEmpty ? 'None' : exclusions.join(', ')}

SPECIAL DIRECTIVES:
- MUST-INCLUDE HERO CRAVING: ${heroCraving == null || heroCraving.isEmpty ? 'None specified' : heroCraving}
- LEFTOVERS & SPECIAL NOTES: ${leftoverNotes == null || leftoverNotes.isEmpty ? 'None specified' : leftoverNotes}

CURRENT KITCHEN INVENTORY AVAILABLE (QUANTITIES & UNITS):
${presentItems.isEmpty ? 'EMPTY PANTRY (No stocked ingredients in kitchen yet. Propose simple recipes and list required ingredients in missingItems so user can restock them).' : presentItems.join('\n')}

// Previous single-line rule:
// 1. PRODUCE 3 DIFFERENT DISHES: Provide 3 distinct meal recipes varying in style (e.g. a quick sauté/stir-fry, a comfort curry/dal/gravy, a hearty rice/one-pot bowl).
// New High-Diversity Culinary & Vegetable Lock:
1. PRODUCE 3 RADICALLY DIFFERENT DISHES (HIGH DIVERSITY LOCK):
   - Each recipe MUST belong to a completely different culinary style & preparation:
     * Option A (Dry Sauté / Stir-Fry / Tawa Roast): e.g., Crispy Bhindi, Paneer/Tofu Tikka Roast, Capsicum-Aloo Stir-Fry.
     * Option B (Rich Gravy / Curry / Dal Tadka): e.g., Lasooni Palak Gravy, Kadai Mushroom/Paneer, Homestyle Mixed Veg Stew.
     * Option C (Aromatic Rice / Grain Bowl / One-Pot): e.g., Veggie Pulao, Masala Khichdi, Herb Rice Bowl.
   - STAR VEGETABLE ISOLATION LOCK: No two dishes may share the same primary hero vegetable or protein. Utilize a wide variety of distinct vegetables across the 3 dishes (e.g., Spinach/Palak, Capsicum, Cauliflower, Bhindi, Green Peas, Carrots, Tomatoes, Paneer/Tofu).
   - FLAVOR PROFILE DIVERSITY: One tangy/zesty, one deeply spiced/earthy, one aromatic/herbaceous.
2. MACRO BREAKDOWN LOCK: Include estimated "macros" object for each dish: {"calories": "380 kcal", "protein": "24g", "carbs": "45g", "fat": "12g"}.
3. EXACT INGREDIENT QUANTITIES LOCK: Output MUST specify exact amounts for every ingredient used (e.g. "200g Tofu", "50g Leftover Rice", "1 tsp Jeera", "1 tbsp Ghee", "1/2 tsp Salt").
4. EXPIRING ITEMS LOCK: IF Prioritize Perishable & Expiring Items is true, inspect present inventory and FORCE perishable items (fresh produce, greens, dairy, open packs) into the recipes to prevent food waste.
5. HERO CRAVING LOCK: IF Hero Craving is specified, dishes MUST feature it as the hero ingredient.
6. LEFTOVER LOCK: IF Leftover notes are specified, dishes MUST creatively consume them as the base.
7. DIET LOCK: IF Diet Preference is Non-Veg or Egg, ALL dishes MUST BE NON-VEGETARIAN / EGG DISHES. DO NOT produce vegetarian/mushroom dishes for Non-Veg!
8. APPLIANCE CONSTRAINTS: Use ONLY specified appliances (${appliances?.join(', ')}).
9. ONE-POT LOCK: IF One-Pot Only is true, prepare entirely in 1 pot/pan for zero cleanup.
10. ZERO SHOPPING LOCK: IF Time Available to Buy is 0 Mins, "missingItems" MUST BE [].
11. FORBIDDEN EXCLUSIONS LOCK: STRICTLY OBEY EXCLUSIONS.
12. UNIVERSAL WATER LOCK: Water and Ice are ALWAYS in infinite supply. NEVER put "Water" or "Ice" in "missingItems".
13. CULINARY REALISM & COOKING STEPS LOCK: All raw ingredients (raw rice, millets, dry lentils, rajma, chana, potatoes, vegetables) MUST include their proper real-world cooking methods (e.g. "Wash rice, add 2 cups water, cover and simmer on low for 12 mins until fluffy" or "Pressure cook soaked rajma for 4 whistles until soft"). NEVER write impossible steps like tossing raw uncooked rice into a pan without boiling or cooking liquid!
14. CRISPY CAVEMAN FORMAT: Direct, action-oriented, clear cooking steps. NO unnecessary storytelling.

OUTPUT FORMAT MUST BE VALID RAW JSON ONLY (NO CODEBLOCKS):
{
  "recipes": [
    {
      "dishName": "Name of Dish 1",
      "prepTime": "$maxCookTimeMinutes Mins",
      "servings": "$numPeople People",
      "dietType": "$dietType",
      "macros": {
        "calories": "380 kcal",
        "protein": "22g",
        "carbs": "48g",
        "fat": "12g"
      },
      "ingredientsWithQuantities": [
        "200g Tofu (Cubed)",
        "1 tsp Cumin Seeds",
        "1 tbsp Desi Ghee",
        "1/2 tsp Turmeric",
        "1/2 tsp Salt"
      ],
      "usedInventory": ["Tofu", "Cumin Seeds", "Ghee"],
      "missingItems": [],
      "substitutions": [],
      "cavemanSteps": [
        "Dice tofu into 1-inch cubes.",
        "Heat ghee in skillet. Splutter cumin seeds.",
        "Add tofu cubes and spices. Sauté 5 mins till golden crisp.",
        "Done. Serve hot."
      ],
      "chefTip": "Add a pinch of chaat masala on top."
    }
  ]
}
''';

    for (final model in OpenRouterClient.models) {
      final stopwatch = Stopwatch()..start();
      try {
        debugPrint('==================== [CHEF AGENT: IDEATE MEALS] ====================');
        debugPrint('🚀 MODEL REQUESTED: $model');
        debugPrint('📥 INPUT PROMPT:\n$cavemanPrompt');

        final requestBody = {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': cavemanPrompt,
            }
          ],
          'temperature': 0.5,
          // 2200 tokens with reasoning suppressed: Instant, full recipe JSON generation
          'max_tokens': 2200,
          if (model.contains('nemotron')) 'reasoning': {'effort': 'none'},
        };

        final response = await http.post(
          Uri.parse(OpenRouterClient.baseUrl),
          headers: OpenRouterClient.defaultHeaders,
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 55));

        stopwatch.stop();
        debugPrint('⏱️ LATENCY: ${stopwatch.elapsedMilliseconds}ms | HTTP STATUS: ${response.statusCode}');
        debugPrint('📋 FULL RAW OPENROUTER OUTPUT:\n${response.body}');
        debugPrint('====================================================================');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final finishReason = data['choices']?[0]?['finish_reason'];
          final usage = data['usage'];
          debugPrint('[ChefAgent:ideateMeals] finish_reason: $finishReason | usage: $usage');

          final content = data['choices']?[0]?['message']?['content'] as String?;

          if (content != null && content.isNotEmpty) {
            final cleanedContent = content
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();

            final decoded = jsonDecode(cleanedContent);
            if (decoded is Map<String, dynamic> && decoded.containsKey('recipes')) {
              final list = decoded['recipes'] as List<dynamic>;
              final parsed = list.map((e) => MealRecipe.fromJson(e as Map<String, dynamic>)).toList();
              if (parsed.isNotEmpty) return parsed;
            } else if (decoded is List) {
              final parsed = decoded.map((e) => MealRecipe.fromJson(e as Map<String, dynamic>)).toList();
              if (parsed.isNotEmpty) return parsed;
            } else if (decoded is Map<String, dynamic>) {
              return [MealRecipe.fromJson(decoded)];
            }
          }
        }
      } catch (e) {
        debugPrint('[ChefAgent:ideateMeals] Error with model $model: $e');
        // Fallback to next candidate model
      }
    }

    throw Exception('Unable to generate AI recipes. Please check your internet connection or try again.');
  }

  static Future<ChatMessage> chatWithChefAgent({
    required List<ChatMessage> conversationHistory,
    required List<GroceryItem> inventory,
    required Map<String, dynamic> userProfile,
    bool allowQuickDelivery = true,
    DeliveryHorizon? deliveryHorizon,
    List<String>? recentDishesToAvoid,
    int maxCookTimeMinutes = 20,
    String? mealSlot,
    String? currentPrompt,
  }) async {
    final dietPreference = userProfile['dietPreference'] ?? 'Veg';
    final householdSize = userProfile['householdSize'] ?? '2';
    final appliances = userProfile['appliances'] ?? 'Gas Stove, Kadai / Pan';
    final exclusions = userProfile['exclusions'] ?? '';

    final effectiveHorizon = deliveryHorizon ?? (allowQuickDelivery ? DeliveryHorizon.quick : DeliveryHorizon.inPantry);

    String deliveryConstraintText = '';
    switch (effectiveHorizon) {
      case DeliveryHorizon.inPantry:
        deliveryConstraintText = 'STRICT IN-PANTRY ONLY (0 min restock. MUST use only in-stock inventory. missingItems MUST be empty []).';
        break;
      case DeliveryHorizon.quick:
        deliveryConstraintText = 'QUICK COMMERCE ALLOWED (10-15 mins. User can get 1-2 minor missing fresh items delivered via Blinkit/Zepto in 10-15 mins. Put these in missingItems).';
        break;
      case DeliveryHorizon.hyperlocal:
        deliveryConstraintText = 'STANDARD HYPERLOCAL DELIVERY (30-45 mins. User can order standard missing ingredients if needed. Put these in missingItems).';
        break;
      case DeliveryHorizon.flexible:
        deliveryConstraintText = 'FLEXIBLE RESTOCK (User has ample delivery time and is open to buying any missing ingredients).';
        break;
    }

    final avoidSection = (recentDishesToAvoid != null && recentDishesToAvoid.isNotEmpty)
        ? '- RECENTLY COOKED DISHES TO EXCLUDE (STRICT VARIETY FILTER):\n'
          '  The user specifically does NOT want to repeat dishes they already cooked recently. STRICTLY DO NOT suggest any of these dishes or direct variations: ${recentDishesToAvoid.join(', ')}\n'
        : '';

    final presentItems = inventory
        .where((item) => item.isAdded || item.quantity > 0)
        .map((item) => '${item.nameEn} (${item.quantity} x ${item.selectedUnit})')
        .toList();

    final systemPrompt = '''
YOU ARE KICHOOK KITCHEN CHEF AGENT, an intelligent, conversational culinary co-pilot for Indian and global home cooking.

KITCHEN PROFILE & ACTIVE CONSTRAINTS:
- Target Meal Slot: ${mealSlot != null && mealSlot.isNotEmpty ? mealSlot : 'Any'}
- Max Prep & Cook Time: $maxCookTimeMinutes Mins
- Diet: $dietPreference
- Household Servings: $householdSize People
- Available Cookware/Appliances: $appliances
- Exclusions & Allergies: ${exclusions.isEmpty ? 'None' : exclusions}
- Delivery Horizon: $deliveryConstraintText
$avoidSection- UNIVERSAL ESSENTIALS: Water (Tap, Drinking, Warm, Boiling Water) and Ice are ALWAYS in infinite supply. NEVER put "Water" or "Ice" in "missingItems" or ask user to buy water.

LIVE KITCHEN PANTRY INVENTORY:
${presentItems.isEmpty ? 'EMPTY PANTRY (No stocked ingredients in kitchen yet).' : presentItems.join('\n')}

INSTRUCTIONS:
1. Converse naturally, warmly, and helpfully like a Michelin-starred chef who respects Indian kitchen habits and practical constraints.
2. INTENT & RECIPE DISPATCH RULES (STRICT RECIPE-ON-DEMAND ONLY):
   - A. GENERAL INQUIRIES, PANTRY CHECKS & IDEATION (DEFAULT MODE):
     * When user asks "what can I cook?", "what can I make?", "dinner ideas", "what do I have?", "how to use my rice?", or asks for meal brainstorming:
       -> DO NOT GENERATE FULL RECIPE CARDS. Set "recipes": [].
       -> In "message", warmly analyze their available pantry inventory and propose 3-4 distinct, appetizing dish possibilities with a 1-line concept of each (e.g. "1. Jeera Rice: Quick fragrant rice using your stocked Basmati Rice & Ghee. 2. Ghee Khichdi: Hearty comfort one-pot meal...").
       -> In "suggestions", provide direct action chips allowing user to tap for the full recipe (e.g. ["Show recipe for Jeera Rice", "Show recipe for Ghee Khichdi", "Show recipe for Pulao"]).
   - B. EXPLICIT RECIPE REQUESTS (FULL RECIPE MODE):
     * ONLY produce a recipe in the "recipes" array if the user EXPLICITLY asks to cook, see, or follow a recipe (e.g. "How to cook X", "Give me recipe for X", "Show recipe for X", "Show steps for X", "How do I make X?", "I want to make X", "Give full recipe", "Recipe for X").
     * When explicitly requested, output EXACTLY 1 complete, high-detail recipe in "recipes" with ingredientsWithQuantities, usedInventory, missingItems, substitutions, cavemanSteps, macros, and chefTip.
   - C. CULINARY TIPS, MODIFICATIONS & KITCHEN ADVICE:
     * If user asks culinary questions, substitutions, storage tips, or setting updates ("how to store paneer?", "can I use butter instead of ghee?", "change diet to Non-Veg"):
       -> Answer directly in "message", set "recipes": [], and give 3 helpful follow-up suggestion chips.
3. STRICT MISSING ITEMS & INVENTORY FORMAT:
   - "ingredientsWithQuantities": Full detailed measurement strings.
   - "missingItems": ONLY clean raw product names without quantities, units, or prep verbs.
   - "usedInventory": ONLY clean raw product names of in-stock items used.
4. CULINARY REALISM & COOKING STEPS LOCK:
   - All raw ingredients (raw rice, millets, dry lentils, rajma, chana, potatoes, vegetables) MUST include their proper real-world cooking methods (e.g. "Wash rice, add 2 cups water, cover and simmer on low for 12 mins until fluffy" or "Pressure cook soaked rajma for 4 whistles until soft"). NEVER write impossible steps like tossing raw uncooked rice into a pan without boiling or cooking liquid!
5. Always provide 3-4 short, relevant follow-up "suggestions" chips.
6. CONCISE SINGLE RECIPE RULE: When proposing an explicit recipe, output exactly 1 complete recipe. Keep instructions direct and actionable so all cooking steps, ingredients, and macros completely finish within the token budget.
7. TOKEN BUDGET LOCK: Your ENTIRE JSON response (message + recipes + suggestions combined) MUST be compact and complete. Keep "message" under 150 words. Keep each cooking step to 1-2 short sentences. Keep "chefTip" to 1 sentence. NEVER leave any JSON array or object incomplete. If you are running long, shorten "cavemanSteps" descriptions rather than omitting steps entirely.

OUTPUT FORMAT MUST BE VALID JSON ONLY (NO MARKDOWN CODEBLOCKS):
{
  "message": "Conversational reply text here...",
  "recipes": [
    {
      "dishName": "Dish Name (or empty array [] if just answering a question)",
      "prepTime": "15 Mins",
      "servings": "$householdSize People",
      "dietType": "$dietPreference",
      "macros": {
        "calories": "380 kcal",
        "protein": "20g",
        "carbs": "45g",
        "fat": "12g"
      },
      "ingredientsWithQuantities": [
        "200g Paneer (Cubed)",
        "1 tsp Cumin Seeds",
        "1 tbsp Ghee",
        "1/2 tsp Salt"
      ],
      "usedInventory": ["Paneer", "Cumin Seeds", "Ghee"],
      "missingItems": [],
      "substitutions": [],
      "cavemanSteps": [
        "Heat ghee in pan. Splutter cumin seeds.",
        "Add paneer cubes. Sauté 3 mins till golden.",
        "Season with salt and spices. Serve hot."
      ],
      "chefTip": "Soak paneer in warm water for 5 mins for extra softness."
    }
  ],
  "suggestions": [
    "What can I make for dinner?",
    "Suggest a 15m option",
    "How to air fry?"
  ]
}
''';

    final List<Map<String, String>> messagesPayload = [
      {'role': 'system', 'content': systemPrompt},
    ];

    final historySlice = conversationHistory.length > 6
        ? conversationHistory.sublist(conversationHistory.length - 6)
        : conversationHistory;

    for (final msg in historySlice) {
      messagesPayload.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    if (currentPrompt != null && currentPrompt.trim().isNotEmpty) {
      if (messagesPayload.isEmpty || messagesPayload.last['content'] != currentPrompt) {
        messagesPayload.add({
          'role': 'user',
          'content': currentPrompt,
        });
      }
    }

    debugPrint('📥 MESSAGES SENT TO OPENROUTER (${messagesPayload.length}):');
    for (int i = 0; i < messagesPayload.length; i++) {
      debugPrint('   [$i ${messagesPayload[i]['role']?.toUpperCase()}]: ${messagesPayload[i]['content']}');
    }

    for (final model in OpenRouterClient.models) {
      final stopwatch = Stopwatch()..start();
      try {
        final requestBody = {
          'model': model,
          'messages': messagesPayload,
          'temperature': 0.5,
          // PREVIOUS LOGIC - COMMENTED OUT: 2200 tokens caused truncated JSON (cooking steps cut off mid-array)
          // 'max_tokens': 2200,
          // New: 3500 tokens gives headroom for complete recipe JSON (message + 1 recipe + suggestions ~2800 tokens)
          'max_tokens': 3500,
          if (model.contains('nemotron')) 'reasoning': {'effort': 'none'},
        };

        if (!model.contains('gemma')) {
          requestBody['response_format'] = {'type': 'json_object'};
        }

        debugPrint('==================== [CHEF AGENT: CHAT] ====================');
        debugPrint('🚀 MODEL REQUESTED: $model');

        final response = await http.post(
          Uri.parse(OpenRouterClient.baseUrl),
          headers: OpenRouterClient.defaultHeaders,
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 55));

        stopwatch.stop();
        debugPrint('⏱️ LATENCY: ${stopwatch.elapsedMilliseconds}ms | HTTP STATUS: ${response.statusCode}');
        debugPrint('📋 FULL RAW OPENROUTER OUTPUT:\n${response.body}');
        debugPrint('============================================================');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final finishReason = data['choices']?[0]?['finish_reason'];
          final usage = data['usage'];
          debugPrint('[ChefAgent:chatWithChefAgent] finish_reason: $finishReason | usage: $usage');

          if (finishReason == 'length') {
            debugPrint('[ChefAgent:chatWithChefAgent] WARNING: Model hit max_tokens limit!');
          }

          final content = data['choices']?[0]?['message']?['content'] as String?;

          if (content != null && content.isNotEmpty) {
            String cleaned = content
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();

            Map<String, dynamic>? decodedMap;

            dynamic safeJsonDecode(String snippet) {
              try {
                return jsonDecode(snippet);
              } catch (_) {
                try {
                  final fixedQuotes = snippet.split('\n').map((line) {
                    int quoteCount = '"'.allMatches(line).length;
                    if (quoteCount % 2 != 0) {
                      if (line.trim().endsWith(',')) {
                        final commaIdx = line.lastIndexOf(',');
                        return '${line.substring(0, commaIdx)}",';
                      } else {
                        return '$line"';
                      }
                    }
                    return line;
                  }).join('\n');

                  final sanitized = fixedQuotes
                      .replaceAll(RegExp(r',\s*\]'), ']')
                      .replaceAll(RegExp(r',\s*\}'), '}');
                  return jsonDecode(sanitized);
                } catch (_) {
                  return null;
                }
              }
            }

            final direct = safeJsonDecode(cleaned);
            if (direct is Map) {
              decodedMap = Map<String, dynamic>.from(direct);
            }

            if (decodedMap == null && cleaned.contains('{') && cleaned.contains('}')) {
              final firstBrace = cleaned.indexOf('{');
              final lastBrace = cleaned.lastIndexOf('}');
              if (firstBrace != -1 && lastBrace > firstBrace) {
                final jsonSnippet = cleaned.substring(firstBrace, lastBrace + 1);
                final parsed = safeJsonDecode(jsonSnippet);
                if (parsed is Map) {
                  decodedMap = Map<String, dynamic>.from(parsed);
                }
              }
            }

            if (decodedMap != null) {
              final messageText = decodedMap['message']?.toString() ?? 'Here are your chef recommendations:';
              List<MealRecipe> recipes = [];
              if (decodedMap['recipes'] is List) {
                final list = decodedMap['recipes'] as List;
                for (final r in list) {
                  if (r is Map) {
                    recipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(r)));
                  }
                }
              } else if (decodedMap['dishName'] != null) {
                recipes.add(MealRecipe.fromJson(decodedMap));
              }

              List<String> suggestions = [];
              if (decodedMap['suggestions'] is List) {
                suggestions = (decodedMap['suggestions'] as List)
                    .map((s) => s.toString().trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
              } else {
                suggestions = [
                  'Make it quicker',
                  'How to adjust spice?',
                  'Suggest an alternative',
                ];
              }

              return ChatMessage(
                id: 'agent_${DateTime.now().microsecondsSinceEpoch}',
                role: MessageRole.assistant,
                content: messageText,
                recipes: recipes,
                suggestions: suggestions,
              );
            } else {
              debugPrint('[ChefAgent:chatWithChefAgent] Incomplete/Unparsable JSON from $model. Failing over to next candidate model...');
              // If there are more models to try, continue the loop
              continue;
            }
          }
        }
      } catch (e) {
        debugPrint('[ChefAgent:chatWithChefAgent] Error calling model $model: $e');
        // Fallback to next model
      }
    }

    // Polished, user-friendly fallback if all providers fail or truncate (Zero broken JSON shown)
    return ChatMessage(
      id: 'agent_${DateTime.now().microsecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: 'I started putting this recipe together for you, but the connection timed out before the full steps were finished. Tap below to regenerate the complete recipe!',
      recipes: const [],
      suggestions: const [
        'Regenerate full recipe',
        'Suggest a quicker dish',
        'What else can I make with my pantry?',
      ],
    );
  }
}
