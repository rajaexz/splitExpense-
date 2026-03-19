import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../core/constants/app_routes.dart';
import '../../../../../../data/models/group_model.dart';
import '../../../../../../application/group/group_cubit.dart';

class AddExpenseGroupPicker extends StatelessWidget {
  final bool isDark;

  const AddExpenseGroupPicker({super.key, required this.isDark});

  static void show(BuildContext context, bool isDark) {
    final groupCubit = context.read<GroupCubit>();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: BlocProvider.value(
          value: groupCubit,
          child: AddExpenseGroupPicker(isDark: isDark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupModel>>(
      stream: context.read<GroupCubit>().getUserGroupsStream(),
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create a group first to add expenses',
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select group',
                style: TextStyle(
                  fontSize: AppFonts.fontSize18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.margin16),
              ...groups.map((g) => ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppDimensions.radius12),
                  ),
                  child: const Icon(Icons.group),
                ),
                title: Text(g.name),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    AppRoutes.addExpense,
                    extra: {'groupId': g.id, 'group': g, 'expense': null},
                  );
                },
              )),
            ],
          ),
        );
      },
    );
  }
}
