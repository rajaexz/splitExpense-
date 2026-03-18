import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../data/models/group_model.dart';
import '../../../../../../application/group/group_cubit.dart';

class SettleUpDateButton extends StatelessWidget {
  final String groupId;
  final GroupModel group;
  final bool isDark;

  const SettleUpDateButton({
    super.key,
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _pickDate(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
