import 'package:equatable/equatable.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final List<UserModel> users;

  const TransactionLoaded({required this.transactions, required this.users});

  @override
  List<Object?> get props => [transactions, users];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionActionSuccess extends TransactionState {
  final String message;
  final List<TransactionModel> transactions;
  final List<UserModel> users;

  const TransactionActionSuccess({
    required this.message,
    required this.transactions,
    required this.users,
  });

  @override
  List<Object?> get props => [message, transactions, users];
}
