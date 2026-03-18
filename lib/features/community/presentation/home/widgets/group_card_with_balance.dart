import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../data/models/expense_model.dart';
import '../../../../../../data/models/group_model.dart';
import '../../../../../../application/group/group_cubit.dart';
import '../../../../../../application/addExpense/expense_cubit.dart';

class GroupCardWithBalance extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const GroupCardWithBalance({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
    required this.onChatTap,
  });

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'trip':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'couple':
        return Icons.favorite;
      default:
        return Icons.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, _) {
        return StreamBuilder<List<ExpenseModel>>(
          stream: context.read<ExpenseCubit>().getGroupExpenses(group.id),
          builder: (context, snapshot) {
            final expenses = snapshot.data ?? [];
            final balances = ExpenseCubit.calculateBalances(currentUserId, expenses);
            double youOwe = 0;
            double youLent = 0;
            for (final v in balances.values) {
              if (v > 0) youOwe += v;
              if (v < 0) youLent += -v;
            }
            final net = youLent - youOwe;
            final currency = group.currency;

            return GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.margin16),
                padding: const EdgeInsets.all(AppDimensions.padding16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radius16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AppDimensions.radius12),
                              bottomRight: Radius.circular(AppDimensions.radius12),
                            ),
                          ),
                          child: Icon(
                            _iconForCategory(group.category),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.margin12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: AppFonts.fontSize18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                net >= 0 ? 'you are owed' : 'you owe',
                                style: const TextStyle(
                                  fontSize: AppFonts.fontSize14,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              Text(
                                '${currency} ${net.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppFonts.fontSize16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                                ),
                              ),
                              if (balances.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...balances.entries.where((e) => e.value != 0).take(3).map((e) {
                                  final owesYou = e.value < 0;
                                  final amt = owesYou ? (-e.value).toStringAsFixed(2) : e.value.toStringAsFixed(2);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      owesYou
                                          ? 'owes you $currency $amt'
                                          : 'You owe $currency $amt',
                                      style: const TextStyle(
                                        fontSize: AppFonts.fontSize12,
                                        color: AppColors.textGrey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, size: 20),
                          onPressed: onChatTap,
                        ),
                        if (group.creatorId == currentUserId)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 20, color: isDark ? AppColors.textWhite : AppColors.textBlack),
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Group?'),
                                    content: Text(
                                      'Are you sure you want to delete "${group.name}"? This cannot be undone.',
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
                                if (confirm == true && context.mounted) {
                                  context.read<GroupCubit>().deleteGroup(group.id);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                    SizedBox(width: 8),
                                    Text('Delete Group'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
