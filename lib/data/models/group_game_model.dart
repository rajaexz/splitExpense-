import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a group question game.
enum GroupGameStatus {
  setup,
  awaitingPayment,
  active,
  completed,
}

class GroupGameModel {
  final String id;
  final String groupId;
  final String hostId;
  final GroupGameStatus status;
  final double perPersonAmount;
  final String currency;
  /// Host first, then circular order.
  final List<String> memberOrder;
  /// Index into [memberOrder] for whose turn it is to ask.
  final int currentTurnIndex;
  /// Total questions asked (0–10).
  final int questionCount;
  /// In-game questions (max 10), with optional answers.
  /// Stored as a list of maps to keep Firestore writes simple.
  final List<Map<String, dynamic>> questions;
  /// Optional interests/hobbies per user for AI favorite mode (per-game).
  final Map<String, String> interestsByUserId;
  final Map<String, bool> amountAgreedBy;
  final Map<String, bool> payments;
  final String? winnerFirstId;
  final String? winnerSecondId;
  final String? winnerThirdId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupGameModel({
    required this.id,
    required this.groupId,
    required this.hostId,
    required this.status,
    required this.perPersonAmount,
    required this.currency,
    required this.memberOrder,
    required this.currentTurnIndex,
    required this.questionCount,
    required this.questions,
    required this.interestsByUserId,
    required this.amountAgreedBy,
    required this.payments,
    this.winnerFirstId,
    this.winnerSecondId,
    this.winnerThirdId,
    required this.createdAt,
    required this.updatedAt,
  });

  static GroupGameStatus _statusFromString(String? s) {
    switch (s) {
      case 'awaiting_payment':
        return GroupGameStatus.awaitingPayment;
      case 'active':
        return GroupGameStatus.active;
      case 'completed':
        return GroupGameStatus.completed;
      case 'setup':
      default:
        return GroupGameStatus.setup;
    }
  }

  static String statusToString(GroupGameStatus status) {
    switch (status) {
      case GroupGameStatus.setup:
        return 'setup';
      case GroupGameStatus.awaitingPayment:
        return 'awaiting_payment';
      case GroupGameStatus.active:
        return 'active';
      case GroupGameStatus.completed:
        return 'completed';
    }
  }

  factory GroupGameModel.fromFirestore(
    DocumentSnapshot doc, {
    required String groupId,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final order = data['memberOrder'];
    final rawQuestions = data['questions'];
    return GroupGameModel(
      id: doc.id,
      groupId: groupId,
      hostId: data['hostId'] ?? '',
      status: _statusFromString(data['status'] as String?),
      perPersonAmount: (data['perPersonAmount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'INR',
      memberOrder: order is List
          ? order.map((e) => e.toString()).toList()
          : <String>[],
      currentTurnIndex: (data['currentTurnIndex'] as num?)?.toInt() ?? 0,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      questions: rawQuestions is List
          ? rawQuestions
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m as Map))
              .toList()
          : const <Map<String, dynamic>>[],
      interestsByUserId: Map<String, String>.from(
        (data['interestsByUserId'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            ) ??
            {},
      ),
      amountAgreedBy: Map<String, bool>.from(
        (data['amountAgreedBy'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v == true),
            ) ??
            {},
      ),
      payments: Map<String, bool>.from(
        (data['payments'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v == true),
            ) ??
            {},
      ),
      winnerFirstId: data['winnerFirstId'] as String?,
      winnerSecondId: data['winnerSecondId'] as String?,
      winnerThirdId: data['winnerThirdId'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'hostId': hostId,
      'status': statusToString(status),
      'perPersonAmount': perPersonAmount,
      'currency': currency,
      'memberOrder': memberOrder,
      'currentTurnIndex': currentTurnIndex,
      'questionCount': questionCount,
      'questions': questions,
      'interestsByUserId': interestsByUserId,
      'amountAgreedBy': amountAgreedBy,
      'payments': payments,
      if (winnerFirstId != null) 'winnerFirstId': winnerFirstId,
      if (winnerSecondId != null) 'winnerSecondId': winnerSecondId,
      if (winnerThirdId != null) 'winnerThirdId': winnerThirdId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GroupGameModel copyWith({
    String? id,
    String? groupId,
    String? hostId,
    GroupGameStatus? status,
    double? perPersonAmount,
    String? currency,
    List<String>? memberOrder,
    int? currentTurnIndex,
    int? questionCount,
    List<Map<String, dynamic>>? questions,
    Map<String, String>? interestsByUserId,
    Map<String, bool>? amountAgreedBy,
    Map<String, bool>? payments,
    String? winnerFirstId,
    String? winnerSecondId,
    String? winnerThirdId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupGameModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      perPersonAmount: perPersonAmount ?? this.perPersonAmount,
      currency: currency ?? this.currency,
      memberOrder: memberOrder ?? this.memberOrder,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      questionCount: questionCount ?? this.questionCount,
      questions: questions ?? this.questions,
      interestsByUserId: interestsByUserId ?? this.interestsByUserId,
      amountAgreedBy: amountAgreedBy ?? this.amountAgreedBy,
      payments: payments ?? this.payments,
      winnerFirstId: winnerFirstId ?? this.winnerFirstId,
      winnerSecondId: winnerSecondId ?? this.winnerSecondId,
      winnerThirdId: winnerThirdId ?? this.winnerThirdId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String? currentTurnUserId() {
    if (memberOrder.isEmpty) return null;
    final i = currentTurnIndex % memberOrder.length;
    return memberOrder[i];
  }

  bool allMembersAgreed() {
    if (memberOrder.isEmpty) return false;
    for (final uid in memberOrder) {
      if (amountAgreedBy[uid] != true) return false;
    }
    return true;
  }

  bool allMembersPaid() {
    if (memberOrder.isEmpty) return false;
    for (final uid in memberOrder) {
      if (payments[uid] != true) return false;
    }
    return true;
  }

  Map<String, dynamic>? lastQuestion() {
    if (questions.isEmpty) return null;
    return questions.last;
  }
}
