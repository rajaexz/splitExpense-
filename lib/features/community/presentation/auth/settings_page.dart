import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/fcm_service.dart';
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
                if (di.sl.isRegistered<FcmService>())
                  SettingsTile(
                    icon: Icons.notifications_active,
                    title: 'FCM Token (Debug)',
                    subtitle: 'Tap to copy token for push notifications',
                    isDark: isDark,
                    onTap: () => _showFcmToken(context, isDark),
                  ),
              ],
            ),
    );
  }

  Future<void> _showFcmToken(BuildContext context, bool isDark) async {
    final fcm = di.sl<FcmService>();
    final token = await fcm.getToken();
    if (!context.mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get FCM token. Check console logs. Use real device for iOS.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM token copied to clipboard')),
      );
    }
  }
}
