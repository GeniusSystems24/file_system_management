import 'dart:async';

import '../entities/entities.dart';
import '../failures/failures.dart';

/// Result type for repository operations.
///
/// Uses Either pattern for functional error handling.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        _ => null,
      };

  Failure? get failureOrNull => switch (this) {
        Fail<T>(:final failure) => failure,
        _ => null,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Fail<T>(:final failure) => onFailure(failure),
    };
  }
}

/// Successful result.
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Failed result.
class Fail<T> extends Result<T> {
  final Failure failure;
  const Fail(this.failure);
}

/// Abstract repository interface for transfer operations.
///
/// This defines the contract for transfer data operations.
/// Implementations can use different data sources (local, remote, etc.).
abstract class TransferRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues a download task.
  ///
  /// Returns a stream of transfer updates.
  Future<Result<Stream<TransferEntity>>> enqueueDownload({
    required String url,
    String? fileName,
    String? directory,
    TransferConfigEntity? config,
  });

  /// Creates a parallel download task.
  Future<Result<Stream<TransferEntity>>> enqueueParallelDownload({
    required String url,
    List<String>? mirrorUrls,
    int chunks = 4,
    String? fileName,
    String? directory,
    TransferConfigEntity? config,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues an upload task.
  Future<Result<Stream<TransferEntity>>> enqueueUpload({
    required String url,
    required String filePath,
    String? fileName,
    Map<String, String>? fields,
    TransferConfigEntity? config,
  });

  /// Enqueues a binary upload task.
  Future<Result<Stream<TransferEntity>>> enqueueBinaryUpload({
    required String url,
    required String filePath,
    String? mimeType,
    TransferConfigEntity? config,
  });

  /// Enqueues a multi-file upload task.
  Future<Result<Stream<TransferEntity>>> enqueueMultiUpload({
    required String url,
    required List<(String fieldName, String filePath)> files,
    Map<String, String>? fields,
    TransferConfigEntity? config,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pauses a transfer.
  Future<Result<bool>> pause(String transferId);

  /// Resumes a transfer.
  Future<Result<bool>> resume(String transferId);

  /// Cancels a transfer.
  Future<Result<bool>> cancel(String transferId);

  /// Retries a failed transfer.
  Future<Result<Stream<TransferEntity>>> retry(String transferId);

  /// Resumes a failed download from where it stopped.
  Future<Result<bool>> resumeFailed(String transferId);

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pauses multiple transfers.
  Future<Result<List<bool>>> pauseAll(List<String> transferIds);

  /// Resumes multiple transfers.
  Future<Result<List<bool>>> resumeAll(List<String> transferIds);

  /// Cancels multiple transfers.
  Future<Result<bool>> cancelAll(List<String> transferIds);

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets a transfer by ID.
  Future<Result<TransferEntity?>> getById(String transferId);

  /// Gets all transfers.
  Future<Result<List<TransferEntity>>> getAll();

  /// Gets transfers by status.
  Future<Result<List<TransferEntity>>> getByStatus(TransferStatusEntity status);

  /// Gets transfers by group.
  Future<Result<List<TransferEntity>>> getByGroup(String group);

  /// Checks if a transfer is cached.
  Future<Result<String?>> getCachedPath(String url);

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Deletes a transfer record.
  Future<Result<void>> delete(String transferId);

  /// Deletes all transfer records.
  Future<Result<void>> deleteAll();

  /// Deletes transfers by status.
  Future<Result<void>> deleteByStatus(TransferStatusEntity status);

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOVERY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reschedules missing tasks after crash.
  Future<Result<(List<TransferEntity> succeeded, List<TransferEntity> failed)>>
      rescheduleMissing();

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Opens a completed file.
  Future<Result<bool>> openFile(String transferId);

  /// Moves a file to shared storage.
  Future<Result<String?>> moveToSharedStorage(
    String transferId, {
    String? directory,
    String? mimeType,
  });

  /// Opens a file by path.
  Future<Result<bool>> openFileByPath(String filePath, {String? mimeType});
}
