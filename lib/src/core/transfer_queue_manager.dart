import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../handlers/cancellation_token.dart';
import '../handlers/transfer_progress.dart';

/// Priority levels for queued transfers.
enum TransferPriority {
  /// Low priority - will be processed last.
  low(0),

  /// Normal priority - default.
  normal(1),

  /// High priority - will be processed before normal.
  high(2),

  /// Urgent priority - will be processed first.
  urgent(3);

  final int value;
  const TransferPriority(this.value);
}

/// Status of a queued transfer.
enum QueuedTransferStatus {
  /// Waiting in queue.
  queued,

  /// Currently being processed.
  running,

  /// Completed successfully.
  completed,

  /// Failed with error.
  failed,

  /// Cancelled by user.
  cancelled,

  /// Paused.
  paused,
}

/// Represents a transfer task in the queue.
class QueuedTransfer<T> {
  /// Unique identifier for this transfer.
  final String id;

  /// The task data.
  final T task;

  /// Priority of this transfer.
  final TransferPriority priority;

  /// When this transfer was added to the queue.
  final DateTime addedAt;

  /// Current status.
  QueuedTransferStatus status;

  /// Current progress (0.0 to 1.0).
  double progress;

  /// Error message if failed.
  String? errorMessage;

  /// Cancellation token for this transfer.
  final CancellationToken cancellationToken;

  /// Completer for the transfer result.
  final Completer<TransferQueueResult<T>> _completer;

  /// Stream controller for progress updates.
  final StreamController<TransferProgress> _progressController;

  /// Position in queue (0 = currently running, 1+ = waiting).
  int queuePosition;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  QueuedTransfer({
    required this.id,
    required this.task,
    this.priority = TransferPriority.normal,
    DateTime? addedAt,
    this.metadata,
  })  : addedAt = addedAt ?? DateTime.now(),
        status = QueuedTransferStatus.queued,
        progress = 0.0,
        queuePosition = -1,
        cancellationToken = CancellationToken(),
        _completer = Completer<TransferQueueResult<T>>(),
        _progressController = StreamController<TransferProgress>.broadcast();

  /// Future that completes when the transfer finishes.
  Future<TransferQueueResult<T>> get future => _completer.future;

  /// Stream of progress updates.
  Stream<TransferProgress> get progressStream => _progressController.stream;

  /// Whether the transfer is waiting in queue.
  bool get isQueued => status == QueuedTransferStatus.queued;

  /// Whether the transfer is currently running.
  bool get isRunning => status == QueuedTransferStatus.running;

  /// Whether the transfer has completed (success, failure, or cancelled).
  bool get isFinished =>
      status == QueuedTransferStatus.completed ||
      status == QueuedTransferStatus.failed ||
      status == QueuedTransferStatus.cancelled;

  /// Marks the transfer as running.
  void markRunning() {
    status = QueuedTransferStatus.running;
    queuePosition = 0;
  }

  /// Updates progress.
  void updateProgress(TransferProgress progressUpdate) {
    progress = progressUpdate.progress;
    if (!_progressController.isClosed) {
      _progressController.add(progressUpdate);
    }
  }

  /// Marks the transfer as completed.
  void markCompleted() {
    status = QueuedTransferStatus.completed;
    progress = 1.0;
    if (!_completer.isCompleted) {
      _completer.complete(TransferQueueResult.success(this));
    }
    _progressController.close();
  }

  /// Marks the transfer as failed.
  void markFailed(String error) {
    status = QueuedTransferStatus.failed;
    errorMessage = error;
    if (!_completer.isCompleted) {
      _completer.complete(TransferQueueResult.failure(this, error));
    }
    _progressController.close();
  }

  /// Marks the transfer as cancelled.
  void markCancelled() {
    status = QueuedTransferStatus.cancelled;
    cancellationToken.cancel('User cancelled');
    if (!_completer.isCompleted) {
      _completer.complete(TransferQueueResult.cancelled(this));
    }
    _progressController.close();
  }

  /// Disposes resources.
  void dispose() {
    cancellationToken.dispose();
    if (!_progressController.isClosed) {
      _progressController.close();
    }
  }
}

/// Result of a queued transfer.
class TransferQueueResult<T> {
  final QueuedTransfer<T> transfer;
  final bool isSuccess;
  final bool isCancelled;
  final String? error;

  const TransferQueueResult._({
    required this.transfer,
    required this.isSuccess,
    required this.isCancelled,
    this.error,
  });

  factory TransferQueueResult.success(QueuedTransfer<T> transfer) {
    return TransferQueueResult._(
      transfer: transfer,
      isSuccess: true,
      isCancelled: false,
    );
  }

  factory TransferQueueResult.failure(QueuedTransfer<T> transfer, String error) {
    return TransferQueueResult._(
      transfer: transfer,
      isSuccess: false,
      isCancelled: false,
      error: error,
    );
  }

  factory TransferQueueResult.cancelled(QueuedTransfer<T> transfer) {
    return TransferQueueResult._(
      transfer: transfer,
      isSuccess: false,
      isCancelled: true,
    );
  }
}

/// Callback type for executing a transfer.
typedef TransferExecutor<T> = Stream<TransferProgress> Function(
  QueuedTransfer<T> transfer,
);

/// Manages a queue of file transfers with configurable concurrency.
///
/// Example:
/// ```dart
/// final queue = TransferQueueManager<DownloadTask>(
///   maxConcurrent: 3,
///   executor: (transfer) async* {
///     yield* downloadFile(transfer.task);
///   },
/// );
///
/// // Add transfers
/// final result1 = queue.add(task1);
/// final result2 = queue.add(task2, priority: TransferPriority.high);
///
/// // Wait for completion
/// await result1.future;
/// ```
class TransferQueueManager<T> {
  /// Maximum number of concurrent transfers.
  int _maxConcurrent;

  /// The executor function for transfers.
  final TransferExecutor<T> _executor;

  /// Queue of pending transfers (sorted by priority and time).
  final Queue<QueuedTransfer<T>> _pendingQueue = Queue();

  /// Currently running transfers.
  final Map<String, QueuedTransfer<T>> _runningTransfers = {};

  /// All transfers (for lookup).
  final Map<String, QueuedTransfer<T>> _allTransfers = {};

  /// Stream controller for queue state changes.
  final _stateController = StreamController<TransferQueueState<T>>.broadcast();

  /// Whether the queue is paused.
  bool _isPaused = false;

  /// Whether the queue is disposed.
  bool _isDisposed = false;

  /// Auto-start transfers when added.
  final bool autoStart;

  /// Retry failed transfers automatically.
  final bool autoRetry;

  /// Maximum retry attempts.
  final int maxRetries;

  /// Retry counts per transfer.
  final Map<String, int> _retryCounts = {};

  TransferQueueManager({
    int maxConcurrent = 3,
    required TransferExecutor<T> executor,
    this.autoStart = true,
    this.autoRetry = false,
    this.maxRetries = 3,
  })  : _maxConcurrent = maxConcurrent,
        _executor = executor {
    assert(maxConcurrent > 0, 'maxConcurrent must be greater than 0');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum concurrent transfers.
  int get maxConcurrent => _maxConcurrent;

  /// Sets maximum concurrent transfers.
  set maxConcurrent(int value) {
    assert(value > 0, 'maxConcurrent must be greater than 0');
    _maxConcurrent = value;
    _processQueue();
  }

  /// Number of transfers currently running.
  int get runningCount => _runningTransfers.length;

  /// Number of transfers waiting in queue.
  int get pendingCount => _pendingQueue.length;

  /// Total number of transfers (running + pending).
  int get totalCount => _allTransfers.length;

  /// Whether the queue is paused.
  bool get isPaused => _isPaused;

  /// Whether there are available slots for more transfers.
  bool get hasAvailableSlots => runningCount < _maxConcurrent;

  /// Stream of queue state changes.
  Stream<TransferQueueState<T>> get stateStream => _stateController.stream;

  /// Current queue state.
  TransferQueueState<T> get state => TransferQueueState<T>(
        runningCount: runningCount,
        pendingCount: pendingCount,
        maxConcurrent: _maxConcurrent,
        isPaused: _isPaused,
        runningTransfers: List.unmodifiable(_runningTransfers.values.toList()),
        pendingTransfers: List.unmodifiable(_pendingQueue.toList()),
      );

  /// Gets a transfer by ID.
  QueuedTransfer<T>? getTransfer(String id) => _allTransfers[id];

  /// Gets all running transfers.
  List<QueuedTransfer<T>> get runningTransfers =>
      List.unmodifiable(_runningTransfers.values.toList());

  /// Gets all pending transfers.
  List<QueuedTransfer<T>> get pendingTransfers =>
      List.unmodifiable(_pendingQueue.toList());

  /// Gets all transfers (for iteration).
  Iterable<QueuedTransfer<T>> get allTransfers => _allTransfers.values;

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adds a transfer to the queue.
  ///
  /// Returns a [QueuedTransfer] that can be used to track progress and await completion.
  QueuedTransfer<T> add(
    T task, {
    String? id,
    TransferPriority priority = TransferPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    if (_isDisposed) {
      throw StateError('TransferQueueManager has been disposed');
    }

    final transferId = id ?? _generateId();

    // Check for duplicate
    if (_allTransfers.containsKey(transferId)) {
      return _allTransfers[transferId]!;
    }

    final transfer = QueuedTransfer<T>(
      id: transferId,
      task: task,
      priority: priority,
      metadata: metadata,
    );

    _allTransfers[transferId] = transfer;
    _insertIntoQueue(transfer);
    _updateQueuePositions();
    _emitState();

    if (autoStart && !_isPaused) {
      _processQueue();
    }

    return transfer;
  }

  /// Adds multiple transfers to the queue.
  List<QueuedTransfer<T>> addAll(
    List<T> tasks, {
    TransferPriority priority = TransferPriority.normal,
  }) {
    return tasks.map((task) => add(task, priority: priority)).toList();
  }

  /// Inserts a transfer into the queue based on priority.
  void _insertIntoQueue(QueuedTransfer<T> transfer) {
    // Find the correct position based on priority
    final newList = _pendingQueue.toList();
    int insertIndex = newList.length;

    for (int i = 0; i < newList.length; i++) {
      if (transfer.priority.value > newList[i].priority.value) {
        insertIndex = i;
        break;
      }
    }

    // Rebuild queue with new transfer
    _pendingQueue.clear();
    for (int i = 0; i < insertIndex; i++) {
      _pendingQueue.add(newList[i]);
    }
    _pendingQueue.add(transfer);
    for (int i = insertIndex; i < newList.length; i++) {
      _pendingQueue.add(newList[i]);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Starts processing the queue.
  void start() {
    if (_isDisposed) return;
    _isPaused = false;
    _processQueue();
    _emitState();
  }

  /// Pauses the queue (running transfers continue, but no new ones start).
  void pause() {
    _isPaused = true;
    _emitState();
  }

  /// Pauses all running transfers.
  void pauseAll() {
    _isPaused = true;
    for (final transfer in _runningTransfers.values) {
      transfer.status = QueuedTransferStatus.paused;
    }
    _emitState();
  }

  /// Resumes all paused transfers.
  void resumeAll() {
    _isPaused = false;
    for (final transfer in _runningTransfers.values) {
      if (transfer.status == QueuedTransferStatus.paused) {
        transfer.status = QueuedTransferStatus.running;
      }
    }
    _processQueue();
    _emitState();
  }

  /// Cancels a specific transfer.
  bool cancel(String id) {
    final transfer = _allTransfers[id];
    if (transfer == null) return false;

    if (transfer.isQueued) {
      _pendingQueue.remove(transfer);
    } else if (transfer.isRunning) {
      _runningTransfers.remove(id);
    }

    transfer.markCancelled();
    _updateQueuePositions();
    _processQueue();
    _emitState();

    return true;
  }

  /// Cancels all transfers.
  void cancelAll() {
    // Cancel pending
    while (_pendingQueue.isNotEmpty) {
      final transfer = _pendingQueue.removeFirst();
      transfer.markCancelled();
    }

    // Cancel running
    for (final transfer in _runningTransfers.values.toList()) {
      transfer.markCancelled();
    }
    _runningTransfers.clear();

    _emitState();
  }

  /// Removes a completed/cancelled/failed transfer from tracking.
  bool remove(String id) {
    final transfer = _allTransfers.remove(id);
    if (transfer == null) return false;

    _pendingQueue.remove(transfer);
    _runningTransfers.remove(id);
    transfer.dispose();
    _updateQueuePositions();
    _emitState();

    return true;
  }

  /// Clears all finished transfers.
  void clearFinished() {
    final toRemove = _allTransfers.values
        .where((t) => t.isFinished)
        .map((t) => t.id)
        .toList();

    for (final id in toRemove) {
      remove(id);
    }
  }

  /// Retries a failed transfer.
  bool retry(String id) {
    final transfer = _allTransfers[id];
    if (transfer == null || transfer.status != QueuedTransferStatus.failed) {
      return false;
    }

    // Reset transfer state
    transfer.status = QueuedTransferStatus.queued;
    transfer.progress = 0.0;
    transfer.errorMessage = null;

    _insertIntoQueue(transfer);
    _updateQueuePositions();
    _processQueue();
    _emitState();

    return true;
  }

  /// Changes the priority of a queued transfer.
  bool changePriority(String id, TransferPriority newPriority) {
    final transfer = _allTransfers[id];
    if (transfer == null || !transfer.isQueued) {
      return false;
    }

    _pendingQueue.remove(transfer);

    // Create new transfer with updated priority
    final updatedTransfer = QueuedTransfer<T>(
      id: transfer.id,
      task: transfer.task,
      priority: newPriority,
      addedAt: transfer.addedAt,
      metadata: transfer.metadata,
    );

    _allTransfers[id] = updatedTransfer;
    _insertIntoQueue(updatedTransfer);
    _updateQueuePositions();
    _emitState();

    return true;
  }

  /// Moves a transfer to the front of the queue.
  bool moveToFront(String id) {
    return changePriority(id, TransferPriority.urgent);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUEUE PROCESSING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Processes the queue, starting new transfers if slots are available.
  void _processQueue() {
    if (_isDisposed || _isPaused) return;

    while (hasAvailableSlots && _pendingQueue.isNotEmpty) {
      final transfer = _pendingQueue.removeFirst();
      _startTransfer(transfer);
    }

    _updateQueuePositions();
  }

  /// Starts a transfer.
  void _startTransfer(QueuedTransfer<T> transfer) {
    transfer.markRunning();
    _runningTransfers[transfer.id] = transfer;
    _emitState();

    // Execute the transfer
    _executeTransfer(transfer);
  }

  /// Executes a transfer using the executor.
  Future<void> _executeTransfer(QueuedTransfer<T> transfer) async {
    try {
      final stream = _executor(transfer);

      await for (final progress in stream) {
        if (transfer.cancellationToken.isCancelled) {
          break;
        }

        transfer.updateProgress(progress);

        if (progress.isCompleted) {
          _onTransferComplete(transfer);
          return;
        }

        if (progress.isFailed) {
          _onTransferFailed(transfer, progress.errorMessage ?? 'Unknown error');
          return;
        }

        if (progress.isCancelled) {
          _onTransferCancelled(transfer);
          return;
        }
      }

      // Stream ended normally - check final state
      if (transfer.progress >= 1.0) {
        _onTransferComplete(transfer);
      } else if (!transfer.cancellationToken.isCancelled) {
        _onTransferFailed(transfer, 'Transfer ended unexpectedly');
      }
    } catch (e) {
      _onTransferFailed(transfer, e.toString());
    }
  }

  void _onTransferComplete(QueuedTransfer<T> transfer) {
    _runningTransfers.remove(transfer.id);
    transfer.markCompleted();
    _retryCounts.remove(transfer.id);
    _processQueue();
    _emitState();

    debugPrint('TransferQueue: Completed ${transfer.id}');
  }

  void _onTransferFailed(QueuedTransfer<T> transfer, String error) {
    _runningTransfers.remove(transfer.id);

    // Check for auto-retry
    if (autoRetry) {
      final retryCount = _retryCounts[transfer.id] ?? 0;
      if (retryCount < maxRetries) {
        _retryCounts[transfer.id] = retryCount + 1;
        debugPrint('TransferQueue: Retrying ${transfer.id} (attempt ${retryCount + 1})');

        transfer.status = QueuedTransferStatus.queued;
        transfer.progress = 0.0;
        _insertIntoQueue(transfer);
        _processQueue();
        _emitState();
        return;
      }
    }

    transfer.markFailed(error);
    _processQueue();
    _emitState();

    debugPrint('TransferQueue: Failed ${transfer.id} - $error');
  }

  void _onTransferCancelled(QueuedTransfer<T> transfer) {
    _runningTransfers.remove(transfer.id);
    transfer.markCancelled();
    _processQueue();
    _emitState();

    debugPrint('TransferQueue: Cancelled ${transfer.id}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  void _updateQueuePositions() {
    int position = _runningTransfers.length;
    for (final transfer in _pendingQueue) {
      transfer.queuePosition = position++;
    }
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  String _generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_allTransfers.length}';
  }

  /// Disposes the queue manager.
  void dispose() {
    _isDisposed = true;
    cancelAll();

    for (final transfer in _allTransfers.values) {
      transfer.dispose();
    }
    _allTransfers.clear();

    _stateController.close();
  }
}

/// State of the transfer queue.
class TransferQueueState<T> {
  /// Number of currently running transfers.
  final int runningCount;

  /// Number of pending transfers.
  final int pendingCount;

  /// Maximum concurrent transfers.
  final int maxConcurrent;

  /// Whether the queue is paused.
  final bool isPaused;

  /// List of running transfers.
  final List<QueuedTransfer<T>> runningTransfers;

  /// List of pending transfers.
  final List<QueuedTransfer<T>> pendingTransfers;

  const TransferQueueState({
    required this.runningCount,
    required this.pendingCount,
    required this.maxConcurrent,
    required this.isPaused,
    required this.runningTransfers,
    required this.pendingTransfers,
  });

  /// Total number of transfers.
  int get totalCount => runningCount + pendingCount;

  /// Whether there are any transfers.
  bool get isEmpty => totalCount == 0;

  /// Whether all slots are in use.
  bool get isFull => runningCount >= maxConcurrent;

  /// Available slots for new transfers.
  int get availableSlots => maxConcurrent - runningCount;

  /// Overall progress (0.0 to 1.0).
  double get overallProgress {
    if (totalCount == 0) return 0.0;

    double total = 0.0;
    for (final t in runningTransfers) {
      total += t.progress;
    }
    // Pending transfers have 0 progress
    return total / totalCount;
  }

  @override
  String toString() {
    return 'TransferQueueState(running: $runningCount/$maxConcurrent, pending: $pendingCount, paused: $isPaused)';
  }
}
