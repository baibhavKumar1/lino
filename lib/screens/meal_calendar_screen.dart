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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _currentMonthView = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _loadEvents();
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
                        // 1. Custom Dish Input
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

                        // 2. Choose from Saved Recipes
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

                        // 3. Servings Stepper
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

                      MealRecipe? attachedRecipe;
                      if (selectedSavedRecipe != null) {
                        attachedRecipe = selectedSavedRecipe!.recipe;
                      }

                      final newEvent = MealCalendarEvent(
                        id: 'cal_${DateTime.now().microsecondsSinceEpoch}',
                        userId: _userId ?? 'user_kichook_primary',
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
                              '${weeklyMissing.length} ingredients missing for planned week',
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
                                '1-Tap Restock',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
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

            // Section Label for Selected Date
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              color: AppColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
