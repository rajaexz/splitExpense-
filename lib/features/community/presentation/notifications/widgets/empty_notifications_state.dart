import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';

/// Empty state for notifications list.
class EmptyNotificationsState extends StatelessWidget {
  final String? message;

  const EmptyNotificationsState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No notifications yet',
            style: TextStyle(
              fontSize: AppFonts.fontSize18,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
