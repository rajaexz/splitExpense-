import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../application/group/group_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../data/models/group_game_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../../domain/group_game_repository.dart';
import 'group_detail_page.dart';
import 'widgets/group_detail_widgets.dart';

Future<void> syncMissingMembersIntoGame({
  required String groupId,
  required GroupModel group,
  required String gameId,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid != group.creatorId) return;

  final ref = FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('games')
      .doc(gameId);
  final snap = await ref.get();
  if (!snap.exists) return;

  final game = GroupGameModel.fromFirestore(snap, groupId: groupId);
  final groupMemberIds = group.members.keys.toSet();
  final existing = game.memberOrder.toSet();
  final missing = groupMemberIds.difference(existing);
  if (missing.isEmpty) return;

  final missingSorted = missing.toList()..sort();
  final updatedOrder = <String>[...game.memberOrder, ...missingSorted];
  final updatedAgreed = Map<String, bool>.from(game.amountAgreedBy);
  final updatedPayments = Map<String, bool>.from(game.payments);
  final updatedInterests = Map<String, String>.from(game.interestsByUserId);

  for (final memberId in missingSorted) {
    updatedAgreed[memberId] = updatedAgreed[memberId] ?? false;
    updatedPayments[memberId] = updatedPayments[memberId] ?? false;
    updatedInterests[memberId] = updatedInterests[memberId] ?? '';
  }

  await ref.update({
    'memberOrder': updatedOrder,
    'amountAgreedBy': updatedAgreed,
    'payments': updatedPayments,
    'interestsByUserId': updatedInterests,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

class GameGroupDetailBody extends StatelessWidget {
  final GroupModel group;
  final String groupId;
  final String? currentUserId;
  final VoidCallback onMenu;
  final VoidCallback onBack;

  const GameGroupDetailBody({
    super.key,
    required this.group,
    required this.groupId,
    required this.currentUserId,
    required this.onMenu,
    required this.onBack,
  });

  Future<Map<String, String>> _loadDisplayNames(List<String> userIds) async {
    final out = <String, String>{};
    for (final uid in userIds.toSet()) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data() ?? const <String, dynamic>{};
        final name = (data['name'] as String?)?.trim();
        final displayName = (data['displayName'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          out[uid] = name;
        } else if (displayName != null && displayName.isNotEmpty) {
          out[uid] = displayName;
        }
      } catch (_) {
        // Ignore per-user lookup failure; fallback is handled in UI.
      }
    }
    return out;
  }

  Future<void> _removeMemberFromGroupAndGame(
    BuildContext context, {
    required String memberId,
    required String latestGameId,
    String? memberName,
  }) async {
    if (memberId == group.creatorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Host cannot be removed.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.stemCard,
        title: const Text('Remove member?'),
        content: Text(
          '${(memberName != null && memberName.isNotEmpty) ? memberName : 'This member'} will be removed from this game group.',
          style: GoogleFonts.manrope(color: AppColors.stemMutedText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
      final memberRef = groupRef.collection('members').doc(memberId);
      final gameRef = groupRef.collection('games').doc(latestGameId);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final groupSnap = await tx.get(groupRef);
        if (!groupSnap.exists) {
          throw Exception('Group not found');
        }

        final groupData = groupSnap.data() ?? <String, dynamic>{};
        final rawMembers = Map<String, dynamic>.from(
          groupData['members'] as Map<String, dynamic>? ?? {},
        );
        rawMembers.remove(memberId);

        tx.delete(memberRef);
        tx.update(groupRef, {
          'members': rawMembers,
          'memberCount': rawMembers.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final gameSnap = await tx.get(gameRef);
        if (gameSnap.exists) {
          final game = GroupGameModel.fromFirestore(gameSnap, groupId: groupId);
          final updatedOrder = game.memberOrder.where((id) => id != memberId).toList();
          final updatedAgreed = Map<String, bool>.from(game.amountAgreedBy)..remove(memberId);
          final updatedPayments = Map<String, bool>.from(game.payments)..remove(memberId);
          final updatedInterests = Map<String, String>.from(game.interestsByUserId)..remove(memberId);
          final safeTurn = updatedOrder.isEmpty
              ? 0
              : (game.currentTurnIndex >= updatedOrder.length ? 0 : game.currentTurnIndex);

          tx.update(gameRef, {
            'memberOrder': updatedOrder,
            'amountAgreedBy': updatedAgreed,
            'payments': updatedPayments,
            'interestsByUserId': updatedInterests,
            'currentTurnIndex': safeTurn,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (!context.mounted) return;
      await context.read<GroupCubit>().loadGroup(groupId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove member: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = group.creatorId == currentUserId;
    if (!di.sl.isRegistered<GroupGameRepository>()) {
      return const Center(
        child: Text(
          'Game service unavailable',
          style: TextStyle(color: AppColors.stemMutedText),
        ),
      );
    }
    final repo = di.sl<GroupGameRepository>();

    return RefreshIndicator(
      onRefresh: () => context.read<GroupCubit>().loadGroup(groupId),
      color: AppColors.stemEmerald,
      backgroundColor: AppColors.stemCard,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
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
                          child: Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.stemLightText),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        group.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.stemEmerald,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onMenu,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.abc_outlined, size: 20, color: AppColors.stemLightText),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
              child: FutureBuilder<String?>(
                future: repo.getLatestGameId(groupId),
                builder: (context, latestSnap) {
                  if (latestSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final latestGameId = latestSnap.data;
                  if (latestGameId == null) {
                    return _NoGameStateCard(
                      isCreator: isCreator,
                      onStart: () => openGroupQuestionGame(
                        context,
                        groupId: groupId,
                        group: group,
                      ),
                      onAddMember: isCreator
                          ? () => AddMemberOptionsSheet.show(
                                context,
                                groupId: groupId,
                                groupName: group.name,
                                isDark: true,
                              )
                          : null,
                    );
                  }
                  return StreamBuilder(
                    stream: repo.watchGame(groupId, latestGameId),
                    builder: (context, gameSnap) {
                      if (gameSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final game = gameSnap.data;
                      if (game == null) {
                        return const SizedBox.shrink();
                      }
                      final allMembers = game.memberOrder.isNotEmpty
                          ? <String>{...game.memberOrder, ...group.members.keys}.toList()
                          : group.members.keys.toList()
                        ..sort();
                      final paidMembers = allMembers.where((id) => game.payments[id] == true).toList();
                      final unpaidMembers = allMembers.where((id) => game.payments[id] != true).toList();
                      final answeredUserIds = <String>{};
                      for (final q in game.questions) {
                        final answerText = q['answerText']?.toString().trim() ?? '';
                        final answererId = q['answererId']?.toString();
                        if (answerText.isNotEmpty && answererId != null && answererId.isNotEmpty) {
                          answeredUserIds.add(answererId);
                        }
                      }
                      final unansweredUserIds =
                          allMembers.where((id) => !answeredUserIds.contains(id)).toList();
                      final answeredItems = game.questions.where((q) {
                        final answerText = q['answerText']?.toString().trim() ?? '';
                        return answerText.isNotEmpty;
                      }).toList();
                      return FutureBuilder<Map<String, String>>(
                        future: _loadDisplayNames(allMembers),
                        builder: (context, namesSnap) {
                          final names = namesSnap.data ?? const <String, String>{};
                          String nameForUserId(String uid) {
                            if (uid == currentUserId) return 'You';
                            final n = names[uid]?.trim();
                            return (n != null && n.isNotEmpty) ? n : 'Member';
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.stemSurface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Paid: ${paidMembers.length} / ${allMembers.length}',
                                  style: GoogleFonts.manrope(color: AppColors.stemMutedText),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.stemSurface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Questions asked: ${game.questionCount} / 10',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.stemLightText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Answered members: ${answeredUserIds.length}',
                                      style: GoogleFonts.manrope(color: AppColors.stemMutedText),
                                    ),
                                    const SizedBox(height: 10),
                                    _InlineMemberStatus(
                                      title: 'Answered',
                                      userIds: answeredUserIds.toList()..sort(),
                                      nameForUserId: nameForUserId,
                                      emptyText: 'No one answered yet',
                                      icon: Icons.check_circle_outline,
                                      iconColor: AppColors.stemEmerald,
                                    ),
                                    const SizedBox(height: 10),
                                    _InlineMemberStatus(
                                      title: 'Not answered',
                                      userIds: unansweredUserIds,
                                      nameForUserId: nameForUserId,
                                      emptyText: 'Everyone has answered at least once',
                                      icon: Icons.pending_actions,
                                      iconColor: AppColors.stemMutedText,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.stemSurface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _AnsweredHistoryList(
                                  answeredItems: answeredItems,
                                  nameForUserId: nameForUserId,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.quiz_outlined,
                                      label: 'Open game',
                                      onTap: () async {
                                        await syncMissingMembersIntoGame(
                                          groupId: groupId,
                                          group: group,
                                          gameId: latestGameId,
                                        );
                                        if (!context.mounted) return;
                                        context.pushNamed(
                                          'group-game',
                                          pathParameters: {'groupId': groupId, 'gameId': latestGameId},
                                          extra: {'groupName': group.name},
                                        );
                                      },
                                    ),
                                  ),
                                  if (isCreator) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ActionButton(
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              DefaultTabController(
                                length: 2,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.stemSurface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const TabBar(
                                        indicatorColor: AppColors.stemEmerald,
                                        labelColor: AppColors.stemLightText,
                                        unselectedLabelColor: AppColors.stemMutedText,
                                        tabs: [Tab(text: 'Paid'), Tab(text: 'Unpaid')],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 360,
                                      child: TabBarView(
                                        children: [
                                          _PaymentMembersList(
                                            userIds: paidMembers,
                                            emptyText: 'No one has paid yet.',
                                            isCreator: isCreator,
                                            creatorId: group.creatorId,
                                            onSetPaid: (uid, paid) => repo.setPaid(
                                              groupId: groupId,
                                              gameId: latestGameId,
                                              userId: uid,
                                              paid: paid,
                                            ),
                                            onRemoveMember: (uid, displayName) => _removeMemberFromGroupAndGame(
                                              context,
                                              memberId: uid,
                                              latestGameId: latestGameId,
                                              memberName: displayName,
                                            ),
                                            nameForUserId: nameForUserId,
                                            paidValue: true,
                                          ),
                                          _PaymentMembersList(
                                            userIds: unpaidMembers,
                                            emptyText: 'All members have paid.',
                                            isCreator: isCreator,
                                            creatorId: group.creatorId,
                                            onSetPaid: (uid, paid) => repo.setPaid(
                                              groupId: groupId,
                                              gameId: latestGameId,
                                              userId: uid,
                                              paid: paid,
                                            ),
                                            onRemoveMember: (uid, displayName) => _removeMemberFromGroupAndGame(
                                              context,
                                              memberId: uid,
                                              latestGameId: latestGameId,
                                              memberName: displayName,
                                            ),
                                            nameForUserId: nameForUserId,
                                            paidValue: false,
                                          ),
                                        ],
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.stemLightText),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.stemLightText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoGameStateCard extends StatelessWidget {
  final bool isCreator;
  final VoidCallback onStart;
  final VoidCallback? onAddMember;
  const _NoGameStateCard({required this.isCreator, required this.onStart, this.onAddMember});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.stemSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No game started', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.stemLightText)),
          const SizedBox(height: 8),
          Text(
            isCreator ? 'Start a new game to track who paid and who is pending.' : 'Ask admin to start the game for this group.',
            style: GoogleFonts.manrope(color: AppColors.stemMutedText),
          ),
          if (isCreator) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (onAddMember != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAddMember,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Add member'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(child: ElevatedButton(onPressed: onStart, child: const Text('Start Game'))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMembersList extends StatelessWidget {
  final List<String> userIds;
  final String emptyText;
  final bool isCreator;
  final String creatorId;
  final Future<void> Function(String userId, bool paid) onSetPaid;
  final Future<void> Function(String userId, String displayName) onRemoveMember;
  final String Function(String userId) nameForUserId;
  final bool paidValue;

  const _PaymentMembersList({
    required this.userIds,
    required this.emptyText,
    required this.isCreator,
    required this.creatorId,
    required this.onSetPaid,
    required this.onRemoveMember,
    required this.nameForUserId,
    required this.paidValue,
  });

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) {
      return Center(child: Text(emptyText, style: GoogleFonts.manrope(color: AppColors.stemMutedText)));
    }
    return ListView.separated(
      itemCount: userIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final uid = userIds[index];
        return ListTile(
          tileColor: AppColors.stemSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: CircleAvatar(
            backgroundColor: AppColors.stemEmerald.withValues(alpha: 0.15),
            child: Icon(paidValue ? Icons.check : Icons.pending_actions, color: paidValue ? AppColors.stemEmerald : AppColors.stemMutedText),
          ),
          title: Text(nameForUserId(uid), style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.stemLightText)),
          subtitle: Text(paidValue ? 'Payment completed' : 'Payment pending', style: GoogleFonts.manrope(color: AppColors.stemMutedText)),
          trailing: isCreator
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: paidValue,
                      onChanged: (v) async => onSetPaid(uid, v),
                      activeColor: AppColors.stemEmerald,
                    ),
                    if (uid != creatorId)
                      IconButton(
                        tooltip: 'Remove member',
                        onPressed: () => onRemoveMember(uid, nameForUserId(uid)),
                        icon: const Icon(Icons.person_remove_outlined, color: AppColors.error),
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class _InlineMemberStatus extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final String Function(String userId) nameForUserId;
  final String emptyText;
  final IconData icon;
  final Color iconColor;

  const _InlineMemberStatus({
    required this.title,
    required this.userIds,
    required this.nameForUserId,
    required this.emptyText,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.stemLightText,
          ),
        ),
        const SizedBox(height: 6),
        if (userIds.isEmpty)
          Text(
            emptyText,
            style: GoogleFonts.manrope(color: AppColors.stemMutedText),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: userIds
                .map(
                  (id) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.stemBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: iconColor),
                        const SizedBox(width: 6),
                        Text(
                          nameForUserId(id),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.stemLightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _AnsweredHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> answeredItems;
  final String Function(String userId) nameForUserId;

  const _AnsweredHistoryList({
    required this.answeredItems,
    required this.nameForUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (answeredItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who answered what',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.stemLightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No answers submitted yet.',
            style: GoogleFonts.manrope(color: AppColors.stemMutedText),
          ),
        ],
      );
    }

    final latestFirst = answeredItems.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who answered what',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.stemLightText,
          ),
        ),
        const SizedBox(height: 10),
        ...latestFirst.map((item) {
          final answererId = item['answererId']?.toString() ?? '';
          final answererName =
              answererId.isEmpty ? 'Member' : nameForUserId(answererId);
          final questionText = item['text']?.toString().trim() ?? '';
          final answerText = item['answerText']?.toString().trim() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answererName,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemLightText,
                  ),
                ),
                if (questionText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Q: $questionText',
                    style: GoogleFonts.manrope(
                      color: AppColors.stemMutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'A: $answerText',
                  style: GoogleFonts.manrope(
                    color: AppColors.stemLightText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
