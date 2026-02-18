import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import 'widgets/transaction_form_dialog.dart';
import 'widgets/transaction_details_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int? _filterUserId;
  int? _filterStampType;
  DateTimeRange? _filterDateRange;

  void _applyFilters() {
    context.read<TransactionBloc>().add(
      LoadTransactions(
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
    context.read<TransactionBloc>().add(const LoadTransactions());
  }

  String _getUserName(int userId, List<UserModel> users) {
    final user = users.where((u) => u.userID == userId).firstOrNull;
    return user?.userName ?? 'User #$userId';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        List<TransactionModel> transactions = [];
        List<UserModel> users = [];

        if (state is TransactionLoaded) {
          transactions = state.transactions;
          users = state.users;
        }
        if (state is TransactionActionSuccess) {
          transactions = state.transactions;
          users = state.users;
        }

        if (state is TransactionLoading) {
          return const AppLoadingIndicator();
        }

        if (state is TransactionError && transactions.isEmpty) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () =>
                context.read<TransactionBloc>().add(const LoadTransactions()),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.transactions,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context, users),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createTransaction),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filters
              _FilterBar(
                users: users,
                filterUserId: _filterUserId,
                filterStampType: _filterStampType,
                filterDateRange: _filterDateRange,
                onUserChanged: (v) => setState(() => _filterUserId = v),
                onStampTypeChanged: (v) => setState(() => _filterStampType = v),
                onDateRangeChanged: (v) => setState(() => _filterDateRange = v),
                onApply: _applyFilters,
                onClear: _clearFilters,
                l10n: l10n,
              ),
              const SizedBox(height: 16),

              // Data table
              Expanded(
                child: transactions.isEmpty
                    ? Center(child: Text(l10n.noData))
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text(l10n.transactionId)),
                                DataColumn(label: Text(l10n.userName)),
                                DataColumn(label: Text(l10n.timestamp)),
                                DataColumn(label: Text(l10n.stampType)),
                                DataColumn(label: Text(l10n.photo)),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: transactions.map((t) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${t.id}')),
                                    DataCell(
                                      Text(_getUserName(t.userID, users)),
                                    ),
                                    DataCell(
                                      Text(
                                        AppDateUtils.formatDateTime(
                                          t.timestamp,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: t.isCheckIn
                                              ? AppColors.checkIn.withValues(
                                                  alpha: 0.15,
                                                )
                                              : AppColors.checkOut.withValues(
                                                  alpha: 0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          t.isCheckIn
                                              ? l10n.checkIn
                                              : l10n.checkOut,
                                          style: TextStyle(
                                            color: t.isCheckIn
                                                ? AppColors.checkIn
                                                : AppColors.checkOut,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      t.photo != null
                                          ? const Icon(Icons.image, size: 20)
                                          : const Text('-'),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.visibility,
                                              size: 20,
                                            ),
                                            onPressed: () => _showDetailsDialog(
                                              context,
                                              users,
                                              t,
                                            ),
                                            tooltip: 'View Details',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 20,
                                            ),
                                            onPressed: () => _showEditDialog(
                                              context,
                                              users,
                                              t,
                                            ),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _confirmDelete(context, t),
                                            tooltip: 'Delete',
                                            color: Colors.red.shade300,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, List<UserModel> users) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TransactionFormDialog(users: users),
    );

    if (result != null && context.mounted) {
      context.read<TransactionBloc>().add(
        CreateTransactionRequested(
          userId: result['userId'],
          stampType: result['stampType'],
          timestamp: result['timestamp'] as String?,
        ),
      );
    }
  }

  void _showEditDialog(
    BuildContext context,
    List<UserModel> users,
    TransactionModel transaction,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          TransactionFormDialog(users: users, transaction: transaction),
    );

    if (result != null && context.mounted) {
      context.read<TransactionBloc>().add(
        UpdateTransactionRequested(
          transactionId: result['transactionId'],
          stampType: result['stampType'],
          timestamp: result['timestamp'] as String?,
        ),
      );
    }
  }

  void _showDetailsDialog(
    BuildContext context,
    List<UserModel> users,
    TransactionModel transaction,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => TransactionDetailsDialog(
        transaction: transaction,
        userName: _getUserName(transaction.userID, users),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final authRepo = getIt<AuthRepository>();
    final isAdmin = authRepo.isAdmin;

    // Check if user has permission to delete
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only administrators can delete transactions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: const Text('Permanent Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ This action cannot be undone!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Transaction Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• ID: ${transaction.id}'),
            Text('• Type: ${transaction.typeLabel}'),
            Text(
              '• Time: ${AppDateUtils.formatDateTime(transaction.timestamp)}',
            ),
            if (transaction.photo != null) ...[
              const SizedBox(height: 8),
              Text(
                '• Associated photo will also be permanently deleted from server',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<TransactionBloc>().add(
        DeleteTransactionRequested(transactionId: transaction.id),
      );
    }
  }
}

class _FilterBar extends StatelessWidget {
  final List<UserModel> users;
  final int? filterUserId;
  final int? filterStampType;
  final DateTimeRange? filterDateRange;
  final ValueChanged<int?> onUserChanged;
  final ValueChanged<int?> onStampTypeChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final AppLocalizations l10n;

  const _FilterBar({
    required this.users,
    required this.filterUserId,
    required this.filterStampType,
    required this.filterDateRange,
    required this.onUserChanged,
    required this.onStampTypeChanged,
    required this.onDateRangeChanged,
    required this.onApply,
    required this.onClear,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            // User filter
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int?>(
                initialValue: filterUserId,
                decoration: InputDecoration(
                  labelText: l10n.selectUser,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allUsers)),
                  ...users.map(
                    (u) => DropdownMenuItem(
                      value: u.userID,
                      child: Text(u.userName),
                    ),
                  ),
                ],
                onChanged: onUserChanged,
              ),
            ),

            // Stamp type filter
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int?>(
                initialValue: filterStampType,
                decoration: InputDecoration(
                  labelText: l10n.stampType,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allTypes)),
                  DropdownMenuItem(value: 0, child: Text(l10n.checkIn)),
                  DropdownMenuItem(value: 1, child: Text(l10n.checkOut)),
                ],
                onChanged: onStampTypeChanged,
              ),
            ),

            // Date range
            SizedBox(
              width: 250,
              child: InkWell(
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: filterDateRange,
                  );
                  if (range != null) {
                    onDateRangeChanged(range);
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
                    suffixIcon: const Icon(Icons.date_range, size: 20),
                  ),
                  child: Text(
                    filterDateRange != null
                        ? '${AppDateUtils.formatDate(filterDateRange!.start)} - ${AppDateUtils.formatDate(filterDateRange!.end)}'
                        : '—',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),

            // Buttons
            FilledButton.tonal(
              onPressed: onApply,
              child: Text(l10n.applyFilters),
            ),
            TextButton(onPressed: onClear, child: Text(l10n.clearFilters)),
          ],
        ),
      ),
    );
  }
}
