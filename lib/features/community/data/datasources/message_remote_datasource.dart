import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/utils/app_logger.dart';

abstract class MessageRemoteDataSource {
  Future<String> sendTextMessage(String groupId, String content);
  Future<String> sendImageMessageWithUrl(String groupId, String imageUrl, {String? caption});
  Future<String> sendMediaMessage(String groupId, File file, MessageType type);
  Future<String> sendLocationMessage(String groupId, double latitude, double longitude);
  Stream<List<MessageModel>> getMessages(String groupId, {int limit = 50});
  Stream<int> getUnreadCountStream(String groupId, String userId);
  Future<void> markAsRead(String groupId, String messageId, String userId);
  Future<void> deleteMessage(String groupId, String messageId);
  Future<String> uploadMedia(File file, String groupId, MessageType type);
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  MessageRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _auth = auth,
        _storage = storage;

  @override
  Future<String> sendTextMessage(String groupId, String content) async {
    try {
      AppLogger.info('Sending text message to group: $groupId', tag: 'MESSAGE');
      
      final messageRef = _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .doc();
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final messageData = {
        'id': messageRef.id,
        'groupId': groupId,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'type': MessageType.text.name,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <Map<String, dynamic>>[],
      };
      
      await messageRef.set(messageData);
      _sendMessageNotifications(groupId, user.displayName ?? 'Unknown', content, MessageType.text);
      AppLogger.success('Message sent successfully: ${messageRef.id}', tag: 'MESSAGE');
      return messageRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error sending message', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> sendImageMessageWithUrl(String groupId, String imageUrl, {String? caption}) async {
    try {
      AppLogger.info('Sending image message (ImgBB) to group: $groupId', tag: 'MESSAGE');

      final messageRef = _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .doc();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageData = {
        'id': messageRef.id,
        'groupId': groupId,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'type': MessageType.image.name,
        'content': caption ?? 'Photo',
        'mediaUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <Map<String, dynamic>>[],
      };

      await messageRef.set(messageData);
      _sendMessageNotifications(groupId, user.displayName ?? 'Unknown', caption ?? 'Photo', MessageType.image);
      AppLogger.success('Image message sent successfully', tag: 'MESSAGE');
      return messageRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error sending image message', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> sendMediaMessage(String groupId, File file, MessageType type) async {
    try {
      AppLogger.info('Sending media message to group: $groupId', tag: 'MESSAGE');
      
      // Upload media to Firebase Storage
      final mediaUrl = await uploadMedia(file, groupId, type);
      
      // Send message with media URL
      final messageRef = _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .doc();
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final messageData = {
        'id': messageRef.id,
        'groupId': groupId,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'type': type.name,
        'content': type == MessageType.image ? 'Photo' : 'Video',
        'mediaUrl': mediaUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <Map<String, dynamic>>[],
      };
      
      await messageRef.set(messageData);
      final contentLabel = type == MessageType.image ? 'Photo' : 'Video';
      _sendMessageNotifications(groupId, user.displayName ?? 'Unknown', contentLabel, type);
      AppLogger.success('Media message sent successfully', tag: 'MESSAGE');
      return messageRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error sending media message', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> sendLocationMessage(String groupId, double latitude, double longitude) async {
    try {
      AppLogger.info('Sending location message to group: $groupId', tag: 'MESSAGE');
      
      final messageRef = _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .doc();
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final messageData = {
        'id': messageRef.id,
        'groupId': groupId,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'type': MessageType.location.name,
        'content': 'Location',
        'location': GeoPoint(latitude, longitude),
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <Map<String, dynamic>>[],
      };
      
      await messageRef.set(messageData);
      _sendMessageNotifications(groupId, user.displayName ?? 'Unknown', 'Location', MessageType.location);
      AppLogger.success('Location message sent successfully', tag: 'MESSAGE');
      return messageRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error sending location message', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<MessageModel>> getMessages(String groupId, {int limit = 50}) {
    try {
      AppLogger.debug('Fetching messages for group: $groupId', tag: 'MESSAGE');
      
      return _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList()
            .reversed
            .toList(); // Reverse to show oldest first
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching messages', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      return Stream.value([]);
    }
  }

  @override
  Stream<int> getUnreadCountStream(String groupId, String userId) {
    try {
      return _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) {
        var count = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final senderId = data['senderId'] as String? ?? '';
          if (senderId == userId) continue; // Skip own messages
          final readBy = data['readBy'] as List<dynamic>? ?? [];
          final hasRead = readBy.any((r) =>
              (r is Map && (r['userId'] as String? ?? '') == userId));
          if (!hasRead) count++;
        }
        return count;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching unread count', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      return Stream.value(0);
    }
  }

  @override
  Future<void> markAsRead(String groupId, String messageId, String userId) async {
    try {
      AppLogger.debug('Marking message as read: $messageId', tag: 'MESSAGE');
      
      final messageRef = _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .doc(messageId);
      
      await messageRef.update({
        'readBy': FieldValue.arrayUnion([
          {
            'userId': userId,
            'timestamp': Timestamp.fromDate(DateTime.now()),
          }
        ]),
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error marking message as read', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      AppLogger.info('Deleting message: $messageId', tag: 'MESSAGE');
      
      await _firestore
          .collection('messages')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
      
      AppLogger.success('Message deleted successfully', tag: 'MESSAGE');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting message', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadMedia(File file, String groupId, MessageType type) async {
    try {
      AppLogger.info('Uploading media to storage', tag: 'MESSAGE');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = '${type.name}_$timestamp.$extension';
      final path = 'groups/$groupId/media/$fileName';
      
      // Determine content type based on file extension
      String? contentType;
      if (type == MessageType.image) {
        contentType = 'image/$extension';
      } else if (type == MessageType.video) {
        contentType = 'video/$extension';
      }
      
      final ref = _storage.ref().child(path);
      
      // Create metadata with content type
      final metadata = SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
        customMetadata: {
          'uploadedBy': user.uid,
          'groupId': groupId,
          'type': type.name,
        },
      );
      
      final uploadTask = ref.putFile(file, metadata);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      AppLogger.success('Media uploaded successfully: $downloadUrl', tag: 'MESSAGE');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Error uploading media', tag: 'MESSAGE', error: e, stackTrace: stackTrace);
      
      // Provide helpful error messages
      if (e.toString().contains('object-not-found')) {
        AppLogger.error(
          'Storage bucket not found. Please enable Firebase Storage in Firebase Console:\n'
          '1. Go to Firebase Console → Storage\n'
          '2. Click "Get started" to enable Storage\n'
          '3. Deploy storage rules from storage.rules file\n'
          '4. Wait 30 seconds and restart app',
          tag: 'MESSAGE',
        );
        throw Exception(
          'Firebase Storage is not enabled. Please enable it in Firebase Console and deploy storage rules. '
          'See STORAGE_FIX.md for detailed instructions.',
        );
      } else if (e.toString().contains('permission-denied')) {
        AppLogger.error(
          'Storage permission denied. Please deploy storage rules:\n'
          '1. Go to Firebase Console → Storage → Rules\n'
          '2. Copy content from storage.rules file\n'
          '3. Paste and click Publish\n'
          '4. Wait 30 seconds and restart app',
          tag: 'MESSAGE',
        );
        throw Exception(
          'Storage permission denied. Please deploy storage rules in Firebase Console. '
          'See STORAGE_FIX.md for detailed instructions.',
        );
      }
      
      rethrow;
    }
  }

  Future<void> _sendMessageNotifications(
    String groupId,
    String senderName,
    String content,
    MessageType type,
  ) async {
    try {
      final senderId = _auth.currentUser?.uid;
      if (senderId == null) return;

      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final groupData = groupDoc.data() ?? {};
      final groupName = groupData['name'] as String? ?? 'Group';
      final mainMembers = groupData['members'] as Map<String, dynamic>? ?? {};

      final membersSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .get();

      final memberIds = <String>{...mainMembers.keys};
      for (final doc in membersSnapshot.docs) {
        memberIds.add(doc.id);
      }

      final batch = _firestore.batch();
      for (final memberId in memberIds) {
        if (memberId == senderId) continue;

        final notificationRef = _firestore
            .collection('notifications')
            .doc(memberId)
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'id': notificationRef.id,
          'userId': memberId,
          'type': 'group_message',
          'title': 'New message in $groupName',
          'body': '$senderName: $content',
          'data': {
            'groupId': groupId,
            'groupName': groupName,
            'senderId': senderId,
            'senderName': senderName,
          },
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      AppLogger.debug('Notifications sent to ${memberIds.length - 1} members', tag: 'MESSAGE');
    } catch (e) {
      AppLogger.warning('Failed to send message notifications: $e', tag: 'MESSAGE');
    }
  }
}

