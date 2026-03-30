import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../application/group/group_cubit.dart';
import '../../../../core/widgets/error_state_with_action.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../application/message/message_cubit.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/constants/app_colors.dart';
import 'widgets/chat_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ChatPage({super.key, required this.groupId, required this.groupName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<CameraDescription>? _cameras;
  bool _isUploadingImage = false;
  final _imagePicker = ImagePicker();
  late final GroupCubit _groupCubit;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    context.read<MessageCubit>().loadMessages(widget.groupId);
    _groupCubit = di.sl<GroupCubit>();
    _groupCubit.loadGroup(widget.groupId);
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
    // Avoid closing DI-owned cubit instances.
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

    return BlocProvider.value(
      value: _groupCubit,
      child: Scaffold(
        backgroundColor: AppColors.stemBackground,
        body: SafeArea(
          child: Column(
            children: [
              _StemChatHeader(
                groupName: widget.groupName,
                groupId: widget.groupId,
                onBack: () => Navigator.pop(context),
                cameras: _cameras,
              ),
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
                        return const EmptyChatMessagesState();
                      }

                      final displayItems = _buildDisplayItems(messages);

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          if (item.isDateMarker) {
                            return _DateMarker(label: item.dateLabel!);
                          }
                          final msg = item.message!;
                          return MessageBubble(
                            message: msg,
                            isDark: isDark,
                            groupId: widget.groupId,
                            onDelete: msg.senderId == currentUserId
                                ? () => context
                                    .read<MessageCubit>()
                                    .deleteMessage(widget.groupId, msg.id)
                                : null,
                          );
                        },
                      );
                    }

                    if (state is MessageError) {
                      return ErrorStateWithAction(message: 'Error: ${state.message}');
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
              ChatInputBar(
                messageController: _messageController,
                isDark: isDark,
                isUploadingImage: _isUploadingImage,
                onSend: _sendMessage,
                onPickImage: _pickAndSendImage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ChatDisplayItem> _buildDisplayItems(List<MessageModel> messages) {
    final items = <_ChatDisplayItem>[];
    DateTime? lastDay;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    for (final msg in messages) {
      final created = msg.createdAt;
      final dayOnly = DateTime(created.year, created.month, created.day);
      if (lastDay == null || lastDay != dayOnly) {
        final formatted = DateFormat('MMM d').format(created);
        final markerLabel =
            dayOnly == todayOnly ? 'Today, $formatted' : formatted;
        items.add(_ChatDisplayItem.date(label: markerLabel));
        lastDay = dayOnly;
      }
      items.add(_ChatDisplayItem.message(message: msg));
    }

    return items;
  }
}

class _ChatDisplayItem {
  final MessageModel? message;
  final String? dateLabel;

  _ChatDisplayItem._({this.message, this.dateLabel});

  bool get isDateMarker => dateLabel != null;

  factory _ChatDisplayItem.date({required String label}) =>
      _ChatDisplayItem._(dateLabel: label);
  factory _ChatDisplayItem.message({required MessageModel message}) =>
      _ChatDisplayItem._(message: message);
}

class _DateMarker extends StatelessWidget {
  final String label;

  const _DateMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.stemCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.borderGreyDark.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.stemMutedText,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _StemChatHeader extends StatelessWidget {
  final String groupName;
  final String groupId;
  final VoidCallback onBack;
  final List<CameraDescription>? cameras;

  const _StemChatHeader({
    required this.groupName,
    required this.groupId,
    required this.onBack,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupCubit, GroupState>(
      builder: (context, state) {
        final memberCount = state is GroupLoaded ? state.group.memberCount : 0;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          color: AppColors.stemBackground,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.stemLightText),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.stemEmerald,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${memberCount > 0 ? memberCount : 12} active members',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.stemMutedText,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              BroadcastVideoButton(
                groupId: groupId,
                cameras: cameras,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: AppColors.stemMutedText),
              ),
            ],
          ),
        );
      },
    );
  }
}
