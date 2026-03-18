import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/group/group_cubit.dart';
import 'widgets/group_detail_widgets.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return BlocProvider(
      create: (context) => context.read<GroupCubit>()..loadGroup(groupId),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('Group Details'),
       
        ),
        body: SafeArea(
          child: BlocBuilder<GroupCubit, GroupState>(
            builder: (context, state) {
            if (state is GroupLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is GroupError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Retry',
                      onPressed: () => context.read<GroupCubit>().loadGroup(groupId),
                    ),
                  ],
                ),
              );
            }

            if (state is GroupLoaded) {
              final group = state.group;
              final isCreator = group.creatorId == currentUserId;
              final isMember = group.members.containsKey(currentUserId);

              return RefreshIndicator(
                onRefresh: () => context.read<GroupCubit>().loadGroup(groupId),
                color: AppColors.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.padding16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Header
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.padding20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radius16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isCreator)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.padding8,
                                    vertical: AppDimensions.padding4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(AppDimensions.radius8),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: AppFonts.fontSize12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (group.description.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.margin8),
                            Text(
                              group.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          if (isMember) ...[
                            const SizedBox(height: AppDimensions.margin16),
                            Row(
                              children: [
                                Expanded(
                                  child: SettleUpDateButton(
                                    groupId: groupId,
                                    group: group,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.margin8),
                                Expanded(
                                  child: InfoChip(
                                    icon: Icons.people,
                                    label: '${group.memberCount} people',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: AppDimensions.margin16),
                            InfoChip(
                              icon: Icons.people,
                              label: '${group.memberCount} members',
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.margin24),

                    // Action Buttons
                    if (isMember) ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Open Chat',
                              height: 36,
                              onPressed: () {
                                context.push(
                                  '${AppRoutes.chat}/${groupId}?name=${Uri.encodeComponent(group.name)}',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.margin8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                AddMemberOptionsSheet.show(
                              context,
                              groupId: groupId,
                              groupName: group.name,
                              isDark: isDark,
                            );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                minimumSize: const Size(0, 36),
                                side: const BorderSide(color: AppColors.primaryGreen),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_add, color: AppColors.primaryGreen, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add Member',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: AppFonts.fontSize12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.margin24),
                      // Trip Expenses Section
                      if (currentUserId != null)
                        ExpenseSection(
                          groupId: groupId,
                          group: group,
                          currentUserId: currentUserId,
                          isDark: isDark,
                          theme: theme,
                        ),
                      const SizedBox(height: AppDimensions.margin24),
                    ] else ...[
                      AppButton(
                        text: 'Join Group',
                        height: 36,
                        onPressed: () {
                          if (currentUserId != null) {
                            context.read<GroupCubit>().joinGroup(groupId, currentUserId);
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.margin24),
                    ],

                    // Members Section (hidden by default, tap View all to show)
                    MembersSection(
                      group: group,
                      currentUserId: currentUserId,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            );
            }

            return const Center(child: Text('No group data'));
          },
        ),
      ),
    ));
  }
}
