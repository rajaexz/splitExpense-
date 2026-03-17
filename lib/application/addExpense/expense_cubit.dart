import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/community/data/datasources/expense_remote_datasource.dart';
import '../../data/models/expense_model.dart';

part 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRemoteDataSource _dataSource;

  ExpenseCubit(this._dataSource) : super(ExpenseInitial());

  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return _dataSource.getGroupExpenses(groupId);
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _dataSource.addExpense(expense);
      emit(ExpenseAdded());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> updateExpense(String groupId, String expenseId, ExpenseModel expense) async {
    try {
      await _dataSource.updateExpense(groupId, expenseId, expense);
      emit(ExpenseUpdated());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    try {
      await _dataSource.deleteExpense(groupId, expenseId);
      emit(ExpenseDeleted());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  /// Calculate balances: for current user, who they owe and who owes them
  static Map<String, double> calculateBalances(
    String currentUserId,
    List<ExpenseModel> expenses,
  ) {
    final balances = <String, double>{};

    for (final exp in expenses) {
      if (!exp.isParticipant(currentUserId)) continue; // Sirf jisme naam hai

      if (exp.paidBy == currentUserId) {
        for (final p in exp.participants) {
          if (p != currentUserId) {
            final share = exp.shareForUser(p);
            balances[p] = (balances[p] ?? 0) - share; // They owe me
          }
        }
      } else {
        final share = exp.shareForUser(currentUserId);
        balances[exp.paidBy] = (balances[exp.paidBy] ?? 0) + share; // I owe them
      }
    }

    return balances;
  }
}
