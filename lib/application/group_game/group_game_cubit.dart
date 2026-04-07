import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/group_game_model.dart';
import '../../domain/group_game_repository.dart';
import '../../features/community/data/datasources/game_content_remote_datasource.dart';
import '../../features/community/data/datasources/notification_remote_datasource.dart';
import 'group_game_state.dart';

class GroupGameCubit extends Cubit<GroupGameState> {
  GroupGameCubit(
    this._repository,
    this._notifications,
    this._gameContent,
    this._firestore,
  ) : super(GroupGameInitial());

  final GroupGameRepository _repository;
  final NotificationRemoteDataSource _notifications;
  final GameContentRemoteDataSource _gameContent;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<GroupGameModel?>? _gameSub;
  String? _groupId;
  String? _gameId;
  String? _groupName;

  Future<void> retry() async {
    final gid = _groupId;
    final g = _gameId;
    if (gid == null || g == null) return;
    await subscribe(groupId: gid, gameId: g, groupName: _groupName);
  }

  Future<void> subscribe({
    required String groupId,
    required String gameId,
    String? groupName,
  }) async {
    _groupId = groupId;
    _gameId = gameId;
    _groupName = groupName;
    emit(GroupGameLoading());
    await _gameSub?.cancel();
    _gameSub = _repository.watchGame(groupId, gameId).listen(
      (game) async {
        if (game == null) {
          emit(GroupGameNotFound());
          return;
        }
        final names = await _loadDisplayNames(game.memberOrder);
        final prev = state;
        if (prev is GroupGameLoaded) {
          emit(prev.copyWith(game: game, displayNames: names));
        } else {
          emit(GroupGameLoaded(game, displayNames: names));
        }
      },
      onError: (Object e, _) => emit(GroupGameError(e.toString())),
    );
  }

  Future<Map<String, String>> _loadDisplayNames(List<String> uids) async {
    final out = <String, String>{};
    for (final uid in uids.toSet()) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        final name = doc.data()?['name'] as String? ?? doc.data()?['displayName'] as String?;
        out[uid] = (name != null && name.isNotEmpty) ? name : 'Member';
      } catch (_) {
        out[uid] = 'Member';
      }
    }
    return out;
  }

  Future<void> agreeToAmount() async {
    final uid = _auth.currentUser?.uid;
    final gid = _groupId;
    final gameId = _gameId;
    if (uid == null || gid == null || gameId == null) return;
    try {
      await _repository.agreeToAmount(
        groupId: gid,
        gameId: gameId,
        userId: uid,
      );
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  /// Host only: mark whether [memberUserId] agreed to the amount (setup phase).
  Future<void> hostSetMemberAmountAgreed(
    String memberUserId,
    bool agreed,
  ) async {
    final gid = _groupId;
    final gameId = _gameId;
    if (gid == null || gameId == null) return;
    try {
      await _repository.setAmountAgreedForMember(
        groupId: gid,
        gameId: gameId,
        memberUserId: memberUserId,
        agreed: agreed,
      );
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  Future<void> setPaid({required bool paid}) async {
    final uid = _auth.currentUser?.uid;
    final gid = _groupId;
    final gameId = _gameId;
    if (uid == null || gid == null || gameId == null) return;
    try {
      await _repository.setPaid(
        groupId: gid,
        gameId: gameId,
        userId: uid,
        paid: paid,
      );
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  Future<void> hostSetMemberPaid(String userId, bool paid) async {
    final gid = _groupId;
    final gameId = _gameId;
    if (gid == null || gameId == null) return;
    try {
      await _repository.setPaid(
        groupId: gid,
        gameId: gameId,
        userId: userId,
        paid: paid,
      );
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  Future<void> hostProceedToAwaitingPayment() async {
    final gid = _groupId;
    final gameId = _gameId;
    if (gid == null || gameId == null) return;
    try {
      await _repository.hostProceedToAwaitingPayment(
        groupId: gid,
        gameId: gameId,
      );
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  Future<void> hostStartActive() async {
    final gid = _groupId;
    final gameId = _gameId;
    if (gid == null || gameId == null) return;
    try {
      await _repository.hostStartActive(groupId: gid, gameId: gameId);
      final game = await _repository.getGame(gid, gameId);
      if (game != null) {
        final nextId = game.currentTurnUserId();
        if (nextId != null) {
          final gname = _groupName ?? 'Group';
          final names = await _loadDisplayNames([nextId]);
          final recipient = _recipientFirstName(names[nextId]);
          final turnBody = await _aiBodyOrFallback(
            kind: 'turn_reminder',
            fallback: _fallbackTurnBody(gname),
            extra: {'recipientName': recipient},
          );
          await _notifications.sendGameTurnNotification(
            groupId: gid,
            groupName: gname,
            targetUserId: nextId,
            gameId: gameId,
            body: turnBody,
          );
        }
      }
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  /// Persists interests for the current user. Does not emit [GroupGameError] — callers should show SnackBar on failure.
  Future<void> setInterestsForSelf(String text) async {
    final uid = _auth.currentUser?.uid;
    final gid = _groupId;
    final gameId = _gameId;
    if (uid == null || gid == null || gameId == null) {
      throw StateError('Not signed in or game not loaded');
    }
    await _repository.setInterestsForUser(
      groupId: gid,
      gameId: gameId,
      userId: uid,
      interestsText: text.trim(),
    );
  }

  Future<String?> generateQuestion({required bool favoriteMode}) async {
    final gid = _groupId;
    final gameId = _gameId;
    final uid = _auth.currentUser?.uid;
    if (gid == null || gameId == null || uid == null) return null;
    final s = state;
    if (s is! GroupGameLoaded) return null;
    emit(s.copyWith(aiGenerating: true));
    try {
      final kind = favoriteMode ? 'question_favorite' : 'question_random';
      final interests = s.game.interestsByUserId[uid] ?? '';
      if (favoriteMode && interests.isEmpty) {
        emit(s.copyWith(aiGenerating: false));
        throw Exception('Add your interests first for Favorite mode');
      }
      final text = await _gameContent.generateGameContent({
        'kind': kind,
        'groupId': gid,
        'groupName': _groupName ?? 'Group',
        'interests': interests,
      });
      emit(s.copyWith(aiGenerating: false));
      return text;
    } catch (e) {
      emit(s.copyWith(aiGenerating: false));
      rethrow;
    }
  }

  Future<void> submitQuestion({
    required String questionText,
    required List<String> options,
    required int correctOptionIndex,
  }) async {
    final uid = _auth.currentUser?.uid;
    final gid = _groupId;
    final gameId = _gameId;
    if (uid == null || gid == null || gameId == null) return;
    try {
      await _repository.submitQuestion(
        groupId: gid,
        gameId: gameId,
        userId: uid,
        questionText: questionText,
        options: options,
        correctOptionIndex: correctOptionIndex,
      );
      final gameAfter = await _repository.getGame(gid, gameId);
      if (gameAfter == null) return;
      final gname = _groupName ?? 'Group';

      if (gameAfter.status == GroupGameStatus.completed &&
          gameAfter.questionCount >= 10) {
        final completeBody = await _aiBodyOrFallback(
          kind: 'game_complete',
          fallback: _fallbackGameCompleteBody(gname),
        );
        await _notifications.sendGameCompleteNotification(
          groupId: gid,
          groupName: gname,
          memberUserIds: gameAfter.memberOrder,
          gameId: gameId,
          body: completeBody,
        );
        return;
      }

      if (gameAfter.status == GroupGameStatus.active &&
          gameAfter.questionCount < 10) {
        final nextId = gameAfter.currentTurnUserId();
        if (nextId != null) {
          final names = await _loadDisplayNames([nextId]);
          final recipient = _recipientFirstName(names[nextId]);
          final turnBody = await _aiBodyOrFallback(
            kind: 'turn_reminder',
            fallback: _fallbackTurnBody(gname),
            extra: {'recipientName': recipient},
          );
          await _notifications.sendGameTurnNotification(
            groupId: gid,
            groupName: gname,
            targetUserId: nextId,
            gameId: gameId,
            body: turnBody,
          );
        }
      }
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  Future<void> submitAnswer({required String answerText}) async {
    final uid = _auth.currentUser?.uid;
    final gid = _groupId;
    final gameId = _gameId;
    if (uid == null || gid == null || gameId == null) return;
    try {
      await _repository.submitAnswer(
        groupId: gid,
        gameId: gameId,
        userId: uid,
        answerText: answerText,
      );
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  Future<void> setWinners({
    required String firstId,
    required String secondId,
    required String thirdId,
  }) async {
    final gid = _groupId;
    final gameId = _gameId;
    if (gid == null || gameId == null) return;
    try {
      await _repository.setWinners(
        groupId: gid,
        gameId: gameId,
        firstId: firstId,
        secondId: secondId,
        thirdId: thirdId,
      );
      final game = await _repository.getGame(gid, gameId);
      final members = game?.memberOrder ?? [];
      final names = await _resolveWinnerNames(firstId, secondId, thirdId);
      final gname = _groupName ?? 'Group';
      final winnerBody = await _aiBodyOrFallback(
        kind: 'winner_announcement',
        fallback: _fallbackWinnerBody(names[0], names[1], names[2]),
        extra: {
          'firstName': names[0],
          'secondName': names[1],
          'thirdName': names[2],
        },
      );
      await _notifications.sendGameWinnerAnnouncement(
        groupId: gid,
        groupName: gname,
        memberUserIds: members,
        firstName: names[0],
        secondName: names[1],
        thirdName: names[2],
        gameId: gameId,
        body: winnerBody,
      );
    } catch (e) {
      emit(GroupGameError(e.toString()));
    }
  }

  Future<List<String>> _resolveWinnerNames(
    String a,
    String b,
    String c,
  ) async {
    final m = await _loadDisplayNames([a, b, c]);
    return [m[a] ?? '1st', m[b] ?? '2nd', m[c] ?? '3rd'];
  }

  Future<void> sendPaymentReminderTo(String targetUserId) async {
    final gid = _groupId;
    final gameId = _gameId;
    if (gid == null || gameId == null) return;
    final gname = _groupName ?? 'Group';
    final names = await _loadDisplayNames([targetUserId]);
    final recipient = _recipientFirstName(names[targetUserId]);
    final body = await _aiBodyOrFallback(
      kind: 'payment_reminder',
      fallback: _fallbackPaymentReminderBody(gname),
      extra: {'recipientName': recipient},
    );
    await _notifications.sendGamePaymentReminder(
      groupId: gid,
      groupName: gname,
      targetUserId: targetUserId,
      gameId: gameId,
      body: body,
    );
  }

  Future<void> sendPokeTo(String targetUserId) async {
    final gid = _groupId;
    final gameId = _gameId;
    if (gid == null || gameId == null) return;
    final gname = _groupName ?? 'Group';
    final names = await _loadDisplayNames([targetUserId]);
    final recipient = _recipientFirstName(names[targetUserId]);
    final body = await _aiBodyOrFallback(
      kind: 'poke',
      fallback: _fallbackPokeBody(gname),
      extra: {'recipientName': recipient},
    );
    await _notifications.sendGamePoke(
      groupId: gid,
      groupName: gname,
      targetUserId: targetUserId,
      gameId: gameId,
      body: body,
    );
  }

  String _recipientFirstName(String? displayName) {
    final s = displayName?.trim() ?? '';
    if (s.isEmpty) return 'Friend';
    return s.split(RegExp(r'\s+')).first;
  }

  Future<String> _aiBodyOrFallback({
    required String kind,
    required String fallback,
    Map<String, dynamic>? extra,
  }) async {
    final gid = _groupId;
    if (gid == null) return fallback;
    try {
      final payload = <String, dynamic>{
        'kind': kind,
        'groupId': gid,
        'groupName': _groupName ?? 'Group',
        ...?extra,
      };
      final text = await _gameContent.generateGameContent(payload);
      final t = text.trim();
      if (t.isEmpty) return fallback;
      return t;
    } catch (_) {
      return fallback;
    }
  }

  static String _fallbackTurnBody(String groupName) =>
      "It's your turn to ask a question in $groupName.";

  static String _fallbackPaymentReminderBody(String groupName) =>
      'Please complete your payment for the group game in $groupName so everyone can continue.';

  static String _fallbackPokeBody(String groupName) =>
      'Friendly reminder from $groupName: your share is still waiting. Tap in and save the game!';

  static String _fallbackWinnerBody(
    String firstName,
    String secondName,
    String thirdName,
  ) =>
      'We have our podium: 1st $firstName, 2nd $secondName, 3rd $thirdName. Thanks for playing!';

  static String _fallbackGameCompleteBody(String groupName) =>
      'The question game in $groupName is finished. Thank you all for playing!';

  @override
  Future<void> close() {
    _gameSub?.cancel();
    return super.close();
  }
}
