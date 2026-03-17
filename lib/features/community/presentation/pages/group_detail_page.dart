import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/group/group_cubit.dart';
import '../../../../application/addExpense/expense_cubit.dart';

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
                                  child: _SettleUpDateButton(
                                    groupId: groupId,
                                    group: group,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.margin8),
                                Expanded(
                                  child: _buildInfoChip(
                                    Icons.people,
                                    '${group.memberCount} people',
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: AppDimensions.margin16),
                            _buildInfoChip(
                              Icons.people,
                              '${group.memberCount} members',
                              isDark,
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
                                context.push(
                                  '${AppRoutes.addMember}/${groupId}',
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
                        _ExpenseSection(
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
                    _MembersSection(
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

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.padding8,
        vertical: AppDimensions.padding4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFonts.fontSize12,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettleUpDateButton extends StatelessWidget {
  final String groupId;
  final GroupModel group;
  final bool isDark;

  const _SettleUpDateButton({
    required this.groupId,
    required this.group,
    required this.isDark,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: group.settleUpDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && context.mounted) {
      context.read<GroupCubit>().updateSettleUpDate(groupId, picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settle up date set. Reminders will be sent on ${picked.day}/${picked.month}/${picked.year}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _clearDate(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove settle up date?'),
        content: const Text('Reminders will no longer be sent for this date.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<GroupCubit>().updateSettleUpDate(groupId, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = group.settleUpDate != null;
    final dateStr = hasDate
        ? '${group.settleUpDate!.day}/${group.settleUpDate!.month}/${group.settleUpDate!.year}'
        : 'Add settle up date';
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      borderRadius: BorderRadius.circular(AppDimensions.radius12),
      child: InkWell(
        onTap: () => _pickDate(context),
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
            border: Border.all(
              color: isDark ? AppColors.borderGreyDark : AppColors.borderGrey,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasDate)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _clearDate(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersSection extends StatefulWidget {
  final GroupModel group;
  final String? currentUserId;
  final bool isDark;
  final ThemeData theme;

  const _MembersSection({
    required this.group,
    this.currentUserId,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<_MembersSection> {
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

enum _ExpenseTab { settleUp, balances, totals, charts }

class _ExpenseSection extends StatefulWidget {
  final String groupId;
  final GroupModel group;
  final String currentUserId;
  final bool isDark;
  final ThemeData theme;

  const _ExpenseSection({
    required this.groupId,
    required this.group,
    required this.currentUserId,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_ExpenseSection> createState() => _ExpenseSectionState();
}

class _ExpenseSectionState extends State<_ExpenseSection> {
  _ExpenseTab _selectedTab = _ExpenseTab.settleUp;

  Widget _buildOweCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double amount,
    required String currency,
    required bool isOwe,
  }) {
    final isDark = widget.isDark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.padding12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(
          color: isDark ? AppColors.borderGreyDark : AppColors.borderGrey,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: AppFonts.fontSize10,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: AppFonts.fontSize8,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radius8),
            ),
            child: Text(
              '$currency ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: AppFonts.fontSize12,
                fontWeight: FontWeight.w600,
                color: isOwe ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseListItem({
    required ExpenseModel e,
    required bool canEditDelete,
    required BuildContext context,
  }) {
    final isDark = widget.isDark;
    final paidByMe = e.paidBy == widget.currentUserId;
    final amIParticipant = e.isParticipant(widget.currentUserId);
    final displayAmount = paidByMe ? e.amount : e.sharePerPerson;
    final isOwe = amIParticipant && !paidByMe;
    final isNeutral = !amIParticipant;
    final payerText = paidByMe
        ? 'You paid ${e.amount.toStringAsFixed(2)}'
        : 'Paid ${e.amount.toStringAsFixed(2)}';
    final monthStr = _getMonthAbbr(e.createdAt.month);
    final dayStr = e.createdAt.day.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.margin12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date block
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthStr,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize8,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
                Text(
                  dayStr,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize8,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.margin12),
          // Icon or receipt image
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radius8),
            ),
            clipBehavior: Clip.antiAlias,
            child: e.imageUrl != null && e.imageUrl!.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          child: CachedNetworkImage(
                            imageUrl: e.imageUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: e.imageUrl!,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                    ),
                  )
                : const Icon(
                    Icons.receipt_long,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
          ),
          const SizedBox(width: AppDimensions.margin12),
          // Description + payer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.description,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize8,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payerText,
                  style: const TextStyle(
                    fontSize: AppFonts.fontSize8,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Amount + direction
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isNeutral)
                Icon(
                  isOwe ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 16,
                  color: isOwe ? AppColors.error : AppColors.success,
                ),
              Text(
                '${e.currency} ${displayAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppFonts.fontSize8,
                  fontWeight: FontWeight.bold,
                  color: isNeutral
                      ? AppColors.textGrey
                      : (isOwe ? AppColors.error : AppColors.success),
                ),
              ),
            ],
          ),
          if (canEditDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push(
                    AppRoutes.addExpense,
                    extra: {
                      'groupId': widget.groupId,
                      'group': widget.group,
                      'expense': e,
                    },
                  );
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Expense?'),
                      content: Text(
                        'Are you sure you want to delete "${e.description}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    context.read<ExpenseCubit>().deleteExpense(widget.groupId, e.id);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }

  static String _getMonthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildExpenseList(
    BuildContext context,
    List<ExpenseModel> expenses,
    GroupModel group,
    bool isDark,
  ) {
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.padding16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        child: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.textGrey, size: 20),
            SizedBox(width: 12),
            Text(
              'No expenses yet',
              style: TextStyle(fontSize: AppFonts.fontSize8, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    // Group expenses by month (year-month key)
    final grouped = <String, List<ExpenseModel>>{};
    for (final e in expenses) {
      final key = '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    // Sort months descending (newest first), sort expenses within month by date desc
    final sortedMonths = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    const monthNames = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in sortedMonths) ...[
          Text(
            '${monthNames[grouped[key]!.first.createdAt.month - 1]} ${grouped[key]!.first.createdAt.year}',
            style: TextStyle(
              fontSize: AppFonts.fontSize10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          for (final e in grouped[key]!) ...[
            _buildExpenseListItem(
              e: e,
              canEditDelete: e.createdBy == widget.currentUserId,
              context: context,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildChartsContent(
    List<ExpenseModel> expenses,
    String currency,
    bool isDark,
    ThemeData theme,
  ) {
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.padding24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: AppColors.textGrey),
              SizedBox(height: 12),
              Text(
                'Add expenses to see charts',
                style: TextStyle(
                  fontSize: AppFonts.fontSize14,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group expenses by description
    final byDescription = <String, double>{};
    for (final e in expenses) {
      final key = e.description.isEmpty ? 'Other' : e.description;
      byDescription[key] = (byDescription[key] ?? 0) + e.amount;
    }

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    if (total <= 0) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.padding24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        child: const Center(
          child: Text(
            'No expense data',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    final chartColors = [
      AppColors.primaryGreen,
      AppColors.accentBlue,
      AppColors.accentOrange,
      AppColors.accentPink,
      AppColors.success,
      AppColors.warning,
    ];

    int colorIndex = 0;
    final sections = byDescription.entries.map((e) {
      final color = chartColors[colorIndex % chartColors.length];
      colorIndex++;
      return PieChartSectionData(
        value: e.value,
        title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: AppFonts.fontSize10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.padding16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...byDescription.entries.map((e) {
            final idx = byDescription.keys.toList().indexOf(e.key);
            final color = chartColors[idx % chartColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
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
                  Text(
                    '$currency ${e.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppFonts.fontSize12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
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

  Widget _buildTab(String label, _ExpenseTab tab) {
    final isSelected = _selectedTab == tab;
    final isDark = widget.isDark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkCard : AppColors.backgroundWhite)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radius8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppFonts.fontSize10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.textWhite : AppColors.textBlack)
                    : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseCubit, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted')),
          );
        }
        if (state is ExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: StreamBuilder<List<ExpenseModel>>(
        stream: context.read<ExpenseCubit>().getGroupExpenses(widget.groupId),
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? [];
          final balances =
              ExpenseCubit.calculateBalances(widget.currentUserId, expenses);

          double youOwe = 0;
          double youLent = 0;
          for (final v in balances.values) {
            if (v > 0) youOwe += v;
            if (v < 0) youLent += -v;
          }
          final totalBalance = youLent - youOwe;
          final group = widget.group;
          final isDark = widget.isDark;
          final theme = widget.theme;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Expenses',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sirf jisme naam add hai, unko hi paisa dena hoga',
                style: TextStyle(
                  fontSize: AppFonts.fontSize12,
                  color: AppColors.textGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            // Total Balance Card - Gradient
            Container(
              padding: const EdgeInsets.all(AppDimensions.padding20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF11998e),
                    Color(0xFF38ef7d),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radius16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: AppFonts.fontSize14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${group.currency} ',
                        style: const TextStyle(
                          fontSize: AppFonts.fontSize14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${totalBalance >= 0 ? "" : "- "}${totalBalance.abs().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          AppRoutes.addExpense,
                          extra: {'groupId': widget.groupId, 'group': group},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a1a1a),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radius12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('+ ADD EXPENSE'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs: Settle Up, Balances, Totals, Charts
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppDimensions.radius12),
              ),
              child: Row(
                children: [
                  _buildTab('Settle', _ExpenseTab.settleUp),
                  _buildTab('Balances', _ExpenseTab.balances),
                  _buildTab('Totals', _ExpenseTab.totals),
                  _buildTab('Charts', _ExpenseTab.charts),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content based on selected tab
            if (_selectedTab == _ExpenseTab.settleUp) ...[
              _buildExpenseList(context, expenses, group, isDark),
            ] else if (_selectedTab == _ExpenseTab.balances) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildOweCard(
                      context: context,
                      title: 'YOU OWE',
                      subtitle: 'You should Pay to others',
                      amount: youOwe,
                      currency: group.currency,
                      isOwe: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOweCard(
                      context: context,
                      title: 'YOU GET BACK',
                      subtitle: 'Others should Pay to you',
                      amount: youLent,
                      currency: group.currency,
                      isOwe: false,
                    ),
                  ),
                ],
              ),
              if (youLent > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final targetIds = balances.entries
                        .where((e) => e.value < 0)
                        .map((e) => e.key)
                        .toList();
                    final userName = FirebaseAuth.instance.currentUser?.displayName ??
                        FirebaseAuth.instance.currentUser?.email ??
                        'Someone';
                    try {
                      await di.sl<NotificationRemoteDataSource>()
                          .sendPaymentReminderNotifications(
                        senderId: widget.currentUserId,
                        senderName: userName,
                        groupId: widget.groupId,
                        groupName: group.name,
                        targetUserIds: targetIds,
                        currency: group.currency,
                        totalAmount: youLent,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notification sent to ${targetIds.length} person(s)',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Notify to Pay - Paise bhejo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              ],
            ] else if (_selectedTab == _ExpenseTab.totals) ...[
              Center(
                child:            Container(

                padding: const EdgeInsets.all(AppDimensions.padding20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppDimensions.radius12),
                ),
                child: Column(

                  children: [
                    Text(
                      'Total spent by group',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${group.currency} ${expenses.fold<double>(0, (sum, ex) => sum + ex.amount).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
  
              )
            ] else if (_selectedTab == _ExpenseTab.charts) ...[
              _buildChartsContent(expenses, group.currency, isDark, theme),
            ],
          ],
        );
      },
    ),
    );
  }
}

