import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../widgets/tactile_tap.dart';

class TemplateDetailScreen extends StatelessWidget {
  final SavedListTemplate template;
  final Function(SavedListTemplate) onUseTemplate;

  const TemplateDetailScreen({
    super.key,
    required this.template,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: AppTypography.displaySmall(fontSize: 18),
            ),
            Text(
              '${template.items.length} restock items',
              style: AppTypography.bodySmall(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: template.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = template.items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.lgBorder,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadii.mdBorder,
                      ),
                      child: Icon(
                        item.category.icon,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.nameEn,
                      style: AppTypography.bodyLarge(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      item.nameHi,
                      style: AppTypography.bodySmall(),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadii.mdBorder,
                      ),
                      child: Text(
                        '${item.quantity} x ${item.selectedUnit}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TactileTap(
                  onTap: () {
                    onUseTemplate(template);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadii.mdBorder,
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_checkout_rounded, color: AppColors.textWhite, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'USE THIS TEMPLATE TO SHOP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
