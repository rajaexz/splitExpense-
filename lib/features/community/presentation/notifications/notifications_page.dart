import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/error_state_with_action.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../../data/models/notification_model.dart';
import 'widgets/notifications_widgets.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            return ErrorStateWithAction(
              message: isPermissionError
                  ? 'Permission denied. Deploy Firestore rules:\nfirebase deploy --only firestore:rules'
                  : 'Error: ${snapshot.error}',
            );
          }

          final notifications = snapshot.data ?? [];

          if (!_hasMarkedAllRead && notifications.isNotEmpty) {
            _hasMarkedAllRead = true;
            di.sl<NotificationRemoteDataSource>().markAllAsRead(userId);
          }

          if (notifications.isEmpty) {
            return const EmptyNotificationsState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                notification: notification,
                isDark: isDark,
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
