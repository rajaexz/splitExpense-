import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_fonts.dart';

class EmptyGroupHistoryState extends StatelessWidget {
  const EmptyGroupHistoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No deleted groups yet',
            style: TextStyle(
              fontSize: AppFonts.fontSize16,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'When you delete a group you created, it will appear here with the members you added.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFonts.fontSize12,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
