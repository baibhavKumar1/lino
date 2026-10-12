import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/grocery_item.dart';

/// Intent types recognized by Jev System One classifier
enum ChefIntent {
  generalIdeation, // "What can I cook?", "dinner ideas", "what do I have?"
  explicitRecipe,  // "How to make Paneer Butter Masala", "Give me recipe for Dal"
  culinaryAdvice,  // "How to store tomatoes?", "Can I substitute butter for ghee?"
  unrelated,
}

/// Jev System One Client by TypeSafe AI
/// Handles fast (sub-100ms) non-autoregressive classification and decision making.
class JevClassificationService {
  static const String _endpoint = 'https://api.typesafe.ai/v1/systemone';
  static const String apiKey = 'apikey_24475ece411234e48809695f27b080075a1_dcefc1a66f797e64b6b8572de70b2d12d4c667238cf0c00e1773606ef9945980';

  static final Map<String, String> _headers = {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  /// Classifies a raw or sanitized ingredient name into an ItemCategory
  static Future<ItemCategory> classifyGroceryCategory(String itemName) async {
    if (itemName.trim().isEmpty) return ItemCategory.freshProduce;

    try {
      final payload = {
        'model': 'jev-latest',
        'state': {
          'ingredient_name': itemName,
        },
        'questions': {
          'category': {
            'type': 'choice',
            'instructions': 'Classify this grocery or pantry ingredient into its appropriate kitchen inventory category.',
            'options': [
              'freshProduce',
              'kitchenStaples',
              'singleSpices',
              'masalaBlends',
              'pulsesLentils',
              'riceGrains',
              'floursBaking',
              'readyToCook',
              'dryFruitsNuts',
            ],
          },
        },
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answers = data['answers'] as Map<String, dynamic>?;
        final chosenCategory = answers?['category']?['choice'] as String?;

        if (chosenCategory != null) {
          for (final cat in ItemCategory.values) {
            if (cat.name.toLowerCase() == chosenCategory.toLowerCase()) {
              return cat;
            }
          }
        }
      } else {
        debugPrint('[JevClassification] API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[JevClassification] Error classifying item "$itemName": $e');
    }

    return ItemCategory.freshProduce;
  }

  /// Evaluates optimal default packaging unit for an ingredient
  static Future<String> classifyDefaultUnit(String itemName) async {
    if (itemName.trim().isEmpty) return '1 Pack';

    try {
      final payload = {
        'model': 'jev-latest',
        'state': {
          'ingredient_name': itemName,
        },
        'questions': {
          'unit': {
            'type': 'choice',
            'instructions': 'What is the standard retail packaging unit for this kitchen item in supermarkets?',
            'options': [
              '1 kg',
              '500 g',
              '200 g',
              '1 L',
              '500 ml',
              '1 Bunch',
              '4 Pcs',
              '1 Pack',
              '1 Box',
            ],
          },
        },
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answers = data['answers'] as Map<String, dynamic>?;
        final chosenUnit = answers?['unit']?['choice'] as String?;
        if (chosenUnit != null && chosenUnit.isNotEmpty) {
          return chosenUnit;
        }
      }
    } catch (e) {
      debugPrint('[JevClassification] Error predicting unit for "$itemName": $e');
    }

    return '1 Pack';
  }

  /// Classifies user chat messages into explicit intent routes before calling LLMs
  static Future<ChefIntent> classifyUserIntent(String message) async {
    if (message.trim().isEmpty) return ChefIntent.generalIdeation;

    try {
      final payload = {
        'model': 'jev-latest',
        'state': {
          'user_message': message,
        },
        'questions': {
          'intent': {
            'type': 'choice',
            'instructions': 'Classify user prompt into one of the operational intents: explicitRecipe (asking for complete cooking steps/recipe card for a specific dish), generalIdeation (brainstorming what to cook or what ingredients are available), or culinaryAdvice (asking for tips, substitutions, or kitchen hacks).',
            'options': [
              'explicitRecipe',
              'generalIdeation',
              'culinaryAdvice',
              'unrelated',
            ],
          },
        },
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answers = data['answers'] as Map<String, dynamic>?;
        final chosenIntent = answers?['intent']?['choice'] as String?;

        switch (chosenIntent) {
          case 'explicitRecipe':
            return ChefIntent.explicitRecipe;
          case 'generalIdeation':
            return ChefIntent.generalIdeation;
          case 'culinaryAdvice':
            return ChefIntent.culinaryAdvice;
          default:
            return ChefIntent.generalIdeation;
        }
      }
    } catch (e) {
      debugPrint('[JevClassification] Error classifying intent: $e');
    }

    return ChefIntent.generalIdeation;
  }
}
