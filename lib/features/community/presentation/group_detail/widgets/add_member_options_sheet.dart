import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../core/constants/app_routes.dart';

class AddMemberOptionsSheet extends StatelessWidget {
  final String groupId;
  final String groupName;
  final bool isDark;

  const AddMemberOptionsSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isDark,
  });

  static void show(
    BuildContext context, {
    required String groupId,
    required String groupName,
    required bool isDark,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AddMemberOptionsSheet(
        groupId: groupId,
        groupName: groupName,
        isDark: isDark,
      ),
    );
  }

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
              'Add Member',
              style: TextStyle(
                fontSize: AppFonts.fontSize18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
            ),
            const SizedBox(height: AppDimensions.margin16),
            ListTile(
              leading: const Icon(Icons.contacts, color: AppColors.primaryGreen),
              title: Text(
                'Add from contacts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.addMemberFromContacts,
                  extra: {'groupId': groupId, 'groupName': groupName},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppColors.primaryGreen),
              title: Text(
                'Add by email or phone',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.addMember}/$groupId');
              },
            ),
          ],
        ),
      ),
    );
  }
}
