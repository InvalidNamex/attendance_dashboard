import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int userID;
  final String userName;
  final String? deviceID;
  final bool isAdmin;

  const UserModel({
    required this.userID,
    required this.userName,
    this.deviceID,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userID: json['userID'] as int,
      userName: json['userName'] as String,
      deviceID: json['deviceID'] as String?,
      isAdmin: json['isAdmin'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'userName': userName,
      'deviceID': deviceID,
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    int? userID,
    String? userName,
    String? deviceID,
    bool? isAdmin,
  }) {
    return UserModel(
      userID: userID ?? this.userID,
      userName: userName ?? this.userName,
      deviceID: deviceID ?? this.deviceID,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  List<Object?> get props => [userID, userName, deviceID, isAdmin];
}
