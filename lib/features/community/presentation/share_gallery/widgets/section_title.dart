import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

/// Section title for share gallery steps.
class SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;

  const SectionTitle({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textWhite : AppColors.textBlack,
      ),
    );
  }
}
