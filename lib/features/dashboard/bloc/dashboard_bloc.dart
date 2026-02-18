import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final UserRepository _userRepository;
  final TransactionRepository _transactionRepository;

  DashboardBloc(this._userRepository, this._transactionRepository)
    : super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
  }

  Future<void> _onLoad(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final today = DateTime.now();
      final startOfToday = AppDateUtils.startOfDay(today);
      final endOfToday = AppDateUtils.endOfDay(today);

      // Parallel API calls
      final results = await Future.wait([
        _userRepository.getAllUsers(),
        _transactionRepository.getTransactions(
          fromDate: startOfToday,
          toDate: endOfToday,
        ),
        _transactionRepository.getTransactions(),
      ]);

      final users = results[0];
      final todayTransactions = results[1];
      final allTransactions = results[2];

      final todayCheckIns = todayTransactions
          .where((t) => (t as dynamic).stampType == 0)
          .length;
      final todayCheckOuts = todayTransactions
          .where((t) => (t as dynamic).stampType == 1)
          .length;

      // Recent 10 transactions
      final recent = allTransactions.toList();
      recent.sort(
        (a, b) => (b as dynamic).timestamp.compareTo((a as dynamic).timestamp),
      );
      final recentList = recent.take(10).toList();

      emit(
        DashboardLoaded(
          totalUsers: users.length,
          todayCheckIns: todayCheckIns,
          todayCheckOuts: todayCheckOuts,
          recentTransactions: recentList.cast(),
        ),
      );
    } on AppFailure catch (e) {
      emit(DashboardError(e.message));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
