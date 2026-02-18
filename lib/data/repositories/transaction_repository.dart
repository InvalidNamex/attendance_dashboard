import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final ApiService _apiService;

  TransactionRepository(this._apiService);

  Future<List<TransactionModel>> getTransactions({
    int? userId,
    int? stampType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;
      if (stampType != null) queryParams['stamp_type'] = stampType;
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String();
      }

      final response = await _apiService.dio.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map(
            (json) => TransactionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkFailure();
      }
      throw const ServerFailure();
    }
  }

  Future<TransactionModel> createTransaction({
    required int userId,
    required int stampType,
    String? timestamp,
    File? photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'stamp_type': stampType,
        if (timestamp != null) 'timestamp': timestamp,
      });

      // Add photo if provided
      if (photo != null) {
        formData.files.add(
          MapEntry(
            'photo',
            await MultipartFile.fromFile(
              photo.path,
              filename: photo.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _apiService.dio.post(
        ApiEndpoints.transactions,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return TransactionModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw const BadRequestFailure('Invalid stamp_type. Must be 0 or 1');
      }
      throw const ServerFailure();
    }
  }

  Future<TransactionModel> getTransaction(int transactionId) async {
    try {
      final response = await _apiService.dio.get(
        ApiEndpoints.transaction(transactionId),
      );
      return TransactionModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw const NotFoundFailure();
      throw const ServerFailure();
    }
  }

  Future<TransactionModel> updateTransaction({
    required int transactionId,
    DateTime? timestamp,
    int? stampType,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (timestamp != null) data['timestamp'] = timestamp.toIso8601String();
      if (stampType != null) data['stamp_type'] = stampType;

      final response = await _apiService.dio.put(
        ApiEndpoints.transaction(transactionId),
        data: data,
      );
      return TransactionModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw const NotFoundFailure();
      if (e.response?.statusCode == 400) {
        throw const BadRequestFailure('Invalid stamp_type. Must be 0 or 1');
      }
      throw const ServerFailure();
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    try {
      await _apiService.dio.delete(ApiEndpoints.transaction(transactionId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw const NotFoundFailure();
      throw const ServerFailure();
    }
  }
}
