import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../data/models/group_history_model.dart';
import '../../../../application/group/group_cubit.dart';

class GroupHistoryPage extends StatelessWidget {
  const GroupHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Group History'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      ),
      body: SafeArea(
        child: currentUserId == null
          ? Center(
              child: Text(
                'Please log in to view history',
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          : StreamBuilder<List<GroupHistoryModel>>(
                stream: context.read<GroupCubit>().getGroupHistoryStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No deleted groups yet',
                            style: TextStyle(
                              fontSize: AppFonts.fontSize16,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'When you delete a group you created, it will appear here with the members you added.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppFonts.fontSize12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.padding16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _HistoryCard(
                        item: item,
                        isDark: isDark,
                        theme: theme,
                      );
                    },
                  );
                },
              ),
        ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GroupHistoryModel item;
  final bool isDark;
  final ThemeData theme;

  const _HistoryCard({
    required this.item,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final deletedDate = DateFormat('MMM d, yyyy').format(item.deletedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.margin12),
      padding: const EdgeInsets.all(AppDimensions.padding16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(
          color: isDark ? AppColors.borderGreyDark : AppColors.borderGrey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group_off,
                color: AppColors.textGrey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.groupName,
                      style: TextStyle(
                        fontSize: AppFonts.fontSize16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                    Text(
                      'Deleted on $deletedDate',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Members you added (${item.members.length})',
            style: TextStyle(
              fontSize: AppFonts.fontSize12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          ...item.members.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      e.key.length >= 1 ? e.key.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize10,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: AppFonts.fontSize12,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: e.value == 'admin'
                          ? AppColors.primaryGreen.withOpacity(0.2)
                          : AppColors.textGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: AppFonts.fontSize10,
                        color: e.value == 'admin'
                            ? AppColors.primaryGreen
                            : AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
