import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsDataLoaded extends ReportsState {
  final List<TransactionModel> transactions;
  final List<UserModel> users;

  const ReportsDataLoaded({required this.transactions, required this.users});

  @override
  List<Object?> get props => [transactions, users];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportGenerated extends ReportsState {
  final Uint8List fileBytes;
  final String fileName;
  final String mimeType;
  final List<TransactionModel> transactions;
  final List<UserModel> users;

  const ReportGenerated({
    required this.fileBytes,
    required this.fileName,
    required this.mimeType,
    required this.transactions,
    required this.users,
  });

  @override
  List<Object?> get props => [fileName, transactions, users];
}
