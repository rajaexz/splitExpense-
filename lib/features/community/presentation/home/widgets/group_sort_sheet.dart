import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';

enum GroupSortOrder {
  dateNewest,
  dateOldest,
  nameAZ,
  nameZA,
}

class GroupSortSheet extends StatelessWidget {
  final GroupSortOrder currentOrder;
  final bool isDark;
  final ValueChanged<GroupSortOrder> onOrderSelected;

  const GroupSortSheet({
    super.key,
    required this.currentOrder,
    required this.isDark,
    required this.onOrderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                fontSize: AppFonts.fontSize18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
            ),
            const SizedBox(height: AppDimensions.margin16),
            _SortOption(
              label: 'Newest first',
              icon: Icons.schedule,
              order: GroupSortOrder.dateNewest,
              isSelected: currentOrder == GroupSortOrder.dateNewest,
              isDark: isDark,
              onTap: () {
                onOrderSelected(GroupSortOrder.dateNewest);
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Oldest first',
              icon: Icons.history,
              order: GroupSortOrder.dateOldest,
              isSelected: currentOrder == GroupSortOrder.dateOldest,
              isDark: isDark,
              onTap: () {
                onOrderSelected(GroupSortOrder.dateOldest);
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Name A → Z',
              icon: Icons.sort_by_alpha,
              order: GroupSortOrder.nameAZ,
              isSelected: currentOrder == GroupSortOrder.nameAZ,
              isDark: isDark,
              onTap: () {
                onOrderSelected(GroupSortOrder.nameAZ);
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Name Z → A',
              icon: Icons.sort_by_alpha,
              order: GroupSortOrder.nameZA,
              isSelected: currentOrder == GroupSortOrder.nameZA,
              isDark: isDark,
              onTap: () {
                onOrderSelected(GroupSortOrder.nameZA);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final GroupSortOrder order;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.order,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryGreen : AppColors.textGrey),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
      onTap: onTap,
    );
  }
}
