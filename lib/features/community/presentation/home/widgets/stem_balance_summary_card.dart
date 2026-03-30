import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/expense_model.dart';
import '../../../../../data/models/group_model.dart';
import '../../../../../application/addExpense/expense_cubit.dart';
import 'package:google_fonts/google_fonts.dart';

/// STEM design: Balance summary card with Total Balance, You are owed, You owe.
class StemBalanceSummaryCard extends StatelessWidget {
  final List<GroupModel> groups;
  final String currentUserId;

  const StemBalanceSummaryCard({
    super.key,
    required this.groups,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, _) {
        return StreamBuilder<List<List<ExpenseModel>>>(
          stream: _combineStreams(context),
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
            final curr = groups.isNotEmpty ? groups.first.currency : 'INR';
            final currency = curr == 'INR' ? '₹' : (curr == 'PKR' ? 'Rs. ' : curr);

            return Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              padding: const EdgeInsets.all(33),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.stemEmerald.withValues(alpha: 0.1),
                    AppColors.primaryGreen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.stemEmerald.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 50,
                    offset: const Offset(0, 25),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BALANCE',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.stemMutedText,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${net < 0 ? '-' : ''}$currency${net.abs().toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.stemLightText,
                          letterSpacing: -1.2,
                        ),
                      ),
                      Text(
                        '.${(net.abs() % 1 * 100).toStringAsFixed(0).padLeft(2, '0')}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.stemEmerald,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StemBalanceTile(
                          label: 'YOU ARE OWED',
                          amount: totalLent,
                          currency: currency,
                          color: AppColors.stemEmerald,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StemBalanceTile(
                          label: 'YOU OWE',
                          amount: totalOwed,
                          currency: currency,
                          color: AppColors.stemOweColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Stream<List<List<ExpenseModel>>> _combineStreams(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();
    if (groups.isEmpty) return Stream.value([]);
    final streams = groups.map((g) => cubit.getGroupExpenses(g.id)).toList();
    return Rx.combineLatestList<List<ExpenseModel>>(streams);
  }
}

class _StemBalanceTile extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _StemBalanceTile({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.stemSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF404944).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppColors.stemMutedText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currency${amount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
