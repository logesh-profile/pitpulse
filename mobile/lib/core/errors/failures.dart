/// Base failure class representing operational failures.
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Connection timed out. Please verify backend is running.']);
}

class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Failed to parse response from server.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
