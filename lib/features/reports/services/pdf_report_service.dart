import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/date_utils.dart';

class PdfReportService {
  static Future<Uint8List> generateReport({
    required List<TransactionModel> transactions,
    required List<UserModel> users,
  }) async {
    final pdf = pw.Document();

    final userMap = {for (var u in users) u.userID: u.userName};

    // Summary stats
    final totalCheckIns = transactions.where((t) => t.stampType == 0).length;
    final totalCheckOuts = transactions.where((t) => t.stampType == 1).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('Total Records', '${transactions.length}'),
                _summaryItem('Check-Ins', '$totalCheckIns'),
                _summaryItem('Check-Outs', '$totalCheckOuts'),
                _summaryItem('Users', '${users.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Transactions table
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['ID', 'User', 'Timestamp', 'Type'],
            data: transactions.map((t) {
              return [
                '${t.id}',
                userMap[t.userID] ?? 'User #${t.userID}',
                AppDateUtils.formatDateTime(t.timestamp),
                t.isCheckIn ? 'Check-In' : 'Check-Out',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Attendance Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
            pw.Text(
              'Generated: ${AppDateUtils.formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Divider(color: PdfColors.teal),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }
}
