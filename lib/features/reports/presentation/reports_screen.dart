import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/user_model.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int? _filterUserId;
  int? _filterStampType;
  DateTimeRange? _filterDateRange;

  void _loadData() {
    context.read<ReportsBloc>().add(
      LoadReportData(
        userId: _filterUserId,
        stampType: _filterStampType,
        fromDate: _filterDateRange?.start,
        toDate: _filterDateRange?.end,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterUserId = null;
      _filterStampType = null;
      _filterDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state is ReportGenerated) {
          _handleReportGenerated(context, state);
        }
        if (state is ReportsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        List<UserModel> users = [];
        int transactionCount = 0;

        if (state is ReportsDataLoaded) {
          users = state.users;
          transactionCount = state.transactions.length;
        }
        if (state is ReportGenerated) {
          users = state.users;
          transactionCount = state.transactions.length;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reports,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Filter card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.filter, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<int?>(
                              initialValue: _filterUserId,
                              decoration: InputDecoration(
                                labelText: l10n.selectUser,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(l10n.allUsers),
                                ),
                                ...users.map(
                                  (u) => DropdownMenuItem(
                                    value: u.userID,
                                    child: Text(u.userName),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filterUserId = v),
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<int?>(
                              initialValue: _filterStampType,
                              decoration: InputDecoration(
                                labelText: l10n.stampType,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(l10n.allTypes),
                                ),
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text(l10n.checkIn),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text(l10n.checkOut),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filterStampType = v),
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: InkWell(
                              onTap: () async {
                                final range = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  initialDateRange: _filterDateRange,
                                );
                                if (range != null) {
                                  setState(() => _filterDateRange = range);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: l10n.dateRange,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.date_range,
                                    size: 20,
                                  ),
                                ),
                                child: Text(
                                  _filterDateRange != null
                                      ? '${AppDateUtils.formatDate(_filterDateRange!.start)} - ${AppDateUtils.formatDate(_filterDateRange!.end)}'
                                      : '—',
                                ),
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: _loadData,
                            child: Text(l10n.applyFilters),
                          ),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(l10n.clearFilters),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results info and export buttons
              if (state is ReportsLoading)
                const Expanded(child: AppLoadingIndicator())
              else if (state is ReportsError && transactionCount == 0)
                Expanded(
                  child: AppErrorWidget(
                    message: state.message,
                    onRetry: _loadData,
                  ),
                )
              else if (state is ReportsDataLoaded || state is ReportGenerated)
                Expanded(
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$transactionCount ${l10n.transactions.toLowerCase()} found',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: transactionCount > 0
                                    ? () => context.read<ReportsBloc>().add(
                                        const GeneratePdfReport(),
                                      )
                                    : null,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: Text(l10n.generatePdf),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonalIcon(
                                onPressed: transactionCount > 0
                                    ? () => context.read<ReportsBloc>().add(
                                        const GenerateExcelReport(),
                                      )
                                    : null,
                                icon: const Icon(Icons.table_chart),
                                label: Text(l10n.generateExcel),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: Text(
                            transactionCount > 0
                                ? l10n.reportGenerated
                                : l10n.noTransactionsForReport,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select filters and load data to generate reports',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleReportGenerated(
    BuildContext context,
    ReportGenerated state,
  ) async {
    if (state.mimeType == 'application/pdf') {
      // Use printing package for PDF preview
      await Printing.layoutPdf(
        onLayout: (_) => state.fileBytes,
        name: state.fileName,
      );
    } else {
      // Save Excel file
      await FileSaver.instance.saveFile(
        name: state.fileName,
        bytes: state.fileBytes,
        mimeType: MimeType.microsoftExcel,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportGenerated),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
