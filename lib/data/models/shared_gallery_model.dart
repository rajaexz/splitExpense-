import 'package:cloud_firestore/cloud_firestore.dart';

/// Gallery shared by user with selected friends. Friends can browse and download.
class SharedGalleryModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final List<String> sharedWith; // userIds who can access
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? expiresAt; // optional - limited time access

  SharedGalleryModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.sharedWith,
    required this.imageUrls,
    required this.createdAt,
    this.expiresAt,
  });

  factory SharedGalleryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urls = (data['imageUrls'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final sharedWith = (data['sharedWith'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return SharedGalleryModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Unknown',
      sharedWith: sharedWith,
      imageUrls: urls,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'sharedWith': sharedWith,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    };
  }

  bool canAccess(String userId) => sharedWith.contains(userId);
  bool isExpired() =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
