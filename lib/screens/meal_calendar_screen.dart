import 'package:flutter/material.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';
import '../models/saved_recipe.dart';
import '../models/meal_calendar_event.dart';
import '../services/openrouter_service.dart';
import '../services/neon_db_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tactile_tap.dart';
import '../widgets/recipe_detail_modal.dart';

class MealCalendarScreen extends StatefulWidget {
  final List<PantryItem> pantryItems;
  final List<GroceryItem> allCatalogItems;
  final List<SavedRecipe> savedRecipes;
  final Function(List<String> missingItems) onAddMissingToCart;
  final Function(MealRecipe recipe) onMealCooked;

  const MealCalendarScreen({
    super.key,
    required this.pantryItems,
    required this.allCatalogItems,
    required this.savedRecipes,
    required this.onAddMissingToCart,
    required this.onMealCooked,
  });

  @override
  State<MealCalendarScreen> createState() => _MealCalendarScreenState();
}

class _MealCalendarScreenState extends State<MealCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonthView = DateTime.now();
  bool _isMonthlyView = false;
  List<MealCalendarEvent> _allEvents = [];
  bool _isLoading = true;
  String? _userId;
  String? _generatingEventId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _currentMonthView = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _loadEvents();
  }

  /// Converts live pantry items to GroceryItem format for OpenRouter culinary agent
  List<GroceryItem> _buildPantryGroceryList() {
    return widget.pantryItems.map<GroceryItem>((p) {
      return GroceryItem(
        id: p.id,
        nameEn: p.name,
        nameHi: p.name,
        category: p.category,
        availableUnits: [p.unit],
        selectedUnit: p.unit,
        quantity: p.quantity,
        isAdded: true,
        /* PREVIOUS GREEN ACCENT - COMMENTED OUT AS PER RULE
        accentColor: const Color(0xFF10B981),
        */
        accentColor: const Color(0xFF0066FF),
      );
    }).toList();
  }

  /// On-demand recipe generation for custom scheduled meal events without an attached recipe
  Future<void> _generateRecipeForEvent(MealCalendarEvent event) async {
    setState(() => _generatingEventId = event.id);
    try {
      final session = await AuthService.getActiveUserSession();
      final dietType = session['dietPreference'] ?? 'Veg';
      final appliances = (session['appliances'] ?? 'Gas Stove,Kadai / Pan').split(',');
      final exclusions = (session['exclusions'] ?? '').split(',').where((e) => e.trim().isNotEmpty).toList();

      final recipes = await OpenRouterService.ideateMeals(
        inventory: _buildPantryGroceryList(),
        mealTime: event.mealSlot.label,
        maxCookTimeMinutes: 25,
        numPeople: event.servings,
        restockTimeMinutes: 15,
        dietType: dietType,
        exclusions: exclusions,
        heroCraving: event.dishName,
        appliances: appliances,
      );

      if (recipes.isNotEmpty) {
        final generatedRecipe = recipes.first;
        final updatedEvent = event.copyWith(
          recipe: generatedRecipe,
          dishName: generatedRecipe.dishName.isNotEmpty ? generatedRecipe.dishName : event.dishName,
        );
        _addOrUpdateEvent(updatedEvent);

        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => RecipeDetailModal(
              recipe: generatedRecipe,
              onSaveRecipe: () {},
              onAddMissingToCart: widget.onAddMissingToCart,
              onCookMeal: () => _toggleCooked(updatedEvent),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not generate recipe at this moment. Please try again!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate recipe: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingEventId = null);
      }
    }
  }

  Future<void> _loadEvents() async {
    final session = await AuthService.getActiveUserSession();
    _userId = session['id'];
    final events = await NeonDbService.fetchMealCalendarEvents(userId: _userId);
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    }
  }

  List<MealCalendarEvent> _getEventsForDate(DateTime date) {
    return _allEvents.where((e) {
      return e.eventDate.year == date.year &&
          e.eventDate.month == date.month &&
          e.eventDate.day == date.day;
    }).toList();
  }

  MealCalendarEvent? _getEventForSlot(DateTime date, CalendarMealSlot slot) {
    final dayEvents = _getEventsForDate(date);
    final match = dayEvents.where((e) => e.mealSlot == slot);
    return match.isNotEmpty ? match.first : null;
  }

  /// Compute missing grocery demand across scheduled recipes in the next 7 days
  List<String> _calculateWeeklyMissingIngredients() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    final upcomingEvents = _allEvents.where((e) {
      return !e.isCooked &&
          e.recipe != null &&
          !e.eventDate.isBefore(today) &&
          !e.eventDate.isAfter(weekEnd);
    }).toList();

    final Set<String> missingAggregated = {};
    final pantryNames = widget.pantryItems.map((p) => p.name.toLowerCase().trim()).toSet();
    final universalStaples = {'water', 'tap water', 'drinking water', 'ice', 'warm water'};

    for (final ev in upcomingEvents) {
      final recipe = ev.recipe!;
      for (final ing in recipe.ingredientsWithQuantities) {
        final rawName = ing.split('(').first.replaceAll(RegExp(r'^\d+[\s\w\/]*\s+'), '').trim();
        final lowerName = rawName.toLowerCase();

        if (universalStaples.contains(lowerName)) continue;

        // Check if item is present in pantry
        final inStock = pantryNames.any((p) => p.contains(lowerName) || lowerName.contains(p));
        if (!inStock) {
          missingAggregated.add(rawName.isNotEmpty ? rawName : ing);
        }
      }
    }

    return missingAggregated.toList();
  }

  void _addOrUpdateEvent(MealCalendarEvent event) {
    setState(() {
      _allEvents.removeWhere((e) => e.id == event.id || (e.eventDate == event.eventDate && e.mealSlot == event.mealSlot));
      _allEvents.add(event);
    });
    NeonDbService.syncMealEventToCloud(event, userId: _userId);
  }

  void _deleteEvent(String eventId) {
    setState(() {
      _allEvents.removeWhere((e) => e.id == eventId);
    });
    NeonDbService.deleteMealEventFromCloud(eventId, userId: _userId);
  }

  void _toggleCooked(MealCalendarEvent event) {
    final updated = event.copyWith(isCooked: !event.isCooked);
    _addOrUpdateEvent(updated);

    if (updated.isCooked && updated.recipe != null) {
      widget.onMealCooked(updated.recipe!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🍳 "${event.dishName}" marked as cooked! Pantry ingredients updated.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /* PREVIOUS SIMPLE PLAN MODAL - COMMENTED OUT AS PER RULE
  void _showPlanMealModal(CalendarMealSlot slot) {
    final dishNameCtrl = TextEditingController();
    int servings = 2;
    SavedRecipe? selectedSavedRecipe;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(slot.icon, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan ${slot.label}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              AppDateUtils.formatFullDate(_selectedDate),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Custom Dish / Dining Plan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: dishNameCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Garlic Tadka Dal, Paneer Paratha, Dining Out',
                            hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) {
                            if (selectedSavedRecipe != null) {
                              setSheetState(() => selectedSavedRecipe = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        if (widget.savedRecipes.isNotEmpty) ...[
                          const Text(
                            'Or Pick From Saved Recipes',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.savedRecipes.length,
                              itemBuilder: (ctx, idx) {
                                final recipe = widget.savedRecipes[idx];
                                final isSelected = selectedSavedRecipe?.id == recipe.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: TactileTap(
                                    onTap: () {
                                      setSheetState(() {
                                        if (isSelected) {
                                          selectedSavedRecipe = null;
                                        } else {
                                          selectedSavedRecipe = recipe;
                                          dishNameCtrl.text = recipe.dishName;
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      width: 140,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryLight : AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.border,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            recipe.dishName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            recipe.prepTime,
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Servings / Portions',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_rounded, size: 16),
                                    onPressed: servings > 1 ? () => setSheetState(() => servings--) : null,
                                  ),
                                  Text(
                                    '$servings People',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    onPressed: servings < 10 ? () => setSheetState(() => servings++) : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
                  child: TactileTap(
                    onTap: () {
                      final dishName = dishNameCtrl.text.trim();
                      if (dishName.isEmpty) return;

                      MealRecipe? attachedRecipe;
                      if (selectedSavedRecipe != null) {
                        attachedRecipe = selectedSavedRecipe!.recipe;
                      }

                      final newEvent = MealCalendarEvent(
                        id: 'cal_${DateTime.now().microsecondsSinceEpoch}',
                        // PREVIOUS USER ID: user_kichook_primary
                        userId: _userId ?? 'user_lino_primary',
                        eventDate: _selectedDate,
                        mealSlot: slot,
                        dishName: dishName,
                        recipeId: selectedSavedRecipe?.id,
                        recipe: attachedRecipe,
                        servings: servings,
                        isCooked: false,
                      );

                      _addOrUpdateEvent(newEvent);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadows.soft,
                      ),
                      child: const Center(
                        child: Text(
                          'Schedule Meal Plan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    */

  bool _isAutoPlanningDay = false;

  /// 1-Tap AI meal plan generator for empty slots in the selected day (Preserves pre-filled slots)
  Future<void> _autoPlanDayWithAi(DateTime targetDate) async {
    final normalizedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final existingEvents = _getEventsForDate(normalizedDate);
    final filledSlots = existingEvents.map((e) => e.mealSlot).toSet();
    final alreadyPlannedDishes = existingEvents.map((e) => e.dishName).where((d) => d.trim().isNotEmpty).toList();

    final targetSlots = [CalendarMealSlot.breakfast, CalendarMealSlot.lunch, CalendarMealSlot.dinner];
    final emptySlots = targetSlots.where((s) => !filledSlots.contains(s)).toList();

    if (emptySlots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All meal slots are already planned for ${AppDateUtils.formatFullDate(targetDate)}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0F172A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isAutoPlanningDay = true);
    try {
      final session = await AuthService.getActiveUserSession();
      final dietType = session['dietPreference'] ?? 'Veg';
      final appliances = (session['appliances'] ?? 'Gas Stove,Kadai / Pan').split(',');
      final exclusions = (session['exclusions'] ?? '').split(',').where((e) => e.trim().isNotEmpty).toList();

      final slotDescriptions = emptySlots.map((s) => s.label).join(', ');
      final contextualExclusions = [...exclusions, ...alreadyPlannedDishes];

      final recipes = await OpenRouterService.ideateMeals(
        inventory: _buildPantryGroceryList(),
        mealTime: 'Plan for empty slots: $slotDescriptions',
        maxCookTimeMinutes: 25,
        numPeople: 2,
        restockTimeMinutes: 15,
        dietType: dietType,
        exclusions: contextualExclusions,
        appliances: appliances,
      );

      if (recipes.isNotEmpty) {
        final List<MealCalendarEvent> newEvents = [];

        for (int i = 0; i < emptySlots.length && i < recipes.length; i++) {
          final slot = emptySlots[i];
          final recipe = recipes[i];
          final event = MealCalendarEvent(
            id: 'cal_${DateTime.now().microsecondsSinceEpoch}_$i',
            userId: _userId ?? 'user_lino_primary',
            eventDate: normalizedDate,
            mealSlot: slot,
            dishName: recipe.dishName,
            recipe: recipe,
            servings: 2,
            isCooked: false,
          );
          newEvents.add(event);
        }

        setState(() {
          for (final ev in newEvents) {
            _allEvents.removeWhere((e) =>
                e.eventDate.year == ev.eventDate.year &&
                e.eventDate.month == ev.eventDate.month &&
                e.eventDate.day == ev.eventDate.day &&
                e.mealSlot == ev.mealSlot);
            _allEvents.add(ev);
          }
        });

        for (final ev in newEvents) {
          NeonDbService.syncMealEventToCloud(ev, userId: _userId);
        }

        if (mounted) {
          final slotNames = emptySlots.map((s) => s.label).join(' and ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ AI generated meals for $slotNames on ${AppDateUtils.formatFullDate(targetDate)}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0F172A),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not auto plan day right now, please try again'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAutoPlanningDay = false);
      }
    }
  }

  void _showPlanMealModal(CalendarMealSlot slot) {
    final dishNameCtrl = TextEditingController();
    int servings = 2;
    SavedRecipe? selectedSavedRecipe;
    MealRecipe? attachedRecipe;
    bool isAiLoading = false;
    List<MealRecipe> aiSuggestions = [];
    String? aiErrorMessage;
    bool hasAutoFetched = false;

    Future<void> fetchAiSuggestions(void Function(void Function()) setSheetState) async {
      setSheetState(() {
        isAiLoading = true;
        aiErrorMessage = null;
      });

      try {
        final session = await AuthService.getActiveUserSession();
        final dietType = session['dietPreference'] ?? 'Veg';
        final appliances = (session['appliances'] ?? 'Gas Stove,Kadai / Pan').split(',');
        final exclusions = (session['exclusions'] ?? '').split(',').where((e) => e.trim().isNotEmpty).toList();

        final recipes = await OpenRouterService.ideateMeals(
          inventory: _buildPantryGroceryList(),
          mealTime: slot.label,
          maxCookTimeMinutes: 20,
          numPeople: servings,
          restockTimeMinutes: 15,
          dietType: dietType,
          exclusions: exclusions,
          appliances: appliances,
        );

        setSheetState(() {
          aiSuggestions = recipes;
          isAiLoading = false;
        });
      } catch (e) {
        setSheetState(() {
          isAiLoading = false;
          // PREVIOUS ERROR STRING WITH DOT - COMMENTED OUT AS PER RULE
          // aiErrorMessage = 'Could not load AI ideas: $e';
          aiErrorMessage = 'Could not load AI ideas, please try again';
        });
      }
    }

    Future<void> generateRecipeForDish(String dishName, void Function(void Function()) setSheetState) async {
      if (dishName.trim().isEmpty) return;

      setSheetState(() {
        isAiLoading = true;
        aiErrorMessage = null;
      });

      try {
        final session = await AuthService.getActiveUserSession();
        final dietType = session['dietPreference'] ?? 'Veg';
        final appliances = (session['appliances'] ?? 'Gas Stove,Kadai / Pan').split(',');
        final exclusions = (session['exclusions'] ?? '').split(',').where((e) => e.trim().isNotEmpty).toList();

        final recipes = await OpenRouterService.ideateMeals(
          inventory: _buildPantryGroceryList(),
          mealTime: slot.label,
          maxCookTimeMinutes: 20,
          numPeople: servings,
          restockTimeMinutes: 15,
          dietType: dietType,
          exclusions: exclusions,
          heroCraving: dishName.trim(),
          appliances: appliances,
        );

        if (recipes.isNotEmpty) {
          setSheetState(() {
            attachedRecipe = recipes.first;
            dishNameCtrl.text = attachedRecipe!.dishName;
            selectedSavedRecipe = null;
            isAiLoading = false;
          });
        } else {
          setSheetState(() {
            isAiLoading = false;
            // PREVIOUS ERROR STRING WITH DOT - COMMENTED OUT AS PER RULE
            // aiErrorMessage = 'Failed to generate recipe for "$dishName".';
            aiErrorMessage = 'Failed to generate recipe for "$dishName"';
          });
        }
      } catch (e) {
        setSheetState(() {
          isAiLoading = false;
          // PREVIOUS ERROR STRING WITH DOT - COMMENTED OUT AS PER RULE
          // aiErrorMessage = 'Error: $e';
          aiErrorMessage = 'Unable to generate recipe right now';
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (!hasAutoFetched) {
            hasAutoFetched = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fetchAiSuggestions(setSheetState);
            });
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: AppShadows.modal,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(slot.icon, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan ${slot.label}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              AppDateUtils.formatFullDate(_selectedDate),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. AI Suggest from Pantry Section
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.accentBlueLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.accentBlue),
                                      const SizedBox(width: 6),
                                      Text(
                                        'AI Chef Ideas for ${slot.label}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TactileTap(
                                    onTap: isAiLoading ? null : () => fetchAiSuggestions(setSheetState),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isAiLoading)
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          else
                                            const Icon(Icons.refresh_rounded, size: 13, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            aiSuggestions.isEmpty ? 'Suggest' : 'Refresh Ideas',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isAiLoading && aiSuggestions.isEmpty) ...[
                                const SizedBox(height: 12),
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        // PREVIOUS TEXT WITH ELLIPSIS - COMMENTED OUT AS PER RULE
                                        // 'Chef Jev is matching your pantry ingredients to create tasty options...',
                                        'Chef Jev is matching your pantry ingredients to create tasty options',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (aiSuggestions.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 108,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: aiSuggestions.length,
                                    itemBuilder: (ctx, idx) {
                                      final suggestion = aiSuggestions[idx];
                                      final isSelected = attachedRecipe?.dishName == suggestion.dishName;

                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: TactileTap(
                                          onTap: () {
                                            setSheetState(() {
                                              if (isSelected) {
                                                attachedRecipe = null;
                                              } else {
                                                attachedRecipe = suggestion;
                                                dishNameCtrl.text = suggestion.dishName;
                                                selectedSavedRecipe = null;
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 160),
                                            width: 160,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.white : AppColors.surface,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected ? AppColors.accentBlue : AppColors.border,
                                                width: isSelected ? 1.8 : 1,
                                              ),
                                              boxShadow: isSelected ? AppShadows.sm : null,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  suggestion.dishName,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      suggestion.prepTime,
                                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                                    ),
                                                    if (isSelected)
                                                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accentBlue)
                                                    else
                                                      const Text(
                                                        'Tap to select',
                                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.accentBlue),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              if (aiErrorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  aiErrorMessage!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.danger),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 2. Custom Dish Input & Instant AI Recipe Generator
                        const Text(
                          'Custom Dish / Craving',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: dishNameCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Garlic Tadka Dal, Paneer Paratha, Chicken Curry',
                            hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (text) {
                            setSheetState(() {
                              if (selectedSavedRecipe != null) selectedSavedRecipe = null;
                              if (attachedRecipe != null && attachedRecipe!.dishName != text.trim()) {
                                attachedRecipe = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        // "Generate Recipe for This Dish" Button
                        TactileTap(
                          onTap: (isAiLoading || dishNameCtrl.text.trim().isEmpty)
                              ? null
                              : () => generateRecipeForDish(dishNameCtrl.text, setSheetState),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                            decoration: BoxDecoration(
                              color: dishNameCtrl.text.trim().isNotEmpty
                                  ? AppColors.primaryLight
                                  : AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: dishNameCtrl.text.trim().isNotEmpty
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isAiLoading && attachedRecipe == null) ...[
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Chef is cooking up full recipe...',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  ),
                                ] else ...[
                                  const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primaryDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    attachedRecipe != null
                                        ? 'Recipe Generated & Attached'
                                        : '✨ Generate Complete Recipe & Steps with AI',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: dishNameCtrl.text.trim().isNotEmpty ? AppColors.primaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // 3. Attached Recipe Banner (Shows when recipe is attached)
                        if (attachedRecipe != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 6),
                                        Text(
                                          attachedRecipe!.dishName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TactileTap(
                                      onTap: () {
                                        setSheetState(() => attachedRecipe = null);
                                      },
                                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${attachedRecipe!.prepTime} • ${attachedRecipe!.macros?.calories ?? "Balanced"}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                                    ),
                                    TactileTap(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => RecipeDetailModal(
                                            recipe: attachedRecipe!,
                                            onSaveRecipe: () {},
                                            onAddMissingToCart: widget.onAddMissingToCart,
                                            onCookMeal: () {},
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF86EFAC)),
                                        ),
                                        child: const Text(
                                          'Preview Recipe',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // 4. Choose from Saved Recipes
                        if (widget.savedRecipes.isNotEmpty) ...[
                          const Text(
                            'Or Pick From Saved Recipes',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 94,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.savedRecipes.length,
                              itemBuilder: (ctx, idx) {
                                final recipe = widget.savedRecipes[idx];
                                final isSelected = selectedSavedRecipe?.id == recipe.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: TactileTap(
                                    onTap: () {
                                      setSheetState(() {
                                        if (isSelected) {
                                          selectedSavedRecipe = null;
                                          attachedRecipe = null;
                                        } else {
                                          selectedSavedRecipe = recipe;
                                          attachedRecipe = recipe.recipe;
                                          dishNameCtrl.text = recipe.dishName;
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      width: 140,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryLight : AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.border,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            recipe.dishName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            recipe.prepTime,
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 5. Servings Stepper
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Servings / Portions',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_rounded, size: 16),
                                    onPressed: servings > 1 ? () => setSheetState(() => servings--) : null,
                                  ),
                                  Text(
                                    '$servings People',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    onPressed: servings < 10 ? () => setSheetState(() => servings++) : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
                  child: TactileTap(
                    onTap: () {
                      final dishName = dishNameCtrl.text.trim();
                      if (dishName.isEmpty) return;

                      final finalRecipe = attachedRecipe ?? selectedSavedRecipe?.recipe;

                      final newEvent = MealCalendarEvent(
                        id: 'cal_${DateTime.now().microsecondsSinceEpoch}',
                        userId: _userId ?? 'user_lino_primary',
                        eventDate: _selectedDate,
                        mealSlot: slot,
                        dishName: dishName,
                        recipeId: selectedSavedRecipe?.id,
                        recipe: finalRecipe,
                        servings: servings,
                        isCooked: false,
                      );

                      _addOrUpdateEvent(newEvent);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Center(
                        child: Text(
                          attachedRecipe != null ? 'Schedule Meal Plan (With Recipe)' : 'Schedule Meal Plan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weeklyMissing = _calculateWeeklyMissingIngredients();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER & WEEK RESTOCK ACTION
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // View Segmented Toggle (Week / Month)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                TactileTap(
                                  onTap: () => setState(() => _isMonthlyView = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: !_isMonthlyView ? const Color(0xFF0F172A) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.view_week_rounded,
                                          size: 13,
                                          color: !_isMonthlyView ? Colors.white : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Week',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: !_isMonthlyView ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TactileTap(
                                  onTap: () => setState(() {
                                    _isMonthlyView = true;
                                    _currentMonthView = DateTime(_selectedDate.year, _selectedDate.month, 1);
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _isMonthlyView ? const Color(0xFF0F172A) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_month_rounded,
                                          size: 13,
                                          color: _isMonthlyView ? Colors.white : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Month',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _isMonthlyView ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Today jump button
                          TactileTap(
                            onTap: () => setState(() {
                              _selectedDate = today;
                              _currentMonthView = DateTime(today.year, today.month, 1);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.today_rounded, size: 14, color: AppColors.primaryDark),
                                  SizedBox(width: 4),
                                  Text(
                                    'Today',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 2. Weekly Demand Alert & 1-Tap Restock
                  if (weeklyMissing.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.warningDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${weeklyMissing.length} ingredients missing for week',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.warningDark),
                            ),
                          ),
                          TactileTap(
                            onTap: () {
                              widget.onAddMissingToCart(weeklyMissing);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🛒 Added ${weeklyMissing.length} missing week items to cart!'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF0F172A),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warningDark,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Restock',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. CALENDAR VIEW (Month Grid or Week Ribbon)
            if (_isMonthlyView)
              _buildMonthCalendarView(today)
            else
              // HORIZONTAL DATE RIBBON (14 Days)
              Container(
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: 14,
                  itemBuilder: (ctx, idx) {
                    // -3 days in past to +10 days in future
                    final date = today.add(Duration(days: idx - 3));
                    final isSelected = date.year == _selectedDate.year &&
                        date.month == _selectedDate.month &&
                        date.day == _selectedDate.day;
                    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                    final dayEvents = _getEventsForDate(date);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TactileTap(
                        onTap: () => setState(() => _selectedDate = date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 52,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F172A) : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : isToday
                                      ? AppColors.primary
                                      : AppColors.border,
                              width: isToday && !isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppDateUtils.formatShortWeekday(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white70
                                      : isToday
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (dayEvents.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${dayEvents.length}',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Section Label for Selected Date & 1-Tap AI Auto-Plan Action
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              color: AppColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.formatFullDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_getEventsForDate(_selectedDate).length} Planned',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TactileTap(
                    onTap: _isAutoPlanningDay ? null : () => _autoPlanDayWithAi(_selectedDate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAutoPlanningDay)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            _isAutoPlanningDay ? 'Planning Day' : '✨ AI Auto-Plan Day',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. DAILY MEAL SLOTS LIST (Breakfast, Lunch, Snacks, Dinner)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      children: CalendarMealSlot.values.map((slot) {
                        final event = _getEventForSlot(_selectedDate, slot);
                        return _buildMealSlotCard(slot, event);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern monthly grid calendar with month navigation and meal count badges
  Widget _buildMonthCalendarView(DateTime today) {
    final firstDayOfMonth = DateTime(_currentMonthView.year, _currentMonthView.month, 1);
    final lastDayOfMonth = DateTime(_currentMonthView.year, _currentMonthView.month + 1, 0);

    // Monday as first day of week: (1=Mon..7=Sun -> offset 0..6)
    final startOffset = (firstDayOfMonth.weekday - 1) % 7;
    final totalDays = lastDayOfMonth.day;
    final totalCells = ((startOffset + totalDays + 6) ~/ 7) * 7;

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          // Month navigation bar (< August 2026 >)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TactileTap(
                onTap: () {
                  setState(() {
                    _currentMonthView = DateTime(_currentMonthView.year, _currentMonthView.month - 1, 1);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textPrimary),
                ),
              ),
              Text(
                AppDateUtils.formatMonthYear(_currentMonthView),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TactileTap(
                onTap: () {
                  setState(() {
                    _currentMonthView = DateTime(_currentMonthView.year, _currentMonthView.month + 1, 1);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Weekday letters row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) {
              return SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // 7-column Date Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (ctx, idx) {
              final cellDate = firstDayOfMonth.subtract(Duration(days: startOffset)).add(Duration(days: idx));
              final isCurrentMonth = cellDate.month == _currentMonthView.month;
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final dayEvents = _getEventsForDate(cellDate);

              return TactileTap(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(cellDate.year, cellDate.month, cellDate.day);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : isToday
                            ? AppColors.primaryLight.withValues(alpha: 0.5)
                            : isCurrentMonth
                                ? AppColors.surfaceMuted
                                : AppColors.surfaceMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : isToday
                              ? AppColors.primary
                              : AppColors.borderLight,
                      width: isToday && !isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${cellDate.day}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isCurrentMonth
                                  ? (isToday ? AppColors.primaryDark : AppColors.textPrimary)
                                  : AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                      if (dayEvents.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${dayEvents.length}',
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.primaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlotCard(CalendarMealSlot slot, MealCalendarEvent? event) {
    final isPlanned = event != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlanned && event.isCooked ? const Color(0xFF86EFAC) : AppColors.border,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(slot.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      slot.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (isPlanned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cooked toggle
                      TactileTap(
                        onTap: () => _toggleCooked(event),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: event.isCooked ? const Color(0xFFDCFCE7) : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: event.isCooked ? const Color(0xFF16A34A) : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                event.isCooked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 13,
                                color: event.isCooked ? const Color(0xFF16A34A) : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.isCooked ? 'Cooked' : 'Mark Cooked',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: event.isCooked ? const Color(0xFF16A34A) : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textSecondary),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteEvent(event.id),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: isPlanned
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.dishName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: event.isCooked ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: event.isCooked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (event.recipe != null) ...[
                            const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(event.recipe!.prepTime, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 10),
                          ],
                          const Icon(Icons.people_outline_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text('${event.servings} Servings', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      if (event.recipe != null) ...[
                        const SizedBox(height: 10),
                        TactileTap(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => RecipeDetailModal(
                                recipe: event.recipe!,
                                onSaveRecipe: () {},
                                onAddMissingToCart: widget.onAddMissingToCart,
                                onCookMeal: () => _toggleCooked(event),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book_rounded, size: 13, color: AppColors.primaryDark),
                                SizedBox(width: 4),
                                Text(
                                  'View Recipe & Steps',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        TactileTap(
                          onTap: _generatingEventId == event.id ? null : () => _generateRecipeForEvent(event),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_generatingEventId == event.id) ...[
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    // PREVIOUS TEXT WITH ELLIPSIS - COMMENTED OUT AS PER RULE
                                    // 'Generating recipe...',
                                    'Generating recipe',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  ),
                                ] else ...[
                                  const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primaryDark),
                                  const SizedBox(width: 5),
                                  const Text(
                                    '✨ Generate Recipe with AI',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : TactileTap(
                    onTap: () => _showPlanMealModal(slot),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Plan ${slot.label}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
