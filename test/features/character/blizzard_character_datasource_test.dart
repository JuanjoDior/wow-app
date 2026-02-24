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

void main() {
  group('CharacterBlizzardData equipment icon parsing', () {
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
