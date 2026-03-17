import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Stream<List<ExpenseModel>> getGroupExpenses(String groupId);
  Future<String> addExpense(ExpenseModel expense);
  Future<void> updateExpense(String groupId, String expenseId, ExpenseModel expense);
  Future<void> deleteExpense(String groupId, String expenseId);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ExpenseRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  @override
  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList());
  }

  @override
  Future<String> addExpense(ExpenseModel expense) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not logged in');

    final data = expense.toFirestore();
    data['createdBy'] = userId; // Sirf add karne wala edit/delete kar sakta hai
    final ref = await _firestore
        .collection('groups')
        .doc(expense.groupId)
        .collection('expenses')
        .add(data);
    return ref.id;
  }

  @override
  Future<void> updateExpense(String groupId, String expenseId, ExpenseModel expense) async {
    final data = expense.toFirestore();
    data['createdBy'] = expense.createdBy; // Preserve createdBy
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .update(data);
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }
}
