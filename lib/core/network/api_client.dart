import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiClient {
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
          _logger.e('ERROR: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(url, queryParameters: queryParameters);
    return response.data as Map<String, dynamic>;
  }
}
