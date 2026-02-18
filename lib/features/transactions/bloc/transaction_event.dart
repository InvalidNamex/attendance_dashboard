import 'package:equatable/equatable.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final int? userId;
  final int? stampType;
  final DateTime? fromDate;
  final DateTime? toDate;

  const LoadTransactions({
    this.userId,
    this.stampType,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [userId, stampType, fromDate, toDate];
}

class CreateTransactionRequested extends TransactionEvent {
  final int userId;
  final int stampType;
  final String? timestamp;

  const CreateTransactionRequested({
    required this.userId,
    required this.stampType,
    this.timestamp,
  });

  @override
  List<Object?> get props => [userId, stampType, timestamp];
}

class LoadTransactionUsers extends TransactionEvent {
  const LoadTransactionUsers();
}

class UpdateTransactionRequested extends TransactionEvent {
  final int transactionId;
  final int? stampType;
  final String? timestamp;

  const UpdateTransactionRequested({
    required this.transactionId,
    this.stampType,
    this.timestamp,
  });

  @override
  List<Object?> get props => [transactionId, stampType, timestamp];
}

class DeleteTransactionRequested extends TransactionEvent {
  final int transactionId;

  const DeleteTransactionRequested({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}
