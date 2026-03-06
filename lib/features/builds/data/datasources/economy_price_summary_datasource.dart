import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/builds/domain/entities/economy_price_summary.dart';

class EconomyPriceSummaryDataSource {
  final ApiClient _client;
  final bool _economyAssistantEnabled;

  static const _workerUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev';
  static const _v1Endpoint = '$_workerUrl/v1/economy/price-summary';
  static const _healthEndpoint = '$_workerUrl/health';
  static const _enabledByFlag = bool.fromEnvironment(
    'FEATURE_ECONOMY_ASSISTANT',
    defaultValue: false,
  );

  bool? _supportsEconomySummaryV1;

  EconomyPriceSummaryDataSource(this._client, {bool? economyAssistantEnabled})
    : _economyAssistantEnabled = economyAssistantEnabled ?? _enabledByFlag;

  Future<EconomyPriceSummary> getPriceSummary({
    required String region,
    required List<int> itemIds,
    int? connectedRealmId,
    bool force = false,
  }) async {
    if (!_economyAssistantEnabled) {
      throw const ServerException(
        message: 'Feature disabled: economy_assistant',
        statusCode: 503,
      );
    }

    final supportsSummary = await _isEconomySummarySupported();
    if (!supportsSummary) {
      throw const ServerException(
        message: 'Feature disabled: economy_assistant',
        statusCode: 503,
      );
    }

    final normalizedIds = itemIds
        .where((id) => id > 0)
        .toSet()
        .toList(growable: false);
    if (normalizedIds.isEmpty) {
      throw const ServerException(
        message: 'Missing required param: item_ids',
        statusCode: 400,
      );
    }

    final query = <String, dynamic>{
      'region': region.toLowerCase(),
      'item_ids': normalizedIds.join(','),
      ...?(connectedRealmId == null
          ? null
          : {'connected_realm_id': connectedRealmId}),
      if (force) 'force': '1',
    };

    try {
      final data = await _client.get(
        _v1Endpoint,
        queryParameters: query,
        expectedErrorStatusCodes: const {400, 404, 405, 501, 503},
      );
      return EconomyPriceSummary.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final workerError = _extractWorkerError(e.response?.data);

      if (statusCode == 400) {
        throw ServerException(
          message: workerError ?? 'Invalid economy summary query parameters.',
          statusCode: 400,
        );
      }

      if (statusCode == 404) {
        throw NotFoundException(
          message:
              workerError ??
              'Economy price summary not found for selected parameters.',
        );
      }

      if (statusCode == 503) {
        throw ServerException(
          message: workerError ?? 'Feature disabled: economy_assistant',
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
        message: workerError ?? e.message ?? 'Unknown economy summary error',
        statusCode: statusCode,
      );
    }
  }

  Future<bool> _isEconomySummarySupported() async {
    if (_supportsEconomySummaryV1 != null) return _supportsEconomySummaryV1!;
    try {
      final health = await _client.get(
        _healthEndpoint,
        expectedErrorStatusCodes: const {404, 405, 501, 503},
      );
      final capabilities = health['capabilities'];
      if (capabilities is Map<String, dynamic>) {
        _supportsEconomySummaryV1 =
            capabilities['economy_price_summary_v1'] == true;
      } else {
        _supportsEconomySummaryV1 = false;
      }
    } on DioException {
      _supportsEconomySummaryV1 = false;
    }

    return _supportsEconomySummaryV1 ?? false;
  }

  String? _extractWorkerError(dynamic payload) {
    if (payload is! Map) return null;
    final error = payload['error'];
    if (error is! String) return null;
    final trimmed = error.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
