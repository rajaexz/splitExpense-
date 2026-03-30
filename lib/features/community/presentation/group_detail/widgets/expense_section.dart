import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../core/constants/app_routes.dart';
import '../../../../../../core/di/injection_container.dart' as di;
import '../../../data/datasources/notification_remote_datasource.dart';
import '../../../../../../data/models/expense_model.dart';
import '../../../../../../data/models/group_model.dart';
import '../../../../../../application/addExpense/expense_cubit.dart';

enum ExpenseTab { settleUp, balances, totals, charts }

class ExpenseSection extends StatefulWidget {
  final String groupId;
  final GroupModel group;
  final String currentUserId;
  final bool isDark;
  final ThemeData theme;
  final bool hideBalanceCard;
  final bool hideHeader;
  final bool useStemDesign;

  const ExpenseSection({
    super.key,
    required this.groupId,
    required this.group,
    required this.currentUserId,
    required this.isDark,
    required this.theme,
    this.hideBalanceCard = false,
    this.hideHeader = false,
    this.useStemDesign = false,
  });

  @override
  State<ExpenseSection> createState() => _ExpenseSectionState();
}

class _ExpenseSectionState extends State<ExpenseSection> {
  ExpenseTab _selectedTab = ExpenseTab.settleUp;

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
              if (!widget.hideHeader) ...[
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
              ],
              if (!widget.hideBalanceCard)
                _TotalBalanceCard(
                  totalBalance: totalBalance,
                  currency: group.currency,
                  group: group,
                  groupId: widget.groupId,
                ),
              if (!widget.hideBalanceCard) const SizedBox(height: 16),
              widget.useStemDesign
                  ? _StemExpenseTabBar(
                      selectedTab: _selectedTab,
                      onTabSelected: (tab) => setState(() => _selectedTab = tab),
                    )
                  : _ExpenseTabBar(
                      selectedTab: _selectedTab,
                      isDark: isDark,
                      onTabSelected: (tab) => setState(() => _selectedTab = tab),
                    ),
              const SizedBox(height: 16),
              if (_selectedTab == ExpenseTab.settleUp)
                _ExpenseListContent(
                  expenses: expenses,
                  group: group,
                  groupId: widget.groupId,
                  currentUserId: widget.currentUserId,
                  isDark: isDark,
                  useStemDesign: widget.useStemDesign,
                )
              else if (_selectedTab == ExpenseTab.balances)
                _BalancesContent(
                  youOwe: youOwe,
                  youLent: youLent,
                  balances: balances,
                  group: group,
                  groupId: widget.groupId,
                  currentUserId: widget.currentUserId,
                  isDark: isDark,
                )
              else if (_selectedTab == ExpenseTab.totals)
                _TotalsContent(
                  expenses: expenses,
                  group: group,
                  theme: theme,
                  isDark: isDark,
                )
              else if (_selectedTab == ExpenseTab.charts)
                _ChartsContent(
                  expenses: expenses,
                  currency: group.currency,
                  isDark: isDark,
                  theme: theme,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final double totalBalance;
  final String currency;
  final GroupModel group;
  final String groupId;

  const _TotalBalanceCard({
    required this.totalBalance,
    required this.currency,
    required this.group,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.padding20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
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
                '$currency ',
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
                  extra: {'groupId': groupId, 'group': group},
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
    );
  }
}

class _ExpenseTabBar extends StatelessWidget {
  final ExpenseTab selectedTab;
  final bool isDark;
  final ValueChanged<ExpenseTab> onTabSelected;

  const _ExpenseTabBar({
    required this.selectedTab,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Row(
        children: [
          _TabChip(
            label: 'Settle',
            tab: ExpenseTab.settleUp,
            isSelected: selectedTab == ExpenseTab.settleUp,
            isDark: isDark,
            onTap: () => onTabSelected(ExpenseTab.settleUp),
          ),
          _TabChip(
            label: 'Balances',
            tab: ExpenseTab.balances,
            isSelected: selectedTab == ExpenseTab.balances,
            isDark: isDark,
            onTap: () => onTabSelected(ExpenseTab.balances),
          ),
          _TabChip(
            label: 'Totals',
            tab: ExpenseTab.totals,
            isSelected: selectedTab == ExpenseTab.totals,
            isDark: isDark,
            onTap: () => onTabSelected(ExpenseTab.totals),
          ),
          _TabChip(
            label: 'Charts',
            tab: ExpenseTab.charts,
            isSelected: selectedTab == ExpenseTab.charts,
            isDark: isDark,
            onTap: () => onTabSelected(ExpenseTab.charts),
          ),
        ],
      ),
    );
  }
}

class _StemExpenseTabBar extends StatelessWidget {
  final ExpenseTab selectedTab;
  final ValueChanged<ExpenseTab> onTabSelected;

  const _StemExpenseTabBar({
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF404944).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _StemTabItem(
              label: 'Settle',
              isSelected: selectedTab == ExpenseTab.settleUp,
              onTap: () => onTabSelected(ExpenseTab.settleUp),
            ),
            _StemTabItem(
              label: 'Balances',
              isSelected: selectedTab == ExpenseTab.balances,
              onTap: () => onTabSelected(ExpenseTab.balances),
            ),
            _StemTabItem(
              label: 'Totals',
              isSelected: selectedTab == ExpenseTab.totals,
              onTap: () => onTabSelected(ExpenseTab.totals),
            ),
            _StemTabItem(
              label: 'Charts',
              isSelected: selectedTab == ExpenseTab.charts,
              onTap: () => onTabSelected(ExpenseTab.charts),
            ),
          ],
        ),
      ),
    );
  }
}

class _StemTabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StemTabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.stemEmerald : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.stemEmerald : AppColors.stemMutedText,
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final ExpenseTab tab;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.tab,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
}

class _OweCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final bool isOwe;
  final bool isDark;

  const _OweCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.isOwe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _ExpenseListContent extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final GroupModel group;
  final String groupId;
  final String currentUserId;
  final bool isDark;
  final bool useStemDesign;

  const _ExpenseListContent({
    required this.expenses,
    required this.group,
    required this.groupId,
    required this.currentUserId,
    required this.isDark,
    this.useStemDesign = false,
  });

  @override
  Widget build(BuildContext context) {
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

    final grouped = <String, List<ExpenseModel>>{};
    for (final e in expenses) {
      final key = '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }
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
          for (final e in grouped[key]!)
            _ExpenseListItem(
              expense: e,
              expenses: expenses,
              canEditDelete: e.createdBy == currentUserId,
              group: group,
              groupId: groupId,
              currentUserId: currentUserId,
              isDark: isDark,
              useStemDesign: useStemDesign,
            ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;
  final List<ExpenseModel> expenses;
  final bool canEditDelete;
  final GroupModel group;
  final String groupId;
  final String currentUserId;
  final bool isDark;
  final bool useStemDesign;

  const _ExpenseListItem({
    required this.expense,
    required this.expenses,
    required this.canEditDelete,
    required this.group,
    required this.groupId,
    required this.currentUserId,
    required this.isDark,
    this.useStemDesign = false,
  });

  String _displayName(String uid) {
    if (uid == currentUserId) return 'You';
    return uid.length > 8 ? '${uid.substring(0, 8)}...' : uid;
  }

  static String _currencySymbol(String c) {
    switch (c) {
      case 'INR':
        return '₹';
      case 'PKR':
        return 'Rs. ';
      case 'USD':
        return '\$';
      default:
        return c;
    }
  }

  static String _getMonthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final paidByMe = e.paidBy == currentUserId;
    final amIParticipant = e.isParticipant(currentUserId);
    final share = e.shareForUser(currentUserId);
    final displayAmount = paidByMe ? e.amount : e.sharePerPerson;
    final isOwe = amIParticipant && !paidByMe;
    final isNeutral = !amIParticipant;
    final payerText = paidByMe
        ? 'You paid ${e.amount.toStringAsFixed(2)}'
        : 'Paid ${e.amount.toStringAsFixed(2)}';
    final sym = _currencySymbol(group.currency);

    if (useStemDesign) {
      return InkWell(
        onTap: () {
          context.push(
            AppRoutes.expenseDetail,
            extra: {
              'groupId': groupId,
              'group': group,
              'expense': e,
              'expenses': expenses,
              'currentUserId': currentUserId,
              'isDark': true,
            },
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.stemCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.stemInactive,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: e.imageUrl != null && e.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: e.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.receipt_long,
                        color: AppColors.stemMutedText,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stemLightText,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.stemMutedText,
                        ),
                        children: [
                          const TextSpan(text: 'Paid by '),
                          TextSpan(
                            text: _displayName(e.paidBy),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.stemEmerald,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' • ${_getMonthAbbr(e.createdAt.month)} ${e.createdAt.day}',
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sym${e.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stemLightText,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (paidByMe && amIParticipant && (e.amount - share) > 0)
                    Text(
                      'You get back\n$sym${(e.amount - share).toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stemEmerald,
                        letterSpacing: 0.5,
                      ),
                    )
                  else if (isOwe)
                    Text(
                      'You owe $sym${share.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stemOweColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
                ),
              ),
              if (canEditDelete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.stemMutedText),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context.push(
                        AppRoutes.addExpense,
                        extra: {
                          'groupId': groupId,
                          'group': group,
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
                        context.read<ExpenseCubit>().deleteExpense(groupId, e.id);
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
        ),
      );
    }

    return InkWell(
      onTap: () {
        context.push(
          AppRoutes.expenseDetail,
          extra: {
            'groupId': groupId,
            'group': group,
            'expense': e,
            'expenses': expenses,
            'currentUserId': currentUserId,
            'isDark': isDark,
          },
        );
      },
      borderRadius: BorderRadius.circular(AppDimensions.radius12),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.margin12),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMonthAbbr(e.createdAt.month),
                  style: TextStyle(
                    fontSize: AppFonts.fontSize8,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
                Text(
                  e.createdAt.day.toString(),
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
                      'groupId': groupId,
                      'group': group,
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
                    context.read<ExpenseCubit>().deleteExpense(groupId, e.id);
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
    ),
    );
  }
}

class _BalancesContent extends StatelessWidget {
  final double youOwe;
  final double youLent;
  final Map<String, double> balances;
  final GroupModel group;
  final String groupId;
  final String currentUserId;
  final bool isDark;

  const _BalancesContent({
    required this.youOwe,
    required this.youLent,
    required this.balances,
    required this.group,
    required this.groupId,
    required this.currentUserId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _OweCard(
                title: 'YOU OWE',
                subtitle: 'You should Pay to others',
                amount: youOwe,
                currency: group.currency,
                isOwe: true,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OweCard(
                title: 'YOU GET BACK',
                subtitle: 'Others should Pay to you',
                amount: youLent,
                currency: group.currency,
                isOwe: false,
                isDark: isDark,
              ),
            ),
          ],
        ),
        if (youLent > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
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
                        senderId: currentUserId,
                        senderName: userName,
                        groupId: groupId,
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
                  label: const Text('Notify'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final membersWhoOwe = balances.entries
                        .where((e) => e.value < 0)
                        .map((e) => {'userId': e.key, 'amount': -e.value})
                        .toList();
                    context.push(
                      AppRoutes.requestPaymentQr,
                      extra: {
                        'amount': youLent,
                        'currency': group.currency,
                        'groupName': group.name,
                        'groupId': groupId,
                        'membersWhoOwe': membersWhoOwe,
                      },
                    );
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Pay via QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TotalsContent extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final GroupModel group;
  final ThemeData theme;
  final bool isDark;

  const _TotalsContent({
    required this.expenses,
    required this.group,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, ex) => sum + ex.amount);
    return Center(
      child: Container(
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
              '${group.currency} ${total.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartsContent extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final String currency;
  final bool isDark;
  final ThemeData theme;

  const _ChartsContent({
    required this.expenses,
    required this.currency,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
}
