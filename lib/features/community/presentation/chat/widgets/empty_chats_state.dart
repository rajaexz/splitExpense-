import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';

class EmptyChatsState extends StatelessWidget {
  const EmptyChatsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(fontSize: AppFonts.fontSize18, color: AppColors.textGrey),
          ),
          const SizedBox(height: 8),
          Text(
            'Join a group from Home to start chatting',
            style: TextStyle(fontSize: AppFonts.fontSize14, color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
