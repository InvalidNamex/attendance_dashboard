import 'package:equatable/equatable.dart';
import '../../../data/models/transaction_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final int totalUsers;
  final int todayCheckIns;
  final int todayCheckOuts;
  final List<TransactionModel> recentTransactions;

  const DashboardLoaded({
    required this.totalUsers,
    required this.todayCheckIns,
    required this.todayCheckOuts,
    required this.recentTransactions,
  });

  @override
  List<Object?> get props => [
    totalUsers,
    todayCheckIns,
    todayCheckOuts,
    recentTransactions,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
