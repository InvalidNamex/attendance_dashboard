import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_dashboard/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../data/models/settings_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../locale/locale_cubit.dart';
import '../../theme/theme_cubit.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import 'widgets/location_picker_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Password controllers
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  // Settings controllers
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _radiusController = TextEditingController();
  final _inTimeController = TextEditingController();
  final _outTimeController = TextEditingController();
  final _settingsFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _radiusController.dispose();
    _inTimeController.dispose();
    _outTimeController.dispose();
    super.dispose();
  }

  void _populateSettings(SettingsModel settings) {
    _latController.text = settings.latitude.toString();
    _lonController.text = settings.longitude.toString();
    _radiusController.text = settings.radius.toString();
    _inTimeController.text = settings.inTime;
    _outTimeController.text = settings.outTime;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoaded) {
          _populateSettings(state.settings);
        }
        if (state is SettingsActionSuccess) {
          _populateSettings(state.settings);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is PasswordChangeSuccess) {
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passwordChanged),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Logout after password change
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              context.read<AuthBloc>().add(const LogoutRequested());
            }
          });
        }
        if (state is SettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SettingsLoading) {
          return const AppLoadingIndicator();
        }
        if (state is SettingsError &&
            state is! SettingsLoaded &&
            state is! SettingsActionSuccess &&
            state is! PasswordChangeSuccess) {
          // Only show full error if we have no settings loaded yet
          if (_latController.text.isEmpty) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () =>
                  context.read<SettingsBloc>().add(const LoadSettings()),
            );
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Settings - Change Password
            Text(
              l10n.accountSettings,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.changePassword,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: l10n.newPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '${l10n.newPassword} is required';
                          }
                          if (value.length < 4) {
                            return 'Password must be at least 4 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return l10n.passwordMismatch;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          if (_passwordFormKey.currentState?.validate() ??
                              false) {
                            context.read<SettingsBloc>().add(
                              ChangePasswordRequested(
                                newPassword: _newPasswordController.text,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: Text(l10n.changePassword),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Settings
            Text(
              l10n.appSettings,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _settingsFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Picker
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: InputDecoration(
                                labelText: l10n.latitude,
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _lonController,
                              decoration: InputDecoration(
                                labelText: l10n.longitude,
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              final result = await showDialog<LatLng>(
                                context: context,
                                builder: (context) => LocationPickerDialog(
                                  initialLatitude: double.tryParse(
                                    _latController.text,
                                  ),
                                  initialLongitude: double.tryParse(
                                    _lonController.text,
                                  ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _latController.text = result.latitude
                                      .toStringAsFixed(6);
                                  _lonController.text = result.longitude
                                      .toStringAsFixed(6);
                                });
                              }
                            },
                            icon: const Icon(Icons.map),
                            label: Text(l10n.map),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _radiusController,
                        decoration: InputDecoration(
                          labelText: l10n.radius,
                          prefixIcon: const Icon(Icons.radar),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _inTimeController,
                              decoration: InputDecoration(
                                labelText: l10n.inTime,
                                prefixIcon: const Icon(Icons.access_time),
                                hintText: 'HH:MM',
                              ),
                              readOnly: true,
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 9,
                                    minute: 0,
                                  ),
                                );
                                if (time != null) {
                                  _inTimeController.text =
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _outTimeController,
                              decoration: InputDecoration(
                                labelText: l10n.outTime,
                                prefixIcon: const Icon(Icons.access_time),
                                hintText: 'HH:MM',
                              ),
                              readOnly: true,
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 17,
                                    minute: 0,
                                  ),
                                );
                                if (time != null) {
                                  _outTimeController.text =
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          if (_settingsFormKey.currentState?.validate() ??
                              false) {
                            context.read<SettingsBloc>().add(
                              UpdateSettingsRequested(
                                latitude: double.tryParse(_latController.text),
                                longitude: double.tryParse(_lonController.text),
                                radius: int.tryParse(_radiusController.text),
                                inTime: _inTimeController.text.isNotEmpty
                                    ? _inTimeController.text
                                    : null,
                                outTime: _outTimeController.text.isNotEmpty
                                    ? _outTimeController.text
                                    : null,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: Text(l10n.save),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Appearance
            Text(
              l10n.appearance,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Theme toggle
                    BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) {
                        return ListTile(
                          leading: Icon(
                            themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: Text(l10n.theme),
                          subtitle: Text(
                            themeMode == ThemeMode.dark
                                ? l10n.darkMode
                                : l10n.lightMode,
                          ),
                          trailing: Switch(
                            value: themeMode == ThemeMode.dark,
                            onChanged: (_) =>
                                context.read<ThemeCubit>().toggleTheme(),
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                    const Divider(),
                    // Language toggle
                    BlocBuilder<LocaleCubit, Locale>(
                      builder: (context, locale) {
                        return ListTile(
                          leading: const Icon(Icons.language),
                          title: Text(l10n.language),
                          subtitle: Text(
                            locale.languageCode == 'ar'
                                ? l10n.arabic
                                : l10n.english,
                          ),
                          trailing: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'en',
                                label: Text(l10n.english),
                              ),
                              ButtonSegment(
                                value: 'ar',
                                label: Text(l10n.arabic),
                              ),
                            ],
                            selected: {locale.languageCode},
                            onSelectionChanged: (value) {
                              context.read<LocaleCubit>().setLocale(
                                Locale(value.first),
                              );
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
