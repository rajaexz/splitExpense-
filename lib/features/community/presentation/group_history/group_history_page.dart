import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../data/models/group_history_model.dart';
import '../../../../application/group/group_cubit.dart';
import 'widgets/group_history_widgets.dart';

class GroupHistoryPage extends StatelessWidget {
  const GroupHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Group History'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      ),
      body: SafeArea(
        child: currentUserId == null
          ? Center(
              child: Text(
                'Please log in to view history',
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          : StreamBuilder<List<GroupHistoryModel>>(
                stream: context.read<GroupCubit>().getGroupHistoryStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return const EmptyGroupHistoryState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.padding16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return HistoryCard(item: item, isDark: isDark);
                    },
                  );
                },
              ),
        ),
    );
  }
}
