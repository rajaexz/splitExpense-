import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/expense_model.dart';
import '../../../../../data/models/group_model.dart';
import '../../../../../application/addExpense/expense_cubit.dart';

/// STEM design: Group card with icon, name, activity, balance status.
class StemGroupCard extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const StemGroupCard({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.onTap,
    this.onMoreTap,
  });

  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'trip':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'couple':
        return Icons.favorite;
      default:
        return Icons.celebration;
    }
  }

  static Color _iconBgForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'home':
        return AppColors.stemOweColor.withValues(alpha: 0.1);
      default:
        return AppColors.stemEmerald.withValues(alpha: 0.1);
    }
  }

  static String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'trip':
        return 'TRIP';
      case 'home':
        return 'HOME';
      case 'food':
        return 'FOOD';
      case 'couple':
        return 'COUPLE';
      default:
        return 'OTHER';
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

            String activityText;
            if (expenses.isEmpty) {
              activityText = 'No expenses yet';
            } else {
              final last = expenses.first;
              activityText = 'Added "${last.description}"';
              if (activityText.length > 35) {
                activityText = '${activityText.substring(0, 32)}…';
              }
            }

            String balanceText;
            Color balanceColor;
            if (net > 0) {
              balanceText = 'You are owed $currency${net.toStringAsFixed(0)}';
              balanceColor = AppColors.stemEmerald;
            } else if (net < 0) {
              balanceText = 'You owe $currency${(-net).toStringAsFixed(0)}';
              balanceColor = AppColors.stemOweColor;
            } else {
              balanceText = 'Settled Up';
              balanceColor = AppColors.stemMutedText;
            }

            return GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: AppColors.stemCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _iconBgForCategory(group.category),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _iconForCategory(group.category),
                        size: 24,
                        color: AppColors.stemEmerald,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.stemLightText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onMoreTap != null)
                                GestureDetector(
                                  onTap: onMoreTap,
                                  child: Icon(
                                    Icons.more_horiz,
                                    size: 20,
                                    color: AppColors.stemMutedText,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.stemInactive,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  _categoryLabel(group.category),
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    color: AppColors.stemMutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activityText,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.stemMutedText,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            balanceText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: balanceColor,
                            ),
                          ),
                        ],
                      ),
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
