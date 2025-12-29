import 'dart:async';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates custom handler implementations.
///
/// Shows how to inject your own upload/download providers
/// for Firebase, AWS, or custom backends.
class CustomHandlersScreen extends StatefulWidget {
  const CustomHandlersScreen({super.key});

  @override
  State<CustomHandlersScreen> createState() => _CustomHandlersScreenState();
}

class _CustomHandlersScreenState extends State<CustomHandlersScreen> {
  TransferProgress? _progress;
  TransferResult? _result;
  bool _isTransferring = false;
  String _selectedHandler = 'mock';
  final List<String> _logs = [];

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 30) _logs.removeLast();
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isTransferring = true;
      _progress = null;
      _result = null;
    });

    _log('Starting download with $_selectedHandler handler...');

    final handler = _getHandler();

    try {
      final stream = handler.download(
        const DownloadPayload(
          url: 'https://example.com/file.zip',
          fileName: 'demo_file.zip',
          expectedSize: 10 * 1024 * 1024,
        ),
      );

      await for (final progress in stream) {
        setState(() => _progress = progress);

        if (progress.isCompleted) {
          _log('Download completed!');
          setState(() {
            _result = TransferSuccess(
              localPath: '/path/to/file.zip',
              fileSize: progress.totalBytes,
            );
          });
        } else if (progress.isFailed) {
          _log('Download failed: ${progress.errorMessage}');
          setState(() {
            _result = TransferError(message: progress.errorMessage ?? 'Failed');
          });
        }
      }
    } catch (e) {
      _log('Error: $e');
    } finally {
      setState(() => _isTransferring = false);
    }
  }

  DownloadHandler _getHandler() {
    switch (_selectedHandler) {
      case 'firebase':
        return _FirebaseStyleHandler();
      case 'aws':
        return _AWSStyleHandler();
      default:
        return _MockHandler();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Handlers'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          _buildInfoCard(theme),
          const SizedBox(height: 16),

          // Handler Selection
          _buildHandlerSelection(theme),
          const SizedBox(height: 16),

          // Handler Info
          _buildHandlerInfo(theme),
          const SizedBox(height: 16),

          // Progress Card
          _buildProgressCard(theme),
          const SizedBox(height: 16),

          // Action Button
          ElevatedButton.icon(
            onPressed: _isTransferring ? null : _startDownload,
            icon: _isTransferring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isTransferring ? 'Transferring...' : 'Start Demo Transfer'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),

          // Interface Code
          _buildInterfaceCode(theme),
          const SizedBox(height: 16),

          // Logs
          _buildLogsCard(theme),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.extension, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Injectable Handlers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Implement your own download/upload logic using the Handler interfaces. '
              'Perfect for integrating with Firebase Storage, AWS S3, or custom backends.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('DownloadHandler', Icons.download),
                _buildChip('UploadHandler', Icons.upload),
                _buildChip('TransferHandler', Icons.swap_vert),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildHandlerSelection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Handler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Mock'),
                  selected: _selectedHandler == 'mock',
                  onSelected: (_) => setState(() => _selectedHandler = 'mock'),
                ),
                ChoiceChip(
                  label: const Text('Firebase-style'),
                  selected: _selectedHandler == 'firebase',
                  onSelected: (_) => setState(() => _selectedHandler = 'firebase'),
                ),
                ChoiceChip(
                  label: const Text('AWS-style'),
                  selected: _selectedHandler == 'aws',
                  onSelected: (_) => setState(() => _selectedHandler = 'aws'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandlerInfo(ThemeData theme) {
    final (icon, title, description) = switch (_selectedHandler) {
      'firebase' => (
        Icons.local_fire_department,
        'Firebase Storage Style',
        'Simulates Firebase Storage download with metadata and progress tracking.',
      ),
      'aws' => (
        Icons.cloud,
        'AWS S3 Style',
        'Simulates AWS S3 download with multipart support and pre-signed URLs.',
      ),
      _ => (
        Icons.code,
        'Mock Handler',
        'A simple mock handler that simulates download progress for testing.',
      ),
    };

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_progress == null && _result == null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to start',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else if (_progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress!.progress,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_progress!.progressText),
                  Text(_progress!.speedText),
                ],
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 16),
              _result!.when(
                success: (s) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text('Transfer completed successfully!'),
                    ],
                  ),
                ),
                error: (e) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text('Error: ${e.message}'),
                    ],
                  ),
                ),
                cancelled: (c) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Transfer cancelled'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInterfaceCode(ThemeData theme) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Handler Interface',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                '''
abstract class DownloadHandler {
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  });

  Future<TransferResult> downloadAndComplete(...);
  Future<bool> pause(String downloadId);
  Future<bool> resume(String downloadId);
  Future<bool> cancel(String downloadId);
}

// Implement your own:
class FirebaseDownloadHandler implements DownloadHandler {
  @override
  Stream<TransferProgress> download(...) async* {
    // Your Firebase logic here
  }
}
''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Log',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _logs.isEmpty ? 'No activity yet' : _logs.join('\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mock Handlers for demonstration
class _MockHandler implements DownloadHandler {
  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    final total = payload.expectedSize ?? 10 * 1024 * 1024;
    const steps = 20;

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      yield TransferProgress(
        bytesTransferred: (total * i / steps).round(),
        totalBytes: total,
        bytesPerSecond: total / 3,
        status: i == steps ? TransferStatus.completed : TransferStatus.running,
      );
    }
  }

  @override
  Future<TransferResult> downloadAndComplete(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    await for (final _ in download(payload)) {}
    return const TransferSuccess(localPath: '/path');
  }

  @override
  Future<String> getDownloadUrl(String fileId) async => fileId;

  @override
  Future<bool> pause(String downloadId) async => false;

  @override
  Future<bool> resume(String downloadId) async => false;

  @override
  Future<bool> cancel(String downloadId) async => false;

  @override
  Stream<TransferProgress> retryDownload(
    String downloadId,
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) => download(payload);
}

class _FirebaseStyleHandler extends _MockHandler {
  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    // Simulate Firebase metadata fetch
    await Future.delayed(const Duration(milliseconds: 300));

    await for (final progress in super.download(payload)) {
      yield progress;
    }
  }
}

class _AWSStyleHandler extends _MockHandler {
  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    // Simulate AWS pre-signed URL generation
    await Future.delayed(const Duration(milliseconds: 200));

    await for (final progress in super.download(payload)) {
      yield progress;
    }
  }
}
