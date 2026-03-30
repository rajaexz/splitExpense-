import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final bool isDark;
  final bool isUploadingImage;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const ChatInputBar({
    super.key,
    required this.messageController,
    required this.isDark,
    required this.isUploadingImage,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xCC1C1B1B) : AppColors.backgroundWhite;
    final borderTopColor =
        isDark ? AppColors.borderGreyDark : AppColors.borderGrey;

    final inputBg = isDark ? AppColors.stemInputBg : AppColors.backgroundGrey;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderTopColor, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(AppDimensions.radius24),
              border: Border.all(color: borderTopColor.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  icon: isUploadingImage
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined, size: 20),
                  onPressed: isUploadingImage ? null : onPickImage,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  icon: const Icon(Icons.videocam_outlined, size: 20),
                  onPressed: isUploadingImage ? null : onPickImage,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: messageController,
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.padding16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radius24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.stemEmerald,
                  AppColors.primaryGreenDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreenDark.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.textWhite, size: 20),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
