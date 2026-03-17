import 'package:cloud_firestore/cloud_firestore.dart';
import '../datasources/group_remote_datasource.dart';
import '../../../../data/models/group_model.dart';
import '../../../../domain/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource _remoteDataSource;

  GroupRepositoryImpl({required GroupRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<String> createGroup(GroupModel group) async {
    return await _remoteDataSource.createGroup(group);
  }

  @override
  Future<void> joinGroup(String groupId, String userId) async {
    return await _remoteDataSource.joinGroup(groupId, userId);
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    return await _remoteDataSource.leaveGroup(groupId, userId);
  }

  @override
  Future<void> addMemberToGroup(String groupId, String userId, String friendId) async {
    return await _remoteDataSource.addMemberToGroup(groupId, userId, friendId);
  }

  @override
  Stream<List<GroupModel>> getNearbyGroups(double latitude, double longitude, double radius) {
    return _remoteDataSource.getNearbyGroups(
      GeoPoint(latitude, longitude),
      radius,
    );
  }

  @override
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _remoteDataSource.getUserGroups(userId);
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    return await _remoteDataSource.getGroupById(groupId);
  }

  @override
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    return await _remoteDataSource.updateGroup(groupId, updates);
  }
}

