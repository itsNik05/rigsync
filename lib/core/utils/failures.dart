import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Used as the Left side of Either<Failure, T> in use cases.
abstract class Failure extends Equatable {
  const Failure([this.message = '']);

  final String message;

  @override
  List<Object> get props => [message];
}

// ── Network ──────────────────────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

// ── Local storage ─────────────────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Record not found']);
}

// ── Auth ──────────────────────────────────────────────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

// ── Business logic ────────────────────────────────────────────────────────────

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}

class PurchaseFailure extends Failure {
  const PurchaseFailure([super.message = 'Purchase could not be completed']);
}