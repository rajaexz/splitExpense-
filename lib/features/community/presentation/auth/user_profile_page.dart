import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import 'widgets/auth_widgets.dart';

/// Shows another user's profile (read-only). Fetches from Firestore.
class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.textGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load profile',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }
          final doc = snapshot.data;
          final data = doc?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? data?['displayName'] ?? data?['email'] ?? 'User';
          final email = data?['email'] ?? '';
          final photoUrl = data?['avatarUrl'] ?? data?['photoURL'] ?? data?['photoUrl'] as String?;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileAvatarPicker(
                    photoUrl: photoUrl,
                    initial: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                    radius: 56,
                    showCameraOverlay: false,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
