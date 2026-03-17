import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_dimensions.dart';

class AppEmptyWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  
  const AppEmptyWidget({
    Key? key,
    required this.message,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: AppDimensions.iconSize48,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: AppDimensions.margin16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

