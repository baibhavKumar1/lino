import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_preferences.dart';
import 'tactile_tap.dart';

class TuneSettingsSheet extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  final DeliveryHorizon initialDeliveryHorizon;
  final MealVarietyOption initialMealVariety;
  final int initialMaxCookTimeMinutes;

  final Function(String diet, String size, String appliances) onProfileUpdated;
  final Function(DeliveryHorizon) onDeliveryHorizonChanged;
  final Function(MealVarietyOption) onMealVarietyChanged;
  final Function(int) onMaxCookTimeChanged;

  const TuneSettingsSheet({
    Key? key,
    required this.initialProfile,
    required this.initialDeliveryHorizon,
    required this.initialMealVariety,
    required this.initialMaxCookTimeMinutes,
    required this.onProfileUpdated,
    required this.onDeliveryHorizonChanged,
    required this.onMealVarietyChanged,
    required this.onMaxCookTimeChanged,
  }) : super(key: key);

  @override
  _TuneSettingsSheetState createState() => _TuneSettingsSheetState();
}

class _TuneSettingsSheetState extends State<TuneSettingsSheet> {
  late String currentDiet;
  late int currentSize;
  late List<String> selectedApps;

  late DeliveryHorizon _deliveryHorizon;
  late MealVarietyOption _mealVariety;
  late int _maxCookTimeMinutes;

  final popularAppliances = [
    'Gas Stove',
    'Kadai / Pan',
    'Pressure Cooker',
    'Air Fryer',
    'Microwave',
    'Oven (OTG)',
    'Mixer Grinder',
  ];

  final dietTypes = ['Veg', 'Non-Veg', 'Jain', 'Eggetarian', 'Vegan'];
  final mealSlots = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  @override
  void initState() {
    super.initState();
    currentDiet = widget.initialProfile['dietPreference'] ?? 'Veg';
    currentSize = int.tryParse(widget.initialProfile['householdSize'] ?? '2') ?? 2;
    selectedApps = (widget.initialProfile['appliances'] as String? ?? 'Gas Stove,Kadai / Pan')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    _deliveryHorizon = widget.initialDeliveryHorizon;
    _mealVariety = widget.initialMealVariety;
    _maxCookTimeMinutes = widget.initialMaxCookTimeMinutes;
  }

  Future<void> _syncProfile() async {
    widget.onProfileUpdated(currentDiet, '$currentSize', selectedApps.join(','));
    await AuthService.updatePersonalization(
      dietPreference: currentDiet,
      householdSize: '$currentSize',
      appliances: selectedApps.join(','),
      exclusions: widget.initialProfile['exclusions'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tune Kitchen & Meal Context',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                TactileTap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Changes apply to your next AI Chef request instantly.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // 1. KITCHEN PROFILE TWEAKS
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diet',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentDiet,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            items: dietTypes.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => currentDiet = val);
                                _syncProfile();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cooking For',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TactileTap(
                              onTap: () {
                                if (currentSize > 1) {
                                  setState(() => currentSize--);
                                  _syncProfile();
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.remove_rounded, size: 18, color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                currentSize == 1 ? '1 Person' : '$currentSize People',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ),
                            TactileTap(
                              onTap: () {
                                if (currentSize < 12) {
                                  setState(() => currentSize++);
                                  _syncProfile();
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.add_rounded, size: 18, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 14),

            // 2. COOKWARE & UTENSILS
            const Text(
              'Available Cookware & Utensils',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: popularAppliances.map((app) {
                final isSel = selectedApps.contains(app);
                return TactileTap(
                  onTap: () {
                    setState(() {
                      if (isSel) {
                        if (selectedApps.length > 1) selectedApps.remove(app);
                      } else {
                        selectedApps.add(app);
                      }
                    });
                    _syncProfile();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSel) const Icon(Icons.check_rounded, size: 12, color: AppColors.primaryDark),
                        if (isSel) const SizedBox(width: 4),
                        Text(
                          app,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 14),

            // 3. MEAL CONSTRAINTS
            const Text(
              'Ingredient Scope (Pantry vs Delivery)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TactileTap(
                    onTap: () {
                      setState(() => _deliveryHorizon = DeliveryHorizon.inPantry);
                      widget.onDeliveryHorizonChanged(_deliveryHorizon);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.primary : AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(DeliveryHorizon.inPantry.icon, size: 18, color: _deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.primaryDark : AppColors.textSecondary),
                          const SizedBox(height: 4),
                          Text(
                            'Pantry Only',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _deliveryHorizon == DeliveryHorizon.inPantry ? AppColors.primaryDark : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TactileTap(
                    onTap: () {
                      setState(() => _deliveryHorizon = DeliveryHorizon.quick);
                      widget.onDeliveryHorizonChanged(_deliveryHorizon);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _deliveryHorizon == DeliveryHorizon.quick ? AppColors.warningLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _deliveryHorizon == DeliveryHorizon.quick ? AppColors.warning : AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(DeliveryHorizon.quick.icon, size: 18, color: _deliveryHorizon == DeliveryHorizon.quick ? AppColors.warningDark : AppColors.textSecondary),
                          const SizedBox(height: 4),
                          Text(
                            'Quick Delivery',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _deliveryHorizon == DeliveryHorizon.quick ? AppColors.warningDark : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Variety Preference (Don\'t repeat recipes)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: MealVarietyOption.values.map((variety) {
                final isSel = _mealVariety == variety;
                return TactileTap(
                  onTap: () {
                    setState(() => _mealVariety = variety);
                    widget.onMealVarietyChanged(variety);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          variety.icon,
                          size: 13,
                          color: isSel ? AppColors.primaryDark : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          variety.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Text(
              'Max Cook Time',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [10, 15, 20, 30, 45].map((time) {
                final isSel = _maxCookTimeMinutes == time;
                return TactileTap(
                  onTap: () {
                    setState(() => _maxCookTimeMinutes = time);
                    widget.onMaxCookTimeChanged(time);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      '${time}m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? AppColors.primaryDark : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
