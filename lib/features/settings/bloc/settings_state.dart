import 'package:equatable/equatable.dart';
import '../../../data/models/settings_model.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final SettingsModel settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SettingsActionSuccess extends SettingsState {
  final String message;
  final SettingsModel settings;

  const SettingsActionSuccess({required this.message, required this.settings});

  @override
  List<Object?> get props => [message, settings];
}

class PasswordChangeSuccess extends SettingsState {
  final String message;
  final SettingsModel settings;

  const PasswordChangeSuccess({required this.message, required this.settings});

  @override
  List<Object?> get props => [message, settings];
}
