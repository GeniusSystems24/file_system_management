import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import '../../shared/constants/sample_files.dart';

/// Demonstrates background and foreground download modes.
///
/// Background downloads continue when the app is minimized.
/// Foreground mode shows a persistent notification on Android.
class BackgroundDownloadsScreen extends StatefulWidget {
  const BackgroundDownloadsScreen({super.key});

  @override
  State<BackgroundDownloadsScreen> createState() =>
      _BackgroundDownloadsScreenState();
}

class _BackgroundDownloadsScreenState extends State<BackgroundDownloadsScreen> {
  final TransferController _controller = TransferController.instance;

  bool _runInForeground = false;
  bool _isDownloading = false;
  TransferEntity? _currentTransfer;
  final List<String> _logs = [];

  final _selectedFile =
      SampleFiles.videos.length > 1
          ? SampleFiles.videos[1]
          : SampleFiles.videos.first;

  void _log(String message) {
    setState(() {
      _logs.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _currentTransfer = null;
    });

    _log(
      'Starting download in ${_runInForeground ? "foreground" : "background"} mode...',
    );

    try {
      final result = await _controller.download(
        url: _selectedFile.url,
        fileName: _selectedFile.fileName,
        config: TransferConfigEntity(
          metadata: {'group': 'background_demo', 'requiresWiFi': false},
        ),
      );

      final stream = result.valueOrNull;
      if (stream != null) {
        await for (final entity in stream) {
          setState(() => _currentTransfer = entity);

          if (entity.isComplete) {
            _log('Download completed!');
          } else if (entity.isFailed) {
            _log('Download failed: ${entity.errorMessage}');
          }
        }
      } else {
        _log('Failed to start download');
      }
    } catch (e) {
      _log('Error: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Background Downloads')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Cards
          _buildBackgroundInfoCard(theme),
          const SizedBox(height: 12),
          _buildForegroundInfoCard(theme),
          const SizedBox(height: 16),

          // Mode Selection
          _buildModeCard(theme),
          const SizedBox(height: 16),

          // Progress
          _buildProgressCard(theme),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(theme),
          const SizedBox(height: 16),

          // Test Instructions
          _buildTestInstructionsCard(theme),
          const SizedBox(height: 16),

          // Logs
          _buildLogsCard(theme),
        ],
      ),
    );
  }

  Widget _buildBackgroundInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cloud_download,
                color: Colors.blue,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Background Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloads continue when app is minimized. '
                    'Works silently without notifications.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForegroundInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.teal,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Foreground Mode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Android',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shows persistent notification with progress. '
                    'Prevents system from killing the process.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Background mode
            RadioListTile<bool>(
              value: false,
              groupValue: _runInForeground,
              onChanged:
                  _isDownloading
                      ? null
                      : (value) {
                        setState(() => _runInForeground = value!);
                      },
              title: const Text('Background Mode'),
              subtitle: const Text('Silent downloads, continues in background'),
              secondary: const Icon(Icons.cloud_download),
            ),

            // Foreground mode
            RadioListTile<bool>(
              value: true,
              groupValue: _runInForeground,
              onChanged:
                  _isDownloading
                      ? null
                      : (value) {
                        setState(() => _runInForeground = value!);
                      },
              title: const Text('Foreground Mode'),
              subtitle: const Text('Shows notification, prevents process kill'),
              secondary: const Icon(Icons.notifications_active),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    final transfer = _currentTransfer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Download Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isDownloading)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // File info
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam, color: Colors.purple),
              ),
              title: Text(_selectedFile.name),
              subtitle: Text(_selectedFile.formattedSize),
            ),

            if (transfer != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: transfer.progress,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(transfer.progress * 100).toStringAsFixed(1)}%'),
                  Text(_formatSpeed(transfer.speed)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: _isDownloading ? null : _startDownload,
      icon:
          _isDownloading
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(
                _runInForeground
                    ? Icons.notifications_active
                    : Icons.cloud_download,
              ),
      label: Text(
        _isDownloading
            ? 'Downloading...'
            : 'Start ${_runInForeground ? "Foreground" : "Background"} Download',
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildTestInstructionsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Test Instructions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '1. Start a download\n'
              '2. Minimize the app (press Home button)\n'
              '3. Wait a few seconds\n'
              '4. Return to the app\n'
              '5. Observe that download continued',
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
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

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024)
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    if (bytesPerSecond < 1024 * 1024)
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }
}
