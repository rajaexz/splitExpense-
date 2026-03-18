import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
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

  Widget _buildAddExpenseFAB(BuildContext context, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => AddExpenseGroupPicker.show(context, isDark),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      icon: Icon(Icons.receipt_long, color: isDark ? AppColors.textWhite : AppColors.textBlack),
      label: Text(
        'Add expense',
        style: TextStyle(
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, currentUserId),
            HomeSearchBar(
              searchController: _searchController,
              isDark: isDark,
              sortOrder: _sortOrder,
              onSortOrderChanged: (order) => setState(() => _sortOrder = order),
              onSearchChanged: () => setState(() {}),
            ),
            Expanded(
              child: _buildContent(context, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddExpenseFAB(context, isDark),
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
            padding: const EdgeInsets.all(AppDimensions.padding16),
            children: [
              OverallSummary(
                groups: filtered,
                currentUserId: currentUserId,
                isDark: isDark,
              ),
              const SizedBox(height: AppDimensions.margin16),
              ...filtered.map((g) => GroupCardWithBalance(
                group: g,
                currentUserId: currentUserId,
                isDark: isDark,
                onTap: () => context.push('${AppRoutes.groupDetail}/${g.id}'),
                onChatTap: () => context.push(
                  '${AppRoutes.chat}/${g.id}?name=${Uri.encodeComponent(g.name)}',
                ),
              )),
              const SizedBox(height: AppDimensions.margin16),
              StartNewGroupButton(isDark: isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String? currentUserId) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.padding16,
        vertical: AppDimensions.padding12,
      ),
      child: Row(
        children: [
          Expanded(child: const SizedBox.shrink()),
          NotificationBell(isDark: isDark, userId: currentUserId),
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

