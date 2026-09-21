import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenRouterClient {
  static const String apiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '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',
  );
  static const String baseUrl = String.fromEnvironment(
    'OPENROUTER_BASE_URL',
    defaultValue: 'https://openrouter.ai/api/v1/chat/completions',
  );

  // Fast Verified 100% Free Zero-Cost ($0.00) Live Endpoints on OpenRouter:
  static const List<String> models = [
    'google/gemma-4-26b-a4b-it:free',
    'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
    'openrouter/free',
    'thinkingmachines/inkling-small:free',
  ];

  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
    'HTTP-Referer': 'https://kichook.app',
    'X-Title': 'Kichook Smart Kitchen Assistant',
  };

  static Future<http.Response> postChatCompletion({
    required List<Map<String, dynamic>> messages,
    String? preferredModel,
    double temperature = 0.4,
    int? maxTokens,
  }) async {
    final candidateModels = preferredModel != null
        ? [preferredModel, ...models.where((m) => m != preferredModel)]
        : models;

    http.Response? lastResponse;
    for (final model in candidateModels) {
      final stopwatch = Stopwatch()..start();
      try {
        final body = {
          'model': model,
          'messages': messages,
          'temperature': temperature,
          if (maxTokens != null) 'max_tokens': maxTokens,
          if (model.contains('nemotron')) 'reasoning': {'effort': 'none'},
        };

        debugPrint('==================== [OPENROUTER API CALL] ====================');
        debugPrint('🚀 MODEL REQUESTED: $model');

        final response = await http.post(
          Uri.parse(baseUrl),
          headers: defaultHeaders,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 55));

        stopwatch.stop();
        debugPrint('⏱️ LATENCY: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('📊 HTTP STATUS: ${response.statusCode}');
        debugPrint('📋 FULL RAW OPENROUTER OUTPUT:\n${response.body}');
        debugPrint('===============================================================');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastResponse = response;
      } catch (e) {
        stopwatch.stop();
        debugPrint('⚠️ [OpenRouterClient] Model $model failed after ${stopwatch.elapsedMilliseconds}ms: $e');
        // Fallback to next model
      }
    }

    if (lastResponse != null) {
      return lastResponse;
    }
    throw Exception('Failed to communicate with OpenRouter across all candidate models.');
  }
}
