import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/image_upload_service.dart';
import '../../../../application/message/message_cubit.dart';
import '../widgets/message_bubble.dart';
import '../widgets/broadcast_video_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ChatPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<CameraDescription>? _cameras;
  bool _isUploadingImage = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    context.read<MessageCubit>().loadMessages(widget.groupId);
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<MessageCubit>().sendTextMessage(widget.groupId, text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isUploadingImage) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _isUploadingImage = true);
      final imageUrl = await di.sl<ImageUploadService>().uploadImage(File(picked.path));
      if (!mounted) return;

      final caption = _messageController.text.trim();
      context.read<MessageCubit>().sendImageMessage(
            widget.groupId,
            imageUrl,
            caption: caption.isEmpty ? null : caption,
          );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
       appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          // Broadcast Video Button
          BroadcastVideoButton(
            groupId: widget.groupId,
            cameras: _cameras,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Messages List
          Expanded(
            child: BlocConsumer<MessageCubit, MessageState>(
              listenWhen: (prev, curr) => curr is MessageLoaded,
              listener: (context, state) {
                if (state is MessageLoaded && currentUserId != null) {
                  for (final msg in state.messages) {
                    if (msg.senderId != currentUserId &&
                        !msg.readBy.any((r) => r.userId == currentUserId)) {
                      context.read<MessageCubit>().markAsRead(
                            widget.groupId,
                            msg.id,
                            currentUserId,
                          );
                    }
                  }
                }
              },
              buildWhen: (prev, curr) => curr is MessageLoading || curr is MessageLoaded || curr is MessageError,
              builder: (context, state) {
                if (state is MessageLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MessageLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppDimensions.padding16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(
                        message: messages[index],
                        isDark: isDark,
                      );
                    },
                  );
                }

                if (state is MessageError) {
                  return Center(
                    child: Text('Error: ${state.message}'),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(AppDimensions.padding8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderGreyDark : AppColors.borderGrey,
                ),
              ),
            ),
            child: Row(
              children: [
                // Image Attach Button
                IconButton(
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined),
                  onPressed: _isUploadingImage ? null : _pickAndSendImage,
                ),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.backgroundWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radius24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.padding16,
                        vertical: AppDimensions.padding12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                const SizedBox(width: AppDimensions.margin8),

                // Send Button
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.textWhite),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

