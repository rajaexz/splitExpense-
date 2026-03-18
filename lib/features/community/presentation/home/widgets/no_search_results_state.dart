import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_fonts.dart';

class NoSearchResultsState extends StatelessWidget {
  const NoSearchResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            'No groups match your search',
            style: TextStyle(fontSize: AppFonts.fontSize16, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
