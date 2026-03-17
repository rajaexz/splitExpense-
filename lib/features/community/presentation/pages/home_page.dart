import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../application/group/group_cubit.dart';
import '../../../../application/addExpense/expense_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum GroupSortOrder {
  dateNewest,
  dateOldest,
  nameAZ,
  nameZA,
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

  void _showAddExpenseGroupPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: StreamBuilder<List<GroupModel>>(
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
                      Navigator.pop(ctx);
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
        ),
      ),
    );
  }

  Widget _buildAddExpenseFAB(BuildContext context, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddExpenseGroupPicker(context, isDark),
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

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  fontSize: AppFonts.fontSize18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.margin16),
              _buildSortOption(ctx, isDark, GroupSortOrder.dateNewest, 'Newest first', Icons.schedule),
              _buildSortOption(ctx, isDark, GroupSortOrder.dateOldest, 'Oldest first', Icons.history),
              _buildSortOption(ctx, isDark, GroupSortOrder.nameAZ, 'Name A → Z', Icons.sort_by_alpha),
              _buildSortOption(ctx, isDark, GroupSortOrder.nameZA, 'Name Z → A', Icons.sort_by_alpha),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, bool isDark, GroupSortOrder order, String label, IconData icon) {
    final selected = _sortOrder == order;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primaryGreen : AppColors.textGrey),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
      onTap: () {
        setState(() => _sortOrder = order);
        Navigator.pop(context);
      },
    );
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
            _buildSearchBar(context, isDark),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final groups = snapshot.data ?? [];
          final filtered = _filterAndSort(groups);

          if (groups.isEmpty) {
            return _buildEmptyState(context, isDark);
          }
          if (filtered.isEmpty) {
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

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            children: [
              _buildOverallSummary(context, isDark, currentUserId, filtered),
              const SizedBox(height: AppDimensions.margin16),
              ...filtered.map((g) => _GroupCardWithBalance(
                group: g,
                currentUserId: currentUserId,
                isDark: isDark,
                onTap: () => context.push('${AppRoutes.groupDetail}/${g.id}'),
                onChatTap: () => context.push(
                  '${AppRoutes.chat}/${g.id}?name=${Uri.encodeComponent(g.name)}',
                ),
              )),
              const SizedBox(height: AppDimensions.margin16),
              _buildStartNewGroupButton(context, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(fontSize: AppFonts.fontSize18, color: AppColors.textGrey),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first group to get started!',
            style: TextStyle(fontSize: AppFonts.fontSize14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          _buildStartNewGroupButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildOverallSummary(
    BuildContext context,
    bool isDark,
    String currentUserId,
    List<GroupModel> groups,
  ) {
    return _OverallSummary(
      groups: groups,
      currentUserId: currentUserId,
      isDark: isDark,
      onFilterTap: () => _showFilterSheet(context, isDark),
    );
  }

  Widget _buildStartNewGroupButton(BuildContext context, bool isDark) {
    return OutlinedButton.icon(
      onPressed: () => context.push(AppRoutes.createGroup),
      icon: const Icon(Icons.group_add, size: 20),
      label: const Text('Start a new group'),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
        side: BorderSide(color: isDark ? AppColors.textGrey : AppColors.borderGrey),
        padding: const EdgeInsets.symmetric(vertical: 14),
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
         
          _buildNotificationBell(context, isDark, currentUserId),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, bool isDark, String? userId) {
    if (userId == null || userId.isEmpty) {
      return IconButton(
        icon: Icon(
          Icons.notifications_outlined,
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
        ),
        onPressed: () => context.push(AppRoutes.messages),
      );
    }
    final notificationDs = di.sl<NotificationRemoteDataSource>();
    return StreamBuilder<int>(
      stream: notificationDs.getUnreadNotificationCountStream(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
              onPressed: () => context.push(AppRoutes.messages),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radius12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.padding16,
                  vertical: AppDimensions.padding12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppDimensions.margin8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
              onPressed: () => _showFilterSheet(context, isDark),
              tooltip: 'Sort & filter',
            ),
          ),
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

class _OverallSummary extends StatelessWidget {
  final List<GroupModel> groups;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onFilterTap;

  const _OverallSummary({
    required this.groups,
    required this.currentUserId,
    required this.isDark,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      buildWhen: (_, __) => true,
      builder: (context, _) {
        return StreamBuilder<List<List<ExpenseModel>>>(
          stream: _combineGroupExpenseStreams(context),
          builder: (context, snapshot) {
            double totalOwed = 0;
            double totalLent = 0;
            if (snapshot.hasData) {
              for (final expenses in snapshot.data!) {
                final balances = ExpenseCubit.calculateBalances(
                  currentUserId,
                  expenses,
                );
                for (final v in balances.values) {
                  if (v > 0) totalOwed += v;
                  if (v < 0) totalLent += -v;
                }
              }
            }
            final net = totalLent - totalOwed;
            final currency = groups.isNotEmpty ? groups.first.currency : 'PKR';
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        net >= 0 ? 'Overall, you are owed' : 'Overall, you owe',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${net >= 0 ? '' : '-'}${currency} ${net.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textWhite : AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
            
              ],
            );
          },
        );
      },
    );
  }

  Stream<List<List<ExpenseModel>>> _combineGroupExpenseStreams(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();
    if (groups.isEmpty) return Stream.value([]);
    final streams = groups.map((g) => cubit.getGroupExpenses(g.id)).toList();
    return Rx.combineLatestList<List<ExpenseModel>>(streams);
  }
}

class _GroupCardWithBalance extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const _GroupCardWithBalance({
    required this.group,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
    required this.onChatTap,
  });

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'trip':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'couple':
        return Icons.favorite;
      default:
        return Icons.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, _) {
        return StreamBuilder<List<ExpenseModel>>(
          stream: context.read<ExpenseCubit>().getGroupExpenses(group.id),
          builder: (context, snapshot) {
            final expenses = snapshot.data ?? [];
            final balances = ExpenseCubit.calculateBalances(currentUserId, expenses);
            double youOwe = 0;
            double youLent = 0;
            for (final v in balances.values) {
              if (v > 0) youOwe += v;
              if (v < 0) youLent += -v;
            }
            final net = youLent - youOwe;
            final currency = group.currency;

            return GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.margin16),
                padding: const EdgeInsets.all(AppDimensions.padding16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radius16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AppDimensions.radius12),
                              bottomRight: Radius.circular(AppDimensions.radius12),
                            ),
                          ),
                          child: Icon(
                            _iconForCategory(group.category),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.margin12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: AppFonts.fontSize18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                net >= 0
                                    ? 'you are owed'
                                    : 'you owe',
                                style: const TextStyle(
                                  fontSize: AppFonts.fontSize14,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              Text(
                                '${currency} ${net.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: AppFonts.fontSize16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                                ),
                              ),
                              if (balances.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...balances.entries.where((e) => e.value != 0).take(3).map((e) {
                                  final owesYou = e.value < 0;
                                  final amt = owesYou ? (-e.value).toStringAsFixed(2) : e.value.toStringAsFixed(2);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      owesYou
                                          ? 'owes you $currency $amt'
                                          : 'You owe $currency $amt',
                                      style: const TextStyle(
                                        fontSize: AppFonts.fontSize12,
                                        color: AppColors.textGrey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, size: 20),
                          onPressed: onChatTap,
                        ),
                        if (group.creatorId == currentUserId)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 20, color: isDark ? AppColors.textWhite : AppColors.textBlack),
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Group?'),
                                    content: Text(
                                      'Are you sure you want to delete "${group.name}"? This cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  context.read<GroupCubit>().deleteGroup(group.id);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                    SizedBox(width: 8),
                                    Text('Delete Group'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

