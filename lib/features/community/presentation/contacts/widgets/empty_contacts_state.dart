import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_fonts.dart';
import '../../../../../core/constants/app_routes.dart';

/// Splitwise-style empty state for contacts/friends page.
class EmptyContactsState extends StatelessWidget {
  final bool isDark;
  final String userName;

  const EmptyContactsState({
    super.key,
    required this.isDark,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            userName.isNotEmpty
                ? 'Welcome to JobCrak, $userName!'
                : 'Welcome to JobCrak!',
            style: TextStyle(
              fontSize: AppFonts.fontSize24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.primaryGreen.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'As you use JobCrak, friends and group mates will show here.',
            style: TextStyle(
              fontSize: AppFonts.fontSize16,
              color: AppColors.textGrey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.addMemberFromContacts),
            icon: const Icon(Icons.person_add_outlined, size: 20),
            label: const Text('Add more friends'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
