import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../data/models/expense_model.dart';
import '../../../../../../data/models/group_model.dart';
import '../../../../../../application/addExpense/expense_cubit.dart';

class OverallSummary extends StatelessWidget {
  final List<GroupModel> groups;
  final String currentUserId;
  final bool isDark;
  final VoidCallback? onFilterTap;

  const OverallSummary({
    super.key,
    required this.groups,
    required this.currentUserId,
    required this.isDark,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      buildWhen: (_, __) => true,
      builder: (context, _) {
        return StreamBuilder<List<List<ExpenseModel>>>(
          stream: _combineGroupExpenseStreams(context),
          builder: (context, snapshot) {
            double totalOwed = 0;
            double totalLent = 0;
            if (snapshot.hasData) {
              for (final expenses in snapshot.data!) {
                final balances = ExpenseCubit.calculateBalances(
                  currentUserId,
                  expenses,
                );
                for (final v in balances.values) {
                  if (v > 0) totalOwed += v;
                  if (v < 0) totalLent += -v;
                }
              }
            }
            final net = totalLent - totalOwed;
            final currency = groups.isNotEmpty ? groups.first.currency : 'PKR';
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        net >= 0 ? 'Overall, you are owed' : 'Overall, you owe',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${net >= 0 ? '' : '-'}${currency} ${net.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textWhite : AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Stream<List<List<ExpenseModel>>> _combineGroupExpenseStreams(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();
    if (groups.isEmpty) return Stream.value([]);
    final streams = groups.map((g) => cubit.getGroupExpenses(g.id)).toList();
    return Rx.combineLatestList<List<ExpenseModel>>(streams);
  }
}
