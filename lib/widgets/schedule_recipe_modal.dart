import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/meal_calendar_event.dart';
import '../services/neon_db_service.dart';
import '../services/auth_service.dart';
import '../services/openrouter_service.dart';
import 'tactile_tap.dart';

class ScheduleRecipeModal extends StatefulWidget {
  final MealRecipe recipe;

  const ScheduleRecipeModal({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  static void show(BuildContext context, MealRecipe recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => ScheduleRecipeModal(recipe: recipe),
    );
  }

  @override
  _ScheduleRecipeModalState createState() => _ScheduleRecipeModalState();
}

class _ScheduleRecipeModalState extends State<ScheduleRecipeModal> {
  DateTime selectedDate = DateTime.now();
  CalendarMealSlot selectedSlot = CalendarMealSlot.dinner;
  int servings = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Schedule "${widget.recipe.dishName}"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Prep Time: ${widget.recipe.prepTime}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Meal Slot',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: CalendarMealSlot.values.map((slot) {
              final isSelected = selectedSlot == slot;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: TactileTap(
                    onTap: () => setState(() => selectedSlot = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(slot.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            slot.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Date (Next 7 Days)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (ctx, idx) {
                final date = DateTime.now().add(Duration(days: idx));
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TactileTap(
                    onTap: () => setState(() => selectedDate = date),
                    child: Container(
                      width: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F172A) : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? const Color(0xFF0F172A) : AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            idx == 0 ? 'TODAY' : AppDateUtils.formatShortWeekday(date),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
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
          const SizedBox(height: 20),
          TactileTap(
            onTap: () async {
              final session = await AuthService.getActiveUserSession();
              final event = MealCalendarEvent(
                id: 'cal_${DateTime.now().microsecondsSinceEpoch}',
                // PREVIOUS DEFAULT USER ID: user_kichook_primary
                userId: session['id'] ?? 'user_lino_primary',
                eventDate: selectedDate,
                mealSlot: selectedSlot,
                dishName: widget.recipe.dishName,
                recipe: widget.recipe,
                servings: servings,
                isCooked: false,
              );
              await NeonDbService.syncMealEventToCloud(event, userId: session['id']);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📅 Scheduled "${widget.recipe.dishName}" for ${AppDateUtils.formatShortDate(selectedDate)} (${selectedSlot.label})!'),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
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
                  'Confirm Schedule',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
