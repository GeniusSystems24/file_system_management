import 'dart:io';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates shared storage and resume failed functionality.
///
/// Move files to Downloads folder and resume interrupted transfers.
class SharedStorageScreen extends StatefulWidget {
  const SharedStorageScreen({super.key});

  @override
  State<SharedStorageScreen> createState() => _SharedStorageScreenState();
}

class _SharedStorageScreenState extends State<SharedStorageScreen> {
  final TransferController _controller = TransferController.instance;

  List<TransferEntity> _completedTransfers = [];
  List<TransferEntity> _failedTransfers = [];
  bool _isLoading = true;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 30) _logs.removeLast();
    });
  }

  Future<void> _loadTransfers() async {
    setState(() => _isLoading = true);

    final result = await _controller.getAllTransfers();
    final transfers = result.valueOrNull ?? [];

    setState(() {
      _completedTransfers = transfers.where((t) => t.isComplete).toList();
      _failedTransfers = transfers.where((t) => t.isFailed).toList();
      _isLoading = false;
    });
  }

  Future<void> _moveToSharedStorage(TransferEntity transfer) async {
    _log('Moving ${transfer.fileName} to shared storage...');

    final result = await _controller.moveToSharedStorage(transfer.id);

    result.fold(
      onSuccess: (newPath) {
        _log('Moved to: $newPath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved to Downloads: ${transfer.fileName}')),
        );
      },
      onFailure: (failure) {
        _log('Failed: ${failure.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move: ${failure.message}')),
        );
      },
    );
  }

  Future<void> _resumeFailed(TransferEntity transfer) async {
    _log('Resuming failed download: ${transfer.fileName}...');

    final result = await _controller.retry(transfer.id);
    final stream = result.valueOrNull;

    if (stream != null) {
      stream.listen(
        (entity) {
          if (entity.isComplete) {
            _log('Download completed!');
            _loadTransfers();
          }
        },
        onError: (e) => _log('Error: $e'),
      );
    } else {
      _log('Failed to resume');
    }
  }

  Future<void> _rescheduleMissing() async {
    _log('Rescheduling missing tasks...');

    final result = await _controller.rescheduleMissing();

    result.fold(
      onSuccess: (data) {
        final (succeeded, failed) = data;
        _log('Rescheduled: ${succeeded.length} succeeded, ${failed.length} failed');
        _loadTransfers();
      },
      onFailure: (failure) {
        _log('Failed: ${failure.message}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Storage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransfers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                _buildInfoCard(theme),
                const SizedBox(height: 16),

                // Move to Shared Storage Section
                _buildSharedStorageSection(theme),
                const SizedBox(height: 16),

                // Resume Failed Section
                _buildResumeFailedSection(theme),
                const SizedBox(height: 16),

                // Reschedule Missing
                _buildRescheduleCard(theme),
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
                Icon(Icons.folder_shared, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Storage Management',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Move completed downloads to shared storage (Downloads folder) '
              'for easy access. Resume failed downloads from where they stopped.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildChip('Move to Downloads', Icons.folder),
                _buildChip('Resume Failed', Icons.replay),
                _buildChip('Reschedule', Icons.schedule),
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

  Widget _buildSharedStorageSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Move to Shared Storage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Move completed files to the public Downloads folder.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            if (_completedTransfers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No completed downloads',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._completedTransfers.map((t) => _buildTransferTile(
                t,
                trailing: IconButton(
                  icon: const Icon(Icons.drive_file_move),
                  onPressed: () => _moveToSharedStorage(t),
                  tooltip: 'Move to Downloads',
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeFailedSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.replay, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Resume Failed Downloads',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Continue downloads from where they failed.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            if (_failedTransfers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No failed downloads',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._failedTransfers.map((t) => _buildTransferTile(
                t,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(t.progress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.orange),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: () => _resumeFailed(t),
                      tooltip: 'Resume',
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferTile(TransferEntity transfer, {Widget? trailing}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getStatusColor(transfer).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getStatusIcon(transfer),
          color: _getStatusColor(transfer),
        ),
      ),
      title: Text(
        transfer.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_formatBytes(transfer.expectedSize)),
      trailing: trailing,
    );
  }

  Widget _buildRescheduleCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Reschedule Missing Tasks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reschedule downloads that were interrupted by app crash or force close.',
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _rescheduleMissing,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reschedule Missing'),
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

  Color _getStatusColor(TransferEntity transfer) {
    if (transfer.isComplete) return Colors.green;
    if (transfer.isFailed) return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon(TransferEntity transfer) {
    if (transfer.isComplete) return Icons.check_circle;
    if (transfer.isFailed) return Icons.error;
    return Icons.hourglass_empty;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
