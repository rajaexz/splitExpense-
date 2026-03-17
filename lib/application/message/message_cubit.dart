import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';
import '../../domain/message_repository.dart';
import '../../core/utils/app_logger.dart';

part 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  final MessageRepository _repository;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  MessageCubit({
    required MessageRepository repository,
  })  : _repository = repository,
        super(MessageInitial());

  void loadMessages(String groupId) {
    _messagesSubscription?.cancel();
    emit(MessageLoading());
    try {
      AppLogger.info('Loading messages for group: $groupId', tag: 'MESSAGE_CUBIT');
      _messagesSubscription = _repository.getMessages(groupId).listen(
        (messages) {
          if (!isClosed) emit(MessageLoaded(messages));
        },
        onError: (error) {
          if (!isClosed) {
            AppLogger.error('Error loading messages', tag: 'MESSAGE_CUBIT', error: error);
            emit(MessageError(error.toString()));
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error loading messages', tag: 'MESSAGE_CUBIT', error: e, stackTrace: stackTrace);
      emit(MessageError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }

  Future<void> sendTextMessage(String groupId, String content) async {
    try {
      AppLogger.info('Sending text message', tag: 'MESSAGE_CUBIT');
      await _repository.sendTextMessage(groupId, content);
    } catch (e, stackTrace) {
      AppLogger.error('Error sending message', tag: 'MESSAGE_CUBIT', error: e, stackTrace: stackTrace);
      emit(MessageError(e.toString()));
    }
  }

  Future<void> sendImageMessage(String groupId, String imageUrl, {String? caption}) async {
    try {
      AppLogger.info('Sending image message (ImgBB)', tag: 'MESSAGE_CUBIT');
      await _repository.sendImageMessageWithUrl(groupId, imageUrl, caption: caption);
    } catch (e, stackTrace) {
      AppLogger.error('Error sending image', tag: 'MESSAGE_CUBIT', error: e, stackTrace: stackTrace);
      emit(MessageError(e.toString()));
    }
  }

  Future<void> sendMediaMessage(String groupId, File file, MessageType type) async {
    try {
      AppLogger.info('Sending media message', tag: 'MESSAGE_CUBIT');
      await _repository.sendMediaMessage(groupId, file, type);
    } catch (e, stackTrace) {
      AppLogger.error('Error sending media', tag: 'MESSAGE_CUBIT', error: e, stackTrace: stackTrace);
      emit(MessageError(e.toString()));
    }
  }

  Future<void> sendLocationMessage(String groupId, double latitude, double longitude) async {
    try {
      AppLogger.info('Sending location message', tag: 'MESSAGE_CUBIT');
      await _repository.sendLocationMessage(groupId, latitude, longitude);
    } catch (e, stackTrace) {
      AppLogger.error('Error sending location', tag: 'MESSAGE_CUBIT', error: e, stackTrace: stackTrace);
      emit(MessageError(e.toString()));
    }
  }

  Future<void> broadcastVideo(
    String groupId,
    File videoFile, {
    required bool sendIndividually,
  }) async {
    emit(MessageLoading());
    try {
      AppLogger.info('Broadcasting video', tag: 'MESSAGE_CUBIT');
      await _repository.broadcastVideo(
        groupId,
        videoFile,
        sendIndividually: sendIndividually,
      );
      emit(MessageSent());
    } catch (e, stackTrace) {
      AppLogger.error('Error broadcasting video', tag: 'MESSAGE_CUBIT', error: e, stackTrace: stackTrace);
      emit(MessageError(e.toString()));
    }
  }

  Future<void> markAsRead(String groupId, String messageId, String userId) async {
    try {
      await _repository.markAsRead(groupId, messageId, userId);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      await _repository.deleteMessage(groupId, messageId);
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }
}

