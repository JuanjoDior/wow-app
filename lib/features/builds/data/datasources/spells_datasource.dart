import 'package:dio/dio.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';

class SpellsDataSource {
  final ApiClient _client;

  static const _workerUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev';

  // Caché por sesión: "query:locale" → resultados (TTL 5 min)
  final _cache = MemoryCache<List<WowSpell>>(ttl: const Duration(minutes: 5));

  SpellsDataSource(this._client);

  Future<List<WowSpell>> searchSpells(
    String name, {
    String locale = 'en_GB',
  }) async {
    final key = '${name.toLowerCase()}:$locale';
    final cached = _cache.get(key);
    if (cached != null) return cached;

    try {
      final data = await _client.get(
        '$_workerUrl/api/spells/search',
        queryParameters: {'name': name, 'locale': locale},
      );

      final results = data['results'] as List<dynamic>? ?? [];
      final spells = results
          .map((e) => WowSpell.fromJson(e as Map<String, dynamic>))
          .toList();

      _cache.set(key, spells);
      return spells;
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
