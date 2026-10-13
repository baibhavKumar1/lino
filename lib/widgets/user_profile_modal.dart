import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'tactile_tap.dart';

class UserProfileModal extends StatefulWidget {
  final Map<String, String?> userProfile;
  final int inStockCount;
  final int savedRecipesCount;
  final Function(Map<String, String?> updatedProfile) onProfileUpdated;

  const UserProfileModal({
    super.key,
    required this.userProfile,
    required this.inStockCount,
    required this.savedRecipesCount,
    required this.onProfileUpdated,
  });

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  late Map<String, String?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = Map<String, String?>.from(widget.userProfile);
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _profile['fullName'] ?? 'Chef';
    final email = _profile['email'] ?? 'Account';
    final photoUrl = _profile['photoUrl'];
    String currentDiet = _profile['dietPreference'] ?? 'Veg';
    String currentSize = _profile['householdSize'] ?? '2';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Profile Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                /* PREVIOUS GREEN AVATAR BACKGROUND - COMMENTED OUT AS PER RULE
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                */
                backgroundColor: AppColors.primaryLight,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'L',
                        /* PREVIOUS GREEN AVATAR TEXT - COMMENTED OUT AS PER RULE
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                        */
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // DIETARY PREFERENCE SELECTOR (Personalization)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadii.lgBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DIETARY PREFERENCE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentDiet,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Veg', 'Non-Veg', 'Jain', 'Eggetarian', 'Vegan'].map((diet) {
                    final isSel = currentDiet == diet;
                    return TactileTap(
                      onTap: () async {
                        setState(() {
                          _profile['dietPreference'] = diet;
                        });
                        widget.onProfileUpdated(_profile);
                        await AuthService.updatePersonalization(
                          dietPreference: diet,
                          householdSize: currentSize,
                          appliances: _profile['appliances'] ?? 'Gas Stove,Kadai / Pan',
                          exclusions: _profile['exclusions'] ?? '',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          diet,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Household Size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HOUSEHOLD MEMBERS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          TactileTap(
                            onTap: () async {
                              final currentVal = int.tryParse(currentSize) ?? 2;
                              if (currentVal > 1) {
                                final newVal = '${currentVal - 1}';
                                setState(() => _profile['householdSize'] = newVal);
                                widget.onProfileUpdated(_profile);
                                await AuthService.updatePersonalization(
                                  dietPreference: currentDiet,
                                  householdSize: newVal,
                                  appliances: _profile['appliances'] ?? 'Gas Stove,Kadai / Pan',
                                  exclusions: _profile['exclusions'] ?? '',
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.remove_rounded, size: 16, color: AppColors.textPrimary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              currentSize == '1' ? '1 Person' : '$currentSize People',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                          TactileTap(
                            onTap: () async {
                              final currentVal = int.tryParse(currentSize) ?? 2;
                              final newVal = '${currentVal + 1}';
                              setState(() => _profile['householdSize'] = newVal);
                              widget.onProfileUpdated(_profile);
                              await AuthService.updatePersonalization(
                                dietPreference: currentDiet,
                                householdSize: newVal,
                                appliances: _profile['appliances'] ?? 'Gas Stove,Kadai / Pan',
                                exclusions: _profile['exclusions'] ?? '',
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.add_rounded, size: 16, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.inStockCount}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const Text(
                        'In Stock Items',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.savedRecipesCount}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const Text(
                        'Saved Recipes',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Privacy Policy button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TactileTap(
              onTap: () async {
                final uri = Uri.parse('https://baibhavkumar1.github.io/lino/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Log out button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TactileTap(
              onTap: () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/auth');
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.6)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
