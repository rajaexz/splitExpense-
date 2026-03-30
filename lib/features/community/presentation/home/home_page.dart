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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  GroupSortOrder _sortOrder = GroupSortOrder.dateNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroupModel> _filterAndSort(List<GroupModel> groups) {
    final query = _searchController.text.trim().toLowerCase();
    var list = groups;
    if (query.isNotEmpty) {
      list = groups.where((g) {
        return g.name.toLowerCase().contains(query) ||
            g.description.toLowerCase().contains(query);
      }).toList();
    }
    switch (_sortOrder) {
      case GroupSortOrder.dateNewest:
        list = List.from(list)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case GroupSortOrder.dateOldest:
        list = List.from(list)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case GroupSortOrder.nameAZ:
        list = List.from(list)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case GroupSortOrder.nameZA:
        list = List.from(list)..sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    return list;
  }

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
            _buildHeader(context, isDark, currentUserId),
            Expanded(
              child: _buildContent(context, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () => AddExpenseGroupPicker.show(context, true),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.stemButtonText,
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Add Expense',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.stemButtonText,
              letterSpacing: -0.35,
            ),
          ),
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
          final filtered = _filterAndSort(groups);

          if (groups.isEmpty) {
            return EmptyGroupsState(isDark: isDark);
          }
          if (filtered.isEmpty) {
            return const NoSearchResultsState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
            children: [
              StemBalanceSummaryCard(
                groups: filtered,
                currentUserId: currentUserId,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Groups',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.stemLightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${filtered.length} Active Collections',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.stemMutedText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _StemIconButton(
                          icon: Icons.tune,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: AppColors.stemCard,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (ctx) => GroupSortSheet(
                                currentOrder: _sortOrder,
                                isDark: true,
                                onOrderSelected: (o) {
                                  setState(() => _sortOrder = o);
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _StemIconButton(
                          icon: Icons.search,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ...filtered.map((g) => StemGroupCard(
                          group: g,
                          currentUserId: currentUserId,
                          onTap: () =>
                              context.push('${AppRoutes.groupDetail}/${g.id}'),
                          onMoreTap: () {},
                        )),
                    _StemCreateGroupButton(
                      onTap: () => context.push(AppRoutes.createGroup),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String? currentUserId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.stemSurface,
            child: Icon(Icons.person, color: AppColors.stemMutedText),
          ),
          Text(
            'JobCrak',
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
    );
  }

  Widget _buildBottomNavBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              context.push(AppRoutes.contacts);
              break;
            case 2:
              context.push(AppRoutes.sharedWithMe);
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
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

class _StemIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StemIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.stemCard,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.stemMutedText),
      ),
    );
  }
}

class _StemCreateGroupButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StemCreateGroupButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.stemEmerald.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.stemButtonText),
            const SizedBox(width: 12),
            Text(
              'Create New Group',
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

