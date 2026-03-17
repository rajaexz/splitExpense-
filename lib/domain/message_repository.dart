import 'dart:io';

import '../data/models/message_model.dart';

abstract class MessageRepository {
  Future<String> sendTextMessage(String groupId, String content);
  Future<String> sendImageMessageWithUrl(String groupId, String imageUrl, {String? caption});
  Future<String> sendMediaMessage(String groupId, File file, MessageType type);
  Future<String> sendLocationMessage(String groupId, double latitude, double longitude);
  Stream<List<MessageModel>> getMessages(String groupId, {int limit = 50});
  Stream<int> getUnreadCountStream(String groupId, String userId);
  Future<void> markAsRead(String groupId, String messageId, String userId);
  Future<void> deleteMessage(String groupId, String messageId);
  Future<String> broadcastVideo(String groupId, File videoFile, {bool sendIndividually = false});
}
