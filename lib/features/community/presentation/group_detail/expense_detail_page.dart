import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/addExpense/expense_cubit.dart';

class ExpenseDetailPage extends StatelessWidget {
  final String groupId;
  final GroupModel group;
  final ExpenseModel expense;
  final List<ExpenseModel> expenses;
  final String currentUserId;
  final bool isDark;

  const ExpenseDetailPage({
    super.key,
    required this.groupId,
    required this.group,
    required this.expense,
    required this.expenses,
    required this.currentUserId,
    required this.isDark,
  });

  String _displayName(String userId) {
    if (userId == currentUserId) return 'You';
    final member = group.members[userId];
    if (member != null) {
      return userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;
    }
    return userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;
  }

  String _currencySymbol() {
    switch (group.currency) {
      case 'INR':
        return '₹';
      case 'PKR':
        return 'Rs.';
      case 'USD':
        return '\$';
      default:
        return group.currency;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final createdByMe = e.createdBy == currentUserId;
    final currency = _currencySymbol();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textWhite : AppColors.textBlack,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: 20,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textGrey,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_a_photo_outlined,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
            onPressed: () {
              context.push(
                AppRoutes.addExpense,
                extra: {
                  'groupId': groupId,
                  'group': group,
                  'expense': e,
                },
              );
            },
          ),
          if (createdByMe)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              onPressed: () async {
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
                  context.read<ExpenseCubit>().deleteExpense(groupId, e.id);
                  if (context.mounted) context.pop();
                }
              },
            ),
          if (createdByMe)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
              onPressed: () {
                context.push(
                  AppRoutes.addExpense,
                  extra: {
                    'groupId': groupId,
                    'group': group,
                    'expense': e,
                  },
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Amount
              Text(
                e.description,
                style: TextStyle(
                  fontSize: AppFonts.fontSize24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$currency ${e.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppFonts.fontSize36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Added by ${createdByMe ? 'you' : _displayName(e.createdBy)} on ${_formatDate(e.createdAt)}',
                style: const TextStyle(
                  fontSize: AppFonts.fontSize12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),

              // Payment & Split breakdown
              _PaymentSplitSection(
                expense: e,
                group: group,
                currentUserId: currentUserId,
                isDark: isDark,
                displayName: _displayName,
                currency: currency,
              ),
              const SizedBox(height: 24),

              // Spending trends
              _SpendingTrendsSection(
                expenses: expenses,
                group: group,
                isDark: isDark,
                currency: currency,
              ),
              const SizedBox(height: 24),

              // Add comment
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.padding16,
                  vertical: AppDimensions.padding12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppDimensions.radius12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Add a comment',
                          hintStyle: const TextStyle(
                            fontSize: AppFonts.fontSize14,
                            color: AppColors.textGrey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: TextStyle(
                          fontSize: AppFonts.fontSize14,
                          color: isDark ? AppColors.textWhite : AppColors.textBlack,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.send,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentSplitSection extends StatelessWidget {
  final ExpenseModel expense;
  final GroupModel group;
  final String currentUserId;
  final bool isDark;
  final String Function(String) displayName;
  final String currency;

  const _PaymentSplitSection({
    required this.expense,
    required this.group,
    required this.currentUserId,
    required this.isDark,
    required this.displayName,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final paidByMe = e.paidBy == currentUserId;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.padding16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paidByMe
                          ? 'You paid $currency ${e.amount.toStringAsFixed(2)}'
                          : '${displayName(e.paidBy)} paid $currency ${e.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...e.participants.where((p) => p != e.paidBy).map((userId) {
                      final share = e.shareForUser(userId);
                      if (share <= 0) return const SizedBox.shrink();
                      final iOwe = !paidByMe && userId == currentUserId;
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.textGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                iOwe
                                    ? 'You owe $currency ${share.toStringAsFixed(2)}'
                                    : '${displayName(userId)} owes $currency ${share.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: AppFonts.fontSize12,
                                  color: AppColors.textGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (paidByMe && e.participants.contains(currentUserId))
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.textGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You owe $currency ${e.shareForUser(currentUserId).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: AppFonts.fontSize12,
                                  color: AppColors.textGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendingTrendsSection extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final GroupModel group;
  final bool isDark;
  final String currency;

  const _SpendingTrendsSection({
    required this.expenses,
    required this.group,
    required this.isDark,
    required this.currency,
  });

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthItems = <MapEntry<int, int>>[];
    for (var i = 2; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      monthItems.add(MapEntry(d.month, d.year));
    }
    final amounts = <MapEntry<int, int>, double>{};
    for (final e in monthItems) {
      amounts[e] = 0;
    }
    for (final ex in expenses) {
      if (ex.groupId != group.id) continue;
      final key = MapEntry(ex.createdAt.month, ex.createdAt.year);
      if (amounts.containsKey(key)) {
        amounts[key] = amounts[key]! + ex.amount;
      }
    }

    final maxAmount = amounts.values.isEmpty
        ? 1.0
        : amounts.values.reduce((a, b) => a > b ? a : b);

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
            'Spending trends for ${group.name} :: General',
            style: TextStyle(
              fontSize: AppFonts.fontSize14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...monthItems.map((item) {
            final m = item.key;
            final amount = amounts[item] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      _monthNames[m - 1],
                      style: TextStyle(
                        fontSize: AppFonts.fontSize12,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = maxAmount > 0
                            ? (amount / maxAmount) * constraints.maxWidth
                            : 0.0;
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 24,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkSurface : AppColors.backgroundWhite)
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              width: barWidth,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '$currency ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize12,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to charts tab in group detail
                context.pop();
              },
              icon: const Icon(Icons.diamond_outlined, size: 18),
              label: const Text('View more charts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

