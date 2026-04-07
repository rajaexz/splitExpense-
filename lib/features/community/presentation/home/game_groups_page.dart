import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/error_state_with_action.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/group/group_cubit.dart';
import 'widgets/home_widgets.dart';

class GameGroupsPage extends StatelessWidget {
  const GameGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.stemBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    'Game Groups',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stemEmerald,
                      letterSpacing: -1.2,
                    ),
                  ),
                  NotificationBell(isDark: true, userId: currentUserId),
                ],
              ),
            ),
            Expanded(
              child: _buildContent(context, isDark),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('Please login to see groups'));
    }

    return BlocListener<GroupCubit, GroupState>(
      listenWhen: (prev, curr) => curr is GroupDeleted || curr is GroupError,
      listener: (context, state) {
        if (state is GroupDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted')),
          );
        }
        if (state is GroupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: StreamBuilder<List<GroupModel>>(
        stream: context.read<GroupCubit>().getUserGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorStateWithAction(message: 'Error: ${snapshot.error}');
          }

          final groups = snapshot.data ?? [];
          final gameGroups =
              groups.where((g) => g.category.toLowerCase() == 'game').toList();

          if (gameGroups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      color: AppColors.stemMutedText,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No game groups yet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stemLightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a dedicated game group and start question game.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: AppColors.stemMutedText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.createGroup,
                        extra: {'initialCategory': 'game'},
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Game Group'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(
                '${gameGroups.length} Active Game Groups',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.stemMutedText,
                ),
              ),
              const SizedBox(height: 12),
              ...gameGroups.map((g) => StemGroupCard(
                    group: g,
                    currentUserId: currentUserId,
                    onTap: () => context.push('${AppRoutes.groupDetail}/${g.id}'),
                    onMoreTap: () {},
                  )),
              const SizedBox(height: 12),
              _GameCreateButton(
                onTap: () => context.push(
                  AppRoutes.createGroup,
                  extra: {'initialCategory': 'game'},
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, bool isDark) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.home);
            break;
          case 1:
            context.push(AppRoutes.contacts);
            break;
          case 2:
            break;
          case 3:
            context.push(AppRoutes.profile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      unselectedItemColor: AppColors.textGrey,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
        BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), label: 'Games'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}

class _GameCreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GameCreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 18, color: AppColors.stemButtonText),
            const SizedBox(width: 12),
            Text(
              'Create Game Group',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.stemButtonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

