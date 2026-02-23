import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

/// Llama al Cloudflare Worker para obtener recomendaciones por spec.
class SpecRecommendationsRemoteDatasource {
  final Dio _dio;
  final Logger _logger;

  // URL base del Worker — cambiar por la URL real tras deploy
  static const String _baseUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev';

  SpecRecommendationsRemoteDatasource({Dio? dio, Logger? logger})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            )),
        _logger = logger ?? Logger();

  Future<SpecRecommendation?> getRecommendations({
    required String className,
    required String specName,
    String? patch,
  }) async {
    try {
      final params = <String, String>{
        'class': className.toLowerCase(),
        'spec': specName.toLowerCase(),
      };
      if (patch != null) params['patch'] = patch;

      final response = await _dio.get(
        '$_baseUrl/recommendations',
        queryParameters: params,
      );

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        return _fromJson(response.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      _logger.w('SpecRecommendations remote failed: ${e.message}');
    } catch (e) {
      _logger.e('SpecRecommendations unexpected error: $e');
    }
    return null;
  }

  // ─── JSON parsing ──────────────────────────────────────────────────────────

  SpecRecommendation _fromJson(Map<String, dynamic> json) {
    final enchantsRaw = json['enchants'] as Map<String, dynamic>? ?? {};
    final enchants = enchantsRaw.map((slot, list) {
      final suggestions = (list as List<dynamic>)
          .map((e) => ItemSuggestion(
                name: e['name'] as String,
                note: e['note'] as String?,
                isPrimary: (e['is_primary'] as bool?) ?? false,
              ))
          .toList();
      return MapEntry(slot, suggestions);
    });

    final gems = json['gems'] as Map<String, dynamic>? ?? {};
    final consumables = json['consumables'] as Map<String, dynamic>? ?? {};
    final statPriority = (json['stat_priority'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final sourceStr = json['_source'] as String? ?? 'generated';
    final source = switch (sourceStr) {
      'cache'     => RecommendationSource.cache,
      'static'    => RecommendationSource.workerStatic,
      _           => RecommendationSource.remote,
    };

    return SpecRecommendation(
      className: json['class_name'] as String? ?? '',
      specName: json['spec_name'] as String? ?? '',
      patch: json['patch'] as String? ?? '',
      enchants: enchants,
      metaGem: _parseSingleSuggestion(gems['meta']),
      genericGem: _parseSingleSuggestion(gems['generic']),
      flask: _parseSingleSuggestion(consumables['flask']),
      food: _parseSingleSuggestion(consumables['food']),
      potion: _parseSingleSuggestion(consumables['potion']),
      weaponEnhancement: _parseSingleSuggestion(consumables['weapon']),
      statPriority: statPriority,
      source: source,
    );
  }

  /// Parsea un objeto JSON simple {"name": "...", "note": "..."} en ItemSuggestion.
  static ItemSuggestion? _parseSingleSuggestion(dynamic raw) {
    if (raw == null) return null;
    final map = raw as Map<String, dynamic>;
    return ItemSuggestion(
      name: map['name'] as String,
      note: map['note'] as String?,
      isPrimary: true,
    );
  }
}
