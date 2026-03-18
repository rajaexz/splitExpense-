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
    return Container(
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
          IconButton(
            icon: isUploadingImage
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined),
            onPressed: isUploadingImage ? null : onPickImage,
          ),
          Expanded(
            child: TextField(
              controller: messageController,
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
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppDimensions.margin8),
          CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.textWhite),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
