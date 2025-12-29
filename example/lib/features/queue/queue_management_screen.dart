import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import '../../shared/constants/sample_files.dart';

/// Demonstrates queue management functionality.
///
/// Queue management allows controlling concurrent transfers
/// with priority queuing and limits.
class QueueManagementScreen extends StatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  final TransferController _controller = TransferController.instance;

  List<TransferEntity> _transfers = [];
  int _maxConcurrent = 3;

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  Future<void> _loadTransfers() async {
    final result = await _controller.getAllTransfers();
    setState(() => _transfers = result.valueOrNull ?? []);
  }

  Future<void> _addToQueue(SampleFile file, int priority) async {
    final result = await _controller.download(
      url: file.url,
      fileName: file.fileName,
      config: TransferConfigEntity(
        group: 'queue_demo',
        priority: priority,
      ),
    );

    final stream = result.valueOrNull;
    if (stream != null) {
      stream.listen((_) => _loadTransfers());
    }
    await _loadTransfers();
  }

  Future<void> _pauseAll() async {
    for (final transfer in _transfers.where((t) => t.isRunning)) {
      await _controller.pause(transfer.id);
    }
    await _loadTransfers();
  }

  Future<void> _resumeAll() async {
    for (final transfer in _transfers.where((t) => t.isPaused)) {
      await _controller.resume(transfer.id);
    }
    await _loadTransfers();
  }

  Future<void> _clearAll() async {
    await _controller.deleteAllTransfers();
    await _loadTransfers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pending = _transfers.where((t) => t.status == TransferStatusEntity.pending).length;
    final running = _transfers.where((t) => t.isRunning).length;
    final completed = _transfers.where((t) => t.isComplete).length;
    final failed = _transfers.where((t) => t.isFailed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransfers,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pause_all':
                  _pauseAll();
                  break;
                case 'resume_all':
                  _resumeAll();
                  break;
                case 'clear_all':
                  _clearAll();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pause_all', child: Text('Pause All')),
              const PopupMenuItem(value: 'resume_all', child: Text('Resume All')),
              const PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          _buildInfoCard(theme),
          const SizedBox(height: 16),

          // Stats Card
          _buildStatsCard(theme, pending, running, completed, failed),
          const SizedBox(height: 16),

          // Concurrency Control
          _buildConcurrencyCard(theme),
          const SizedBox(height: 16),

          // Add to Queue
          _buildAddToQueueCard(theme),
          const SizedBox(height: 16),

          // Queue List
          _buildQueueList(theme),
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
                  'Queue Management',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Control how many downloads run simultaneously. '
              'Higher priority items start first. '
              'Pause and resume individual or all downloads.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('Priority Queuing', Icons.low_priority),
                _buildFeatureChip('Concurrency Limit', Icons.tune),
                _buildFeatureChip('Pause/Resume', Icons.pause_circle),
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

  Widget _buildStatsCard(ThemeData theme, int pending, int running, int completed, int failed) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Pending', pending, Colors.grey, Icons.hourglass_empty),
            _buildStatItem('Running', running, Colors.blue, Icons.downloading),
            _buildStatItem('Completed', completed, Colors.green, Icons.check_circle),
            _buildStatItem('Failed', failed, Colors.red, Icons.error),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildConcurrencyCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Concurrency Limit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum simultaneous downloads',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Max: '),
                Expanded(
                  child: Slider(
                    value: _maxConcurrent.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_maxConcurrent',
                    onChanged: (value) {
                      setState(() => _maxConcurrent = value.toInt());
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_maxConcurrent',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToQueueCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Queue',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityButton('High Priority', 10, Colors.red),
                _buildPriorityButton('Normal', 5, Colors.blue),
                _buildPriorityButton('Low Priority', 1, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, int priority, Color color) {
    return ElevatedButton.icon(
      onPressed: () {
        final files = SampleFiles.all.where((f) {
          return !_transfers.any((t) => t.url == f.url);
        }).toList();

        if (files.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All files already in queue')),
          );
          return;
        }

        _showFileSelectionDialog(files, priority);
      },
      icon: Icon(Icons.add, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
      ),
    );
  }

  void _showFileSelectionDialog(List<SampleFile> files, int priority) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select File'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: Icon(_getTypeIcon(file.type)),
                title: Text(file.name),
                subtitle: Text(file.formattedSize),
                onTap: () {
                  Navigator.pop(context);
                  _addToQueue(file, priority);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(ThemeData theme) {
    if (_transfers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.queue,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Queue is empty',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add files to start downloading',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Queue (${_transfers.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ..._transfers.map((t) => _buildQueueItem(t, theme)),
        ],
      ),
    );
  }

  Widget _buildQueueItem(TransferEntity transfer, ThemeData theme) {
    return ListTile(
      leading: _buildStatusIndicator(transfer),
      title: Text(
        transfer.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transfer.isRunning) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: transfer.progress,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Text(
                '${(transfer.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(transfer.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'P${transfer.priority}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getPriorityColor(transfer.priority),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: _buildQueueItemActions(transfer),
    );
  }

  Widget _buildStatusIndicator(TransferEntity transfer) {
    if (transfer.isRunning) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: transfer.progress,
              strokeWidth: 3,
            ),
            Text(
              '${(transfer.progress * 100).toInt()}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }

    final (color, icon) = switch (transfer.status) {
      TransferStatusEntity.pending => (Colors.grey, Icons.hourglass_empty),
      TransferStatusEntity.paused => (Colors.amber, Icons.pause_circle),
      TransferStatusEntity.complete => (Colors.green, Icons.check_circle),
      TransferStatusEntity.failed => (Colors.red, Icons.error),
      TransferStatusEntity.canceled => (Colors.grey, Icons.cancel),
      _ => (Colors.grey, Icons.help),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildQueueItemActions(TransferEntity transfer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (transfer.isRunning)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () async {
              await _controller.pause(transfer.id);
              await _loadTransfers();
            },
          )
        else if (transfer.isPaused)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () async {
              await _controller.resume(transfer.id);
              await _loadTransfers();
            },
          ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await _controller.cancel(transfer.id);
            await _controller.deleteTransfer(transfer.id);
            await _loadTransfers();
          },
        ),
      ],
    );
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red;
    if (priority >= 5) return Colors.blue;
    return Colors.grey;
  }

  IconData _getTypeIcon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.videocam;
      case FileType.audio:
        return Icons.audiotrack;
      case FileType.document:
        return Icons.description;
      case FileType.archive:
        return Icons.folder_zip;
      case FileType.other:
        return Icons.insert_drive_file;
    }
  }
}
