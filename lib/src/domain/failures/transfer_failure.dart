/// Base class for domain failures.
///
/// Failures represent expected error conditions in the domain layer.
/// They are different from exceptions in that they are expected and handled.
sealed class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Failure related to transfer operations.
sealed class TransferFailure extends Failure {
  const TransferFailure({required super.message, super.code});
}

/// Network-related failures.
class NetworkFailure extends TransferFailure {
  final int? statusCode;

  const NetworkFailure({
    required super.message,
    super.code,
    this.statusCode,
  });
}

/// File not found failure.
class FileNotFoundFailure extends TransferFailure {
  final String filePath;

  const FileNotFoundFailure({
    required this.filePath,
    super.code,
  }) : super(message: 'File not found: $filePath');
}

/// Permission denied failure.
class PermissionFailure extends TransferFailure {
  final String permission;

  const PermissionFailure({
    required this.permission,
    super.code,
  }) : super(message: 'Permission denied: $permission');
}

/// Storage-related failures.
class StorageFailure extends TransferFailure {
  final int? requiredBytes;
  final int? availableBytes;

  const StorageFailure({
    required super.message,
    super.code,
    this.requiredBytes,
    this.availableBytes,
  });

  factory StorageFailure.insufficientSpace({
    required int requiredBytes,
    required int availableBytes,
  }) =>
      StorageFailure(
        message: 'Insufficient storage space',
        code: 'INSUFFICIENT_SPACE',
        requiredBytes: requiredBytes,
        availableBytes: availableBytes,
      );
}

/// Transfer was cancelled.
class CancelledFailure extends TransferFailure {
  final int? bytesTransferred;

  const CancelledFailure({
    String? reason,
    this.bytesTransferred,
  }) : super(message: reason ?? 'Transfer cancelled', code: 'CANCELLED');
}

/// Transfer timed out.
class TimeoutFailure extends TransferFailure {
  final Duration timeout;

  TimeoutFailure({
    required this.timeout,
  }) : super(
          message: 'Transfer timed out after ${timeout.inSeconds}s',
          code: 'TIMEOUT',
        );
}

/// Unknown or unexpected failure.
class UnknownFailure extends TransferFailure {
  final Object? exception;
  final StackTrace? stackTrace;

  const UnknownFailure({
    required super.message,
    super.code,
    this.exception,
    this.stackTrace,
  });
}

/// Validation failure.
class ValidationFailure extends TransferFailure {
  final String field;

  const ValidationFailure({
    required this.field,
    required super.message,
  }) : super(code: 'VALIDATION_ERROR');
}
