import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../routing/app_router.dart';
import '../utils/app_logger.dart';
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

  /// Get FCM token (for debugging or manual use).
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        AppLogger.success('FCM token generated: ${token.substring(0, 20)}...', tag: 'FCM');
      } else {
        AppLogger.warning('FCM getToken() returned null', tag: 'FCM');
      }
      return token;
    } catch (e, st) {
      AppLogger.error('FCM getToken failed', tag: 'FCM', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> initialize() async {
    AppLogger.info('Initializing FCM...', tag: 'FCM');

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final permissionGranted = await _requestPermission();
    if (!permissionGranted) {
      AppLogger.warning('Notification permission denied - FCM token may not work', tag: 'FCM');
    }

    await _setupLocalNotifications();

    // Get token immediately (works even without login)
    final token = await getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    } else {
      AppLogger.warning('Could not get FCM token. Check: 1) Real device (not simulator for iOS) 2) google-services.json 3) Firebase Console Cloud Messaging enabled', tag: 'FCM');
    }

    _messaging.onTokenRefresh.listen((_) async {
      AppLogger.info('FCM token refreshed', tag: 'FCM');
      final newToken = await getToken();
      if (newToken != null) await _saveTokenToFirestore(newToken);
    });

    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        AppLogger.info('User logged in, saving FCM token', tag: 'FCM');
        final t = await getToken();
        if (t != null) await _saveTokenToFirestore(t);
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationNavigation(initialMessage, null);
      });
    }

    try {
      await _messaging.subscribeToTopic('all');
    } catch (e) {
      AppLogger.warning('Failed to subscribe to topic: $e', tag: 'FCM');
    }

    AppLogger.success('FCM initialized', tag: 'FCM');
  }

  Future<bool> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      AppLogger.info('Notification permission: ${settings.authorizationStatus}', tag: 'FCM');
      return granted;
    } catch (e) {
      AppLogger.error('Permission request failed', tag: 'FCM', error: e);
      return false;
    }
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
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx == null) return;

      // Try JSON payload (used for payment_reminder with QR data)
      if (payload.startsWith('{')) {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final type = data['type'] as String? ?? '';
        final upiUri = data['upiUri'] as String?;
        final amount = double.tryParse((data['amount'] ?? '').toString()) ?? 0.0;
        if (type == 'payment_reminder' &&
            upiUri != null &&
            upiUri.isNotEmpty &&
            amount > 0) {
          ctx.push(
            AppRoutes.paymentRequestView,
            extra: {
              'upiUri': upiUri,
              'amount': amount,
              'currency': data['currency'] ?? 'INR',
              'senderName': data['senderName'] ?? 'Someone',
              'groupName': data['groupName'],
            },
          );
          return;
        }
      }

      // Legacy pipe-delimited payload
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final type = parts[0];
        final groupId = parts[1];
        final groupName = parts.length >= 3 ? parts[2] : 'Chat';
        if (type == 'group_message') {
          ctx.push(
              '${AppRoutes.chat}/$groupId?name=${Uri.encodeComponent(groupName)}');
        } else {
          ctx.push('${AppRoutes.groupDetail}/$groupId');
        }
      }
    } catch (_) {}
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      AppLogger.debug('FCM token ready but user not logged in - will save on login', tag: 'FCM');
      return;
    }
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppLogger.success('FCM token saved to Firestore for user $userId', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to save FCM token to Firestore', tag: 'FCM', error: e);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final type = data['type'] as String? ?? '';
    final isExpense = type == 'payment_reminder';

    if (notification != null) {
      String payload;
      if (type == 'payment_reminder' &&
          data['upiUri'] != null &&
          (data['upiUri'] as String).isNotEmpty) {
        payload = jsonEncode({
          'type': type,
          'groupId': data['groupId'] ?? '',
          'groupName': data['groupName'] ?? 'Chat',
          'upiUri': data['upiUri'],
          'amount': data['amount']?.toString() ?? '',
          'currency': data['currency'] ?? 'INR',
          'senderName': data['senderName'] ?? 'Someone',
        });
      } else {
        payload = '${data['type']}|${data['groupId']}|${data['groupName'] ?? 'Chat'}';
      }
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
        payload: payload,
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
