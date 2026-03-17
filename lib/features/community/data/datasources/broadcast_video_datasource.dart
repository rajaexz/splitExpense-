import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../data/models/group_model.dart';
import '../../../../core/utils/app_logger.dart';

abstract class BroadcastVideoDataSource {
  Future<String> broadcastVideoToGroup(String groupId, File videoFile, {bool sendIndividually = false});
  Future<String> broadcastVideoToMembers(String groupId, List<String> memberIds, File videoFile);
  Future<String> uploadVideo(File videoFile, String groupId);
}

class BroadcastVideoDataSourceImpl implements BroadcastVideoDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  BroadcastVideoDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _auth = auth,
        _storage = storage;

  @override
  Future<String> broadcastVideoToGroup(
    String groupId,
    File videoFile, {
    bool sendIndividually = false,
  }) async {
    try {
      AppLogger.info(
        'Broadcasting video to group: $groupId (individually: $sendIndividually)',
        tag: 'BROADCAST',
      );

      // Upload video
      final videoUrl = await uploadVideo(videoFile, groupId);

      // Get group members
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final group = GroupModel.fromFirestore(groupDoc);
      final memberIds = group.members.keys.toList();

      if (sendIndividually) {
        // Send to each member individually
        await broadcastVideoToMembers(groupId, memberIds, videoFile);
      } else {
        // Send as group message
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final messageRef = _firestore
            .collection('messages')
            .doc(groupId)
            .collection('messages')
            .doc();

        final messageData = {
          'id': messageRef.id,
          'groupId': groupId,
          'senderId': user.uid,
          'senderName': user.displayName ?? 'Unknown',
          'type': 'video',
          'content': 'Broadcast Video',
          'mediaUrl': videoUrl,
          'isBroadcast': true,
          'createdAt': FieldValue.serverTimestamp(),
          'readBy': <Map<String, dynamic>>[],
        };

        await messageRef.set(messageData);

        // Send push notification to all members
        await _sendBroadcastNotification(groupId, memberIds, 'New broadcast video');
      }

      AppLogger.success('Video broadcasted successfully', tag: 'BROADCAST');
      return videoUrl;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error broadcasting video',
        tag: 'BROADCAST',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<String> broadcastVideoToMembers(
    String groupId,
    List<String> memberIds,
    File videoFile,
  ) async {
    try {
      AppLogger.info('Broadcasting video to ${memberIds.length} members', tag: 'BROADCAST');

      // Upload video once
      final videoUrl = await uploadVideo(videoFile, groupId);

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Send individual messages to each member
      final batch = _firestore.batch();

      for (final memberId in memberIds) {
        if (memberId == user.uid) continue; // Skip sender

        final messageRef = _firestore
            .collection('messages')
            .doc(groupId)
            .collection('messages')
            .doc();

        final messageData = {
          'id': messageRef.id,
          'groupId': groupId,
          'senderId': user.uid,
          'senderName': user.displayName ?? 'Unknown',
          'type': 'video',
          'content': 'Video Message',
          'mediaUrl': videoUrl,
          'recipientId': memberId, // Individual recipient
          'isBroadcast': true,
          'createdAt': FieldValue.serverTimestamp(),
          'readBy': <Map<String, dynamic>>[],
        };

        batch.set(messageRef, messageData);
      }

      await batch.commit();

      // Send push notifications
      await _sendBroadcastNotification(groupId, memberIds, 'New video message');

      AppLogger.success('Video broadcasted to all members', tag: 'BROADCAST');
      return videoUrl;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error broadcasting to members',
        tag: 'BROADCAST',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String groupId) async {
    try {
      AppLogger.info('Uploading video to storage', tag: 'BROADCAST');

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'broadcast_video_$timestamp.mp4';
      final path = 'groups/$groupId/broadcasts/$fileName';

      final ref = _storage.ref().child(path);
      
      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploadedBy': user.uid,
          'groupId': groupId,
          'timestamp': timestamp.toString(),
        },
      );

      final uploadTask = ref.putFile(videoFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.success('Video uploaded successfully', tag: 'BROADCAST');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Error uploading video', tag: 'BROADCAST', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _sendBroadcastNotification(
    String groupId,
    List<String> memberIds,
    String message,
  ) async {
    try {
      // Create notifications for each member
      final batch = _firestore.batch();

      for (final memberId in memberIds) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(memberId)
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'id': notificationRef.id,
          'userId': memberId,
          'type': 'broadcast_video',
          'title': 'New Broadcast Video',
          'body': message,
          'data': {'groupId': groupId},
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      AppLogger.debug('Notifications sent to ${memberIds.length} members', tag: 'BROADCAST');
    } catch (e) {
      AppLogger.warning('Error sending notifications', tag: 'BROADCAST');
    }
  }
}

