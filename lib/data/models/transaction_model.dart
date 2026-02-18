import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  final int id;
  final int userID;
  final DateTime timestamp;
  final String? photo;
  final int stampType;

  const TransactionModel({
    required this.id,
    required this.userID,
    required this.timestamp,
    this.photo,
    required this.stampType,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      userID: json['userID'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      photo: json['photo'] as String?,
      stampType: json['stamp_type'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userID': userID,
      'timestamp': timestamp.toIso8601String(),
      'photo': photo,
      'stamp_type': stampType,
    };
  }

  bool get isCheckIn => stampType == 0;
  bool get isCheckOut => stampType == 1;
  String get typeLabel => isCheckIn ? 'Check-In' : 'Check-Out';

  TransactionModel copyWith({
    int? id,
    int? userID,
    DateTime? timestamp,
    String? photo,
    int? stampType,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userID: userID ?? this.userID,
      timestamp: timestamp ?? this.timestamp,
      photo: photo ?? this.photo,
      stampType: stampType ?? this.stampType,
    );
  }

  @override
  List<Object?> get props => [id, userID, timestamp, photo, stampType];
}
