import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_fonts.dart';
import 'start_new_group_button.dart';

class EmptyGroupsState extends StatelessWidget {
  final bool isDark;

  const EmptyGroupsState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(fontSize: AppFonts.fontSize18, color: AppColors.textGrey),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first group to get started!',
            style: TextStyle(fontSize: AppFonts.fontSize14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          StartNewGroupButton(isDark: isDark),
        ],
      ),
    );
  }
}
