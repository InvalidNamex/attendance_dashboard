import 'package:equatable/equatable.dart';

class SettingsModel extends Equatable {
  final int id;
  final double latitude;
  final double longitude;
  final int radius;
  final String inTime;
  final String outTime;

  const SettingsModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.inTime,
    required this.outTime,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: json['radius'] as int,
      inTime: json['in_time'] as String,
      outTime: json['out_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'in_time': inTime,
      'out_time': outTime,
    };
  }

  SettingsModel copyWith({
    int? id,
    double? latitude,
    double? longitude,
    int? radius,
    String? inTime,
    String? outTime,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
    );
  }

  @override
  List<Object?> get props => [id, latitude, longitude, radius, inTime, outTime];
}
