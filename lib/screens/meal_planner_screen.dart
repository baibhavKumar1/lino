import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../models/saved_recipe.dart';
import '../models/chat_message.dart';
import '../models/user_preferences.dart';
import '../services/openrouter_service.dart';
import '../services/neon_db_service.dart';
import '../services/auth_service.dart';
import '../widgets/tactile_tap.dart';
import '../widgets/tune_settings_sheet.dart';
import '../widgets/chat_message_tile.dart';
import '../widgets/meal_planner_top_bar.dart';

class MealPlannerScreen extends StatefulWidget {
  final List<GroceryItem> inventory;
  final Function(List<String>) onAddMissingItemsToList;
  final Function(SavedRecipe)? onSaveRecipe;
  final Function(MealRecipe recipe)? onMealCooked;
  final VoidCallback? onViewSavedPresets;

  const MealPlannerScreen({
    super.key,
    required this.inventory,
    required this.onAddMissingItemsToList,
    this.onSaveRecipe,
    this.onMealCooked,
    this.onViewSavedPresets,
  });

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _userId;
  Map<String, dynamic> _userProfile = {};

  // Session-Level Dynamic Levers
  DeliveryHorizon _deliveryHorizon = DeliveryHorizon.quick;
  MealVarietyOption _mealVariety = MealVarietyOption.lastWeek;
  String _selectedMealSlot = 'Dinner';
  int _maxCookTimeMinutes = 20;

  final Set<String> _savedRecipeIds = {};
  final Set<String> _cookedRecipeIds = {};

  final List<String> _defaultStarterPrompts = [
    'What can I make for dinner in 15 mins?',
    'High-protein quick snack',
    'Suggest a meal with my in-stock items',
    'Low-calorie comfort food',
    'How do I make a quick curry with paneer?',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final session = await AuthService.getActiveUserSession();
    final history = await NeonDbService.fetchChatHistory(userId: session['id']);

    if (mounted) {
      setState(() {
        _userId = session['id'];
        _userProfile = session;
        _isInitializing = false;
        if (history.isNotEmpty) {
          _messages = history;
        } else {
          _messages = [
            ChatMessage(
              id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.assistant,
              content: 'Namaste! 🙏 I am your **Kichook Kitchen Chef** co-pilot.\n\nI tailor meal recommendations based on your in-stock pantry, dietary preferences, and cooking horizon.',
              suggestions: [
                'What can I make for dinner in 15m?',
                'Quick high-protein recipe',
                'Use my in-stock ingredients',
              ],
            ),
          ];
        }
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isLoading) return;

    _textController.clear();
    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: prompt,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _scrollToBottom();
    NeonDbService.saveChatMessage(userMsg, userId: _userId);

    try {
      List<String> recentDishes = [];
      if (_mealVariety != MealVarietyOption.off) {
        recentDishes = await NeonDbService.fetchRecentlyCookedDishes(
          days: _mealVariety.days,
          userId: _userId,
        );
      }

      final reply = await OpenRouterService.chatWithChefAgent(
        conversationHistory: _messages,
        inventory: widget.inventory,
        userProfile: _userProfile,
        deliveryHorizon: _deliveryHorizon,
        recentDishesToAvoid: recentDishes,
        maxCookTimeMinutes: _maxCookTimeMinutes,
        mealSlot: _selectedMealSlot,
        currentPrompt: prompt,
      );

      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isLoading = false;
        });
        _scrollToBottom();
        NeonDbService.saveChatMessage(reply, userId: _userId);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ChatMessage(
          id: 'err_${DateTime.now().microsecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: 'Oops! I encountered an issue connecting to the culinary brain. Please try asking again.',
          suggestions: ['Retry again', 'Quick meal idea'],
        );
        setState(() {
          _messages.add(errorMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _clearConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Fresh Cooking Session?'),
        content: const Text('This will reset the active chat memory with your Chef Agent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear Memory', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NeonDbService.clearChatHistory(userId: _userId);
      setState(() {
        final freshMsg = ChatMessage(
          id: 'welcome_${DateTime.now().microsecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: 'Fresh kitchen session started! What ingredients or meal would you like to explore?',
          suggestions: [
            'What can I make for dinner in 15m?',
            'High-protein quick recipe',
            'Cook with my in-stock items',
          ],
        );
        _messages = [freshMsg];
      });
    }
  }

  void _handleSaveRecipe(MealRecipe recipe, String uniqueKey) {
    final saved = SavedRecipe.fromMealRecipe(recipe);
    if (widget.onSaveRecipe != null) {
      widget.onSaveRecipe!(saved);
    }
    NeonDbService.syncSavedRecipeToCloud(saved);

    setState(() {
      _savedRecipeIds.add(uniqueKey);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Saved "${recipe.dishName}" to your Recipes!',
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  void _handleCookedRecipe(MealRecipe recipe, String uniqueKey) {
    setState(() {
      _cookedRecipeIds.add(uniqueKey);
    });

    // 1. Trigger live inventory auto-depletion in HomeScreen
    widget.onMealCooked?.call(recipe);

    // 2. Persist cooked dish record in Neon DB memory
    Future.microtask(() => NeonDbService.recordCookedDish(
      dishName: recipe.dishName,
      recipeId: recipe.dishName,
      userId: _userId,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Enjoy your meal! "${recipe.dishName}" marked as cooked.',
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  void _showQuickSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TuneSettingsSheet(
        initialProfile: _userProfile,
        initialDeliveryHorizon: _deliveryHorizon,
        initialMealVariety: _mealVariety,
        initialMaxCookTimeMinutes: _maxCookTimeMinutes,
        onProfileUpdated: (diet, size, apps) {
          setState(() {
            _userProfile['dietPreference'] = diet;
            _userProfile['householdSize'] = size;
            _userProfile['appliances'] = apps;
          });
        },
        onDeliveryHorizonChanged: (horizon) {
          setState(() => _deliveryHorizon = horizon);
        },
        onMealVarietyChanged: (variety) {
          setState(() => _mealVariety = variety);
        },
        onMaxCookTimeChanged: (time) {
          setState(() => _maxCookTimeMinutes = time);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /* PREVIOUS FROSTED STACK LAYOUT - COMMENTED OUT AS PER RULE
    return Stack(
      children: [
        Positioned.fill(child: ShaderMask(...)),
        Positioned(top: 0, child: MealPlannerTopBar(...)),
        Positioned(bottom: 0, child: BackdropFilter(...)),
      ],
    );
    */

    return Column(
      children: [
        // 1. TOP WAYFINDER & CONTEXT BANNER (Pure Alpha Edge Dissolve)
        MealPlannerTopBar(
          userProfile: _userProfile,
          deliveryHorizon: _deliveryHorizon,
          mealVariety: _mealVariety,
          maxCookTimeMinutes: _maxCookTimeMinutes,
          onOpenTune: _showQuickSettingsSheet,
          onClearConversation: _clearConversation,
          onMaxCookTimeChanged: (time) => setState(() => _maxCookTimeMinutes = time),
        ),

        // 2. CHAT STREAM (Pure Vertical Alpha ShaderMask Dissolve)
        Expanded(
          child: _isInitializing
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                )
              : ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.04, 0.96, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildThinkingBubble();
                      }
                      final message = _messages[index];
                      return _buildMessageTile(message, index);
                    },
                  ),
                ),
        ),

        // 3. CONTEXTUAL PROMPT SUGGESTION CHIPS (Flat & Clean)
        if (_messages.isNotEmpty && _messages.last.suggestions.isNotEmpty && !_isLoading)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _messages.last.suggestions.length,
              itemBuilder: (context, i) {
                final sug = _messages.last.suggestions[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TactileTap(
                    onTap: () => _sendMessage(sug),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            sug,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else if (_messages.length <= 1 && !_isLoading)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _defaultStarterPrompts.length,
              itemBuilder: (context, i) {
                final sug = _defaultStarterPrompts[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TactileTap(
                    onTap: () => _sendMessage(sug),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            sug,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // 4. BOTTOM INPUT BAR (Flat Cardstock Container, Zero Borders)
        Container(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Chat with Chef (e.g. "I have 20m, leftover dal")...',
                      hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TactileTap(
                onTap: _isLoading ? null : () => _sendMessage(_textController.text),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.soft,
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MESSAGE BUBBLES & EMBEDDED RECIPE CARDS
  // ==========================================
  Widget _buildMessageTile(ChatMessage message, int messageIndex) {
    return ChatMessageTile(
      message: message,
      messageIndex: messageIndex,
      savedRecipeIds: _savedRecipeIds,
      cookedRecipeIds: _cookedRecipeIds,
      onSaveRecipe: _handleSaveRecipe,
      onCookedRecipe: _handleCookedRecipe,
      onAddMissingItems: widget.onAddMissingItemsToList,
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 8),
            Text(
              'Chef is brainstorming recipes...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
