part of 'group_cubit.dart';

abstract class GroupState extends Equatable {
  const GroupState();

  @override
  List<Object?> get props => [];
}

class GroupInitial extends GroupState {}

class GroupLoading extends GroupState {}

class GroupCreated extends GroupState {
  final String groupId;

  const GroupCreated(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class GroupJoined extends GroupState {}

class GroupLeft extends GroupState {}

class GroupDeleted extends GroupState {}

class FriendAdded extends GroupState {}

class GroupsLoaded extends GroupState {
  final List<GroupModel> groups;

  const GroupsLoaded(this.groups);

  @override
  List<Object?> get props => [groups];
}

class GroupLoaded extends GroupState {
  final GroupModel group;

  const GroupLoaded(this.group);

  @override
  List<Object?> get props => [group];
}

class GroupError extends GroupState {
  final String message;

  const GroupError(this.message);

  @override
  List<Object?> get props => [message];
}

