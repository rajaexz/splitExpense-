import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';

/// Empty state for gallery lists.
class EmptyGalleryState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const EmptyGalleryState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.photo_library_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: AppFonts.fontSize16,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: AppFonts.fontSize14,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
