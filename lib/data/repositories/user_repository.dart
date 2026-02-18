import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiService.dio.get(ApiEndpoints.users);
      return (response.data as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedFailure();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkFailure();
      }
      throw const ServerFailure();
    }
  }

  Future<UserModel> createUser({
    required String username,
    required String password,
    String? deviceID,
    bool isAdmin = false,
  }) async {
    try {
      final response = await _apiService.dio.post(
        ApiEndpoints.users,
        data: {
          'userName': username,
          'password': password,
          'deviceID': deviceID,
          'isAdmin': isAdmin,
        },
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw const BadRequestFailure('Username already exists');
      }
      if (e.response?.statusCode == 403) throw const ForbiddenFailure();
      throw const ServerFailure();
    }
  }

  Future<UserModel> updateUser(
    int userID, {
    String? username,
    String? password,
    String? deviceID,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['userName'] = username;
      if (password != null) data['password'] = password;
      if (deviceID != null) data['deviceID'] = deviceID;

      final response = await _apiService.dio.put(
        ApiEndpoints.user(userID),
        data: data,
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const ForbiddenFailure('Not authorized to update this user');
      }
      if (e.response?.statusCode == 404) throw const NotFoundFailure();
      throw const ServerFailure();
    }
  }

  Future<void> deleteUser(int userID) async {
    try {
      await _apiService.dio.delete(ApiEndpoints.user(userID));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const ForbiddenFailure(
          'Cannot delete admin users or insufficient permissions',
        );
      }
      if (e.response?.statusCode == 404) throw const NotFoundFailure();
      throw const ServerFailure();
    }
  }
}
