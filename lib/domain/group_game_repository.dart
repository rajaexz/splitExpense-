import '../data/models/group_game_model.dart';

abstract class GroupGameRepository {
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
