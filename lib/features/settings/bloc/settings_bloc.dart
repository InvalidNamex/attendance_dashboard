import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;
  SettingsModel? _currentSettings;

  SettingsBloc(this._settingsRepository, this._authRepository)
    : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoad);
    on<UpdateSettingsRequested>(_onUpdate);
    on<ChangePasswordRequested>(_onChangePassword);
  }

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      _currentSettings = await _settingsRepository.getSettings();
      emit(SettingsLoaded(_currentSettings!));
    } on AppFailure catch (e) {
      emit(SettingsError(e.message));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateSettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      _currentSettings = await _settingsRepository.updateSettings(
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        inTime: event.inTime,
        outTime: event.outTime,
      );
      emit(
        SettingsActionSuccess(
          message: 'Settings updated successfully',
          settings: _currentSettings!,
        ),
      );
    } on AppFailure catch (e) {
      emit(SettingsError(e.message));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final userID = _authRepository.currentUserID;
      if (userID == null) {
        emit(const SettingsError('User not found'));
        return;
      }

      await _authRepository.changePassword(
        userID: userID,
        newPassword: event.newPassword,
      );

      emit(
        PasswordChangeSuccess(
          message: 'Password changed successfully',
          settings:
              _currentSettings ??
              const SettingsModel(
                id: 0,
                latitude: 0,
                longitude: 0,
                radius: 100,
                inTime: '09:00',
                outTime: '17:00',
              ),
        ),
      );
    } on AppFailure catch (e) {
      emit(SettingsError(e.message));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
