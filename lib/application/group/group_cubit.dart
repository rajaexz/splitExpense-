import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/group_history_model.dart';
import '../../data/models/group_model.dart';
import '../../features/community/data/datasources/group_remote_datasource.dart';
import '../../features/community/data/datasources/notification_remote_datasource.dart';
import '../../core/utils/app_logger.dart';

part 'group_state.dart';

class GroupCubit extends Cubit<GroupState> {
  final GroupRemoteDataSource _dataSource;
  final NotificationRemoteDataSource _notificationDataSource;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GroupCubit(this._dataSource, this._notificationDataSource) : super(GroupInitial());

  Future<void> createGroup(GroupModel group) async {
    emit(GroupLoading());
    try {
      AppLogger.info('Creating group: ${group.name}', tag: 'GROUP_CUBIT');
      final groupId = await _dataSource.createGroup(group);
      emit(GroupCreated(groupId));
    } catch (e, stackTrace) {
      AppLogger.error('Error creating group', tag: 'GROUP_CUBIT', error: e, stackTrace: stackTrace);
      emit(GroupError(e.toString()));
    }
  }

  Future<void> joinGroup(String groupId, String userId) async {
    emit(GroupLoading());
    try {
      await _dataSource.joinGroup(groupId, userId);
      emit(GroupJoined());
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    emit(GroupLoading());
    try {
      await _dataSource.leaveGroup(groupId, userId);
      emit(GroupLeft());
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  Future<void> deleteGroup(String groupId) async {
    emit(GroupLoading());
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _notificationDataSource.deleteNotificationsForGroup(groupId, userId);
      }
      await _dataSource.deleteGroup(groupId);
      emit(GroupDeleted());
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  Future<void> addFriendToGroup(String groupId, String userId, String friendId) async {
    emit(GroupLoading());
    try {
      await _dataSource.addMemberToGroup(groupId, userId, friendId);
      emit(FriendAdded());
      await loadGroup(groupId);
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  /// Add member by email, phone, or user ID. Resolves to userId first.
  Future<void> addMemberByEmailOrPhone(String groupId, String emailOrPhone) async {
    emit(GroupLoading());
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Please login first');

      final friendId = await _dataSource.findUserIdByEmailOrPhone(emailOrPhone);
      if (friendId == null) {
        emit(GroupError('User not found. Enter valid email, phone, or user ID.'));
        return;
      }
      if (friendId == userId) {
        emit(GroupError('You cannot add yourself'));
        return;
      }

      await _dataSource.addMemberToGroup(groupId, userId, friendId);
      emit(FriendAdded());
      await loadGroup(groupId);
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  Stream<List<GroupHistoryModel>> getGroupHistoryStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    return _dataSource.getGroupHistory(userId);
  }

  Stream<List<GroupModel>> getUserGroupsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      AppLogger.warning('User not authenticated', tag: 'GROUP_CUBIT');
      return Stream.value([]);
    }
    return _dataSource.getUserGroups(userId);
  }

  Future<void> loadGroup(String groupId) async {
    emit(GroupLoading());
    try {
      final group = await _dataSource.getGroupById(groupId);
      if (group != null) {
        emit(GroupLoaded(group));
      } else {
        emit(GroupError('Group not found'));
      }
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  Future<void> updateSettleUpDate(String groupId, DateTime? date) async {
    try {
      await _dataSource.updateGroup(groupId, {
        'settleUpDate': date != null ? Timestamp.fromDate(date) : FieldValue.delete(),
      });
      await loadGroup(groupId);
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

}

