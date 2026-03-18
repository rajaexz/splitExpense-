import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_fonts.dart';
import '../../../../../core/di/injection_container.dart' as di;
import '../../../../../data/models/group_model.dart';
import '../../../../../domain/message_repository.dart';

class ChatListItem extends StatelessWidget {
  final GroupModel group;
  final bool isDark;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.group,
    required this.isDark,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final messageRepo = di.sl<MessageRepository>();

    return StreamBuilder<int>(
      stream: messageRepo.getUnreadCountStream(group.id, currentUserId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.padding16,
            vertical: AppDimensions.padding8,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            child: Text(
              group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            group.name,
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          subtitle: Text(
            '${group.memberCount} members',
            style: const TextStyle(fontSize: AppFonts.fontSize12, color: AppColors.textGrey),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const Icon(Icons.chevron_right, color: AppColors.textGrey),
        );
      },
    );
  }
}
