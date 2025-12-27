import 'dart:math';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing queue management functionality.
class QueueDemoScreen extends StatefulWidget {
  const QueueDemoScreen({super.key});

  @override
  State<QueueDemoScreen> createState() => _QueueDemoScreenState();
}

class _QueueDemoScreenState extends State<QueueDemoScreen> {
  late TransferQueueManager<MockDownloadTask> _queue;
  final _random = Random();

  int _maxConcurrent = 3;
  TransferQueueState<MockDownloadTask>? _state;

  @override
  void initState() {
    super.initState();
    _initQueue();
  }

  void _initQueue() {
    _queue = TransferQueueManager<MockDownloadTask>(
      maxConcurrent: _maxConcurrent,
      autoRetry: true,
      maxRetries: 2,
      executor: _mockExecutor,
    );

    _queue.stateStream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
      }
    });
  }

  /// Mock executor that simulates file downloads.
  Stream<TransferProgress> _mockExecutor(
    QueuedTransfer<MockDownloadTask> transfer,
  ) async* {
    final task = transfer.task;
    final steps = 20;
    final stepDuration = Duration(
      milliseconds: task.duration.inMilliseconds ~/ steps,
    );

    for (int i = 1; i <= steps; i++) {
      // Check cancellation
      if (transfer.cancellationToken.isCancelled) {
        yield TransferProgress(
          bytesTransferred: (task.size * (i - 1) / steps).round(),
          totalBytes: task.size,
          status: TransferStatus.cancelled,
        );
        return;
      }

      await Future.delayed(stepDuration);

      // Simulate random failure (10% chance after 50%)
      if (_random.nextDouble() < 0.1 && i > steps ~/ 2) {
        yield TransferProgress.failed(
          bytesTransferred: (task.size * i / steps).round(),
          totalBytes: task.size,
          errorMessage: 'خطأ في الشبكة',
        );
        return;
      }

      yield TransferProgress(
        bytesTransferred: (task.size * i / steps).round(),
        totalBytes: task.size,
        bytesPerSecond: task.size / task.duration.inSeconds,
        status: i == steps ? TransferStatus.completed : TransferStatus.running,
      );
    }
  }

  void _addDownloads(int count, {TransferPriority priority = TransferPriority.normal}) {
    for (int i = 0; i < count; i++) {
      final task = MockDownloadTask(
        name: 'ملف_${DateTime.now().millisecondsSinceEpoch}_$i.pdf',
        size: (_random.nextInt(50) + 10) * 1024 * 1024, // 10-60 MB
        duration: Duration(seconds: _random.nextInt(8) + 3), // 3-10 seconds
      );

      _queue.add(task, priority: priority);
    }
  }

  void _addUrgentDownload() {
    final task = MockDownloadTask(
      name: 'عاجل_${DateTime.now().millisecondsSinceEpoch}.pdf',
      size: 5 * 1024 * 1024, // 5 MB
      duration: const Duration(seconds: 2),
    );

    _queue.add(task, priority: TransferPriority.urgent);
  }

  @override
  void dispose() {
    _queue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطابور'),
        actions: [
          IconButton(
            icon: Icon(_queue.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              if (_queue.isPaused) {
                _queue.start();
              } else {
                _queue.pause();
              }
            },
            tooltip: _queue.isPaused ? 'استمرار' : 'إيقاف مؤقت',
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: _queue.totalCount > 0 ? _queue.cancelAll : null,
            tooltip: 'إلغاء الكل',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _queue.clearFinished,
            tooltip: 'مسح المكتمل',
          ),
        ],
      ),
      body: Column(
        children: [
          // Queue stats
          _buildStatsCard(),

          // Concurrent control
          _buildConcurrentControl(),

          // Divider
          const Divider(height: 1),

          // Transfers list
          Expanded(
            child: _buildTransfersList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'urgent',
            onPressed: _addUrgentDownload,
            backgroundColor: Colors.red,
            child: const Icon(Icons.priority_high),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'add5',
            onPressed: () => _addDownloads(5),
            child: const Text('+5'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add10',
            onPressed: () => _addDownloads(10),
            child: const Text('+10'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final state = _state;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'قيد التنفيذ',
                  '${state?.runningCount ?? 0}',
                  Colors.blue,
                ),
                _buildStatItem(
                  'في الانتظار',
                  '${state?.pendingCount ?? 0}',
                  Colors.orange,
                ),
                _buildStatItem(
                  'الحد الأقصى',
                  '$_maxConcurrent',
                  Colors.green,
                ),
              ],
            ),
            if (state != null && state.totalCount > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: state.overallProgress,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Text(
                'التقدم الكلي: ${(state.overallProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildConcurrentControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('الحد الأقصى للتزامن:'),
          Expanded(
            child: Slider(
              value: _maxConcurrent.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_maxConcurrent',
              onChanged: (value) {
                setState(() {
                  _maxConcurrent = value.round();
                  _queue.maxConcurrent = _maxConcurrent;
                });
              },
            ),
          ),
          Text('$_maxConcurrent'),
        ],
      ),
    );
  }

  Widget _buildTransfersList() {
    final state = _state;
    if (state == null || state.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد تنزيلات',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على + لإضافة تنزيلات',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final allTransfers = [
      ...state.runningTransfers,
      ...state.pendingTransfers,
    ];

    return ListView.builder(
      itemCount: allTransfers.length,
      itemBuilder: (context, index) {
        final transfer = allTransfers[index];
        return _buildTransferTile(transfer);
      },
    );
  }

  Widget _buildTransferTile(QueuedTransfer<MockDownloadTask> transfer) {
    final task = transfer.task;
    final isRunning = transfer.isRunning;
    final isQueued = transfer.isQueued;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (transfer.status) {
      case QueuedTransferStatus.running:
        statusColor = Colors.blue;
        statusText = 'جاري التنزيل';
        statusIcon = Icons.download;
      case QueuedTransferStatus.queued:
        statusColor = Colors.orange;
        statusText = 'في الانتظار (${transfer.queuePosition})';
        statusIcon = Icons.hourglass_empty;
      case QueuedTransferStatus.completed:
        statusColor = Colors.green;
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle;
      case QueuedTransferStatus.failed:
        statusColor = Colors.red;
        statusText = 'فشل';
        statusIcon = Icons.error;
      case QueuedTransferStatus.cancelled:
        statusColor = Colors.grey;
        statusText = 'ملغي';
        statusIcon = Icons.cancel;
      case QueuedTransferStatus.paused:
        statusColor = Colors.amber;
        statusText = 'متوقف';
        statusIcon = Icons.pause_circle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: isRunning ? transfer.progress : (isQueued ? 0 : 1),
              strokeWidth: 3,
              backgroundColor: Colors.grey[200],
              color: statusColor,
            ),
            Icon(statusIcon, size: 20, color: statusColor),
          ],
        ),
        title: Text(
          task.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatBytes(task.size)} • $statusText',
              style: TextStyle(color: statusColor),
            ),
            if (isRunning)
              LinearProgressIndicator(
                value: transfer.progress,
                backgroundColor: Colors.grey[200],
              ),
            if (transfer.errorMessage != null)
              Text(
                transfer.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isQueued) ...[
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: () => _queue.moveToFront(transfer.id),
                tooltip: 'نقل للمقدمة',
                iconSize: 20,
              ),
            ],
            if (transfer.status == QueuedTransferStatus.failed) ...[
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _queue.retry(transfer.id),
                tooltip: 'إعادة المحاولة',
                iconSize: 20,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _queue.cancel(transfer.id),
              tooltip: 'إلغاء',
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}

/// Mock download task for demonstration.
class MockDownloadTask {
  final String name;
  final int size;
  final Duration duration;

  const MockDownloadTask({
    required this.name,
    required this.size,
    required this.duration,
  });
}
