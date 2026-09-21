import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_preferences.dart';
import 'tactile_tap.dart';

class MealPlannerTopBar extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final DeliveryHorizon deliveryHorizon;
  final MealVarietyOption mealVariety;
  final int maxCookTimeMinutes;
  final VoidCallback onOpenTune;
  final VoidCallback onClearConversation;
  final ValueChanged<int> onMaxCookTimeChanged;

  const MealPlannerTopBar({
    Key? key,
    required this.userProfile,
    required this.deliveryHorizon,
    required this.mealVariety,
    required this.maxCookTimeMinutes,
    required this.onOpenTune,
    required this.onClearConversation,
    required this.onMaxCookTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentDiet = userProfile['dietPreference'] ?? 'Veg';
    final currentSize = userProfile['householdSize'] ?? '2';
    final appliancesStr = userProfile['appliances'] ?? 'Gas Stove, Kadai / Pan';
    final applianceList = KitchenAppliance.parseList(appliancesStr);

    /* PREVIOUS TWO-ROW LOGIC - COMMENTED OUT AS PER RULE
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(...),
          const SizedBox(height: 6),
          Row(...),
        ],
      ),
    );
    */

    /* PREVIOUS FROSTED GLASS LOGIC - COMMENTED OUT AS PER RULE
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(...),
      ),
    );
    */

    // Clean flat top bar with pure alpha ShaderMask on horizontal pill strip
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      color: Colors.transparent,
      child: Row(
        children: [
          // Scrollable Single Row of Preferences with Edge Alpha Dissolve
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.03, 0.92, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pill 1: Dietary Preference
                        TactileTap(
                          onTap: onOpenTune,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.eco_rounded, size: 12, color: AppColors.primaryDark),
                                const SizedBox(width: 4),
                                Text(
                                  currentDiet,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Pill 2: Household Size
                        TactileTap(
                          onTap: onOpenTune,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_alt_rounded, size: 12, color: AppColors.textPrimary),
                                const SizedBox(width: 4),
                                Text(
                                  currentSize,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Pill 3: Cookware & Appliance Icons
                        TactileTap(
                          onTap: onOpenTune,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: applianceList.map((app) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                  child: Tooltip(
                                    message: app.label,
                                    child: Icon(
                                      app.icon,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Pill 4: Delivery Horizon Window
                        TactileTap(
                          onTap: onOpenTune,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.surface : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.border : AppColors.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  deliveryHorizon.icon,
                                  size: 12,
                                  color: deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.textSecondary : AppColors.warningDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  deliveryHorizon.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.textPrimary : AppColors.warningDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Pill 5: Max Cook Time Dropdown
                        PopupMenuButton<int>(
                          initialValue: maxCookTimeMinutes,
                          onSelected: onMaxCookTimeChanged,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          itemBuilder: (ctx) => [10, 15, 20, 30, 45].map((m) {
                            return PopupMenuItem<int>(
                              value: m,
                              child: Text('$m mins max'),
                            );
                          }).toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '$maxCookTimeMinutes mins',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),

                        // Pill 6: Meal Variety Filter (if active)
                        if (mealVariety != MealVarietyOption.off) ...[
                          const SizedBox(width: 6),
                          TactileTap(
                            onTap: onOpenTune,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(mealVariety.icon, size: 12, color: AppColors.primaryDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    mealVariety.key == 'week' ? 'No Repeats (7d)' : 'No Repeats (30d)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Pinned Right Action Buttons (Quick Tune & New Chat Session)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TactileTap(
                      onTap: onOpenTune,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 5),
                    TactileTap(
                      onTap: onClearConversation,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Tooltip(
                          message: 'New Chat Session',
                          child: Icon(Icons.refresh_rounded, size: 14, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }
}
