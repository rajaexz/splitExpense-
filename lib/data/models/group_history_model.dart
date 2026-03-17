import 'package:cloud_firestore/cloud_firestore.dart';

/// Archived record of a deleted group - for creator to see history.
class GroupHistoryModel {
  final String id;
  final String groupId;
  final String groupName;
  final String creatorId;
  final Map<String, String> members; // userId -> role
  final DateTime createdAt;
  final DateTime deletedAt;

  GroupHistoryModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.creatorId,
    required this.members,
    required this.createdAt,
    required this.deletedAt,
  });

  factory GroupHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final membersRaw = data['members'] as Map<String, dynamic>? ?? {};
    final members = <String, String>{};
    for (final entry in membersRaw.entries) {
      final v = entry.value;
      final role = v is Map ? (v['role'] ?? 'member').toString() : 'member';
      members[entry.key.toString()] = role;
    }
    return GroupHistoryModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      creatorId: data['creatorId'] ?? '',
      members: members,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
