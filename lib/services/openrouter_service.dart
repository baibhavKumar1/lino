import 'dart:typed_data';
import '../models/grocery_item.dart';
import '../models/chat_message.dart';
import '../models/user_preferences.dart';
import 'openrouter/meal_recipe.dart';
import 'openrouter/receipt_ocr_service.dart';
import 'openrouter/chef_agent_service.dart';

export 'openrouter/openrouter_client.dart';
export 'openrouter/meal_recipe.dart';
export 'openrouter/receipt_ocr_service.dart';
export 'openrouter/chef_agent_service.dart';
export 'jev_classification_service.dart';

class OpenRouterService {
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
  }) =>
      ChefAgentService.ideateMeals(
        inventory: inventory,
        mealTime: mealTime,
        maxCookTimeMinutes: maxCookTimeMinutes,
        numPeople: numPeople,
        restockTimeMinutes: restockTimeMinutes,
        dietType: dietType,
        exclusions: exclusions,
        heroCraving: heroCraving,
        isPrioritizeExpiring: isPrioritizeExpiring,
        leftoverNotes: leftoverNotes,
        appliances: appliances,
        mealVibe: mealVibe,
        isOnePotOnly: isOnePotOnly,
      );

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
  }) =>
      ChefAgentService.chatWithChefAgent(
        conversationHistory: conversationHistory,
        inventory: inventory,
        userProfile: userProfile,
        allowQuickDelivery: allowQuickDelivery,
        deliveryHorizon: deliveryHorizon,
        recentDishesToAvoid: recentDishesToAvoid,
        maxCookTimeMinutes: maxCookTimeMinutes,
        mealSlot: mealSlot,
        currentPrompt: currentPrompt,
      );

  static Future<List<ScannedReceiptItem>> analyzeReceiptImage(Uint8List imageBytes) =>
      ReceiptOcrService.analyzeReceiptImage(imageBytes);
}
