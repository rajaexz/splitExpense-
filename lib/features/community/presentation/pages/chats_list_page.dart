import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../data/models/group_model.dart';
import '../../../../domain/message_repository.dart';
import '../../../../application/group/group_cubit.dart';

/// Lists user's groups - tap to open chat for that group.
class ChatsListPage extends StatelessWidget {
  const ChatsListPage({Key? key}) : super(key: key);

  void _openChat(BuildContext context, GroupModel group) {
    context.push(
      '${AppRoutes.chat}/${group.id}?name=${Uri.encodeComponent(group.name)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        ),
        body: SafeArea(
          child: const Center(child: Text('Please login to see your chats')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      ),
      body: SafeArea(
        child: StreamBuilder<List<GroupModel>>(
        stream: context.read<GroupCubit>().getUserGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textGrey),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(fontSize: AppFonts.fontSize18, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join a group from Home to start chatting',
                    style: TextStyle(fontSize: AppFonts.fontSize14, color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _ChatListItem(
                group: group,
                isDark: isDark,
                currentUserId: currentUserId,
                onTap: () => _openChat(context, group),
              );
            },
          );
        },
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final GroupModel group;
  final bool isDark;
  final String currentUserId;

  final VoidCallback onTap;

  const _ChatListItem({
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
