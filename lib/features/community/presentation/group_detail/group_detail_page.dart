import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../data/models/group_model.dart';
import '../../../../application/group/group_cubit.dart';
import '../../../../application/addExpense/expense_cubit.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../domain/group_game_repository.dart';
import '../../data/datasources/group_remote_datasource.dart';
import 'widgets/group_detail_widgets.dart';
import 'widgets/settle_up_sheet.dart';

Future<void> openGroupQuestionGame(
  BuildContext context, {
  required String groupId,
  required GroupModel group,
}) async {
  if (!di.sl.isRegistered<GroupGameRepository>()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firebase is not available.')),
    );
    return;
  }
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final repo = di.sl<GroupGameRepository>();
  final latest = await repo.getLatestGameId(groupId);
  if (latest != null) {
    if (!context.mounted) return;
    context.pushNamed(
      'group-game',
      pathParameters: {'groupId': groupId, 'gameId': latest},
      extra: {'groupName': group.name},
    );
    return;
  }
  if (group.creatorId != uid) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ask the group admin to start a question game.'),
      ),
    );
    return;
  }
  final amount = await showDialog<double>(
    context: context,
    builder: (ctx) {
      final c = TextEditingController();
      return AlertDialog(
        backgroundColor: AppColors.stemCard,
        title: Text(
          'Per person amount',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.stemLightText,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.stemLightText),
          decoration: InputDecoration(
            labelText: 'Amount',
            labelStyle: const TextStyle(color: AppColors.stemMutedText),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderGreyDark.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(c.text.trim())),
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
  if (amount == null || amount <= 0) return;
  final others = group.members.keys.where((id) => id != group.creatorId).toList()
    ..sort();
  final memberOrder = [group.creatorId, ...others];
  final gameId = await repo.createGame(
    groupId: groupId,
    hostId: uid,
    perPersonAmount: amount,
    currency: group.currency,
    memberOrder: memberOrder,
  );
  if (!context.mounted) return;
  context.pushNamed(
    'group-game',
    pathParameters: {'groupId': groupId, 'gameId': gameId},
    extra: {'groupName': group.name},
  );
}

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return BlocProvider(
      create: (context) => context.read<GroupCubit>()..loadGroup(groupId),
      child: Scaffold(
        backgroundColor: AppColors.stemBackground,
        body: SafeArea(
          child: BlocBuilder<GroupCubit, GroupState>(
            builder: (context, state) {
              if (state is GroupLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.stemEmerald),
                );
              }

              if (state is GroupError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.stemMutedText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: GoogleFonts.manrope(
                          color: AppColors.stemLightText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Retry',
                        onPressed: () =>
                            context.read<GroupCubit>().loadGroup(groupId),
                      ),
                    ],
                  ),
                );
              }

              if (state is GroupLoaded) {
                final group = state.group;
                return _StemGroupDetailBody(
                  group: group,
                  groupId: groupId,
                  currentUserId: currentUserId,
                );
              }

              return const Center(
                child: Text(
                  'No group data',
                  style: TextStyle(color: AppColors.stemMutedText),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}

Future<void> _showGroupActions(
  BuildContext context, {
  required GroupModel group,
  required String groupId,
  required String? currentUserId,
}) async {
  final isCreator = group.creatorId == currentUserId;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.stemCard,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppColors.stemMutedText),
                title: Text(
                  'Edit',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemLightText,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!isCreator) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Only admin can edit group.'),
                      ),
                    );
                    return;
                  }
                  await _showEditGroupDialog(
                    context,
                    group: group,
                    groupId: groupId,
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  'Delete',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!isCreator) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Only admin can delete group.'),
                      ),
                    );
                    return;
                  }
                  await _confirmAndDeleteGroup(
                    context,
                    groupId: groupId,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showEditGroupDialog(
  BuildContext context, {
  required GroupModel group,
  required String groupId,
}) async {
    final nameController = TextEditingController(text: group.name);
    final descriptionController =
        TextEditingController(text: group.description);

    try {
      bool isSaving = false;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                backgroundColor: AppColors.stemCard,
                title: Text(
                  'Edit Group',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.stemLightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: AppColors.stemLightText),
                        decoration: InputDecoration(
                          labelText: 'Group Name',
                          labelStyle: TextStyle(
                            color: AppColors.stemMutedText.withValues(alpha: 0.9),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.borderGreyDark
                                  .withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.stemEmerald.withValues(alpha: 0.8),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: AppColors.stemLightText),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(
                            color: AppColors.stemMutedText.withValues(alpha: 0.9),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.borderGreyDark
                                  .withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.stemEmerald.withValues(alpha: 0.8),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.pop(ctx);
                          },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.stemMutedText),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setState(() => isSaving = true);
                            final newName = nameController.text.trim();
                            final newDesc = descriptionController.text.trim();

                            if (newName.isEmpty) {
                              if (!context.mounted) return;
                              setState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Group name can not be empty.'),
                                ),
                              );
                              return;
                            }

                            try {
                              await di
                                  .sl<GroupRemoteDataSource>()
                                  .updateGroup(groupId, {
                                'name': newName,
                                'description': newDesc,
                              });

                              await context
                                  .read<GroupCubit>()
                                  .loadGroup(groupId);

                              if (!context.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Group updated.'),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              setState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update group.'),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

Future<void> _confirmAndDeleteGroup(
  BuildContext context, {
  required String groupId,
}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.stemCard,
          title: Text(
            'Delete Group?',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.stemLightText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This will permanently delete the group and its related data.',
            style: TextStyle(color: AppColors.stemMutedText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await context.read<GroupCubit>().deleteGroup(groupId);
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete group: $e')),
      );
    }
  }

class _StemGroupDetailBody extends StatelessWidget {
  final GroupModel group;
  final String groupId;
  final String? currentUserId;

  const _StemGroupDetailBody({
    required this.group,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isCreator = group.creatorId == currentUserId;
    final isMember = group.members.containsKey(currentUserId);

    return RefreshIndicator(
      onRefresh: () => context.read<GroupCubit>().loadGroup(groupId),
      color: AppColors.stemEmerald,
      backgroundColor: AppColors.stemCard,
      child: CustomScrollView(
        slivers: [
          _StemHeader(
            groupName: group.name,
            onBack: () => context.pop(),
            onMenu: () => _showGroupActions(
              context,
              group: group,
              groupId: groupId,
              currentUserId: currentUserId,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GroupHero(
                    group: group,
                    groupId: groupId,
                    isCreator: isCreator,
                    currentUserId: currentUserId,
                  ),
                  const SizedBox(height: 24),
                  if (isMember) ...[
                    _ActionButtons(
                      groupId: groupId,
                      group: group,
                    ),
                    const SizedBox(height: 24),
                    _StemBentoSection(
                      groupId: groupId,
                      group: group,
                      currentUserId: currentUserId ?? '',
                    ),
                    const SizedBox(height: 24),
                    ExpenseSection(
                      groupId: groupId,
                      group: group,
                      currentUserId: currentUserId ?? '',
                      isDark: true,
                      theme: Theme.of(context),
                      hideBalanceCard: true,
                      hideHeader: true,
                      useStemDesign: true,
                    ),
                  ] else ...[
                    AppButton(
                      text: 'Join Group',
                      height: 48,
                      onPressed: () {
                        if (currentUserId != null) {
                          context
                              .read<GroupCubit>()
                              .joinGroup(groupId, currentUserId!);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StemHeader extends StatelessWidget {
  final String groupName;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  const _StemHeader({
    required this.groupName,
    required this.onBack,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: AppColors.stemLightText,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  groupName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemEmerald,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),

            GestureDetector(
              onTap: onMenu,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.abc_outlined,
                  size: 20,
                  color: AppColors.stemLightText,
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
}

class _GroupHero extends StatelessWidget {
  final GroupModel group;
  final String groupId;
  final bool isCreator;
  final String? currentUserId;

  const _GroupHero({
    required this.group,
    required this.groupId,
    required this.isCreator,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isCreator)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.stemEmerald.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.stemEmerald.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ADMIN',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemEmerald,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (isCreator) const SizedBox(width: 12),
            Row(
              children: [
                Icon(Icons.people_outline, size: 14, color: AppColors.stemMutedText),
                const SizedBox(width: 4),
                Text(
                  '${group.memberCount} members',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.stemMutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          group.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.stemLightText,
            letterSpacing: -0.9,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SettleUpDateButton(
          groupId: groupId,
          group: group,
          isDark: true,
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String groupId;
  final GroupModel group;

  const _ActionButtons({
    required this.groupId,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StemActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Open Chat',
                onTap: () => context.push(
                  '${AppRoutes.chat}/$groupId?name=${Uri.encodeComponent(group.name)}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StemActionButton(
                icon: Icons.person_add_outlined,
                label: 'Add\nMember',
                onTap: () => AddMemberOptionsSheet.show(
                  context,
                  groupId: groupId,
                  groupName: group.name,
                  isDark: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StemActionButton(
          icon: Icons.quiz_outlined,
          label: 'Question game',
          onTap: () => openGroupQuestionGame(
            context,
            groupId: groupId,
            group: group,
          ),
        ),
      ],
    );
  }
}

class _StemActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StemActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.stemSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF404944).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.stemLightText),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.stemLightText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StemBentoSection extends StatelessWidget {
  final String groupId;
  final GroupModel group;
  final String currentUserId;

  const _StemBentoSection({
    required this.groupId,
    required this.group,
    required this.currentUserId,
  });

  static String _currencySymbol(String c) {
    switch (c) {
      case 'INR':
        return '₹';
      case 'PKR':
        return 'Rs. ';
      case 'USD':
        return '\$';
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, _) {
        return StreamBuilder<List<ExpenseModel>>(
          stream: context.read<ExpenseCubit>().getGroupExpenses(groupId),
          builder: (context, snapshot) {
            final expenses = snapshot.data ?? [];
            final balances =
                ExpenseCubit.calculateBalances(currentUserId, expenses);
            double youOwe = 0;
            double youLent = 0;
            for (final v in balances.values) {
              if (v > 0) youOwe += v;
              if (v < 0) youLent += -v;
            }
            final membersWhoOwe = balances.entries
                .where((e) => e.value > 0)
                .map((e) => {
                      'userId': e.key,
                      'amount': e.value,
                    })
                .toList();
            final totalBalance = youLent - youOwe;
            final sym = _currencySymbol(group.currency);

            return Column(
              children: [
                _StemBalanceCard(
                  totalBalance: totalBalance,
                  youOwe: youOwe,
                  membersWhoOwe: membersWhoOwe,
                  currency: sym,
                  groupId: groupId,
                  group: group,
                ),
                const SizedBox(height: 24),
                StemMembersCard(
                  group: group,
                  currentUserId: currentUserId,
                  balances: balances,
                  currency: sym,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StemBalanceCard extends StatelessWidget {
  final double totalBalance;
  final double youOwe;
  final List<Map<String, dynamic>> membersWhoOwe;
  final String currency;
  final String groupId;
  final GroupModel group;

  const _StemBalanceCard({
    required this.totalBalance,
    required this.youOwe,
    required this.membersWhoOwe,
    required this.currency,
    required this.groupId,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.9, 0.5),
          end: Alignment(-0.1, 0.5),
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF002115).withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currency${totalBalance.abs().toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF002115),
              letterSpacing: -2.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(
                AppRoutes.addExpense,
                extra: {'groupId': groupId, 'group': group},
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002115),
                foregroundColor: const Color(0xFFADF1D0),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'ADD EXPENSE',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (membersWhoOwe.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nothing to settle.')),
                  );
                  return;
                }

                SettleUpSheet.show(
                  context: context,
                  groupId: groupId,
                  group: group,
                  membersWhoOwe: membersWhoOwe,
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF002115).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF002115),
                side: BorderSide(
                  color: const Color(0xFF002115).withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'SETTLE UP',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
