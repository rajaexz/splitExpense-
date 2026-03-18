import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                SettingsTile(
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
