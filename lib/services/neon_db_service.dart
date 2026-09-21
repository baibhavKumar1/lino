import '../models/grocery_item.dart';
import '../models/saved_recipe.dart';
import '../models/pantry_item.dart';
import '../models/chat_message.dart';
import '../models/meal_calendar_event.dart';

import 'db/neon_connection.dart';
import 'db/inventory_db_service.dart';
import 'db/recipes_db_service.dart';
import 'db/user_db_service.dart';
import 'db/chat_history_db_service.dart';
import 'db/meal_calendar_db_service.dart';

export 'db/neon_connection.dart';
export 'db/inventory_db_service.dart';
export 'db/recipes_db_service.dart';
export 'db/user_db_service.dart';
export 'db/chat_history_db_service.dart';
export 'db/meal_calendar_db_service.dart';

class NeonDbService {
  static Future<void> initDatabase() => NeonConnection.initDatabase();
  static Future<void> closeConnection() => NeonConnection.closeConnection();

  // Pantry & Inventory
  static Future<bool> syncPantryToCloud(List<PantryItem> items, {String? userId}) =>
      InventoryDbService.syncPantryToCloud(items, userId: userId);

  static Future<bool> upsertPantryItemInCloud(PantryItem item, {String? userId}) =>
      InventoryDbService.upsertPantryItemInCloud(item, userId: userId);

  static Future<bool> deletePantryItemFromCloud(String id, {String? userId}) =>
      InventoryDbService.deletePantryItemFromCloud(id, userId: userId);

  static Future<List<PantryItem>> fetchPantryFromCloud({String? userId}) =>
      InventoryDbService.fetchPantryFromCloud(userId: userId);

  static Future<bool> syncInventoryToCloud(List<GroceryItem> items, {String? userId}) =>
      InventoryDbService.syncInventoryToCloud(items, userId: userId);

  static Future<bool> seedGlobalInventoryIfEmpty(List<GroceryItem> defaultCatalog) =>
      InventoryDbService.seedGlobalInventoryIfEmpty(defaultCatalog);

  static Future<List<GroceryItem>> fetchGlobalInventory() =>
      InventoryDbService.fetchGlobalInventory();

  // Recipes & Templates
  static Future<bool> syncTemplateToCloud(SavedListTemplate template, {String? userId}) =>
      RecipesDbService.syncTemplateToCloud(template, userId: userId);

  static Future<bool> syncSavedRecipeToCloud(SavedRecipe recipe, {String? userId}) =>
      RecipesDbService.syncSavedRecipeToCloud(recipe, userId: userId);

  static Future<bool> deleteSavedRecipeFromCloud(String recipeId, {String? userId}) =>
      RecipesDbService.deleteSavedRecipeFromCloud(recipeId, userId: userId);

  static Future<List<SavedRecipe>> fetchSavedRecipesFromCloud({String? userId}) =>
      RecipesDbService.fetchSavedRecipesFromCloud(userId: userId);

  // User & Accounts
  static Future<Map<String, dynamic>?> fetchUserByEmail(String email) =>
      UserDbService.fetchUserByEmail(email);

  static Future<void> registerUserInCloud({
    required String id,
    required String email,
    required String fullName,
    String? photoUrl,
    required String householdName,
    String dietPreference = 'Veg',
    String householdSize = '2',
    String appliances = 'Gas Stove,Kadai / Pan',
    String exclusions = '',
  }) =>
      UserDbService.registerUserInCloud(
        id: id,
        email: email,
        fullName: fullName,
        photoUrl: photoUrl,
        householdName: householdName,
        dietPreference: dietPreference,
        householdSize: householdSize,
        appliances: appliances,
        exclusions: exclusions,
      );

  static Future<void> updateUserProfileInCloud({
    required String email,
    String? fullName,
    String? householdName,
    String? dietPreference,
    String? householdSize,
    String? appliances,
    String? exclusions,
  }) =>
      UserDbService.updateUserProfileInCloud(
        email: email,
        fullName: fullName,
        householdName: householdName,
        dietPreference: dietPreference,
        householdSize: householdSize,
        appliances: appliances,
        exclusions: exclusions,
      );

  static Future<void> updateUserLastLogin(String emailOrUserId) =>
      UserDbService.updateUserLastLogin(emailOrUserId);

  static Future<bool> cleanUserDataForFreshStart() =>
      UserDbService.cleanUserDataForFreshStart();

  // Chat Memory
  static Future<bool> saveChatMessage(ChatMessage message, {String? userId}) =>
      ChatHistoryDbService.saveChatMessage(message, userId: userId);

  static Future<List<ChatMessage>> fetchChatHistory({String? userId, int limit = 40}) =>
      ChatHistoryDbService.fetchChatHistory(userId: userId, limit: limit);

  static Future<bool> clearChatHistory({String? userId}) =>
      ChatHistoryDbService.clearChatHistory(userId: userId);

  static Future<List<String>> fetchRecentlyCookedDishes({int days = 30, String? userId}) =>
      ChatHistoryDbService.fetchRecentlyCookedDishes(days: days, userId: userId);

  static Future<bool> recordCookedDish({
    required String dishName,
    String? recipeId,
    String? userId,
  }) =>
      ChatHistoryDbService.recordCookedDish(
        dishName: dishName,
        recipeId: recipeId,
        userId: userId,
      );

  // Meal Calendar
  static Future<bool> syncMealEventToCloud(MealCalendarEvent event, {String? userId}) =>
      MealCalendarDbService.syncMealEventToCloud(event, userId: userId);

  static Future<bool> deleteMealEventFromCloud(String eventId, {String? userId}) =>
      MealCalendarDbService.deleteMealEventFromCloud(eventId, userId: userId);

  static Future<bool> markMealEventAsCooked(String eventId, bool isCooked, {String? userId}) =>
      MealCalendarDbService.markMealEventAsCooked(eventId, isCooked, userId: userId);

  static Future<List<MealCalendarEvent>> fetchMealCalendarEvents({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      MealCalendarDbService.fetchMealCalendarEvents(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
}
