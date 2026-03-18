import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class CategoryTypeGrid extends StatelessWidget {
  final String selectedValue;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const CategoryTypeGrid({
    super.key,
    required this.selectedValue,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _TypeButton(
          value: 'trip',
          icon: Icons.flight,
          label: 'Trip',
          isSelected: selectedValue == 'trip',
          isDark: isDark,
          onPressed: () => onSelected('trip'),
        ),
        _TypeButton(
          value: 'home',
          icon: Icons.home,
          label: 'Home',
          isSelected: selectedValue == 'home',
          isDark: isDark,
          onPressed: () => onSelected('home'),
        ),
        _TypeButton(
          value: 'couple',
          icon: Icons.favorite,
          label: 'Couple',
          isSelected: selectedValue == 'couple',
          isDark: isDark,
          onPressed: () => onSelected('couple'),
        ),
        _TypeButton(
          value: 'other',
          icon: Icons.list,
          label: 'Other',
          isSelected: selectedValue == 'other',
          isDark: isDark,
          onPressed: () => onSelected('other'),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String value;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onPressed;

  const _TypeButton({
    required this.value,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
        side: BorderSide(
          color: isSelected ? AppColors.primaryGreen : (isDark ? AppColors.textGrey : AppColors.borderGrey),
        ),
        backgroundColor: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
