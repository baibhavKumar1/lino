import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../services/openrouter_service.dart';
import 'embedded_recipe_card.dart';
import 'markdown_text.dart';

class ChatMessageTile extends StatelessWidget {
  final ChatMessage message;
  final int messageIndex;
  final Set<String> savedRecipeIds;
  final Set<String> cookedRecipeIds;
  final Function(MealRecipe recipe, String uniqueKey) onSaveRecipe;
  final Function(MealRecipe recipe, String uniqueKey) onCookedRecipe;
  final Function(List<String> missingItems) onAddMissingItems;

  const ChatMessageTile({
    Key? key,
    required this.message,
    required this.messageIndex,
    required this.savedRecipeIds,
    required this.cookedRecipeIds,
    required this.onSaveRecipe,
    required this.onCookedRecipe,
    required this.onAddMissingItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(2)),
          ),
          /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
          child: Text(
            message.content,
            style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
          ),
          */
          child: MarkdownText(
            message.content,
            style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
            boldStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
          ),
        ),
      );
    }

    // Assistant Message with optional embedded recipe cards
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chef Header & Avatar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  */
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.soup_kitchen_rounded, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Kichook Chef',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Conversational text bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16).copyWith(topLeft: const Radius.circular(2)),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35),
              ),
              */
              child: MarkdownText(
                message.content,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35),
                boldStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.35),
              ),
            ),

            // Embedded Recipe Cards
            if (message.hasRecipes) ...[
              const SizedBox(height: 10),
              ...message.recipes.asMap().entries.map((entry) {
                final recipeIndex = entry.key;
                final recipe = entry.value;
                final recipeKey = '${message.id}_recipe_$recipeIndex';
                final isSaved = savedRecipeIds.contains(recipeKey);
                final isCooked = cookedRecipeIds.contains(recipeKey);

                return EmbeddedRecipeCard(
                  recipe: recipe,
                  uniqueKey: recipeKey,
                  isSaved: isSaved,
                  isCooked: isCooked,
                  onSave: () => onSaveRecipe(recipe, recipeKey),
                  onCooked: () => onCookedRecipe(recipe, recipeKey),
                  onAddMissingItems: onAddMissingItems,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
