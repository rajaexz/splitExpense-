import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Stream<List<NotificationModel>> getUserNotifications(String userId);
  Stream<int> getUnreadNotificationCountStream(String userId);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotificationsForGroup(String groupId, String userId);
  Future<void> sendPaymentReminderNotifications({
    required String senderId,
    required String senderName,
    required String groupId,
    required String groupName,
    required List<String> targetUserIds,
    required String currency,
    required double totalAmount,
    String? upiUri,
  });

  Future<void> sendGameTurnNotification({
    required String groupId,
    required String groupName,
    required String targetUserId,
    required String gameId,
    String? body,
  });

  Future<void> sendGamePaymentReminder({
    required String groupId,
    required String groupName,
    required String targetUserId,
    required String gameId,
    String? body,
  });

  Future<void> sendGamePoke({
    required String groupId,
    required String groupName,
    required String targetUserId,
    required String gameId,
    String? body,
  });

  Future<void> sendGameWinnerAnnouncement({
    required String groupId,
    required String groupName,
    required List<String> memberUserIds,
    required String firstName,
    required String secondName,
    required String thirdName,
    required String gameId,
    String? body,
  });

  Future<void> sendGameCompleteNotification({
    required String groupId,
    required String groupName,
    required List<String> memberUserIds,
    required String gameId,
    String? body,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  @override
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<int> getUnreadNotificationCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    if (snapshot.docs.isNotEmpty) await batch.commit();
  }

  @override
  Future<void> deleteNotificationsForGroup(String groupId, String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('notifications')
        .where('data.groupId', isEqualTo: groupId)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> sendPaymentReminderNotifications({
    required String senderId,
    required String senderName,
    required String groupId,
    required String groupName,
    required List<String> targetUserIds,
    required String currency,
    required double totalAmount,
    String? upiUri,
  }) async {
    if (targetUserIds.isEmpty) return;

    final batch = _firestore.batch();
    final amountStr = '$currency ${totalAmount.toStringAsFixed(2)}';

    for (final userId in targetUserIds) {
      final notificationRef = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('notifications')
          .doc();

      final data = <String, dynamic>{
        'groupId': groupId,
        'groupName': groupName,
        'senderId': senderId,
        'senderName': senderName,
        'amount': totalAmount,
        'currency': currency,
      };
      if (upiUri != null && upiUri.isNotEmpty) {
        data['upiUri'] = upiUri;
      }

      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': userId,
        'type': 'payment_reminder',
        'title': 'Payment Reminder',
        'body': '$senderName is requesting $amountStr. Scan QR to pay.',
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> sendGameTurnNotification({
    required String groupId,
    required String groupName,
    required String targetUserId,
    required String gameId,
    String? body,
  }) async {
    final ref = _firestore
        .collection('notifications')
        .doc(targetUserId)
        .collection('notifications')
        .doc();
    await ref.set({
      'id': ref.id,
      'userId': targetUserId,
      'type': 'game_turn',
      'title': 'Your turn',
      'body': body ?? 'It\'s your turn to ask a question in $groupName.',
      'data': {
        'groupId': groupId,
        'groupName': groupName,
        'gameId': gameId,
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendGamePaymentReminder({
    required String groupId,
    required String groupName,
    required String targetUserId,
    required String gameId,
    String? body,
  }) async {
    final ref = _firestore
        .collection('notifications')
        .doc(targetUserId)
        .collection('notifications')
        .doc();
    await ref.set({
      'id': ref.id,
      'userId': targetUserId,
      'type': 'game_payment',
      'title': 'Complete payment',
      'body': body ??
          'Please complete your payment for the group game in $groupName so everyone can continue.',
      'data': {
        'groupId': groupId,
        'groupName': groupName,
        'gameId': gameId,
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendGamePoke({
    required String groupId,
    required String groupName,
    required String targetUserId,
    required String gameId,
    String? body,
  }) async {
    final ref = _firestore
        .collection('notifications')
        .doc(targetUserId)
        .collection('notifications')
        .doc();
    await ref.set({
      'id': ref.id,
      'userId': targetUserId,
      'type': 'game_poke',
      'title': 'Payment nudge',
      'body': body ??
          'Friendly reminder from $groupName: your share is still waiting. Tap in and save the game!',
      'data': {
        'groupId': groupId,
        'groupName': groupName,
        'gameId': gameId,
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendGameWinnerAnnouncement({
    required String groupId,
    required String groupName,
    required List<String> memberUserIds,
    required String firstName,
    required String secondName,
    required String thirdName,
    required String gameId,
    String? body,
  }) async {
    if (memberUserIds.isEmpty) return;
    final batch = _firestore.batch();
    final resolvedBody = body ??
        'We have our podium: 1st $firstName, 2nd $secondName, 3rd $thirdName. Thanks for playing!';
    for (final userId in memberUserIds.toSet()) {
      final ref = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'id': ref.id,
        'userId': userId,
        'type': 'game_winner',
        'title': 'Game complete',
        'body': resolvedBody,
        'data': {
          'groupId': groupId,
          'groupName': groupName,
          'gameId': gameId,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> sendGameCompleteNotification({
    required String groupId,
    required String groupName,
    required List<String> memberUserIds,
    required String gameId,
    String? body,
  }) async {
    if (memberUserIds.isEmpty) return;
    final batch = _firestore.batch();
    final resolvedBody = body ??
        'The question game in $groupName is finished. Thank you all for playing!';
    for (final userId in memberUserIds.toSet()) {
      final ref = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'id': ref.id,
        'userId': userId,
        'type': 'game_complete',
        'title': 'Thanks everyone',
        'body': resolvedBody,
        'data': {
          'groupId': groupId,
          'groupName': groupName,
          'gameId': gameId,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
