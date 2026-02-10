import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? suggestion;
  final int? statusCode;

  const Failure({required this.message, this.suggestion, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Something went wrong on the server.',
    super.suggestion = 'Try again in a few seconds.',
    super.statusCode,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Could not connect to the internet.',
    super.suggestion = 'Check your connection and try again.',
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Could not load cached data.',
    super.suggestion = 'Try refreshing.',
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Character not found.',
    super.suggestion = 'Check the region, realm, and character name.',
    super.statusCode = 404,
  });
}

class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'Too many requests.',
    super.suggestion = 'Wait a moment and try again.',
    super.statusCode = 429,
  });
}
