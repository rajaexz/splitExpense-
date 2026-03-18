import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_routes.dart';

class StartNewGroupButton extends StatelessWidget {
  final bool isDark;

  const StartNewGroupButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push(AppRoutes.createGroup),
      icon: const Icon(Icons.group_add, size: 20),
      label: const Text('Start a new group'),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
        side: BorderSide(color: isDark ? AppColors.textGrey : AppColors.borderGrey),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
