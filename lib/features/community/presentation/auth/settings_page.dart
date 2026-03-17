import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      ),
      body: FirebaseAuth.instance.currentUser == null
          ? Center(
              child: Text(
                'Please log in',
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.padding16),
              children: [
                _SettingsTile(
                  icon: Icons.history,
                  title: 'Group History',
                  subtitle: 'Deleted groups and members you added',
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.groupHistory),
                ),
              ],
            ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radius12),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.padding16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: AppDimensions.margin16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppFonts.fontSize16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppFonts.fontSize12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textGrey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
