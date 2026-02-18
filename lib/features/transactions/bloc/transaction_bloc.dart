import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/transaction_realtime_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _transactionRepository;
  final UserRepository _userRepository;
  final TransactionRealtimeService _realtimeService;
  List<UserModel> _cachedUsers = [];
  StreamSubscription? _realtimeSubscription;

  TransactionBloc(
    this._transactionRepository,
    this._userRepository,
    this._realtimeService,
  ) : super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<CreateTransactionRequested>(_onCreate);
    on<UpdateTransactionRequested>(_onUpdate);
    on<DeleteTransactionRequested>(_onDelete);
    on<LoadTransactionUsers>(_onLoadUsers);
    on<TransactionRealtimeUpdateReceived>(_onRealtimeUpdate);

    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _realtimeService.connect();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      add(TransactionRealtimeUpdateReceived(event));
    });
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    _realtimeService.disconnect();
    return super.close();
  }

  Future<void> _onRealtimeUpdate(
    TransactionRealtimeUpdateReceived event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionLoaded &&
        currentState is! TransactionActionSuccess) {
      return;
    }

    final currentTransactions = currentState is TransactionLoaded
        ? currentState.transactions
        : (currentState as TransactionActionSuccess).transactions;

    final List<TransactionModel> updatedTransactions = List.from(
      currentTransactions,
    );
    final data = event.event.data;
    final type = event.event.type;

    try {
      if (type == 'INSERT') {
        final newTransaction = TransactionModel.fromJson(data);
        // Add to top if sorting by newest, or just add
        updatedTransactions.insert(0, newTransaction);
      } else if (type == 'UPDATE') {
        final updatedTransaction = TransactionModel.fromJson(data);
        final index = updatedTransactions.indexWhere(
          (t) => t.id == updatedTransaction.id,
        );
        if (index != -1) {
          updatedTransactions[index] = updatedTransaction;
        }
      } else if (type == 'DELETE') {
        final id = data['id'] as int;
        updatedTransactions.removeWhere((t) => t.id == id);
      }

      emit(
        TransactionLoaded(
          transactions: updatedTransactions,
          users: _cachedUsers,
        ),
      );
    } catch (e) {
      // Ignore malformed realtime events
    }
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

      final transactions = results[0] as List<TransactionModel>;
      if (results.length > 1) {
        _cachedUsers = (results[1] as List).cast<UserModel>();
      }

      emit(TransactionLoaded(transactions: transactions, users: _cachedUsers));
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
      // We still fetch to ensure consistency, but realtime might have already updated it
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
