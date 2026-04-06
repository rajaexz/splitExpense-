import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_fonts.dart';
import '../../../../../data/models/notification_model.dart';

/// Tile for displaying a single notification.
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onClearGroup;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.isDark,
    required this.onTap,
    this.onClearGroup,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'group_message':
        return Icons.group;
      case 'game_turn':
        return Icons.quiz_outlined;
      case 'game_payment':
        return Icons.payment_outlined;
      case 'game_poke':
        return Icons.nightlight_round;
      case 'game_winner':
        return Icons.emoji_events_outlined;
      case 'game_complete':
        return Icons.celebration_outlined;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroupMessage = notification.type == 'group_message';

    return GestureDetector(
      onTap: notification.groupId != null ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.margin12),
        padding: const EdgeInsets.all(AppDimensions.padding16),
        decoration: BoxDecoration(
          color: notification.read
              ? (isDark ? AppColors.darkCard : AppColors.backgroundGrey)
              : (isDark ? AppColors.darkCard : AppColors.primaryGreen.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          border: !notification.read
              ? Border.all(color: AppColors.primaryGreen.withOpacity(0.3))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGroupMessage ? Icons.group : _iconForType(notification.type),
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDimensions.margin12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.groupName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          notification.groupName!,
                          style: TextStyle(
                            fontSize: AppFonts.fontSize12,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (notification.groupId != null && onClearGroup != null)
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: onClearGroup,
                tooltip: 'Clear all notifications for this group',
              ),
          ],
        ),
      ),
    );
  }
}
