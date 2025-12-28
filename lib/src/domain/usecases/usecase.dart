import '../repositories/transfer_repository.dart';

/// Base class for all use cases.
///
/// Use cases encapsulate a single piece of business logic.
/// They depend on repositories and return [Result] types.
abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

/// Use case that doesn't require parameters.
abstract class NoParamsUseCase<Type> {
  Future<Result<Type>> call();
}

/// Use case that returns a stream.
abstract class StreamUseCase<Type, Params> {
  Future<Result<Stream<Type>>> call(Params params);
}

/// No parameters placeholder.
class NoParams {
  const NoParams();
}
