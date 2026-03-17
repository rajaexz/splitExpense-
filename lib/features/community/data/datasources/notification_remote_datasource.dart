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

      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': userId,
        'type': 'payment_reminder',
        'title': 'Payment Reminder',
        'body': '$senderName is requesting $amountStr. Please send the money.',
        'data': {
          'groupId': groupId,
          'groupName': groupName,
          'senderId': senderId,
          'senderName': senderName,
          'amount': totalAmount,
          'currency': currency,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
