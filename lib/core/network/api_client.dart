import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static const String _expectedErrorStatusesKey = 'expectedErrorStatusCodes';

  final Dio _dio;
  final Logger _logger;

  ApiClient({Dio? dio, Logger? logger})
    : _dio = dio ?? Dio(),
      _logger = logger ?? Logger() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('REQUEST: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('RESPONSE: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          final statusCode = error.response?.statusCode;
          final request = error.requestOptions;
          final method = request.method;
          final uri = request.uri;
          final extra = request.extra[_expectedErrorStatusesKey];
          final expectedStatuses = extra is Set<int> ? extra : const <int>{};
          final isExpectedStatus =
              statusCode != null && expectedStatuses.contains(statusCode);

          final logMessage =
              'HTTP ${statusCode ?? '-'} $method $uri: ${error.message}';
          if (isExpectedStatus) {
            _logger.w('EXPECTED $logMessage');
          } else {
            _logger.e('ERROR $logMessage');
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Set<int> expectedErrorStatusCodes = const {},
  }) async {
    final options = expectedErrorStatusCodes.isEmpty
        ? null
        : Options(extra: {_expectedErrorStatusesKey: expectedErrorStatusCodes});
    final response = await _dio.get(
      url,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as Map<String, dynamic>;
  }
}
