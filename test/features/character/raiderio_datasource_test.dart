import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/character/data/datasources/raiderio_datasource.dart';

class _DynamicResponseAdapter implements HttpClientAdapter {
  final Map<String, dynamic> Function(RequestOptions options) handler;
  int fetchCount = 0;

  _DynamicResponseAdapter({required this.handler});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount++;
    final body = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('RaiderIoDataSource.getCurrentLiveRaid', () {
    test('selects the active raid for region and current date', () async {
      final now = DateTime.now().toUtc();
      final adapter = _DynamicResponseAdapter(
        handler: (_) => _staticDataResponse([
          _raidJson(
            slug: 'old-raid',
            name: 'Old Raid',
            start: now.subtract(const Duration(days: 60)),
            end: now.subtract(const Duration(days: 20)),
            bosses: 8,
          ),
          _raidJson(
            slug: 'current-raid',
            name: 'Current Raid',
            start: now.subtract(const Duration(days: 2)),
            end: now.add(const Duration(days: 10)),
            bosses: 9,
          ),
        ]),
      );

      final dio = Dio()..httpClientAdapter = adapter;
      final ds = RaiderIoDataSource(ApiClient(dio: dio));

      final raid = await ds.getCurrentLiveRaid(region: 'eu');

      expect(raid, isNotNull);
      expect(raid!.slug, 'current-raid');
      expect(raid.name, 'Current Raid');
      expect(raid.totalBosses, 9);
    });

    test('falls back to latest started raid when none is active', () async {
      final now = DateTime.now().toUtc();
      final adapter = _DynamicResponseAdapter(
        handler: (_) => _staticDataResponse([
          _raidJson(
            slug: 'older-start',
            name: 'Older Start',
            start: now.subtract(const Duration(days: 90)),
            end: now.subtract(const Duration(days: 30)),
            bosses: 8,
          ),
          _raidJson(
            slug: 'latest-started',
            name: 'Latest Started',
            start: now.subtract(const Duration(days: 10)),
            end: now.subtract(const Duration(days: 1)),
            bosses: 10,
          ),
        ]),
      );

      final dio = Dio()..httpClientAdapter = adapter;
      final ds = RaiderIoDataSource(ApiClient(dio: dio));

      final raid = await ds.getCurrentLiveRaid(region: 'us');

      expect(raid, isNotNull);
      expect(raid!.slug, 'latest-started');
      expect(raid.totalBosses, 10);
    });

    test('returns cached value on second call within ttl', () async {
      final now = DateTime.now().toUtc();
      final adapter = _DynamicResponseAdapter(
        handler: (_) => _staticDataResponse([
          _raidJson(
            slug: 'cache-raid',
            name: 'Cache Raid',
            start: now.subtract(const Duration(days: 1)),
            end: now.add(const Duration(days: 10)),
            bosses: 8,
          ),
        ]),
      );

      final dio = Dio()..httpClientAdapter = adapter;
      final ds = RaiderIoDataSource(ApiClient(dio: dio));

      final first = await ds.getCurrentLiveRaid(region: 'eu');
      final second = await ds.getCurrentLiveRaid(region: 'eu');

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.slug, second!.slug);
      expect(adapter.fetchCount, 1);
    });
  });
}

Map<String, dynamic> _staticDataResponse(List<Map<String, dynamic>> raids) {
  return {'raids': raids};
}

Map<String, dynamic> _raidJson({
  required String slug,
  required String name,
  required DateTime start,
  required DateTime end,
  required int bosses,
}) {
  final starts = <String, String>{
    'us': start.toIso8601String(),
    'eu': start.toIso8601String(),
    'kr': start.toIso8601String(),
    'tw': start.toIso8601String(),
  };
  final ends = <String, String>{
    'us': end.toIso8601String(),
    'eu': end.toIso8601String(),
    'kr': end.toIso8601String(),
    'tw': end.toIso8601String(),
  };

  return {
    'slug': slug,
    'name': name,
    'starts': starts,
    'ends': ends,
    'encounters': List.generate(
      bosses,
      (index) => {'slug': '$slug-boss-$index', 'name': 'Boss ${index + 1}'},
    ),
  };
}
