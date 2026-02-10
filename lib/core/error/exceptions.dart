class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({this.message = 'Server error', this.statusCode});
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error'});
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException({this.message = 'Not found'});
}

class RateLimitException implements Exception {
  final String message;

  const RateLimitException({this.message = 'Rate limit exceeded'});
}
