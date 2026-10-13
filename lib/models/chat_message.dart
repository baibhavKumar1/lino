import 'dart:convert';
import '../services/openrouter_service.dart';

enum MessageRole {
  user('user'),
  assistant('assistant'),
  system('system');

  final String role;
  const MessageRole(this.role);
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final List<MealRecipe> recipes;
  final List<String> suggestions;
  final DateTime createdAt;

  /* PREVIOUS CONSTRUCTOR WITHOUT SESSION ID - COMMENTED OUT AS PER RULE
  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.recipes = const [],
    this.suggestions = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  */

  final String sessionId;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.sessionId = 'default_session',
    this.recipes = const [],
    this.suggestions = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get hasRecipes => recipes.isNotEmpty;

  /* PREVIOUS TOJSON WITHOUT SESSION ID - COMMENTED OUT AS PER RULE
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.role,
      'content': content,
      'recipes': recipes.map((r) => r.toJson()).toList(),
      'suggestions': suggestions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  */

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role.role,
      'content': content,
      'recipes': recipes.map((r) => r.toJson()).toList(),
      'suggestions': suggestions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<MealRecipe> parsedRecipes = [];
    if (json['recipes'] is List) {
      final list = json['recipes'] as List;
      for (final r in list) {
        if (r is Map) {
          parsedRecipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    } else if (json['recipe_json'] != null && json['recipe_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(json['recipe_json'].toString());
        if (decoded is List) {
          for (final r in decoded) {
            if (r is Map) {
              parsedRecipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(r)));
            }
          }
        } else if (decoded is Map) {
          parsedRecipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }

    String cleanContent = json['content'] as String? ?? '';

    List<String> parsedSuggestions = [];
    if (json['suggestions'] != null) {
      parsedSuggestions = List<String>.from(json['suggestions']);
    }

    // Backward-compatibility: If recipes were not in recipes/recipe_json, but raw JSON was stored in content:
    if (parsedRecipes.isEmpty && cleanContent.contains('{') && cleanContent.contains('}')) {
      try {
        final startIndex = cleanContent.indexOf('{');
        final endIndex = cleanContent.lastIndexOf('}');
        if (startIndex != -1 && endIndex > startIndex) {
          final jsonSnippet = cleanContent.substring(startIndex, endIndex + 1);
          final decoded = jsonDecode(jsonSnippet);
          if (decoded is Map) {
            if (decoded['recipes'] is List) {
              for (final r in decoded['recipes'] as List) {
                if (r is Map) {
                  parsedRecipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(r)));
                }
              }
            } else if (decoded['dishName'] != null) {
              parsedRecipes.add(MealRecipe.fromJson(Map<String, dynamic>.from(decoded)));
            }

            if (parsedSuggestions.isEmpty && decoded['suggestions'] is List) {
              parsedSuggestions = (decoded['suggestions'] as List)
                  .map((s) => s.toString().trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }

            if (decoded['message'] != null && decoded['message'].toString().trim().isNotEmpty) {
              cleanContent = decoded['message'].toString().trim();
            } else if (startIndex > 0) {
              cleanContent = cleanContent.substring(0, startIndex).trim();
            }
          }
        }
      } catch (_) {}
    }

    final roleStr = json['role'] as String? ?? 'user';
    final role = MessageRole.values.firstWhere(
      (r) => r.role == roleStr,
      orElse: () => MessageRole.user,
    );

    /* PREVIOUS RETURN WITHOUT SESSION ID - COMMENTED OUT AS PER RULE
    return ChatMessage(
      id: json['id'] as String? ?? 'msg_${DateTime.now().microsecondsSinceEpoch}',
      role: role,
      content: cleanContent,
      recipes: parsedRecipes,
      suggestions: parsedSuggestions,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['created_at'] ?? json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
    */

    return ChatMessage(
      id: json['id'] as String? ?? 'msg_${DateTime.now().microsecondsSinceEpoch}',
      sessionId: json['session_id'] as String? ?? json['sessionId'] as String? ?? 'default_session',
      role: role,
      content: cleanContent,
      recipes: parsedRecipes,
      suggestions: parsedSuggestions,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['created_at'] ?? json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
