import '../../../../data/models/group_game_model.dart';
import '../../../../domain/group_game_repository.dart';
import '../datasources/group_game_remote_datasource.dart';

class GroupGameRepositoryImpl implements GroupGameRepository {
  final GroupGameRemoteDataSource _remote;

  GroupGameRepositoryImpl({required GroupGameRemoteDataSource remote})
      : _remote = remote;

  @override
  Stream<GroupGameModel?> watchGame(String groupId, String gameId) =>
      _remote.watchGame(groupId, gameId);

  @override
  Future<GroupGameModel?> getGame(String groupId, String gameId) =>
      _remote.getGame(groupId, gameId);

  @override
  Future<String?> getLatestGameId(String groupId) =>
      _remote.getLatestGameId(groupId);

  @override
  Future<String> createGame({
    required String groupId,
    required String hostId,
    required double perPersonAmount,
    required String currency,
    required List<String> memberOrder,
  }) =>
      _remote.createGame(
        groupId: groupId,
        hostId: hostId,
        perPersonAmount: perPersonAmount,
        currency: currency,
        memberOrder: memberOrder,
      );

  @override
  Future<void> setInterestsForUser({
    required String groupId,
    required String gameId,
    required String userId,
    required String interestsText,
  }) =>
      _remote.setInterestsForUser(
        groupId: groupId,
        gameId: gameId,
        userId: userId,
        interestsText: interestsText,
      );

  @override
  Future<void> agreeToAmount({
    required String groupId,
    required String gameId,
    required String userId,
  }) =>
      _remote.agreeToAmount(
        groupId: groupId,
        gameId: gameId,
        userId: userId,
      );

  @override
  Future<void> setAmountAgreedForMember({
    required String groupId,
    required String gameId,
    required String memberUserId,
    required bool agreed,
  }) =>
      _remote.setAmountAgreedForMember(
        groupId: groupId,
        gameId: gameId,
        memberUserId: memberUserId,
        agreed: agreed,
      );

  @override
  Future<void> setPaid({
    required String groupId,
    required String gameId,
    required String userId,
    required bool paid,
  }) =>
      _remote.setPaid(
        groupId: groupId,
        gameId: gameId,
        userId: userId,
        paid: paid,
      );

  @override
  Future<void> hostProceedToAwaitingPayment({
    required String groupId,
    required String gameId,
  }) =>
      _remote.hostProceedToAwaitingPayment(
        groupId: groupId,
        gameId: gameId,
      );

  @override
  Future<void> hostStartActive({
    required String groupId,
    required String gameId,
  }) =>
      _remote.hostStartActive(
        groupId: groupId,
        gameId: gameId,
      );

  @override
  Future<void> submitQuestion({
    required String groupId,
    required String gameId,
    required String userId,
    required String questionText,
    required List<String> options,
    required int correctOptionIndex,
  }) =>
      _remote.submitQuestion(
        groupId: groupId,
        gameId: gameId,
        userId: userId,
        questionText: questionText,
        options: options,
        correctOptionIndex: correctOptionIndex,
      );

  @override
  Future<void> submitAnswer({
    required String groupId,
    required String gameId,
    required String userId,
    required String answerText,
  }) =>
      _remote.submitAnswer(
        groupId: groupId,
        gameId: gameId,
        userId: userId,
        answerText: answerText,
      );

  @override
  Future<void> setWinners({
    required String groupId,
    required String gameId,
    required String firstId,
    required String secondId,
    required String thirdId,
  }) =>
      _remote.setWinners(
        groupId: groupId,
        gameId: gameId,
        firstId: firstId,
        secondId: secondId,
        thirdId: thirdId,
      );
}
