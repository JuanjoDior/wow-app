import 'package:dio/dio.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/tooltip_detail.dart';

class TooltipRemoteDataSource {
  final ApiClient _client;
  final _detailCache = MemoryCache<TooltipDetail>(
    ttl: const Duration(minutes: 10),
  );
  static const _cacheVersion = 'tooltip-v2';

  static const _workerUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev';

  TooltipRemoteDataSource(this._client);

  Future<TooltipDetail> getTooltipDetail(
    TooltipEntityKind kind,
    int id, {
    required String locale,
    String region = 'eu',
    List<int> bonusIds = const [],
  }) async {
    final cacheKey = [
      _cacheVersion,
      kind.apiValue,
      id,
      locale,
      region.toLowerCase(),
      ...bonusIds,
    ].join(':');
    final cached = _detailCache.get(cacheKey);
    if (cached != null) return cached;

    final query = <String, dynamic>{
      'locale': locale,
      'region': region.toLowerCase(),
      if (bonusIds.isNotEmpty) 'bonus_ids': bonusIds.join(','),
    };

    try {
      final data = await _client.get(
        '$_workerUrl/api/tooltips/${kind.apiValue}/$id',
        queryParameters: query,
        expectedErrorStatusCodes: const {404},
      );
      final detail = TooltipDetail.fromJson(data);
      _detailCache.set(cacheKey, detail);
      return detail;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) throw const RateLimitException();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(message: 'Request timed out.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
