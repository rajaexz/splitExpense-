import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/shared_gallery_model.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/app_logger.dart';

abstract class SharedGalleryDataSource {
  Future<String> createGalleryShare({
    required List<File> imageFiles,
    required List<String> sharedWithUserIds,
  });
  Stream<List<SharedGalleryModel>> getGalleriesSharedWithMe(String userId);
  Stream<List<SharedGalleryModel>> getGalleriesSharedByMe(String ownerId);
  Future<Map<String, String>> getUserNames(List<String> userIds);
  Future<void> deleteGalleryShare(String shareId);
}

class SharedGalleryDataSourceImpl implements SharedGalleryDataSource {
  final FirebaseFirestore _firestore;
  final ImageUploadService _imageUpload;
  final FirebaseAuth _auth;

  SharedGalleryDataSourceImpl({
    required FirebaseFirestore firestore,
    required ImageUploadService imageUpload,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _imageUpload = imageUpload,
        _auth = auth;

  @override
  Future<String> createGalleryShare({
    required List<File> imageFiles,
    required List<String> sharedWithUserIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (imageFiles.isEmpty) throw Exception('Select at least one image');
    if (sharedWithUserIds.isEmpty) throw Exception('Select at least one friend');

    final shareRef = _firestore.collection('gallery_shares').doc();
    final shareId = shareRef.id;
    final imageUrls = <String>[];

    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final url = await _imageUpload.uploadImage(file);
      imageUrls.add(url);
    }

    final gallery = SharedGalleryModel(
      id: shareId,
      ownerId: user.uid,
      ownerName: user.displayName ?? user.email ?? 'User',
      sharedWith: sharedWithUserIds,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      expiresAt: null,
    );

    await shareRef.set(gallery.toFirestore());
    AppLogger.success('Gallery shared with ${sharedWithUserIds.length} friends', tag: 'GALLERY');
    return shareId;
  }

  @override
  Stream<List<SharedGalleryModel>> getGalleriesSharedWithMe(String userId) {
    return _firestore
        .collection('gallery_shares')
        .where('sharedWith', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharedGalleryModel.fromFirestore(doc))
            .where((g) => !g.isExpired())
            .toList());
  }

  @override
  Stream<List<SharedGalleryModel>> getGalleriesSharedByMe(String ownerId) {
    return _firestore
        .collection('gallery_shares')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharedGalleryModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<void> deleteGalleryShare(String shareId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final doc = await _firestore.collection('gallery_shares').doc(shareId).get();
    if (!doc.exists) throw Exception('Gallery not found');
    final ownerId = doc.data()?['ownerId'] as String?;
    if (ownerId != user.uid) throw Exception('You can only delete galleries you shared');
    await _firestore.collection('gallery_shares').doc(shareId).delete();
    AppLogger.success('Gallery deleted', tag: 'GALLERY');
  }

  @override
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    final result = <String, String>{};
    if (userIds.isEmpty) return result;
    final unique = userIds.toSet().toList();
    for (final uid in unique) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          result[uid] = data?['name'] ?? data?['email'] ?? uid;
        } else {
          result[uid] = uid;
        }
      } catch (_) {
        result[uid] = uid;
      }
    }
    return result;
  }
}
