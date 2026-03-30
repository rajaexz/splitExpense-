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
    final useStemStyle = isDark;
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: useStemStyle ? 14 : 18,
            color: useStemStyle ? AppColors.stemEmerald : AppColors.primaryGreen,
          ),
          SizedBox(width: useStemStyle ? 6 : 8),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: useStemStyle ? 14 : AppFonts.fontSize12,
              fontWeight: FontWeight.w600,
              color: useStemStyle ? AppColors.stemEmerald : (isDark ? AppColors.textWhite : AppColors.textBlack),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (hasDate) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _clearDate(context),
              child: Icon(
                Icons.close,
                size: useStemStyle ? 14 : 16,
                color: useStemStyle ? AppColors.stemMutedText : AppColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
