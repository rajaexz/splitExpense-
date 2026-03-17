import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../../data/models/notification_model.dart';

Future<void> _clearGroupNotifications(
  BuildContext context,
  NotificationRemoteDataSource ds,
  String userId,
  NotificationModel notification,
) async {
  final groupId = notification.groupId;
  if (groupId == null) return;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clear notifications?'),
      content: Text(
        'Remove all notifications for "${notification.groupName ?? 'this group'}"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
  if (confirm == true && context.mounted) {
    await ds.deleteNotificationsForGroup(groupId, userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications cleared')),
      );
    }
  }
}

void _handleNotificationTap(BuildContext context, NotificationModel notification) {
  final groupId = notification.groupId;
  if (groupId == null) return;

  switch (notification.type) {
    case 'group_message':
      context.push(
        '${AppRoutes.chat}/$groupId?name=${Uri.encodeComponent(notification.groupName ?? 'Chat')}',
      );
      break;
    case 'payment_reminder':
      context.push('${AppRoutes.groupDetail}/$groupId');
      break;
    case 'broadcast_video':
      context.push('${AppRoutes.groupDetail}/$groupId');
      break;
    default:
      context.push('${AppRoutes.groupDetail}/$groupId');
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _hasMarkedAllRead = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: SafeArea(
          child: const Center(child: Text('Please login to see notifications')),
        ),
      );
    }

    final notificationDataSource = di.sl<NotificationRemoteDataSource>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<NotificationModel>>(
        stream: notificationDataSource.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final isPermissionError = snapshot.error.toString().contains('PERMISSION_DENIED') ||
                snapshot.error.toString().contains('permission');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      isPermissionError
                          ? 'Permission denied. Deploy Firestore rules:\nfirebase deploy --only firestore:rules'
                          : 'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (!_hasMarkedAllRead && notifications.isNotEmpty) {
            _hasMarkedAllRead = true;
            di.sl<NotificationRemoteDataSource>().markAllAsRead(userId);
          }

          if (notifications.isEmpty) {
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
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: AppFonts.fontSize18,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                isDark: isDark,
                userId: userId,
                onTap: () {
                  notificationDataSource.markAsRead(userId, notification.id);
                  _handleNotificationTap(context, notification);
                },
                onClearGroup: () => _clearGroupNotifications(
                  context,
                  notificationDataSource,
                  userId,
                  notification,
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback? onClearGroup;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.userId,
    required this.onTap,
    this.onClearGroup,
  });

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
                color: isGroupMessage
                    ? AppColors.primaryGreen.withOpacity(0.2)
                    : AppColors.primaryGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGroupMessage ? Icons.group : Icons.notifications,
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
                          '${notification.groupName}',
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
