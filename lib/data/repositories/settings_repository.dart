import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  final ApiService _apiService;

  SettingsRepository(this._apiService);

  Future<SettingsModel> getSettings() async {
    try {
      final response = await _apiService.dio.get(ApiEndpoints.settings);
      return SettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedFailure();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkFailure();
      }
      throw const ServerFailure();
    }
  }

  Future<SettingsModel> updateSettings({
    double? latitude,
    double? longitude,
    int? radius,
    String? inTime,
    String? outTime,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (radius != null) data['radius'] = radius;
      if (inTime != null) data['in_time'] = inTime;
      if (outTime != null) data['out_time'] = outTime;

      final response = await _apiService.dio.put(
        ApiEndpoints.settings,
        data: data,
      );
      return SettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw const ForbiddenFailure();
      throw const ServerFailure();
    }
  }
}
