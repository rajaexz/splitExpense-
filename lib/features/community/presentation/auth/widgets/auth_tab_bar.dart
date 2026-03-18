import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';

/// Tab bar for Login/Register auth screens.
class AuthTabBar extends StatelessWidget {
  final TabController controller;
  final String loginLabel;
  final String registerLabel;
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;

  const AuthTabBar({
    super.key,
    required this.controller,
    this.loginLabel = 'Login',
    this.registerLabel = 'Register',
    this.onLoginTap,
    this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicatorColor: AppColors.primaryGreen,
      labelColor: AppColors.primaryGreen,
      unselectedLabelColor: AppColors.textBlack,
      labelStyle: const TextStyle(
        fontSize: AppFonts.fontSize16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: AppFonts.fontSize16,
        fontWeight: FontWeight.normal,
      ),
      tabs: [
        Tab(text: loginLabel),
        Tab(text: registerLabel),
      ],
      onTap: (index) {
        if (index == 0) {
          onLoginTap?.call();
        } else {
          onRegisterTap?.call();
        }
      },
    );
  }
}
