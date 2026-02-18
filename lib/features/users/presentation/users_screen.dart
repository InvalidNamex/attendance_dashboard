import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/user_model.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import 'widgets/user_form_dialog.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is UserError) {
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
        if (state is UserLoaded) users = state.users;
        if (state is UserActionSuccess) users = state.users;

        if (state is UserLoading) {
          return const AppLoadingIndicator();
        }

        if (state is UserError && users.isEmpty) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () => context.read<UserBloc>().add(const LoadUsers()),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.users,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createUser),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Data table
              Expanded(
                child: users.isEmpty
                    ? Center(child: Text(l10n.noData))
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text(l10n.userId)),
                                DataColumn(label: Text(l10n.userName)),
                                DataColumn(label: Text(l10n.deviceId)),
                                DataColumn(label: Text(l10n.role)),
                                DataColumn(label: Text(l10n.actions)),
                              ],
                              rows: users.map((user) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${user.userID}')),
                                    DataCell(Text(user.userName)),
                                    DataCell(Text(user.deviceID ?? '-')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.isAdmin
                                              ? theme.colorScheme.primary
                                                    .withValues(alpha: 0.15)
                                              : theme.colorScheme.secondary
                                                    .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          user.isAdmin ? l10n.admin : l10n.user,
                                          style: TextStyle(
                                            color: user.isAdmin
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            tooltip: l10n.edit,
                                            onPressed: () =>
                                                _showEditDialog(context, user),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: theme.colorScheme.error,
                                            ),
                                            tooltip: l10n.delete,
                                            onPressed: () => _showDeleteDialog(
                                              context,
                                              user,
                                            ),
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

  void _showCreateDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const UserFormDialog(),
    );

    if (result != null && context.mounted) {
      context.read<UserBloc>().add(
        CreateUserRequested(
          username: result['username'],
          password: result['password'],
          deviceID: result['deviceID'],
          isAdmin: result['isAdmin'] ?? false,
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context, UserModel user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );

    if (result != null && context.mounted) {
      context.read<UserBloc>().add(
        UpdateUserRequested(
          userID: user.userID,
          username: result['username'],
          password: result['password'],
          deviceID: result['deviceID'],
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserBloc>().add(DeleteUserRequested(user.userID));
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
