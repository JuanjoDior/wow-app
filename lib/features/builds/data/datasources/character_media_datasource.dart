import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';

class CharacterMedia {
  final String? renderUrl;
  final String? avatarUrl;

  const CharacterMedia({this.renderUrl, this.avatarUrl});
}

class CharacterMediaDataSource {
  final ApiClient _client;

  static const _workerUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev';

  // Caché en memoria por sesión: key → media (null = sin imagen)
  final Map<String, CharacterMedia?> _cache = {};

  CharacterMediaDataSource(this._client);

  /// Devuelve [CharacterMedia] para el personaje indicado.
  /// Usa caché en memoria para no repetir llamadas en la misma sesión.
  Future<CharacterMedia?> getMedia({
    required String region,
    required String realm,
    required String name,
  }) async {
    final key =
        '${region.toLowerCase()}-'
        '${realm.toLowerCase()}-'
        '${name.toLowerCase()}';

    if (_cache.containsKey(key)) return _cache[key];

    try {
      final data = await _client.get(
        '$_workerUrl/api/character/$region/$realm/$name/media',
      );

      final media = CharacterMedia(
        renderUrl: data['renderUrl'] as String?,
        avatarUrl: data['avatarUrl'] as String?,
      );

      _cache[key] = media;
      return media;
    } on DioException catch (e) {
      // Ante cualquier error de red guardamos null en caché para
      // no reintentar en cada rebuild del cubit
      _cache[key] = null;
      if (e.response?.statusCode == 429) throw const RateLimitException();
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    } catch (_) {
      _cache[key] = null;
      return null;
    }
  }
}
