import '../data/models/group_model.dart';

abstract class GroupRepository {
  Future<String> createGroup(GroupModel group);
  Future<void> joinGroup(String groupId, String userId);
  Future<void> leaveGroup(String groupId, String userId);
  Future<void> addMemberToGroup(String groupId, String userId, String friendId);
  Stream<List<GroupModel>> getNearbyGroups(double latitude, double longitude, double radius);
  Stream<List<GroupModel>> getUserGroups(String userId);
  Future<GroupModel?> getGroupById(String groupId);
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates);
}
