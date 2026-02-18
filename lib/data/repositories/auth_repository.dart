import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthRepository(this._apiService, this._prefs);

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _apiService.dio.post(
        ApiEndpoints.login,
        data: {'userName': username, 'password': password},
      );

      _apiService.setAuth(username, password);
      final user = UserModel.fromJson(response.data);

      // Persist credentials
      await _prefs.setString(AppConstants.keyUsername, username);
      await _prefs.setString(AppConstants.keyPassword, password);
      await _prefs.setInt(AppConstants.keyUserID, user.userID);
      await _prefs.setBool(AppConstants.keyIsAdmin, user.isAdmin);

      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AppFailure('Invalid username or password', statusCode: 401);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkFailure();
      }
      throw const ServerFailure();
    }
  }

  Future<UserModel?> restoreSession() async {
    final username = _prefs.getString(AppConstants.keyUsername);
    final password = _prefs.getString(AppConstants.keyPassword);

    if (username == null || password == null) return null;

    _apiService.setAuth(username, password);

    final userID = _prefs.getInt(AppConstants.keyUserID);
    final isAdmin = _prefs.getBool(AppConstants.keyIsAdmin) ?? false;

    if (userID == null) return null;

    return UserModel(userID: userID, userName: username, isAdmin: isAdmin);
  }

  Future<void> changePassword({
    required int userID,
    required String newPassword,
  }) async {
    try {
      await _apiService.dio.put(
        ApiEndpoints.user(userID),
        data: {'password': newPassword},
      );

      // Update stored password
      final username = _prefs.getString(AppConstants.keyUsername);
      if (username != null) {
        _apiService.setAuth(username, newPassword);
        await _prefs.setString(AppConstants.keyPassword, newPassword);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const ForbiddenFailure();
      }
      if (e.response?.statusCode == 404) {
        throw const NotFoundFailure();
      }
      throw const ServerFailure();
    }
  }

  Future<void> logout() async {
    _apiService.clearAuth();
    await _prefs.remove(AppConstants.keyUsername);
    await _prefs.remove(AppConstants.keyPassword);
    await _prefs.remove(AppConstants.keyUserID);
    await _prefs.remove(AppConstants.keyIsAdmin);
  }

  int? get currentUserID => _prefs.getInt(AppConstants.keyUserID);
  bool get isAdmin => _prefs.getBool(AppConstants.keyIsAdmin) ?? false;
}
