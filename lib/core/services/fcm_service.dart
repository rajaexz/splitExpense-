import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_routes.dart';
import '../routing/app_router.dart';
import 'notification_navigation.dart';

/// Handles Firebase Cloud Messaging for push notifications.
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Chat and expense notifications',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('fuck_sound_effect'),
  );

  Future<void> initialize() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermission();
    await _setupLocalNotifications();
    await _saveToken();

    _messaging.onTokenRefresh.listen((_) => _saveToken());
    _auth.authStateChanges().listen((user) async {
      if (user != null) await _saveToken();
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationNavigation(initialMessage, null);
      });
    }

    await _messaging.subscribeToTopic('all');
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _handlePayloadNavigation(response.payload!);
        }
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  void _handlePayloadNavigation(String payload) {
    try {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final type = parts[0];
        final groupId = parts[1];
        final groupName = parts.length >= 3 ? parts[2] : 'Chat';
        final ctx = AppRouter.navigatorKey.currentContext;
        if (ctx != null) {
          if (type == 'group_message') {
            ctx.push(
                '${AppRoutes.chat}/$groupId?name=${Uri.encodeComponent(groupName)}');
          } else {
            ctx.push('${AppRoutes.groupDetail}/$groupId');
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToken() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final type = data['type'] as String? ?? '';
    final isExpense = type == 'payment_reminder';

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('fuck_sound_effect'),
          ),
        ),
        payload: '${data['type']}|${data['groupId']}|${data['groupName'] ?? 'Chat'}',
      );

      if (isExpense) {
        _playExpenseSound();
      }
    }
  }

  Future<void> _playExpenseSound() async {
    try {
      await _audioPlayer.play(AssetSource('sound/fuck-sound-effect.mp3'));
    } catch (_) {}
  }

  void _handleNotificationTap(RemoteMessage message) {
    handleNotificationNavigation(message, null);
  }
}
