import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _transactionRepository;
  final UserRepository _userRepository;
  List<UserModel> _cachedUsers = [];

  TransactionBloc(this._transactionRepository, this._userRepository)
    : super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<CreateTransactionRequested>(_onCreate);
    on<UpdateTransactionRequested>(_onUpdate);
    on<DeleteTransactionRequested>(_onDelete);
    on<LoadTransactionUsers>(_onLoadUsers);
  }

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      final results = await Future.wait([
        _transactionRepository.getTransactions(
          userId: event.userId,
          stampType: event.stampType,
          fromDate: event.fromDate,
          toDate: event.toDate,
        ),
        if (_cachedUsers.isEmpty) _userRepository.getAllUsers(),
      ]);

      final transactions = results[0];
      if (results.length > 1) {
        _cachedUsers = (results[1] as List).cast<UserModel>();
      }

      emit(
        TransactionLoaded(
          transactions: transactions.cast(),
          users: _cachedUsers,
        ),
      );
    } on AppFailure catch (e) {
      emit(TransactionError(e.message));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      await _transactionRepository.createTransaction(
        userId: event.userId,
        stampType: event.stampType,
        timestamp: event.timestamp,
      );
      final transactions = await _transactionRepository.getTransactions();
      emit(
        TransactionActionSuccess(
          message: 'Transaction created successfully',
          transactions: transactions,
          users: _cachedUsers,
        ),
      );
    } on AppFailure catch (e) {
      emit(TransactionError(e.message));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      await _transactionRepository.updateTransaction(
        transactionId: event.transactionId,
        stampType: event.stampType,
        timestamp: event.timestamp != null
            ? DateTime.parse(event.timestamp!)
            : null,
      );
      final transactions = await _transactionRepository.getTransactions();
      emit(
        TransactionActionSuccess(
          message: 'Transaction updated successfully',
          transactions: transactions,
          users: _cachedUsers,
        ),
      );
    } on AppFailure catch (e) {
      emit(TransactionError(e.message));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      await _transactionRepository.deleteTransaction(event.transactionId);
      final transactions = await _transactionRepository.getTransactions();
      emit(
        TransactionActionSuccess(
          message: 'Transaction deleted successfully',
          transactions: transactions,
          users: _cachedUsers,
        ),
      );
    } on AppFailure catch (e) {
      emit(TransactionError(e.message));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadUsers(
    LoadTransactionUsers event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      _cachedUsers = await _userRepository.getAllUsers();
    } catch (_) {}
  }
}
