import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';

class BuildGapAnalysisDataSource {
  final ApiClient _client;
  final bool _v2Enabled;

  static const _workerUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev';
  static const _v1Endpoint = '$_workerUrl/v1/build/gap-analysis';
  static const _v2Endpoint = '$_workerUrl/v2/build/verification';
  static const _healthEndpoint = '$_workerUrl/health';
  static const _v2EnabledByFlag = bool.fromEnvironment(
    'BUILD_VERIFICATION_V2',
    defaultValue: false,
  );

  bool? _supportsV2;

  BuildGapAnalysisDataSource(this._client, {bool? v2Enabled})
    : _v2Enabled = v2Enabled ?? _v2EnabledByFlag;

  Future<BuildGapAnalysis> getGapAnalysis({
    required String region,
    required String realm,
    required String name,
    String? className,
    String? specName,
    List<BuildSlot>? buildSlots,
    bool force = false,
  }) async {
    final serializedBuildSlots = _serializeBuildSlots(buildSlots);
    final query = <String, dynamic>{
      'region': region.toLowerCase(),
      'realm': realm.toLowerCase(),
      'name': name.toLowerCase(),
    };
    if (className != null && className.trim().isNotEmpty) {
      query['class'] = className.trim().toLowerCase();
    }
    if (specName != null && specName.trim().isNotEmpty) {
      query['spec'] = specName.trim().toLowerCase();
    }
    if (serializedBuildSlots != null) {
      query['build_slots'] = serializedBuildSlots;
    }
    if (force) {
      query['force'] = '1';
    }

    try {
      final data = await _getGapAnalysisPayload(query);
      return BuildGapAnalysis.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final workerError = _extractWorkerError(e.response?.data);

      if (statusCode == 400) {
        throw ServerException(
          message: workerError ?? 'Invalid gap-analysis query parameters.',
          statusCode: 400,
        );
      }

      if (statusCode == 404) {
        throw NotFoundException(
          message:
              workerError ??
              'Gap analysis data not found for the selected character/spec.',
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
        message: workerError ?? e.message ?? 'Unknown gap-analysis error',
        statusCode: statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> _getGapAnalysisPayload(
    Map<String, dynamic> query,
  ) async {
    final canUseV2 = await _canUseV2();
    if (!canUseV2) {
      return _requestV1(query);
    }

    try {
      final v2Data = await _requestV2(query);
      if (_looksLikeGapAnalysisPayload(v2Data)) {
        return v2Data;
      }
      return _requestV1(query);
    } on DioException catch (error) {
      if (_shouldFallbackToV1(error)) {
        _supportsV2 = false;
        return _requestV1(query);
      }
      rethrow;
    } catch (_) {
      return _requestV1(query);
    }
  }

  Future<bool> _canUseV2() async {
    if (!_v2Enabled) return false;
    if (_supportsV2 != null) return _supportsV2!;

    try {
      final health = await _client.get(_healthEndpoint);
      final capabilities = health['capabilities'];
      if (capabilities is Map) {
        final enabled = capabilities['build_verification_v2'];
        _supportsV2 = enabled == true;
      } else {
        _supportsV2 = false;
      }
    } catch (_) {
      _supportsV2 = false;
    }
    return _supportsV2!;
  }

  Future<Map<String, dynamic>> _requestV2(Map<String, dynamic> query) {
    return _client.get(
      _v2Endpoint,
      queryParameters: query,
      expectedErrorStatusCodes: const {400, 404, 405, 501},
    );
  }

  Future<Map<String, dynamic>> _requestV1(Map<String, dynamic> query) {
    return _client.get(
      _v1Endpoint,
      queryParameters: query,
      expectedErrorStatusCodes: const {400, 404},
    );
  }

  bool _shouldFallbackToV1(DioException error) {
    final status = error.response?.statusCode;
    if (status == 405 || status == 501) {
      return true;
    }

    if (status != 404) {
      return false;
    }

    final data = error.response?.data;
    if (data is! Map) {
      return true;
    }

    final payload = Map<String, dynamic>.from(data);
    final endpoint = payload['endpoint']?.toString();
    if (endpoint == '/v2/build/verification') {
      return false;
    }

    final workerError = payload['error']?.toString().toLowerCase().trim() ?? '';
    if (workerError.contains('character not found') ||
        workerError.contains('unknown region') ||
        workerError.contains('missing required params')) {
      return false;
    }

    return true;
  }

  bool _looksLikeGapAnalysisPayload(Map<String, dynamic> payload) {
    final summary = payload['summary'];
    final actions = payload['actions'];
    return summary is Map && actions is List;
  }

  String? _extractWorkerError(dynamic payload) {
    if (payload is! Map) return null;
    final error = payload['error'];
    if (error is! String) return null;
    final trimmed = error.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _serializeBuildSlots(List<BuildSlot>? buildSlots) {
    if (buildSlots == null || buildSlots.isEmpty) return null;

    final payload = <Map<String, dynamic>>[];
    for (final slot in buildSlots) {
      final enchantCanonicalName =
          slot.enchantment?.canonicalNameEn?.trim() ?? '';
      final enchantFallbackName = slot.enchantment?.name.trim() ?? '';
      final enchantName = enchantCanonicalName.isNotEmpty
          ? enchantCanonicalName
          : (enchantFallbackName.isNotEmpty ? enchantFallbackName : null);
      final enchantId = slot.enchantment?.id;
      final gemNames = slot.gems
          .map((gem) {
            final canonical = gem.canonicalNameEn?.trim() ?? '';
            if (canonical.isNotEmpty) return canonical;
            return gem.name.trim();
          })
          .where((name) => name.isNotEmpty)
          .toList();
      final gemIds = slot.gems.map((gem) => gem.id).toList();
      if ((enchantName == null || enchantName.isEmpty) && gemNames.isEmpty) {
        continue;
      }

      payload.add({
        'slot': slot.slot.name,
        ...?enchantId == null ? null : {'enchantment_id': enchantId},
        ...?((enchantName == null || enchantName.isEmpty)
            ? null
            : {'enchantment': enchantName}),
        ...?(gemIds.isEmpty ? null : {'gem_ids': gemIds}),
        ...?(gemNames.isEmpty ? null : {'gems': gemNames}),
      });
    }

    if (payload.isEmpty) return null;
    return jsonEncode(payload);
  }
}
