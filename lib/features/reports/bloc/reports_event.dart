import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportData extends ReportsEvent {
  final int? userId;
  final int? stampType;
  final DateTime? fromDate;
  final DateTime? toDate;

  const LoadReportData({
    this.userId,
    this.stampType,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [userId, stampType, fromDate, toDate];
}

class GeneratePdfReport extends ReportsEvent {
  const GeneratePdfReport();
}

class GenerateExcelReport extends ReportsEvent {
  const GenerateExcelReport();
}
