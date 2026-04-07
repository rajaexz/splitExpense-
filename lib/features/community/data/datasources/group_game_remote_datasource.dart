import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/group_game_model.dart';

abstract class GroupGameRemoteDataSource {
  Stream<GroupGameModel?> watchGame(String groupId, String gameId);
  Future<GroupGameModel?> getGame(String groupId, String gameId);
  Future<String?> getLatestGameId(String groupId);
  Future<String> createGame({
    required String groupId,
    required String hostId,
    required double perPersonAmount,
    required String currency,
    required List<String> memberOrder,
  });
  Future<void> updateGame(
    String groupId,
    String gameId,
    Map<String, dynamic> updates,
  );
  Future<void> setInterestsForUser({
    required String groupId,
    required String gameId,
    required String userId,
    required String interestsText,
  });
  Future<void> agreeToAmount({
    required String groupId,
    required String gameId,
    required String userId,
  });

  /// Host can set any member; a member may only set [agreed] to true for themselves (or host toggles anyone).
  Future<void> setAmountAgreedForMember({
    required String groupId,
    required String gameId,
    required String memberUserId,
    required bool agreed,
  });
  Future<void> setPaid({
    required String groupId,
    required String gameId,
    required String userId,
    required bool paid,
  });
  /// Host moves to awaiting payment after all agreed (or sets amount flow).
  Future<void> hostSetStatus({
    required String groupId,
    required String gameId,
    required GroupGameStatus status,
  });
  Future<void> hostProceedToAwaitingPayment({
    required String groupId,
    required String gameId,
  });
  Future<void> hostStartActive({
    required String groupId,
    required String gameId,
  });
  Future<void> submitQuestion({
    required String groupId,
    required String gameId,
    required String userId,
    required String questionText,
    required List<String> options,
    required int correctOptionIndex,
  });
  Future<void> submitAnswer({
    required String groupId,
    required String gameId,
    required String userId,
    required String answerText,
  });
  Future<void> setWinners({
    required String groupId,
    required String gameId,
    required String firstId,
    required String secondId,
    required String thirdId,
  });
}

class GroupGameRemoteDataSourceImpl implements GroupGameRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GroupGameRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  CollectionReference<Map<String, dynamic>> _gamesCol(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('games');

  @override
  Stream<GroupGameModel?> watchGame(String groupId, String gameId) {
    return _gamesCol(groupId).doc(gameId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupGameModel.fromFirestore(doc, groupId: groupId);
    });
  }

  @override
  Future<GroupGameModel?> getGame(String groupId, String gameId) async {
    final doc = await _gamesCol(groupId).doc(gameId).get();
    if (!doc.exists) return null;
    return GroupGameModel.fromFirestore(doc, groupId: groupId);
  }

  @override
  Future<String?> getLatestGameId(String groupId) async {
    final snap = await _gamesCol(groupId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  @override
  Future<String> createGame({
    required String groupId,
    required String hostId,
    required double perPersonAmount,
    required String currency,
    required List<String> memberOrder,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != hostId) {
      throw Exception('Only the signed-in host can create a game');
    }
    final ref = _gamesCol(groupId).doc();
    final now = DateTime.now();
    final agreed = <String, bool>{
      for (final id in memberOrder) id: false,
    };
    final pays = <String, bool>{
      for (final id in memberOrder) id: false,
    };
    final model = GroupGameModel(
      id: ref.id,
      groupId: groupId,
      hostId: hostId,
      status: GroupGameStatus.setup,
      perPersonAmount: perPersonAmount,
      currency: currency,
      memberOrder: List<String>.from(memberOrder),
      currentTurnIndex: 0,
      questionCount: 0,
      questions: const [],
      interestsByUserId: {},
      amountAgreedBy: agreed,
      payments: pays,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set({
      ...model.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<void> updateGame(
    String groupId,
    String gameId,
    Map<String, dynamic> updates,
  ) async {
    await _gamesCol(groupId).doc(gameId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setInterestsForUser({
    required String groupId,
    required String gameId,
    required String userId,
    required String interestsText,
  }) async {
    await _gamesCol(groupId).doc(gameId).update({
      'interestsByUserId.$userId': interestsText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> agreeToAmount({
    required String groupId,
    required String gameId,
    required String userId,
  }) async {
    await setAmountAgreedForMember(
      groupId: groupId,
      gameId: gameId,
      memberUserId: userId,
      agreed: true,
    );
  }

  @override
  Future<void> setAmountAgreedForMember({
    required String groupId,
    required String gameId,
    required String memberUserId,
    required bool agreed,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    final game = await getGame(groupId, gameId);
    if (game == null) throw Exception('Game not found');
    if (game.status != GroupGameStatus.setup) {
      throw Exception('Amount agreement is only available during setup');
    }
    if (!game.memberOrder.contains(memberUserId)) {
      throw Exception('That user is not in this game');
    }
    final isHost = uid == game.hostId;
    if (memberUserId != uid && !isHost) {
      throw Exception('Only the host can record agreement for other members');
    }
    if (memberUserId == uid && !agreed && !isHost) {
      throw Exception('Ask the host to change your agreement');
    }
    await _gamesCol(groupId).doc(gameId).update({
      'amountAgreedBy.$memberUserId': agreed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setPaid({
    required String groupId,
    required String gameId,
    required String userId,
    required bool paid,
  }) async {
    await _gamesCol(groupId).doc(gameId).update({
      'payments.$userId': paid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> hostSetStatus({
    required String groupId,
    required String gameId,
    required GroupGameStatus status,
  }) async {
    final uid = _auth.currentUser?.uid;
    final game = await getGame(groupId, gameId);
    if (game == null || uid != game.hostId) {
      throw Exception('Only the host can change status');
    }
    await updateGame(groupId, gameId, {
      'status': GroupGameModel.statusToString(status),
    });
  }

  @override
  Future<void> hostProceedToAwaitingPayment({
    required String groupId,
    required String gameId,
  }) async {
    final uid = _auth.currentUser?.uid;
    final game = await getGame(groupId, gameId);
    if (game == null || uid != game.hostId) {
      throw Exception('Only the host can continue');
    }
    if (!game.allMembersAgreed()) {
      throw Exception('All members must agree to the amount first');
    }
    await updateGame(groupId, gameId, {
      'status': GroupGameModel.statusToString(GroupGameStatus.awaitingPayment),
    });
  }

  @override
  Future<void> hostStartActive({
    required String groupId,
    required String gameId,
  }) async {
    final uid = _auth.currentUser?.uid;
    final game = await getGame(groupId, gameId);
    if (game == null || uid != game.hostId) {
      throw Exception('Only the host can start the game');
    }
    if (game.status != GroupGameStatus.awaitingPayment) {
      throw Exception('Game must be in payment phase');
    }
    if (!game.allMembersPaid()) {
      throw Exception('All members must complete payment first');
    }
    await updateGame(groupId, gameId, {
      'status': GroupGameModel.statusToString(GroupGameStatus.active),
      'currentTurnIndex': 0,
      'questionCount': 0,
    });
  }

  @override
  Future<void> submitQuestion({
    required String groupId,
    required String gameId,
    required String userId,
    required String questionText,
    required List<String> options,
    required int correctOptionIndex,
  }) async {
    await _firestore.runTransaction((tx) async {
      final ref = _gamesCol(groupId).doc(gameId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Game not found');
      final g = GroupGameModel.fromFirestore(snap, groupId: groupId);
      if (g.status != GroupGameStatus.active) {
        throw Exception('Game is not active');
      }
      if (!g.allMembersPaid()) {
        throw Exception('All members must complete payment first');
      }
      final turn = g.currentTurnUserId();
      if (turn != userId) {
        throw Exception('Not your turn');
      }
      final q = questionText.trim();
      if (q.isEmpty) throw Exception('Question cannot be empty');
      final cleanedOptions = options.map((e) => e.trim()).toList();
      if (cleanedOptions.length != 4 || cleanedOptions.any((e) => e.isEmpty)) {
        throw Exception('Add exactly 4 non-empty options');
      }
      if (correctOptionIndex < 0 || correctOptionIndex >= 4) {
        throw Exception('Select a correct option');
      }

      // Must answer previous question before asking a new one.
      if (g.questionCount > 0 && g.questions.isNotEmpty) {
        final last = g.questions.last;
        final expectedAnswerer = last['answererId']?.toString();
        final ans = last['answerText']?.toString().trim() ?? '';
        if (expectedAnswerer == userId && ans.isEmpty) {
          throw Exception('Answer the previous question before asking your question');
        }
      }

      final now = Timestamp.now();
      final len = g.memberOrder.isEmpty ? 1 : g.memberOrder.length;
      final nextIndex = (g.currentTurnIndex + 1) % len;
      final nextAnswererId = g.memberOrder.isEmpty ? '' : g.memberOrder[nextIndex];
      final nextCount = g.questionCount + 1;

      final nextQuestions = List<Map<String, dynamic>>.from(g.questions);
      nextQuestions.add({
        'index': g.questionCount,
        'askerId': userId,
        'text': q,
        'options': cleanedOptions,
        'correctOptionIndex': correctOptionIndex,
        'correctAnswerText': cleanedOptions[correctOptionIndex],
        'askedAt': now,
        'answererId': nextAnswererId,
        'answerText': '',
        'answeredAt': null,
      });
      if (nextCount >= 10) {
        tx.update(ref, {
          'questionCount': 10,
          'currentTurnIndex': nextIndex,
          'questions': nextQuestions,
          'status': GroupGameModel.statusToString(GroupGameStatus.completed),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, {
          'questionCount': nextCount,
          'currentTurnIndex': nextIndex,
          'questions': nextQuestions,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> submitAnswer({
    required String groupId,
    required String gameId,
    required String userId,
    required String answerText,
  }) async {
    final a = answerText.trim();
    if (a.isEmpty) throw Exception('Answer cannot be empty');
    await _firestore.runTransaction((tx) async {
      final ref = _gamesCol(groupId).doc(gameId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Game not found');
      final g = GroupGameModel.fromFirestore(snap, groupId: groupId);
      if (g.status != GroupGameStatus.active) {
        throw Exception('Game is not active');
      }
      if (!g.allMembersPaid()) {
        throw Exception('All members must complete payment first');
      }
      final turn = g.currentTurnUserId();
      if (turn != userId) throw Exception('Not your turn');
      if (g.questions.isEmpty) throw Exception('No question to answer');
      final last = Map<String, dynamic>.from(g.questions.last);
      final expected = last['answererId']?.toString();
      if (expected != userId) throw Exception('No pending answer for you');
      final existing = last['answerText']?.toString().trim() ?? '';
      if (existing.isNotEmpty) return;

      last['answerText'] = a;
      last['answeredAt'] = Timestamp.now();
      final nextQuestions = List<Map<String, dynamic>>.from(g.questions);
      nextQuestions[nextQuestions.length - 1] = last;
      tx.update(ref, {
        'questions': nextQuestions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> setWinners({
    required String groupId,
    required String gameId,
    required String firstId,
    required String secondId,
    required String thirdId,
  }) async {
    final uid = _auth.currentUser?.uid;
    final game = await getGame(groupId, gameId);
    if (game == null || uid != game.hostId) {
      throw Exception('Only the host can set winners');
    }
    await updateGame(groupId, gameId, {
      'winnerFirstId': firstId,
      'winnerSecondId': secondId,
      'winnerThirdId': thirdId,
      'status': GroupGameModel.statusToString(GroupGameStatus.completed),
    });
  }
}
