import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';

class WeeklyPlannerDataSource {
  final ApiClient _client;
  final bool _weeklyPlannerEnabled;

  static const _workerUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev';
  static const _v1Endpoint = '$_workerUrl/v1/planner/weekly';
  static const _healthEndpoint = '$_workerUrl/health';
  static const _enabledByFlag = bool.fromEnvironment(
    'FEATURE_WEEKLY_PLANNER',
    defaultValue: false,
  );

  bool? _supportsWeeklyPlanner;

  WeeklyPlannerDataSource(this._client, {bool? weeklyPlannerEnabled})
    : _weeklyPlannerEnabled = weeklyPlannerEnabled ?? _enabledByFlag;

  Future<WeeklyPlanner> getWeeklyPlanner({
    required String region,
    required String realm,
    required String name,
    bool force = false,
  }) async {
    if (!_weeklyPlannerEnabled) {
      throw const ServerException(
        message: 'Feature disabled: weekly_planner',
        statusCode: 503,
      );
    }

    final supportsPlanner = await _isWeeklyPlannerSupported();
    if (!supportsPlanner) {
      throw const ServerException(
        message: 'Feature disabled: weekly_planner',
        statusCode: 503,
      );
    }

    final query = <String, dynamic>{
      'region': region.toLowerCase(),
      'realm': realm.toLowerCase(),
      'name': name.toLowerCase(),
      if (force) 'force': '1',
    };

    try {
      final data = await _client.get(
        _v1Endpoint,
        queryParameters: query,
        expectedErrorStatusCodes: const {400, 404, 405, 501, 503},
      );
      return WeeklyPlanner.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final workerError = _extractWorkerError(e.response?.data);

      if (statusCode == 400) {
        throw ServerException(
          message: workerError ?? 'Invalid weekly planner query parameters.',
          statusCode: 400,
        );
      }

      if (statusCode == 404) {
        throw NotFoundException(
          message:
              workerError ??
              'Weekly planner data not found for the selected character.',
        );
      }

      if (statusCode == 503) {
        throw ServerException(
          message: workerError ?? 'Feature disabled: weekly_planner',
          statusCode: 503,
        );
      }

      if (statusCode == 429) {
        throw const RateLimitException();
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(message: 'Request timed out.');
      }

      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }

      throw ServerException(
        message: workerError ?? e.message ?? 'Unknown weekly planner error',
        statusCode: statusCode,
      );
    }
  }

  Future<bool> _isWeeklyPlannerSupported() async {
    if (_supportsWeeklyPlanner != null) return _supportsWeeklyPlanner!;
    try {
      final health = await _client.get(
        _healthEndpoint,
        expectedErrorStatusCodes: const {404, 405, 501, 503},
      );
      final capabilities = health['capabilities'];
      if (capabilities is Map<String, dynamic>) {
        _supportsWeeklyPlanner = capabilities['weekly_planner'] == true;
      } else {
        _supportsWeeklyPlanner = false;
      }
    } on DioException {
      _supportsWeeklyPlanner = false;
    }
    return _supportsWeeklyPlanner ?? false;
  }

  String? _extractWorkerError(dynamic payload) {
    if (payload is! Map) return null;
    final error = payload['error'];
    if (error is! String) return null;
    final trimmed = error.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
