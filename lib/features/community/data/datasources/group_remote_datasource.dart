import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/group_history_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../../core/utils/app_logger.dart';

abstract class GroupRemoteDataSource {
  Future<String> createGroup(GroupModel group);
  Future<void> joinGroup(String groupId, String userId);
  Future<void> leaveGroup(String groupId, String userId);
  Future<void> addMemberToGroup(String groupId, String userId, String friendId);
  Future<String?> findUserIdByEmailOrPhone(String emailOrPhone);
  Future<void> deleteGroup(String groupId);
  Stream<List<GroupHistoryModel>> getGroupHistory(String userId);
  Stream<List<GroupModel>> getNearbyGroups(GeoPoint location, double radius);
  Stream<List<GroupModel>> getUserGroups(String userId);
  Future<GroupModel?> getGroupById(String groupId);
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GroupRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  @override
  Future<String> createGroup(GroupModel group) async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to create a group');
      }
      
      AppLogger.info('Creating group: ${group.name}', tag: 'GROUP');
      
      final groupRef = _firestore.collection('groups').doc();
      final groupData = group.toFirestore();
      groupData['id'] = groupRef.id;
      groupData['creatorId'] = currentUser.uid; // Ensure creatorId is set
      
      // Add creator as admin member
      groupData['members'] = {
        currentUser.uid: {
          'userId': currentUser.uid,
          'role': 'admin',
          'joinedAt': FieldValue.serverTimestamp(),
          'locationSharingEnabled': false,
        }
      };
      groupData['memberCount'] = 1;
      
      await groupRef.set(groupData);
      
      AppLogger.success('Group created successfully: ${groupRef.id}', tag: 'GROUP');
      return groupRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating group', tag: 'GROUP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      AppLogger.info('User $userId joining group $groupId', tag: 'GROUP');
      
      final groupRef = _firestore.collection('groups').doc(groupId);
      final memberRef = groupRef.collection('members').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) {
          throw Exception('Group does not exist');
        }
        
        final data = groupDoc.data() ?? {};
        final currentCount = data['memberCount'] ?? 0;
        final members = Map<String, dynamic>.from(data['members'] as Map<String, dynamic>? ?? {});

        final memberData = {
          'userId': userId,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'locationSharingEnabled': false,
        };
        members[userId] = memberData;

        transaction.set(memberRef, memberData);
        transaction.update(groupRef, {
          'members': members,
          'memberCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      AppLogger.success('User joined group successfully', tag: 'GROUP');
    } catch (e, stackTrace) {
      AppLogger.error('Error joining group', tag: 'GROUP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      AppLogger.info('User $userId leaving group $groupId', tag: 'GROUP');
      
      final groupRef = _firestore.collection('groups').doc(groupId);
      final memberRef = groupRef.collection('members').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) {
          throw Exception('Group does not exist');
        }
        
        final data = groupDoc.data() ?? {};
        final currentCount = data['memberCount'] ?? 0;
        final members = Map<String, dynamic>.from(data['members'] as Map<String, dynamic>? ?? {});
        members.remove(userId);

        transaction.delete(memberRef);
        transaction.update(groupRef, {
          'members': members,
          'memberCount': (currentCount - 1).clamp(0, double.infinity).toInt(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      AppLogger.success('User left group successfully', tag: 'GROUP');
    } catch (e, stackTrace) {
      AppLogger.error('Error leaving group', tag: 'GROUP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      AppLogger.info('Deleting group: $groupId', tag: 'GROUP');
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final groupDoc = await _firestore.collection('groups').doc(groupId).get();
        if (groupDoc.exists) {
          final data = groupDoc.data();
          final creatorId = data?['creatorId'] as String?;
          if (creatorId == userId) {
            await _firestore.collection('group_history').add({
              'groupId': groupId,
              'groupName': data?['name'] ?? '',
              'creatorId': creatorId,
              'members': data?['members'] ?? {},
              'createdAt': data?['createdAt'],
              'deletedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      await _firestore.collection('groups').doc(groupId).delete();
      AppLogger.success('Group deleted successfully', tag: 'GROUP');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting group', tag: 'GROUP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<GroupHistoryModel>> getGroupHistory(String userId) {
    return _firestore
        .collection('group_history')
        .where('creatorId', isEqualTo: userId)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupHistoryModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<String?> findUserIdByEmailOrPhone(String emailOrPhone) async {
    try {
      final input = emailOrPhone.trim();
      if (input.isEmpty) return null;

      // If it looks like email (contains @)
      if (input.contains('@')) {
        final snapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: input.toLowerCase())
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) return snapshot.docs.first.id;
        return null;
      }

      // If it looks like phone (digits, maybe with + or spaces)
      final digitsOnly = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (digitsOnly.length >= 10) {
        // Try exact match first
        var snapshot = await _firestore
            .collection('users')
            .where('phone', isEqualTo: input.trim())
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) return snapshot.docs.first.id;

        // Try with + prefix variants
        final withPlus = input.startsWith('+') ? input : '+$digitsOnly';
        snapshot = await _firestore
            .collection('users')
            .where('phone', isEqualTo: withPlus)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) return snapshot.docs.first.id;
      }

      // Treat as userId - check if user exists
      final doc = await _firestore.collection('users').doc(input).get();
      return doc.exists ? input : null;
    } catch (e) {
      AppLogger.warning('findUserIdByEmailOrPhone error: $e', tag: 'GROUP');
      return null;
    }
  }

  @override
  Future<void> addMemberToGroup(String groupId, String userId, String friendId) async {
    try {
      AppLogger.info('Adding friend $friendId to group $groupId', tag: 'GROUP');
      
      // First check if user is admin and if friend is already a member
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data() ?? {};
      final members = Map<String, dynamic>.from(groupData['members'] as Map<String, dynamic>? ?? {});
      final userMember = members[userId] as Map<String, dynamic>?;
      
      if (userMember?['role'] != 'admin') {
        throw Exception('Only admins can add members');
      }
      
      // Check if friend is already in group (main doc or subcollection)
      if (members.containsKey(friendId)) {
        throw Exception('This person is already a member of the group');
      }
      final memberDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(friendId)
          .get();
      if (memberDoc.exists) {
        throw Exception('This person is already a member of the group');
      }
      
      // Add friend to group
      await joinGroup(groupId, friendId);
      
      AppLogger.success('Friend added to group successfully', tag: 'GROUP');
    } catch (e, stackTrace) {
      AppLogger.error('Error adding member', tag: 'GROUP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<GroupModel>> getNearbyGroups(GeoPoint location, double radius) {
    try {
      AppLogger.debug('Fetching nearby groups', tag: 'GROUP');
      
      return _firestore
          .collection('groups')
          .where('type', isEqualTo: 'public')
          .snapshots()
          .map((snapshot) {
        final groups = <GroupModel>[];
        
        for (var doc in snapshot.docs) {
          try {
            final group = GroupModel.fromFirestore(doc);
            
            // Calculate distance
            final distance = _calculateDistance(
              location.latitude,
              location.longitude,
              group.location.latitude,
              group.location.longitude,
            );
            
            // Filter by radius
            if (distance <= radius) {
              groups.add(group);
            }
          } catch (e) {
            AppLogger.warning('Error parsing group: ${doc.id}', tag: 'GROUP');
          }
        }
        
        return groups;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching nearby groups', tag: 'GROUP', error: e, stackTrace: stackTrace);
      return Stream.value([]);
    }
  }

  @override
  Stream<List<GroupModel>> getUserGroups(String userId) {
    try {
      AppLogger.debug('Fetching user groups for: $userId', tag: 'GROUP');
      
      // Fetch all groups and filter client-side
      // This avoids Firestore security rules issues with nested field queries
      return _firestore
          .collection('groups')
          .snapshots()
          .map((snapshot) {
        final groups = <GroupModel>[];
        
        for (var doc in snapshot.docs) {
          try {
            final group = GroupModel.fromFirestore(doc);
            // Check if user is a member
            if (group.members.containsKey(userId)) {
              groups.add(group);
            }
          } catch (e) {
            AppLogger.warning('Error parsing group: ${doc.id}', tag: 'GROUP');
          }
        }
        
        return groups;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching user groups', tag: 'GROUP', error: e, stackTrace: stackTrace);
      return Stream.value([]);
    }
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      AppLogger.debug('Fetching group: $groupId', tag: 'GROUP');
      
      final groupRef = _firestore.collection('groups').doc(groupId);
      final doc = await groupRef.get();
      if (!doc.exists) return null;

      final groupData = doc.data()!;
      final mainDocMembers = groupData['members'] as Map<String, dynamic>? ?? {};

      // Fetch members from subcollection (joinGroup adds members here)
      final membersSnapshot = await groupRef.collection('members').get();
      final membersFromSubcollection = <String, Map<String, dynamic>>{};
      for (final memberDoc in membersSnapshot.docs) {
        final data = memberDoc.data();
        if (data.isNotEmpty) {
          membersFromSubcollection[memberDoc.id] = {
            'userId': data['userId'] ?? memberDoc.id,
            'role': data['role'] ?? 'member',
            'joinedAt': data['joinedAt'],
            'locationSharingEnabled': data['locationSharingEnabled'] ?? false,
          };
        }
      }

      // Merge: subcollection overrides (has latest), main doc fills gaps (creator)
      final mergedMembers = Map<String, dynamic>.from(mainDocMembers);
      for (final entry in membersFromSubcollection.entries) {
        mergedMembers[entry.key] = entry.value;
      }

      final mergedData = Map<String, dynamic>.from(groupData)..['members'] = mergedMembers;
      return GroupModel.fromFirestore(doc, dataOverride: mergedData);
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching group', tag: 'GROUP', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      AppLogger.info('Updating group: $groupId', tag: 'GROUP');
      
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('groups').doc(groupId).update(updates);
      
      AppLogger.success('Group updated successfully', tag: 'GROUP');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating group', tag: 'GROUP', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

