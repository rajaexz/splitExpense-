import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/error_state_with_action.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/group/group_cubit.dart';
import 'widgets/chat_widgets.dart';

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
            return ErrorStateWithAction(message: 'Error: ${snapshot.error}');
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const EmptyChatsState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ChatListItem(
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
