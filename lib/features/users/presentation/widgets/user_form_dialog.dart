import 'package:flutter/material.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import '../../../../data/models/user_model.dart';

class UserFormDialog extends StatefulWidget {
  final UserModel? user; // null for create, non-null for edit

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _deviceIdController;
  late bool _isAdmin;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.user?.userName ?? '',
    );
    _passwordController = TextEditingController();
    _deviceIdController = TextEditingController(
      text: widget.user?.deviceID ?? '',
    );
    _isAdmin = widget.user?.isAdmin ?? false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(isEditing ? l10n.editUser : l10n.createUser),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: l10n.userName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${l10n.userName} is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: isEditing ? l10n.passwordHint : null,
                ),
                obscureText: true,
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return '${l10n.password} is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (isEditing)
                TextFormField(
                  controller: _deviceIdController,
                  decoration: InputDecoration(
                    labelText: l10n.deviceId,
                    prefixIcon: const Icon(Icons.phone_android),
                  ),
                ),
              if (isEditing) const SizedBox(height: 16),
              if (!isEditing)
                SwitchListTile(
                  title: Text(l10n.isAdmin),
                  value: _isAdmin,
                  onChanged: (value) {
                    setState(() => _isAdmin = value);
                  },
                  contentPadding: EdgeInsets.zero,
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
          onPressed: _submit,
          child: Text(isEditing ? l10n.save : l10n.create),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final result = <String, dynamic>{
        'username': _usernameController.text.trim(),
        'deviceID': _deviceIdController.text.trim().isEmpty
            ? null
            : _deviceIdController.text.trim(),
        'isAdmin': _isAdmin,
      };

      final password = _passwordController.text;
      if (password.isNotEmpty) {
        result['password'] = password;
      }

      Navigator.pop(context, result);
    }
  }
}
