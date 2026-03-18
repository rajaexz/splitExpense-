import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';

class DateRangeField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String placeholder;
  final VoidCallback onTap;

  const DateRangeField({
    super.key,
    required this.label,
    required this.date,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.textGrey : AppColors.borderGrey,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date!.day}/${date!.month}/${date!.year}'
                        : placeholder,
                    style: TextStyle(
                      fontSize: AppFonts.fontSize14,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, size: 20, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
