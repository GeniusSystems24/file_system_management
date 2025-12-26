/// Result of a file transfer operation.
///
/// This sealed class represents the possible outcomes of an upload or download operation.
/// Use pattern matching to handle different result types.
///
/// Example:
/// ```dart
/// final result = await handler.upload(file);
/// switch (result) {
///   case TransferSuccess(:final path, :final url):
///     print('Upload successful: $url');
///   case TransferFailure(:final error, :final code):
///     print('Upload failed: $error');
///   case TransferCancelled(:final reason):
///     print('Upload cancelled: $reason');
/// }
/// ```
sealed class TransferResult {
  const TransferResult();

  /// Whether the transfer was successful.
  bool get isSuccess => this is TransferSuccess;

  /// Whether the transfer failed.
  bool get isFailure => this is TransferFailure;

  /// Whether the transfer was cancelled.
  bool get isCancelled => this is TransferCancelled;
}

/// Represents a successful transfer.
class TransferSuccess extends TransferResult {
  /// The local file path.
  final String localPath;

  /// The remote URL (for uploads) or the download URL (for downloads).
  final String? remoteUrl;

  /// File size in bytes.
  final int? fileSize;

  /// MIME type of the file.
  final String? mimeType;

  /// Duration of the transfer.
  final Duration? duration;

  /// Average transfer speed in bytes per second.
  final double? averageSpeed;

  /// Additional metadata returned by the server or handler.
  final Map<String, dynamic>? metadata;

  /// Server response (for uploads).
  final dynamic serverResponse;

  const TransferSuccess({
    required this.localPath,
    this.remoteUrl,
    this.fileSize,
    this.mimeType,
    this.duration,
    this.averageSpeed,
    this.metadata,
    this.serverResponse,
  });

  @override
  String toString() {
    return 'TransferSuccess(localPath: $localPath, remoteUrl: $remoteUrl, '
        'fileSize: $fileSize, duration: $duration)';
  }
}

/// Represents a failed transfer.
class TransferFailure extends TransferResult {
  /// The error message.
  final String message;

  /// Error code for programmatic handling.
  final String? code;

  /// The underlying exception, if any.
  final Object? exception;

  /// Stack trace, if available.
  final StackTrace? stackTrace;

  /// Whether the error is recoverable (can be retried).
  final bool isRecoverable;

  /// HTTP status code, if applicable.
  final int? httpStatusCode;

  /// Bytes transferred before the failure.
  final int? bytesTransferred;

  /// Additional error details.
  final Map<String, dynamic>? details;

  const TransferFailure({
    required this.message,
    this.code,
    this.exception,
    this.stackTrace,
    this.isRecoverable = true,
    this.httpStatusCode,
    this.bytesTransferred,
    this.details,
  });

  /// Creates a failure from a network error.
  factory TransferFailure.network({
    String message = 'Network error occurred',
    Object? exception,
    StackTrace? stackTrace,
  }) {
    return TransferFailure(
      message: message,
      code: 'NETWORK_ERROR',
      exception: exception,
      stackTrace: stackTrace,
      isRecoverable: true,
    );
  }

  /// Creates a failure from a timeout.
  factory TransferFailure.timeout({
    String message = 'Transfer timed out',
    int? bytesTransferred,
  }) {
    return TransferFailure(
      message: message,
      code: 'TIMEOUT',
      isRecoverable: true,
      bytesTransferred: bytesTransferred,
    );
  }

  /// Creates a failure from a server error.
  factory TransferFailure.server({
    required int statusCode,
    String? message,
    dynamic responseBody,
  }) {
    return TransferFailure(
      message: message ?? 'Server error: $statusCode',
      code: 'SERVER_ERROR',
      httpStatusCode: statusCode,
      isRecoverable: statusCode >= 500,
      details: responseBody != null ? {'response': responseBody} : null,
    );
  }

  /// Creates a failure from a file error.
  factory TransferFailure.file({
    required String message,
    Object? exception,
  }) {
    return TransferFailure(
      message: message,
      code: 'FILE_ERROR',
      exception: exception,
      isRecoverable: false,
    );
  }

  /// Creates a failure from insufficient storage.
  factory TransferFailure.insufficientStorage({
    int? requiredBytes,
    int? availableBytes,
  }) {
    return TransferFailure(
      message: 'Insufficient storage space',
      code: 'INSUFFICIENT_STORAGE',
      isRecoverable: false,
      details: {
        if (requiredBytes != null) 'requiredBytes': requiredBytes,
        if (availableBytes != null) 'availableBytes': availableBytes,
      },
    );
  }

  /// Creates a failure from an authentication error.
  factory TransferFailure.unauthorized({
    String message = 'Authentication required',
  }) {
    return TransferFailure(
      message: message,
      code: 'UNAUTHORIZED',
      httpStatusCode: 401,
      isRecoverable: false,
    );
  }

  /// Creates a failure from a permission error.
  factory TransferFailure.forbidden({
    String message = 'Permission denied',
  }) {
    return TransferFailure(
      message: message,
      code: 'FORBIDDEN',
      httpStatusCode: 403,
      isRecoverable: false,
    );
  }

  /// Creates a failure for file not found.
  factory TransferFailure.notFound({
    String? url,
  }) {
    return TransferFailure(
      message: url != null ? 'File not found: $url' : 'File not found',
      code: 'NOT_FOUND',
      httpStatusCode: 404,
      isRecoverable: false,
    );
  }

  @override
  String toString() {
    return 'TransferFailure(message: $message, code: $code, '
        'isRecoverable: $isRecoverable)';
  }
}

/// Represents a cancelled transfer.
class TransferCancelled extends TransferResult {
  /// The reason for cancellation.
  final String? reason;

  /// Bytes transferred before cancellation.
  final int? bytesTransferred;

  /// Whether the partial data was preserved.
  final bool partialDataPreserved;

  const TransferCancelled({
    this.reason,
    this.bytesTransferred,
    this.partialDataPreserved = false,
  });

  @override
  String toString() {
    return 'TransferCancelled(reason: $reason, '
        'bytesTransferred: $bytesTransferred)';
  }
}

/// Extension methods for [TransferResult].
extension TransferResultExtensions on TransferResult {
  /// Maps the result to a value based on its type.
  T when<T>({
    required T Function(TransferSuccess success) success,
    required T Function(TransferFailure failure) failure,
    required T Function(TransferCancelled cancelled) cancelled,
  }) {
    return switch (this) {
      TransferSuccess s => success(s),
      TransferFailure f => failure(f),
      TransferCancelled c => cancelled(c),
    };
  }

  /// Maps the result to a value, with a default for non-success cases.
  T? whenSuccess<T>(T Function(TransferSuccess success) success) {
    if (this is TransferSuccess) {
      return success(this as TransferSuccess);
    }
    return null;
  }

  /// Gets the local path if successful, null otherwise.
  String? get localPathOrNull {
    return whenSuccess((s) => s.localPath);
  }

  /// Gets the error message if failed, null otherwise.
  String? get errorMessageOrNull {
    if (this is TransferFailure) {
      return (this as TransferFailure).message;
    }
    return null;
  }

  /// Throws if the result is a failure or cancelled.
  TransferSuccess getOrThrow() {
    return switch (this) {
      TransferSuccess s => s,
      TransferFailure f => throw TransferException(f.message, f.code),
      TransferCancelled c =>
        throw TransferCancelledException(c.reason ?? 'Transfer cancelled'),
    };
  }
}

/// Exception thrown when a transfer fails.
class TransferException implements Exception {
  final String message;
  final String? code;

  const TransferException(this.message, [this.code]);

  @override
  String toString() => 'TransferException: $message (code: $code)';
}

/// Exception thrown when a transfer is cancelled.
class TransferCancelledException implements Exception {
  final String reason;

  const TransferCancelledException(this.reason);

  @override
  String toString() => 'TransferCancelledException: $reason';
}
