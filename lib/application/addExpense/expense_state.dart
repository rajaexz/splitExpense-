part of 'expense_cubit.dart';

abstract class ExpenseState {}

class ExpenseInitial extends ExpenseState {}

class ExpenseAdded extends ExpenseState {}

class ExpenseDeleted extends ExpenseState {}

class ExpenseUpdated extends ExpenseState {}

class ExpenseError extends ExpenseState {
  final String message;
  ExpenseError(this.message);
}
