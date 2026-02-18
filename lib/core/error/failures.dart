class AppFailure implements Exception {
  final String message;
  final int? statusCode;

  const AppFailure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'Network error. Please check your connection.',
  ]);
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'Unauthorized. Please login again.',
  ]) : super(statusCode: 401);
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'Insufficient permissions.'])
    : super(statusCode: 403);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Resource not found.'])
    : super(statusCode: 404);
}

class BadRequestFailure extends AppFailure {
  const BadRequestFailure([super.message = 'Invalid request.'])
    : super(statusCode: 400);
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error. Please try again later.'])
    : super(statusCode: 500);
}
