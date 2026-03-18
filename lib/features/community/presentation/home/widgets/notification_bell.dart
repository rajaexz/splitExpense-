import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/di/injection_container.dart' as di;
import '../../../../../../core/constants/app_routes.dart';
import '../../../data/datasources/notification_remote_datasource.dart';

class NotificationBell extends StatelessWidget {
  final bool isDark;
  final String? userId;

  const NotificationBell({super.key, required this.isDark, this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return IconButton(
        icon: Icon(
          Icons.notifications_outlined,
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
        ),
        onPressed: () => context.push(AppRoutes.messages),
      );
    }
    final notificationDs = di.sl<NotificationRemoteDataSource>();
    return StreamBuilder<int>(
      stream: notificationDs.getUnreadNotificationCountStream(userId!),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
              onPressed: () => context.push(AppRoutes.messages),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
