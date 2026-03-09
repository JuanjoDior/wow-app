import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';

class BuildGapAnalysisDataSource {
  final ApiClient _client;

  static const _workerUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev';
  static const _v2Endpoint = '$_workerUrl/v2/build/verification';

  BuildGapAnalysisDataSource(this._client);

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
      final data = await _requestV2(query);
      if (!_looksLikeGapAnalysisPayload(data)) {
        throw const ServerException(
          message: 'Unexpected response from worker build verification.',
        );
      }
      return BuildGapAnalysis.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final workerError = _extractWorkerError(e.response?.data);

      if (statusCode == 400) {
        throw ServerException(
          message: workerError ?? 'Invalid build verification query parameters.',
          statusCode: 400,
        );
      }

      if (statusCode == 404) {
        throw NotFoundException(
          message:
              workerError ??
              'Build verification data not found for the selected character.',
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
        message: workerError ?? e.message ?? 'Unknown build verification error',
        statusCode: statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> _requestV2(Map<String, dynamic> query) {
    return _client.get(
      _v2Endpoint,
      queryParameters: query,
      expectedErrorStatusCodes: const {400, 404},
    );
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
