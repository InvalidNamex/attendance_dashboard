import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../data/repositories/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc(this._userRepository) : super(const UserInitial()) {
    on<LoadUsers>(_onLoad);
    on<CreateUserRequested>(_onCreate);
    on<UpdateUserRequested>(_onUpdate);
    on<DeleteUserRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadUsers event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    try {
      final users = await _userRepository.getAllUsers();
      emit(UserLoaded(users));
    } on AppFailure catch (e) {
      emit(UserError(e.message));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateUserRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      await _userRepository.createUser(
        username: event.username,
        password: event.password,
        deviceID: event.deviceID,
        isAdmin: event.isAdmin,
      );
      final users = await _userRepository.getAllUsers();
      emit(
        UserActionSuccess(message: 'User created successfully', users: users),
      );
    } on AppFailure catch (e) {
      emit(UserError(e.message));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateUserRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      await _userRepository.updateUser(
        event.userID,
        username: event.username,
        password: event.password,
        deviceID: event.deviceID,
      );
      final users = await _userRepository.getAllUsers();
      emit(
        UserActionSuccess(message: 'User updated successfully', users: users),
      );
    } on AppFailure catch (e) {
      emit(UserError(e.message));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteUserRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      await _userRepository.deleteUser(event.userID);
      final users = await _userRepository.getAllUsers();
      emit(
        UserActionSuccess(message: 'User deleted successfully', users: users),
      );
    } on AppFailure catch (e) {
      emit(UserError(e.message));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
