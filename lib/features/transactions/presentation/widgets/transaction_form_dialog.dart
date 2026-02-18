import 'package:flutter/material.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/transaction_model.dart';

class TransactionFormDialog extends StatefulWidget {
  final List<UserModel> users;
  final TransactionModel? transaction;

  const TransactionFormDialog({
    super.key,
    required this.users,
    this.transaction,
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedUserId;
  int _stampType = 0;
  DateTime _selectedTimestamp = DateTime.now();
  final _timestampController = TextEditingController();
  bool _useCurrentTime = true;

  @override
  void initState() {
    super.initState();

    // Initialize with existing transaction data if editing
    if (widget.transaction != null) {
      _selectedUserId = widget.transaction!.userID;
      _stampType = widget.transaction!.isCheckIn ? 0 : 1;
      _selectedTimestamp = widget.transaction!.timestamp;
      _useCurrentTime = false; // When editing, always show the timestamp
    }

    _updateTimestampText();
  }

  @override
  void dispose() {
    _timestampController.dispose();
    super.dispose();
  }

  void _updateTimestampText() {
    _timestampController.text =
        '${_selectedTimestamp.year}-${_selectedTimestamp.month.toString().padLeft(2, '0')}-${_selectedTimestamp.day.toString().padLeft(2, '0')} '
        '${_selectedTimestamp.hour.toString().padLeft(2, '0')}:${_selectedTimestamp.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTimestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTimestamp),
      );

      if (time != null) {
        setState(() {
          _selectedTimestamp = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _updateTimestampText();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        widget.transaction == null
            ? l10n.createTransaction
            : 'Edit Transaction',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedUserId,
                decoration: InputDecoration(
                  labelText: l10n.selectUser,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: widget.users.map((user) {
                  return DropdownMenuItem(
                    value: user.userID,
                    child: Text(user.userName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedUserId = value),
                validator: (value) {
                  if (value == null) return '${l10n.selectUser} is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Only show timestamp picker for creating new transactions
              if (widget.transaction == null) ...[
                SwitchListTile(
                  title: Text('Use Current Time'),
                  subtitle: Text(
                    _useCurrentTime
                        ? 'Transaction will use server\'s current time'
                        : 'Specify custom date and time',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _useCurrentTime,
                  onChanged: (value) {
                    setState(() {
                      _useCurrentTime = value;
                      if (value) {
                        _selectedTimestamp = DateTime.now();
                        _updateTimestampText();
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _timestampController,
                decoration: InputDecoration(
                  labelText: l10n.timestamp,
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: widget.transaction == null && _useCurrentTime
                      ? Icon(Icons.lock_outline, size: 20, color: Colors.grey)
                      : Icon(Icons.edit_calendar, size: 20),
                  helperText: widget.transaction == null && _useCurrentTime
                      ? 'Automatic - will use server time'
                      : widget.transaction != null
                          ? 'Tap to change timestamp'
                          : 'Tap to set custom time',
                ),
                readOnly: true,
                enabled: widget.transaction != null || !_useCurrentTime,
                onTap: (widget.transaction != null || !_useCurrentTime)
                    ? _pickDateTime
                    : null,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.stampType,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text(l10n.checkIn),
                        icon: const Icon(Icons.login),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text(l10n.checkOut),
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                    selected: {_stampType},
                    onSelectionChanged: (value) {
                      setState(() => _stampType = value.first);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final result = <String, dynamic>{
                'stampType': _stampType,
              };

              if (widget.transaction == null) {
                // Creating new transaction
                result['userId'] = _selectedUserId;
                
                // Only include timestamp if using manual time
                if (!_useCurrentTime) {
                  result['timestamp'] = _selectedTimestamp.toIso8601String();
                }
              } else {
                // Updating existing transaction
                result['transactionId'] = widget.transaction!.id;
                result['timestamp'] = _selectedTimestamp.toIso8601String();
              }

              Navigator.pop(context, result);
            }
          },
          child: Text(widget.transaction == null ? l10n.create : 'Update'),
        ),
      ],
    );
  }
}
