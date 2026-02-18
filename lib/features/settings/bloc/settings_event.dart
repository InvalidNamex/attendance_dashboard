import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateSettingsRequested extends SettingsEvent {
  final double? latitude;
  final double? longitude;
  final int? radius;
  final String? inTime;
  final String? outTime;

  const UpdateSettingsRequested({
    this.latitude,
    this.longitude,
    this.radius,
    this.inTime,
    this.outTime,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius, inTime, outTime];
}

class ChangePasswordRequested extends SettingsEvent {
  final String newPassword;

  const ChangePasswordRequested({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}
