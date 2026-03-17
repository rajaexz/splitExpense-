import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/app_routes.dart';
import '../routing/app_router.dart';

/// Handles navigation when user taps FCM notification.
void handleNotificationNavigation(RemoteMessage message, BuildContext? context) {
  final data = message.data;
  final groupId = data['groupId'] as String?;
  final groupName = data['groupName'] as String? ?? 'Chat';
  final type = data['type'] as String? ?? '';

  if (groupId == null) return;

  final ctx = context ?? AppRouter.navigatorKey.currentContext;
  if (ctx == null) return;

  switch (type) {
    case 'group_message':
      ctx.push('${AppRoutes.chat}/$groupId?name=${Uri.encodeComponent(groupName)}');
      break;
    case 'payment_reminder':
    case 'settle_up_reminder':
    case 'broadcast_video':
    default:
      ctx.push('${AppRoutes.groupDetail}/$groupId');
  }
}
