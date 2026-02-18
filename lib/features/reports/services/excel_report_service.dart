import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/date_utils.dart';

class ExcelReportService {
  static Uint8List generateReport({
    required List<TransactionModel> transactions,
    required List<UserModel> users,
  }) {
    final excel = Excel.createExcel();

    final userMap = {for (var u in users) u.userID: u.userName};

    // Sheet 1: Transaction data
    final transactionsSheet = excel['Transactions'];
    excel.setDefaultSheet('Transactions');

    // Headers
    transactionsSheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('User ID'),
      TextCellValue('User Name'),
      TextCellValue('Timestamp'),
      TextCellValue('Type'),
      TextCellValue('Photo'),
    ]);

    // Style header row
    for (int col = 0; col < 6; col++) {
      final cell = transactionsSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#009688'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Data rows
    for (final t in transactions) {
      transactionsSheet.appendRow([
        IntCellValue(t.id),
        IntCellValue(t.userID),
        TextCellValue(userMap[t.userID] ?? 'User #${t.userID}'),
        TextCellValue(AppDateUtils.formatDateTime(t.timestamp)),
        TextCellValue(t.isCheckIn ? 'Check-In' : 'Check-Out'),
        TextCellValue(t.photo ?? '-'),
      ]);
    }

    // Sheet 2: Summary per user
    final summarySheet = excel['Summary'];

    summarySheet.appendRow([
      TextCellValue('User ID'),
      TextCellValue('User Name'),
      TextCellValue('Total Check-Ins'),
      TextCellValue('Total Check-Outs'),
      TextCellValue('Total Transactions'),
    ]);

    // Style summary headers
    for (int col = 0; col < 5; col++) {
      final cell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#009688'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Per-user summary
    for (final user in users) {
      final userTransactions = transactions
          .where((t) => t.userID == user.userID)
          .toList();
      final checkIns = userTransactions.where((t) => t.stampType == 0).length;
      final checkOuts = userTransactions.where((t) => t.stampType == 1).length;

      summarySheet.appendRow([
        IntCellValue(user.userID),
        TextCellValue(user.userName),
        IntCellValue(checkIns),
        IntCellValue(checkOuts),
        IntCellValue(userTransactions.length),
      ]);
    }

    // Remove default Sheet1 if it exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded!);
  }
}
