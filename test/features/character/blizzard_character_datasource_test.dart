import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/features/character/data/datasources/blizzard_character_datasource.dart';

class _StaticResponseAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> body;

  _StaticResponseAdapter({required this.statusCode, required this.body});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RouteAwareAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) responder;
  final List<String> requestedPaths = <String>[];
  final List<Map<String, dynamic>> requestedQueryParameters =
      <Map<String, dynamic>>[];

  _RouteAwareAdapter({required this.responder});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    requestedQueryParameters.add(
      Map<String, dynamic>.from(options.queryParameters),
    );
    return responder(options);
  }
}

void main() {
  group('CharacterBlizzardData equipment icon parsing', () {
    test('reads thumbnail_url', () {
      final data = CharacterBlizzardData.fromJson({
        'name': 'Test',
        'realm': 'Realm',
        'region': 'eu',
        'class': 'Mage',
        'race': 'Human',
        'thumbnail_url': 'https://cdn.example/avatar.jpg',
        'equipment': const [],
      });

      expect(data.thumbnailUrl, 'https://cdn.example/avatar.jpg');
    });

    test('reads icon_url (snake_case)', () {
      final data = CharacterBlizzardData.fromJson({
        'name': 'Test',
        'realm': 'Realm',
        'region': 'eu',
        'class': 'Mage',
        'race': 'Human',
        'equipment': [
          {
            'slot': 'HEAD',
            'name': 'Helm',
            'item_level': 626,
            'quality': 'EPIC',
            'item_id': 1001,
            'icon_url': 'https://cdn.example/head.jpg',
          },
        ],
      });

      expect(data.equipment, hasLength(1));
      expect(data.equipment.first.iconUrl, 'https://cdn.example/head.jpg');
    });

    test('reads iconUrl (camelCase)', () {
      final data = CharacterBlizzardData.fromJson({
        'name': 'Test',
        'realm': 'Realm',
        'region': 'eu',
        'class': 'Mage',
        'race': 'Human',
        'equipment': [
          {
            'slot': 'HEAD',
            'name': 'Helm',
            'item_level': 626,
            'quality': 'EPIC',
            'item_id': 1001,
            'iconUrl': 'https://cdn.example/head-camel.jpg',
          },
        ],
      });

      expect(data.equipment, hasLength(1));
      expect(
        data.equipment.first.iconUrl,
        'https://cdn.example/head-camel.jpg',
      );
    });

    test('keeps iconUrl null when no icon fields exist', () {
      final data = CharacterBlizzardData.fromJson({
        'name': 'Test',
        'realm': 'Realm',
        'region': 'eu',
        'class': 'Mage',
        'race': 'Human',
        'equipment': [
          {
            'slot': 'HEAD',
            'name': 'Helm',
            'item_level': 626,
            'quality': 'EPIC',
            'item_id': 1001,
          },
        ],
      });

      expect(data.equipment, hasLength(1));
      expect(data.equipment.first.iconUrl, isNull);
    });
  });

  group('BlizzardCharacterDatasource v2 snapshot', () {
    test('reads snapshot payload when Worker returns v2 envelope', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StaticResponseAdapter(
        statusCode: 200,
        body: {
          'version': 'v2',
          'source': 'blizzard',
          'generated_at': '2026-03-03T10:00:00Z',
          'snapshot': {
            'name': 'Apastar',
            'realm': 'Sanguino',
            'region': 'eu',
            'class': 'Druid',
            'race': 'Night Elf',
            'level': 80,
            'equipment': const [],
          },
        },
      );

      final datasource = BlizzardCharacterDatasource(dio: dio);
      final result = await datasource.getCharacter(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      );

      expect(result.name, 'Apastar');
      expect(result.realm, 'Sanguino');
      expect(result.region, 'EU');
      expect(result.characterClass, 'Druid');
    });

    test('passes locale parameter to worker', () async {
      final adapter = _RouteAwareAdapter(
        responder: (options) async => ResponseBody.fromString(
          jsonEncode({
            'version': 'v2',
            'snapshot': {
              'name': 'Apastar',
              'realm': 'Sanguino',
              'region': 'eu',
              'class': 'Druid',
              'race': 'Night Elf',
              'level': 80,
              'equipment': const [],
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final datasource = BlizzardCharacterDatasource(dio: dio);

      await datasource.getCharacter(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
        locale: 'es_ES',
      );

      expect(adapter.requestedQueryParameters, isNotEmpty);
      expect(adapter.requestedQueryParameters.first['locale'], 'es_ES');
    });

    test(
      'falls back to legacy /character when v2 endpoint is unavailable',
      () async {
        final adapter = _RouteAwareAdapter(
          responder: (options) async {
            if (options.path.endsWith('/v2/character/snapshot')) {
              return ResponseBody.fromString(
                'Not Found',
                404,
                headers: {
                  Headers.contentTypeHeader: ['text/plain'],
                },
              );
            }

            if (options.path.endsWith('/character')) {
              return ResponseBody.fromString(
                jsonEncode({
                  'name': 'Apastar',
                  'realm': 'Sanguino',
                  'region': 'eu',
                  'class': 'Druid',
                  'race': 'Night Elf',
                  'level': 80,
                  'equipment': const [],
                }),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }

            return ResponseBody.fromString(
              jsonEncode({'error': 'Unexpected path: ${options.path}'}),
              500,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        final dio = Dio()..httpClientAdapter = adapter;
        final datasource = BlizzardCharacterDatasource(dio: dio);

        final result = await datasource.getCharacter(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        );

        expect(result.name, 'Apastar');
        expect(
          adapter.requestedPaths
              .where((p) => p.endsWith('/v2/character/snapshot'))
              .length,
          1,
        );
        expect(
          adapter.requestedPaths.where((p) => p.endsWith('/character')).length,
          1,
        );
      },
    );

    test(
      'does not fallback when v2 returns character-not-found error',
      () async {
        final adapter = _RouteAwareAdapter(
          responder: (options) async {
            if (options.path.endsWith('/v2/character/snapshot')) {
              return ResponseBody.fromString(
                jsonEncode({
                  'version': 'v2',
                  'endpoint': '/v2/character/snapshot',
                  'error': 'Character not found. Check region, realm and name.',
                }),
                404,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }

            return ResponseBody.fromString(
              jsonEncode({
                'name': 'ShouldNotBeCalled',
                'realm': 'Sanguino',
                'region': 'eu',
                'class': 'Druid',
                'race': 'Night Elf',
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        final dio = Dio()..httpClientAdapter = adapter;
        final datasource = BlizzardCharacterDatasource(dio: dio);

        expect(
          () => datasource.getCharacter(
            region: 'eu',
            realm: 'sanguino',
            name: 'missing',
          ),
          throwsA(isA<NotFoundException>()),
        );
        expect(
          adapter.requestedPaths.where((p) => p.endsWith('/character')).length,
          0,
        );
      },
    );
  });

  group('BlizzardCharacterDatasource errors', () {
    test('propagates Worker 400 error message', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StaticResponseAdapter(
        statusCode: 400,
        body: {'error': 'Unknown region: cn. Use: us, eu, kr, tw'},
      );

      final datasource = BlizzardCharacterDatasource(dio: dio);

      try {
        await datasource.getCharacter(
          region: 'cn',
          realm: 'test',
          name: 'test',
        );
        fail('Expected ServerException');
      } on ServerException catch (e) {
        expect(e.statusCode, 400);
        expect(e.message, 'Unknown region: cn. Use: us, eu, kr, tw');
      }
    });
  });
}
