import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../services/excel_report_service.dart';
import '../services/pdf_report_service.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final TransactionRepository _transactionRepository;
  final UserRepository _userRepository;
  List<TransactionModel> _currentTransactions = [];
  List<UserModel> _currentUsers = [];

  ReportsBloc(this._transactionRepository, this._userRepository)
    : super(const ReportsInitial()) {
    on<LoadReportData>(_onLoadData);
    on<GeneratePdfReport>(_onGeneratePdf);
    on<GenerateExcelReport>(_onGenerateExcel);
  }

  Future<void> _onLoadData(
    LoadReportData event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      final results = await Future.wait([
        _transactionRepository.getTransactions(
          userId: event.userId,
          stampType: event.stampType,
          fromDate: event.fromDate,
          toDate: event.toDate,
        ),
        _userRepository.getAllUsers(),
      ]);

      _currentTransactions = (results[0] as List).cast<TransactionModel>();
      _currentUsers = (results[1] as List).cast<UserModel>();

      emit(
        ReportsDataLoaded(
          transactions: _currentTransactions,
          users: _currentUsers,
        ),
      );
    } on AppFailure catch (e) {
      emit(ReportsError(e.message));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onGeneratePdf(
    GeneratePdfReport event,
    Emitter<ReportsState> emit,
  ) async {
    if (_currentTransactions.isEmpty) {
      emit(
        const ReportsError('No transactions found for the selected filters'),
      );
      return;
    }

    emit(const ReportsLoading());
    try {
      final bytes = await PdfReportService.generateReport(
        transactions: _currentTransactions,
        users: _currentUsers,
      );

      emit(
        ReportGenerated(
          fileBytes: bytes,
          fileName:
              'attendance_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
          mimeType: 'application/pdf',
          transactions: _currentTransactions,
          users: _currentUsers,
        ),
      );
    } catch (e) {
      emit(ReportsError('Failed to generate PDF: $e'));
    }
  }

  Future<void> _onGenerateExcel(
    GenerateExcelReport event,
    Emitter<ReportsState> emit,
  ) async {
    if (_currentTransactions.isEmpty) {
      emit(
        const ReportsError('No transactions found for the selected filters'),
      );
      return;
    }

    emit(const ReportsLoading());
    try {
      final bytes = ExcelReportService.generateReport(
        transactions: _currentTransactions,
        users: _currentUsers,
      );

      emit(
        ReportGenerated(
          fileBytes: bytes,
          fileName:
              'attendance_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          transactions: _currentTransactions,
          users: _currentUsers,
        ),
      );
    } catch (e) {
      emit(ReportsError('Failed to generate Excel: $e'));
    }
  }
}
