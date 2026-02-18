import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<SessionRestoreRequested>(_onSessionRestore);
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onSessionRestore(
    SessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.restoreSession();
      if (user != null && user.isAdmin) {
        emit(AuthAuthenticated(user));
      } else {
        // If user is not admin or session invalid, logout
        await _authRepository.logout();
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(event.username, event.password);
      // Only allow admin users to login
      if (!user.isAdmin) {
        await _authRepository.logout();
        emit(
          const AuthFailure('Only administrators can access this dashboard.'),
        );
        return;
      }
      emit(AuthAuthenticated(user));
    } on AppFailure catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('An unknown error occurred.'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
