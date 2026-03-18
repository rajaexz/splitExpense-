import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_fonts.dart';
import '../selected_member_model.dart';

class ReviewTile extends StatelessWidget {
  final SelectedMember member;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const ReviewTile({
    super.key,
    required this.member,
    required this.isDark,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.margin12),
      padding: const EdgeInsets.all(AppDimensions.padding12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                child: const Icon(Icons.mail_outline, color: AppColors.textGrey),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.error,
                    child: Icon(Icons.close, size: 14, color: AppColors.textWhite),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🇮🇳 ', style: TextStyle(fontSize: 14)),
                    Text(
                      member.phone,
                      style: const TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(
              'Edit',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
