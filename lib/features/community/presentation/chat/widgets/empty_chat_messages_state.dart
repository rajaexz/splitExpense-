import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class EmptyChatMessagesState extends StatelessWidget {
  const EmptyChatMessagesState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No messages yet. Start the conversation!',
        style: TextStyle(color: AppColors.textGrey),
      ),
    );
  }
}
