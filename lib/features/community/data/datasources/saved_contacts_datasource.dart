import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/saved_contact_model.dart';

abstract class SavedContactsDataSource {
  Future<void> saveContact(String name, String phone);
  Stream<List<SavedContactModel>> getSavedContacts(String userId);
}

class SavedContactsDataSourceImpl implements SavedContactsDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SavedContactsDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  /// Normalize phone for use as doc id (digits only, with p prefix for +)
  String _phoneToDocId(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return 'p${digits.replaceAll('+', '')}';
  }

  @override
  Future<void> saveContact(String name, String phone) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docId = _phoneToDocId(phone);
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('savedContacts')
        .doc(docId);

    await ref.set({
      'name': name.trim(),
      'phone': phone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<SavedContactModel>> getSavedContacts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedContacts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['createdAt'] = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        return SavedContactModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }
}
