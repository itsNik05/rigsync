import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'failures.dart';

/// Base class for all use cases.
/// [Type] is the success return type.
/// [Params] is the input parameter type. Use [NoParams] for use cases with no input.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use cases that return a Stream instead of a Future.
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Placeholder for use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
