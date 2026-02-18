import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserEvent {
  const LoadUsers();
}

class CreateUserRequested extends UserEvent {
  final String username;
  final String password;
  final String? deviceID;
  final bool isAdmin;

  const CreateUserRequested({
    required this.username,
    required this.password,
    this.deviceID,
    this.isAdmin = false,
  });

  @override
  List<Object?> get props => [username, password, deviceID, isAdmin];
}

class UpdateUserRequested extends UserEvent {
  final int userID;
  final String? username;
  final String? password;
  final String? deviceID;

  const UpdateUserRequested({
    required this.userID,
    this.username,
    this.password,
    this.deviceID,
  });

  @override
  List<Object?> get props => [userID, username, password, deviceID];
}

class DeleteUserRequested extends UserEvent {
  final int userID;

  const DeleteUserRequested(this.userID);

  @override
  List<Object?> get props => [userID];
}
