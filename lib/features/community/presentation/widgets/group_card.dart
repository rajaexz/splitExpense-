import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';

class GroupCard extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String location;
  final String? salary;
  final String type;
  final bool isRemote;
  final IconData icon;
  final Color color;
  final bool isDark;

  const GroupCard({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.location,
    this.salary,
    required this.type,
    required this.isRemote,
    required this.icon,
    required this.color,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to group details
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppDimensions.padding16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and salary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radius12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.textWhite,
                    size: 24,
                  ),
                ),
                if (salary != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.padding8,
                      vertical: AppDimensions.padding4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppDimensions.radius8),
                    ),
                    child: Text(
                      salary!,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: AppFonts.fontSize14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.margin16),
            // Group name
            Text(
              groupName,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: AppFonts.fontSize18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.margin4),
            // Location
            Text(
              location,
              style: TextStyle(
                color: AppColors.textWhite.withOpacity(0.8),
                fontSize: AppFonts.fontSize14,
              ),
            ),
            const Spacer(),
            // Tags and bookmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tags
                Row(
                  children: [
                    _buildTag(type, AppColors.textWhite),
                    if (isRemote) ...[
                      const SizedBox(width: AppDimensions.margin4),
                      _buildTag('Remote', AppColors.textWhite),
                    ],
                  ],
                ),
                // Bookmark
                IconButton(
                  icon: const Icon(
                    Icons.bookmark_border,
                    color: AppColors.textWhite,
                  ),
                  onPressed: () {
                    // Handle bookmark
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.padding8,
        vertical: AppDimensions.padding4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radius8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFonts.fontSize12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

