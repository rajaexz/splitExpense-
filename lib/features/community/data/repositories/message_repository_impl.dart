import 'dart:io';
import '../datasources/message_remote_datasource.dart';
import '../datasources/broadcast_video_datasource.dart';
import '../../../../data/models/message_model.dart';
import '../../../../domain/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _messageDataSource;
  final BroadcastVideoDataSource _broadcastDataSource;

  MessageRepositoryImpl({
    required MessageRemoteDataSource messageDataSource,
    required BroadcastVideoDataSource broadcastDataSource,
  })  : _messageDataSource = messageDataSource,
        _broadcastDataSource = broadcastDataSource;

  @override
  Future<String> sendTextMessage(String groupId, String content) async {
    return await _messageDataSource.sendTextMessage(groupId, content);
  }

  @override
  Future<String> sendImageMessageWithUrl(String groupId, String imageUrl, {String? caption}) async {
    return await _messageDataSource.sendImageMessageWithUrl(groupId, imageUrl, caption: caption);
  }

  @override
  Future<String> sendMediaMessage(String groupId, File file, MessageType type) async {
    return await _messageDataSource.sendMediaMessage(groupId, file, type);
  }

  @override
  Future<String> sendLocationMessage(String groupId, double latitude, double longitude) async {
    return await _messageDataSource.sendLocationMessage(groupId, latitude, longitude);
  }

  @override
  Stream<List<MessageModel>> getMessages(String groupId, {int limit = 50}) {
    return _messageDataSource.getMessages(groupId, limit: limit);
  }

  @override
  Stream<int> getUnreadCountStream(String groupId, String userId) {
    return _messageDataSource.getUnreadCountStream(groupId, userId);
  }

  @override
  Future<void> markAsRead(String groupId, String messageId, String userId) async {
    return await _messageDataSource.markAsRead(groupId, messageId, userId);
  }

  @override
  Future<void> deleteMessage(String groupId, String messageId) async {
    return await _messageDataSource.deleteMessage(groupId, messageId);
  }

  @override
  Future<String> broadcastVideo(String groupId, File videoFile, {bool sendIndividually = false}) async {
    return await _broadcastDataSource.broadcastVideoToGroup(
      groupId,
      videoFile,
      sendIndividually: sendIndividually,
    );
  }
}

