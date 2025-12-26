import 'dart:async';
import 'dart:typed_data';

import 'cancellation_token.dart';
import 'transfer_progress.dart';
import 'transfer_result.dart';

/// Configuration for transfer operations.
class TransferConfig {
  /// Request headers.
  final Map<String, String>? headers;

  /// Request timeout.
  final Duration? timeout;

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Whether to allow resumable transfers.
  final bool allowResume;

  /// Chunk size for uploads (in bytes).
  final int? chunkSize;

  /// Custom metadata to include with the transfer.
  final Map<String, dynamic>? metadata;

  const TransferConfig({
    this.headers,
    this.timeout,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.allowResume = true,
    this.chunkSize,
    this.metadata,
  });

  /// Creates a copy with updated values.
  TransferConfig copyWith({
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? allowResume,
    int? chunkSize,
    Map<String, dynamic>? metadata,
  }) {
    return TransferConfig(
      headers: headers ?? this.headers,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      allowResume: allowResume ?? this.allowResume,
      chunkSize: chunkSize ?? this.chunkSize,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Payload for upload operations.
class UploadPayload {
  /// Local file path to upload.
  final String? filePath;

  /// File bytes to upload (alternative to filePath).
  final Uint8List? bytes;

  /// File name.
  final String fileName;

  /// MIME type.
  final String? mimeType;

  /// File size in bytes.
  final int? fileSize;

  /// Additional form fields for multipart uploads.
  final Map<String, String>? formFields;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  const UploadPayload({
    this.filePath,
    this.bytes,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    this.formFields,
    this.metadata,
  }) : assert(
         filePath != null || bytes != null,
         'Either filePath or bytes must be provided',
       );

  /// Creates a payload from a file path.
  factory UploadPayload.fromPath({
    required String filePath,
    String? fileName,
    String? mimeType,
    int? fileSize,
    Map<String, String>? formFields,
    Map<String, dynamic>? metadata,
  }) {
    return UploadPayload(
      filePath: filePath,
      fileName: fileName ?? filePath.split('/').last,
      mimeType: mimeType,
      fileSize: fileSize,
      formFields: formFields,
      metadata: metadata,
    );
  }

  /// Creates a payload from bytes.
  factory UploadPayload.fromBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    Map<String, String>? formFields,
    Map<String, dynamic>? metadata,
  }) {
    return UploadPayload(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      fileSize: bytes.length,
      formFields: formFields,
      metadata: metadata,
    );
  }
}

/// Payload for download operations.
class DownloadPayload {
  /// URL to download from.
  final String url;

  /// Local file path to save to.
  final String? destinationPath;

  /// File name (used if destinationPath is a directory).
  final String? fileName;

  /// Expected file size (for progress calculation).
  final int? expectedSize;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  const DownloadPayload({
    required this.url,
    this.destinationPath,
    this.fileName,
    this.expectedSize,
    this.metadata,
  });
}

/// Abstract handler for upload operations.
///
/// Implement this interface to provide custom upload logic.
///
/// Example:
/// ```dart
/// class MyUploadHandler implements UploadHandler {
///   @override
///   Stream<TransferProgress> upload(
///     String uploadUrl,
///     UploadPayload payload, {
///     TransferConfig? config,
///     CancellationToken? cancellationToken,
///   }) async* {
///     // Your upload implementation
///     yield TransferProgress(...);
///   }
///
///   @override
///   Future<TransferResult> uploadAndComplete(...) async {
///     // Your upload implementation
///     return TransferSuccess(...);
///   }
/// }
/// ```
abstract class UploadHandler {
  /// Uploads a file and yields progress updates.
  ///
  /// [uploadUrl] is the URL to upload to.
  /// [payload] contains the file data and metadata.
  /// [config] contains optional configuration.
  /// [cancellationToken] can be used to cancel the upload.
  ///
  /// Yields [TransferProgress] updates as the upload progresses.
  Stream<TransferProgress> upload(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  /// Uploads a file and returns the final result.
  ///
  /// This is a convenience method that completes when the upload finishes.
  Future<TransferResult> uploadAndComplete(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  /// Pauses an ongoing upload.
  ///
  /// Returns true if the upload was paused successfully.
  /// Not all implementations support pausing.
  Future<bool> pause(String uploadId) async => false;

  /// Resumes a paused upload.
  ///
  /// Returns true if the upload was resumed successfully.
  /// Not all implementations support resuming.
  Future<bool> resume(String uploadId) async => false;

  /// Cancels an ongoing upload.
  ///
  /// Returns true if the upload was cancelled successfully.
  Future<bool> cancel(String uploadId) async => false;

  /// Retries a failed upload.
  ///
  /// Returns a new progress stream for the retry attempt.
  Stream<TransferProgress> retryUpload(
    String uploadId,
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return upload(
      uploadUrl,
      payload,
      config: config,
      cancellationToken: cancellationToken,
    );
  }
}

/// Abstract handler for download operations.
///
/// Implement this interface to provide custom download logic.
abstract class DownloadHandler {
  /// Downloads a file and yields progress updates.
  ///
  /// [payload] contains the download URL and destination.
  /// [config] contains optional configuration.
  /// [cancellationToken] can be used to cancel the download.
  ///
  /// Yields [TransferProgress] updates as the download progresses.
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  /// Downloads a file and returns the final result.
  ///
  /// This is a convenience method that completes when the download finishes.
  Future<TransferResult> downloadAndComplete(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  /// Gets the download URL for a file.
  ///
  /// This can be used to get a signed or temporary URL.
  Future<String> getDownloadUrl(String fileId) async => fileId;

  /// Pauses an ongoing download.
  Future<bool> pause(String downloadId) async => false;

  /// Resumes a paused download.
  Future<bool> resume(String downloadId) async => false;

  /// Cancels an ongoing download.
  Future<bool> cancel(String downloadId) async => false;

  /// Retries a failed download.
  Stream<TransferProgress> retryDownload(
    String downloadId,
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return download(
      payload,
      config: config,
      cancellationToken: cancellationToken,
    );
  }
}

/// Combined handler for both upload and download operations.
///
/// This is a convenience class for handlers that support both operations.
abstract class TransferHandler implements UploadHandler, DownloadHandler {
  // UploadHandler required methods
  @override
  Stream<TransferProgress> upload(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  @override
  Future<TransferResult> uploadAndComplete(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  // DownloadHandler required methods
  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  @override
  Future<TransferResult> downloadAndComplete(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  /// Retries a failed upload.
  ///
  /// Returns a new progress stream for the retry attempt.
  @override
  Stream<TransferProgress> retryUpload(
    String uploadId,
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return upload(
      uploadUrl,
      payload,
      config: config,
      cancellationToken: cancellationToken,
    );
  }

  /// Retries a failed download.
  ///
  /// Returns a new progress stream for the retry attempt.
  @override
  Stream<TransferProgress> retryDownload(
    String downloadId,
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return download(
      payload,
      config: config,
      cancellationToken: cancellationToken,
    );
  }

  /// Opens a completed file.
  Future<bool> openFile(String filePath) async => false;

  /// Deletes a file.
  Future<bool> deleteFile(String filePath) async => false;

  /// Gets file info.
  Future<Map<String, dynamic>?> getFileInfo(String fileId) async => null;
}

/// Callback types for transfer operations.
typedef OnUploadProgress = void Function(TransferProgress progress);
typedef OnDownloadProgress = void Function(TransferProgress progress);
typedef OnTransferComplete = void Function(TransferResult result);
typedef OnTransferError = void Function(TransferFailure failure);
typedef OnTransferCancel = void Function(String? reason);

/// A builder class for creating transfer operations with callbacks.
class TransferBuilder {
  final UploadHandler? _uploadHandler;
  final DownloadHandler? _downloadHandler;

  OnUploadProgress? _onUploadProgress;
  OnDownloadProgress? _onDownloadProgress;
  OnTransferComplete? _onComplete;
  OnTransferError? _onError;
  OnTransferCancel? _onCancel;
  TransferConfig? _config;
  CancellationToken? _cancellationToken;

  TransferBuilder({
    UploadHandler? uploadHandler,
    DownloadHandler? downloadHandler,
  }) : _uploadHandler = uploadHandler,
       _downloadHandler = downloadHandler;

  /// Sets the upload progress callback.
  TransferBuilder onUploadProgress(OnUploadProgress callback) {
    _onUploadProgress = callback;
    return this;
  }

  /// Sets the download progress callback.
  TransferBuilder onDownloadProgress(OnDownloadProgress callback) {
    _onDownloadProgress = callback;
    return this;
  }

  /// Sets the completion callback.
  TransferBuilder onComplete(OnTransferComplete callback) {
    _onComplete = callback;
    return this;
  }

  /// Sets the error callback.
  TransferBuilder onError(OnTransferError callback) {
    _onError = callback;
    return this;
  }

  /// Sets the cancel callback.
  TransferBuilder onCancel(OnTransferCancel callback) {
    _onCancel = callback;
    return this;
  }

  /// Sets the transfer configuration.
  TransferBuilder withConfig(TransferConfig config) {
    _config = config;
    return this;
  }

  /// Sets the cancellation token.
  TransferBuilder withCancellationToken(CancellationToken token) {
    _cancellationToken = token;
    return this;
  }

  /// Starts an upload operation.
  Future<TransferResult> upload(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    if (_uploadHandler == null) {
      return const TransferFailure(
        message: 'No upload handler configured',
        code: 'NO_HANDLER',
        isRecoverable: false,
      );
    }

    try {
      final stream = _uploadHandler.upload(
        uploadUrl,
        payload,
        config: config ?? _config,
        cancellationToken: cancellationToken ?? _cancellationToken,
      );

      TransferProgress? lastProgress;

      await for (final progress in stream) {
        lastProgress = progress;
        _onUploadProgress?.call(progress);

        if (progress.isCancelled) {
          _onCancel?.call(progress.errorMessage);
          return TransferCancelled(
            reason: progress.errorMessage,
            bytesTransferred: progress.bytesTransferred,
          );
        }

        if (progress.isFailed) {
          final failure = TransferFailure(
            message: progress.errorMessage ?? 'Upload failed',
            bytesTransferred: progress.bytesTransferred,
          );
          _onError?.call(failure);
          return failure;
        }
      }

      if (lastProgress?.isCompleted == true) {
        final success = TransferSuccess(
          localPath: payload.filePath ?? '',
          fileSize: payload.fileSize,
          metadata: payload.metadata,
        );
        _onComplete?.call(success);
        return success;
      }

      return const TransferFailure(
        message: 'Upload ended unexpectedly',
        code: 'UNEXPECTED_END',
      );
    } on CancellationException catch (e) {
      _onCancel?.call(e.reason);
      return TransferCancelled(reason: e.reason);
    } catch (e, stackTrace) {
      final failure = TransferFailure(
        message: e.toString(),
        exception: e,
        stackTrace: stackTrace,
      );
      _onError?.call(failure);
      return failure;
    }
  }

  /// Starts a download operation.
  Future<TransferResult> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    if (_downloadHandler == null) {
      return const TransferFailure(
        message: 'No download handler configured',
        code: 'NO_HANDLER',
        isRecoverable: false,
      );
    }

    try {
      final stream = _downloadHandler.download(
        payload,
        config: config ?? _config,
        cancellationToken: cancellationToken ?? _cancellationToken,
      );

      TransferProgress? lastProgress;

      await for (final progress in stream) {
        lastProgress = progress;
        _onDownloadProgress?.call(progress);

        if (progress.isCancelled) {
          _onCancel?.call(progress.errorMessage);
          return TransferCancelled(
            reason: progress.errorMessage,
            bytesTransferred: progress.bytesTransferred,
          );
        }

        if (progress.isFailed) {
          final failure = TransferFailure(
            message: progress.errorMessage ?? 'Download failed',
            bytesTransferred: progress.bytesTransferred,
          );
          _onError?.call(failure);
          return failure;
        }
      }

      if (lastProgress?.isCompleted == true) {
        final success = TransferSuccess(
          localPath: payload.destinationPath ?? '',
          remoteUrl: payload.url,
          fileSize: payload.expectedSize,
          metadata: payload.metadata,
        );
        _onComplete?.call(success);
        return success;
      }

      return const TransferFailure(
        message: 'Download ended unexpectedly',
        code: 'UNEXPECTED_END',
      );
    } on CancellationException catch (e) {
      _onCancel?.call(e.reason);
      return TransferCancelled(reason: e.reason);
    } catch (e, stackTrace) {
      final failure = TransferFailure(
        message: e.toString(),
        exception: e,
        stackTrace: stackTrace,
      );
      _onError?.call(failure);
      return failure;
    }
  }
}
