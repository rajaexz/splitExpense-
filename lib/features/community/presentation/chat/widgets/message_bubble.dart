import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isDark,
  }) : super(key: key);

  bool get _isMe => message.senderId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.margin8),
      child: Row(
        mainAxisAlignment: _isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: AppFonts.fontSize12,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.margin8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.padding12),
              decoration: BoxDecoration(
                color: _isMe
                    ? AppColors.primaryGreen
                    : (isDark ? AppColors.darkCard : AppColors.backgroundGrey),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppDimensions.radius16),
                  topRight: const Radius.circular(AppDimensions.radius16),
                  bottomLeft: Radius.circular(_isMe ? AppDimensions.radius16 : 0),
                  bottomRight: Radius.circular(_isMe ? 0 : AppDimensions.radius16),
                ),
              ),
              child: _buildMessageContent(),
            ),
          ),
          if (_isMe) ...[
            const SizedBox(width: AppDimensions.margin8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: AppFonts.fontSize12,
                ),
              ),
            ),
          ],
        ],
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
                  color: _isMe ? AppColors.textWhite : (isDark ? AppColors.textWhite : AppColors.textBlack),
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
                const Icon(Icons.play_circle, color: AppColors.textWhite),
                const SizedBox(width: AppDimensions.margin4),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: AppColors.textWhite,
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
            const Icon(Icons.location_on, color: AppColors.textWhite, size: 40),
            const SizedBox(height: AppDimensions.margin4),
            Text(
              'Location Shared',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: AppFonts.fontSize14,
              ),
            ),
          ],
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: _isMe ? AppColors.textWhite : (isDark ? AppColors.textWhite : AppColors.textBlack),
            fontSize: AppFonts.fontSize14,
          ),
        );
    }
  }
}
