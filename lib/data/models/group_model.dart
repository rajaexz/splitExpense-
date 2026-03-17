import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported currencies for group expenses
const List<String> kGroupCurrencies = ['PKR', 'INR', 'USD'];

/// Group category: Trip, Home, Couple, Other
const List<String> kGroupCategories = ['trip', 'home', 'couple', 'other'];

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final GeoPoint location;
  final double radius; // in meters (2000-5000)
  final String type; // public, private, invite-only
  final String currency; // PKR, INR, USD - for expense tracking
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, GroupMember> members;
  final GroupSettings settings;
  final String category; // trip, home, couple, other
  final String? imageUrl;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final DateTime? settleUpDate;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.location,
    required this.radius,
    required this.type,
    this.currency = 'PKR',
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
    required this.settings,
    this.category = 'other',
    this.imageUrl,
    this.tripStartDate,
    this.tripEndDate,
    this.settleUpDate,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc, {Map<String, dynamic>? dataOverride}) {
    final data = dataOverride ?? (doc.data() as Map<String, dynamic>);
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final tripStart = data['tripStartDate'];
    final tripEnd = data['tripEndDate'];
    final settleUp = data['settleUpDate'];
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      location: data['location'] as GeoPoint,
      radius: (data['radius'] ?? 2000).toDouble(),
      type: data['type'] ?? 'public',
      currency: data['currency'] ?? 'PKR',
      memberCount: data['memberCount'] ?? 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
      members: (data['members'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          GroupMember.fromMap(value as Map<String, dynamic>),
        ),
      ),
      settings: GroupSettings.fromMap(data['settings'] as Map<String, dynamic>? ?? {}),
      category: data['category'] ?? 'other',
      imageUrl: data['imageUrl'] as String?,
      tripStartDate: tripStart is Timestamp ? tripStart.toDate() : null,
      tripEndDate: tripEnd is Timestamp ? tripEnd.toDate() : null,
      settleUpDate: settleUp is Timestamp ? settleUp.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'location': location,
      'radius': radius,
      'type': type,
      'currency': currency,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'members': members.map((key, value) => MapEntry(key, value.toMap())),
      'settings': settings.toMap(),
      'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl!,
      if (tripStartDate != null) 'tripStartDate': Timestamp.fromDate(tripStartDate!),
      if (tripEndDate != null) 'tripEndDate': Timestamp.fromDate(tripEndDate!),
      if (settleUpDate != null) 'settleUpDate': Timestamp.fromDate(settleUpDate!),
    };
    return map;
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    GeoPoint? location,
    double? radius,
    String? type,
    String? currency,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, GroupMember>? members,
    GroupSettings? settings,
    String? category,
    String? imageUrl,
    DateTime? tripStartDate,
    DateTime? tripEndDate,
    DateTime? settleUpDate,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      tripStartDate: tripStartDate ?? this.tripStartDate,
      tripEndDate: tripEndDate ?? this.tripEndDate,
      settleUpDate: settleUpDate ?? this.settleUpDate,
    );
  }
}

class GroupMember {
  final String userId;
  final String role; // admin, member
  final DateTime joinedAt;
  final bool locationSharingEnabled;

  GroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.locationSharingEnabled,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    final joinedAt = map['joinedAt'];
    return GroupMember(
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'member',
      joinedAt: joinedAt is Timestamp ? joinedAt.toDate() : DateTime.now(),
      locationSharingEnabled: map['locationSharingEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'locationSharingEnabled': locationSharingEnabled,
    };
  }
}

class GroupSettings {
  final bool allowLocationSharing;
  final bool allowExpenseTracking;

  GroupSettings({
    required this.allowLocationSharing,
    required this.allowExpenseTracking,
  });

  factory GroupSettings.fromMap(Map<String, dynamic> map) {
    return GroupSettings(
      allowLocationSharing: map['allowLocationSharing'] ?? true,
      allowExpenseTracking: map['allowExpenseTracking'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowLocationSharing': allowLocationSharing,
      'allowExpenseTracking': allowExpenseTracking,
    };
  }
}
