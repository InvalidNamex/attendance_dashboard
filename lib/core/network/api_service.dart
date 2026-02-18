import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/constants.dart';

class ApiService {
  late final Dio dio;
  String? _username;
  String? _password;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  void setAuth(String username, String password) {
    _username = username;
    _password = password;
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    dio.options.headers['Authorization'] = basicAuth;
  }

  void clearAuth() {
    _username = null;
    _password = null;
    dio.options.headers.remove('Authorization');
  }

  String? get currentUsername => _username;
  String? get currentPassword => _password;

  bool get isAuthenticated => _username != null && _password != null;
}
