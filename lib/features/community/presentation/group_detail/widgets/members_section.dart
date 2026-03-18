import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../core/constants/app_routes.dart';
import '../../../../../../data/models/group_model.dart';

class MembersSection extends StatefulWidget {
  final GroupModel group;
  final String? currentUserId;
  final bool isDark;
  final ThemeData theme;

  const MembersSection({
    super.key,
    required this.group,
    this.currentUserId,
    required this.isDark,
    required this.theme,
  });

  @override
  State<MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<MembersSection> {
  bool _showMembers = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isDark = widget.isDark;
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members (${group.memberCount})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: AppFonts.fontSize12,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showMembers = !_showMembers;
                });
              },
              icon: Icon(
                _showMembers ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: AppColors.primaryGreen,
              ),
              label: Text(
                _showMembers ? 'Hide' : 'View all',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: AppFonts.fontSize10,
                ),
              ),
            ),
          ],
        ),
        if (_showMembers) ...[
          const SizedBox(height: AppDimensions.margin8),
          ...group.members.entries.map((entry) {
            final member = entry.value;
            final isCurrentUser = widget.currentUserId == member.userId;
            return InkWell(
              onTap: () {
                if (isCurrentUser) {
                  context.push(AppRoutes.profile);
                } else {
                  context.push('${AppRoutes.userProfile}/${member.userId}');
                }
              },
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.margin8),
                padding: const EdgeInsets.all(AppDimensions.padding8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppDimensions.radius12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryGreen,
                      child: Text(
                        member.userId.length >= 1
                            ? member.userId.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: AppFonts.fontSize12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.margin8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.userId,
                            style: TextStyle(
                              fontSize: AppFonts.fontSize12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textWhite : AppColors.textBlack,
                            ),
                          ),
                          Text(
                            member.role,
                            style: const TextStyle(
                              fontSize: AppFonts.fontSize10,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (member.role == 'admin')
                      const Icon(
                        Icons.star,
                        color: AppColors.primaryGreen,
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
