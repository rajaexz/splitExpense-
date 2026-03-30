import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../data/models/message_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;
  final String groupId;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    required this.groupId,
    this.onDelete,
  });

  bool get _isMe => message.senderId == FirebaseAuth.instance.currentUser?.uid;
  String get _initials {
    final n = message.senderName;
    if (n.isEmpty) return '?';
    return n[0].toUpperCase();
  }

  Color get _bubbleTextColor {
    // STEM chat: "my" messages use dark text on emerald gradient,
    // others use light text on dark card.
    return _isMe ? AppColors.stemButtonText : AppColors.stemLightText;
  }

  String get _timeLabel {
    final dt = message.createdAt;
    return DateFormat('h:mm a').format(dt);
  }

  void _showMessageOptions(BuildContext context) {
    if (!_isMe || onDelete == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete message'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmAndDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'This message will be removed for everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _isMe ? () => _showMessageOptions(context) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.margin8),
        child: Row(
          mainAxisAlignment:
              _isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? AppColors.stemCard : AppColors.backgroundGrey,
                foregroundColor: AppColors.stemLightText,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontSize: AppFonts.fontSize12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.margin8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.padding12),
                decoration: _isMe
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.stemEmerald, AppColors.primaryGreenDark],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft:
                              const Radius.circular(AppDimensions.radius16),
                          topRight:
                              const Radius.circular(AppDimensions.radius16),
                          bottomLeft: Radius.circular(
                            _isMe ? AppDimensions.radius16 : 0,
                          ),
                          bottomRight: Radius.circular(
                            _isMe ? 0 : AppDimensions.radius16,
                          ),
                        ),
                      )
                    : BoxDecoration(
                        color: AppColors.stemCard,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(
                            AppDimensions.radius16,
                          ),
                          topRight: const Radius.circular(
                            AppDimensions.radius16,
                          ),
                          bottomLeft: Radius.circular(
                            _isMe ? AppDimensions.radius16 : 0,
                          ),
                          bottomRight: Radius.circular(
                            _isMe ? 0 : AppDimensions.radius16,
                          ),
                        ),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isMe) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            color: AppColors.stemMutedText,
                            fontSize: AppFonts.fontSize12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    _buildMessageContent(),
                    const SizedBox(height: 6),
                    Align(
                      alignment: _isMe
                          ? Alignment.bottomRight
                          : Alignment.bottomLeft,
                      child: Text(
                        _timeLabel,
                        style: TextStyle(
                          color: _bubbleTextColor.withValues(alpha: 0.85),
                          fontSize: AppFonts.fontSize12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.image:
        final hasCaption = message.content.isNotEmpty && message.content != 'Photo';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            if (hasCaption) ...[
              const SizedBox(height: AppDimensions.margin4),
              Text(
                message.content,
                style: TextStyle(
                  color: _bubbleTextColor,
                  fontSize: AppFonts.fontSize14,
                ),
              ),
            ],
          ],
        );

      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: message.mediaUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
            ),
            const SizedBox(height: AppDimensions.margin4),
            Row(
              children: [
                const Icon(Icons.play_circle, color: AppColors.stemLightText),
                const SizedBox(width: AppDimensions.margin4),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: AppColors.stemLightText,
                    fontSize: AppFonts.fontSize14,
                  ),
                ),
              ],
            ),
          ],
        );

      case MessageType.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on, color: _bubbleTextColor, size: 40),
            const SizedBox(height: AppDimensions.margin4),
            Text(
              'Location Shared',
              style: TextStyle(
                color: _bubbleTextColor,
                fontSize: AppFonts.fontSize14,
              ),
            ),
          ],
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: _bubbleTextColor,
            fontSize: AppFonts.fontSize14,
          ),
        );
    }
  }
}
