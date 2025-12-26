import 'dart:async';
import 'dart:math';

import 'package:file_system_management/file_system_management.dart';

/// Mock provider for simulating file transfers.
///
/// This provider can simulate:
/// - Successful transfers
/// - Failed transfers
/// - Slow/fast transfers
/// - Pause/resume
/// - Cancel
class MockTransferProvider {
  final Random _random = Random();

  /// Simulates a download with progress updates.
  Stream<TransferProgress> mockDownload({
    required int totalBytes,
    Duration duration = const Duration(seconds: 5),
    double failureRate = 0.0,
    CancellationToken? cancellationToken,
  }) async* {
    final steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    bool isPaused = false;

    // Register pause/resume handlers
    void Function()? unregisterCancel;
    if (cancellationToken != null) {
      unregisterCancel = cancellationToken.onCancel(() {
        // Will be handled in the loop
      });
    }

    for (int i = 1; i <= steps; i++) {
      // Check for cancellation
      if (cancellationToken?.isCancelled == true) {
        yield TransferProgress(
          bytesTransferred: (totalBytes * (i - 1) / steps).round(),
          totalBytes: totalBytes,
          status: TransferStatus.cancelled,
        );
        return;
      }

      // Wait for step duration
      await Future.delayed(stepDuration);

      // Simulate random failure
      if (failureRate > 0 && _random.nextDouble() < failureRate && i > steps ~/ 2) {
        yield TransferProgress.failed(
          bytesTransferred: (totalBytes * i / steps).round(),
          totalBytes: totalBytes,
          errorMessage: 'Simulated network error',
          errorCode: 'MOCK_ERROR',
        );
        return;
      }

      final bytesTransferred = (totalBytes * i / steps).round();
      final bytesPerSecond = totalBytes / duration.inSeconds;
      final remainingSeconds = (steps - i) * stepDuration.inSeconds;

      yield TransferProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: totalBytes,
        bytesPerSecond: bytesPerSecond,
        estimatedTimeRemaining: Duration(seconds: remainingSeconds),
        status: i == steps ? TransferStatus.completed : TransferStatus.running,
      );
    }

    unregisterCancel?.call();
  }

  /// Simulates an upload with progress updates.
  Stream<TransferProgress> mockUpload({
    required int totalBytes,
    Duration duration = const Duration(seconds: 5),
    double failureRate = 0.0,
    CancellationToken? cancellationToken,
  }) {
    return mockDownload(
      totalBytes: totalBytes,
      duration: duration,
      failureRate: failureRate,
      cancellationToken: cancellationToken,
    );
  }

  /// Simulates a slow transfer (useful for testing pause/resume).
  Stream<TransferProgress> mockSlowTransfer({
    required int totalBytes,
    CancellationToken? cancellationToken,
  }) {
    return mockDownload(
      totalBytes: totalBytes,
      duration: const Duration(seconds: 15),
      cancellationToken: cancellationToken,
    );
  }

  /// Simulates a transfer that always fails.
  Stream<TransferProgress> mockFailingTransfer({
    required int totalBytes,
  }) {
    return mockDownload(
      totalBytes: totalBytes,
      duration: const Duration(seconds: 3),
      failureRate: 1.0,
    );
  }

  /// Simulates a transfer that fails but can be retried.
  Stream<TransferProgress> mockRetryableTransfer({
    required int totalBytes,
    required int attempt,
  }) async* {
    // Fail on first attempt, succeed on retry
    if (attempt == 1) {
      await Future.delayed(const Duration(seconds: 2));
      yield TransferProgress.failed(
        bytesTransferred: totalBytes ~/ 3,
        totalBytes: totalBytes,
        errorMessage: 'Connection lost. Tap to retry.',
        errorCode: 'NETWORK_ERROR',
      );
      return;
    }

    // Succeed on retry
    yield* mockDownload(
      totalBytes: totalBytes,
      duration: const Duration(seconds: 3),
    );
  }
}

/// Mock download handler that uses [MockTransferProvider].
class MockDownloadHandler implements DownloadHandler {
  final MockTransferProvider _provider = MockTransferProvider();
  bool _isPaused = false;
  String? _currentId;

  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    _currentId = payload.url;
    _isPaused = false;

    return _provider.mockDownload(
      totalBytes: payload.expectedSize ?? 1024 * 1024,
      cancellationToken: cancellationToken,
    );
  }

  @override
  Future<TransferResult> downloadAndComplete(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    TransferProgress? lastProgress;

    await for (final progress in download(
      payload,
      config: config,
      cancellationToken: cancellationToken,
    )) {
      lastProgress = progress;
    }

    if (lastProgress?.isCompleted == true) {
      return TransferSuccess(
        localPath: payload.destinationPath ?? '/mock/path/${payload.fileName}',
        remoteUrl: payload.url,
        fileSize: payload.expectedSize,
      );
    }

    return TransferFailure(
      message: lastProgress?.errorMessage ?? 'Download failed',
    );
  }

  @override
  Future<bool> pause(String downloadId) async {
    if (_currentId == downloadId) {
      _isPaused = true;
      return true;
    }
    return false;
  }

  @override
  Future<bool> resume(String downloadId) async {
    if (_currentId == downloadId) {
      _isPaused = false;
      return true;
    }
    return false;
  }

  @override
  Future<bool> cancel(String downloadId) async {
    return true;
  }

  @override
  Future<String> getDownloadUrl(String fileId) async {
    return fileId;
  }

  @override
  Stream<TransferProgress> retry(
    String downloadId,
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return download(payload, config: config, cancellationToken: cancellationToken);
  }
}

/// Mock upload handler that uses [MockTransferProvider].
class MockUploadHandler implements UploadHandler {
  final MockTransferProvider _provider = MockTransferProvider();

  @override
  Stream<TransferProgress> upload(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return _provider.mockUpload(
      totalBytes: payload.fileSize ?? 1024 * 1024,
      cancellationToken: cancellationToken,
    );
  }

  @override
  Future<TransferResult> uploadAndComplete(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    TransferProgress? lastProgress;

    await for (final progress in upload(
      uploadUrl,
      payload,
      config: config,
      cancellationToken: cancellationToken,
    )) {
      lastProgress = progress;
    }

    if (lastProgress?.isCompleted == true) {
      return TransferSuccess(
        localPath: payload.filePath ?? '/mock/path/${payload.fileName}',
        remoteUrl: uploadUrl,
        fileSize: payload.fileSize,
      );
    }

    return TransferFailure(
      message: lastProgress?.errorMessage ?? 'Upload failed',
    );
  }

  @override
  Future<bool> pause(String uploadId) async => false;

  @override
  Future<bool> resume(String uploadId) async => false;

  @override
  Future<bool> cancel(String uploadId) async => true;

  @override
  Stream<TransferProgress> retry(
    String uploadId,
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return upload(uploadUrl, payload, config: config, cancellationToken: cancellationToken);
  }
}
