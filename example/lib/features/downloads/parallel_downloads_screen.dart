import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import '../../shared/constants/sample_files.dart';

/// Demonstrates parallel download functionality.
///
/// Parallel downloads split large files into chunks and download
/// them simultaneously for faster speeds.
class ParallelDownloadsScreen extends StatefulWidget {
  const ParallelDownloadsScreen({super.key});

  @override
  State<ParallelDownloadsScreen> createState() => _ParallelDownloadsScreenState();
}

class _ParallelDownloadsScreenState extends State<ParallelDownloadsScreen> {
  final TransferController _controller = TransferController.instance;

  int _chunks = 4;
  bool _isDownloading = false;
  TransferEntity? _currentTransfer;
  final List<String> _logs = [];

  final _selectedFile = SampleFiles.largeFiles.isNotEmpty
      ? SampleFiles.largeFiles.first
      : SampleFiles.videos.last;

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _startParallelDownload() async {
    setState(() {
      _isDownloading = true;
      _currentTransfer = null;
    });

    _log('Starting parallel download with $_chunks chunks...');
    _log('URL: ${_selectedFile.url}');

    try {
      final result = await _controller.downloadParallel(
        url: _selectedFile.url,
        chunks: _chunks,
        fileName: _selectedFile.fileName,
      );

      final stream = result.valueOrNull;
      if (stream != null) {
        await for (final entity in stream) {
          setState(() => _currentTransfer = entity);

          if (entity.isComplete) {
            _log('Download completed successfully!');
            _log('File saved to: ${entity.filePath}');
          } else if (entity.isFailed) {
            _log('Download failed: ${entity.errorMessage}');
          }
        }
      } else {
        _log('Failed to start download: ${result.failureOrNull?.message}');
      }
    } catch (e) {
      _log('Error: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _cancelDownload() async {
    if (_currentTransfer != null) {
      await _controller.cancel(_currentTransfer!.id);
      _log('Download cancelled');
      setState(() {
        _isDownloading = false;
        _currentTransfer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parallel Downloads'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          _buildInfoCard(theme),
          const SizedBox(height: 16),

          // Configuration Card
          _buildConfigCard(theme),
          const SizedBox(height: 16),

          // Progress Card
          _buildProgressCard(theme),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(theme),
          const SizedBox(height: 16),

          // Logs Card
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
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'How Parallel Downloads Work',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Parallel downloads split a large file into multiple chunks and '
              'download them simultaneously using multiple HTTP connections. '
              'This can significantly speed up downloads, especially for large files.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('Multiple Connections', Icons.cable),
                _buildFeatureChip('Resume Support', Icons.replay),
                _buildFeatureChip('Mirror URLs', Icons.copy_all),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildConfigCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

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
              subtitle: Text('${_selectedFile.formattedSize} • ${_selectedFile.extension.toUpperCase()}'),
            ),

            const Divider(),

            // Chunks slider
            Row(
              children: [
                const Text('Chunks: '),
                Expanded(
                  child: Slider(
                    value: _chunks.toDouble(),
                    min: 2,
                    max: 8,
                    divisions: 6,
                    label: '$_chunks',
                    onChanged: _isDownloading ? null : (value) {
                      setState(() => _chunks = value.toInt());
                    },
                  ),
                ),
                Text(
                  '$_chunks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            Text(
              'More chunks = faster download (if server supports range requests)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
            Text(
              'Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (transfer == null)
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
                      'Ready to download',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: transfer.progress,
                  minHeight: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat('Progress', '${(transfer.progress * 100).toStringAsFixed(1)}%'),
                  _buildStat('Speed', _formatSpeed(transfer.speed)),
                  _buildStat('ETA', _formatDuration(transfer.timeRemaining)),
                ],
              ),
              const SizedBox(height: 12),

              // Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transfer).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(transfer),
                          size: 14,
                          color: _getStatusColor(transfer),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(transfer),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(transfer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatBytes(transfer.transferredBytes)} / ${_formatBytes(transfer.expectedSize)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isDownloading ? null : _startParallelDownload,
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Start Parallel Download'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_isDownloading) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _cancelDownload,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
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
                  'Logs',
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
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _logs.isEmpty ? 'No logs yet' : _logs.join('\n'),
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

  Color _getStatusColor(TransferEntity transfer) {
    if (transfer.isComplete) return Colors.green;
    if (transfer.isFailed) return Colors.red;
    if (transfer.isPaused) return Colors.amber;
    return Colors.blue;
  }

  IconData _getStatusIcon(TransferEntity transfer) {
    if (transfer.isComplete) return Icons.check_circle;
    if (transfer.isFailed) return Icons.error;
    if (transfer.isPaused) return Icons.pause_circle;
    return Icons.downloading;
  }

  String _getStatusLabel(TransferEntity transfer) {
    if (transfer.isComplete) return 'Completed';
    if (transfer.isFailed) return 'Failed';
    if (transfer.isPaused) return 'Paused';
    return 'Downloading';
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
}
