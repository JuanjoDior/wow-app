import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/network/api_client.dart';

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

class _MockLogger extends Mock implements Logger {}

void main() {
  group('ApiClient expected error logging', () {
    late _MockLogger logger;

    setUp(() {
      logger = _MockLogger();
    });

    test('logs warning when status is expected for request', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StaticResponseAdapter(
        statusCode: 400,
        body: {'error': 'Bad request'},
      );
      final client = ApiClient(dio: dio, logger: logger);

      await expectLater(
        () => client.get(
          'https://example.test/expected',
          expectedErrorStatusCodes: const {400, 404},
        ),
        throwsA(isA<DioException>()),
      );

      verify(() => logger.w(any<dynamic>())).called(1);
      verifyNever(() => logger.e(any<dynamic>()));
    });

    test('logs error when status is not expected for request', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StaticResponseAdapter(
        statusCode: 500,
        body: {'error': 'Server error'},
      );
      final client = ApiClient(dio: dio, logger: logger);

      await expectLater(
        () => client.get(
          'https://example.test/unexpected',
          expectedErrorStatusCodes: const {400, 404},
        ),
        throwsA(isA<DioException>()),
      );

      verify(() => logger.e(any<dynamic>())).called(1);
      verifyNever(() => logger.w(any<dynamic>()));
    });
  });
}
