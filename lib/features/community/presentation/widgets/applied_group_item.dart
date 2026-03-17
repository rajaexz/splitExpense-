import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';

class AppliedGroupItem extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String location;
  final IconData icon;
  final bool isDark;

  const AppliedGroupItem({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.location,
    required this.icon,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to group details
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(AppDimensions.padding12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          border: Border.all(
            color: isDark ? AppColors.borderGreyDark : AppColors.borderGrey,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radius8),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.margin12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    groupName,
                    style: TextStyle(
                      fontSize: AppFonts.fontSize14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.margin4),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: AppFonts.fontSize12,
                      color: AppColors.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // More options
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? AppColors.textGrey : AppColors.textGreyDark,
                size: 20,
              ),
              onPressed: () {
                // Show options menu
              },
            ),
          ],
        ),
      ),
    );
  }
}

