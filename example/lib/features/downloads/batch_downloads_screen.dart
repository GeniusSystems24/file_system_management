import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import '../../shared/constants/sample_files.dart';

/// Demonstrates batch download functionality.
///
/// Batch downloads allow downloading multiple files efficiently
/// with overall progress tracking.
class BatchDownloadsScreen extends StatefulWidget {
  const BatchDownloadsScreen({super.key});

  @override
  State<BatchDownloadsScreen> createState() => _BatchDownloadsScreenState();
}

class _BatchDownloadsScreenState extends State<BatchDownloadsScreen> {
  final TransferController _controller = TransferController.instance;

  final Map<String, TransferEntity?> _transfers = {};
  final Set<String> _selectedUrls = {};
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingTransfers();
  }

  Future<void> _loadExistingTransfers() async {
    final result = await _controller.getAllTransfers();
    final transfers = result.valueOrNull ?? [];

    for (final file in SampleFiles.all) {
      final existing = transfers.where((t) => t.url == file.url).firstOrNull;
      if (existing != null) {
        _transfers[file.url] = existing;
      }
    }
    setState(() {});
  }

  Future<void> _startBatchDownload() async {
    if (_selectedUrls.isEmpty) return;

    setState(() => _isDownloading = true);

    for (final url in _selectedUrls) {
      final file = SampleFiles.all.firstWhere((f) => f.url == url);

      final result = await _controller.download(
        url: url,
        fileName: file.fileName,
      );

      final stream = result.valueOrNull;
      if (stream != null) {
        stream.listen((entity) {
          if (mounted) {
            setState(() => _transfers[url] = entity);
          }
        });
      }
    }

    setState(() {
      _isDownloading = false;
      _selectedUrls.clear();
    });
  }

  Future<void> _cancelAll() async {
    for (final entry in _transfers.entries) {
      if (entry.value?.isRunning == true) {
        await _controller.cancel(entry.value!.id);
      }
    }
    await _loadExistingTransfers();
  }

  Future<void> _clearCompleted() async {
    for (final entry in _transfers.entries.toList()) {
      if (entry.value?.isComplete == true) {
        await _controller.deleteTransfer(entry.value!.id);
        _transfers.remove(entry.key);
      }
    }
    setState(() {});
  }

  void _toggleSelection(String url) {
    setState(() {
      if (_selectedUrls.contains(url)) {
        _selectedUrls.remove(url);
      } else {
        _selectedUrls.add(url);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedUrls.addAll(
        SampleFiles.all
            .where((f) => _transfers[f.url] == null || _transfers[f.url]!.isFailed)
            .map((f) => f.url),
      );
    });
  }

  void _clearSelection() {
    setState(() => _selectedUrls.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate overall progress
    final activeTransfers = _transfers.values.where((t) => t != null && t.isRunning).toList();
    final overallProgress = activeTransfers.isEmpty
        ? 0.0
        : activeTransfers.map((t) => t!.progress).reduce((a, b) => a + b) / activeTransfers.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Downloads'),
        actions: [
          if (_selectedUrls.isNotEmpty)
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear),
              label: Text('${_selectedUrls.length}'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'select_all':
                  _selectAll();
                  break;
                case 'cancel_all':
                  _cancelAll();
                  break;
                case 'clear_completed':
                  _clearCompleted();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'select_all', child: Text('Select All')),
              const PopupMenuItem(value: 'cancel_all', child: Text('Cancel All')),
              const PopupMenuItem(value: 'clear_completed', child: Text('Clear Completed')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Overall Progress
          if (activeTransfers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.primaryContainer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Downloading ${activeTransfers.length} files',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${(overallProgress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

          // File List
          Expanded(
            child: ListView.builder(
              itemCount: SampleFiles.all.length,
              itemBuilder: (context, index) {
                final file = SampleFiles.all[index];
                return _buildFileItem(file, theme);
              },
            ),
          ),

          // Action Bar
          if (_selectedUrls.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _startBatchDownload,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isDownloading
                        ? 'Downloading...'
                        : 'Download ${_selectedUrls.length} Files',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(SampleFile file, ThemeData theme) {
    final transfer = _transfers[file.url];
    final isSelected = _selectedUrls.contains(file.url);
    final isDownloaded = transfer?.isComplete == true;
    final isDownloading = transfer?.isRunning == true;
    final isFailed = transfer?.isFailed == true;

    return ListTile(
      leading: _buildLeadingWidget(file, transfer, isSelected),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(file.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  file.extension.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(file.type),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(file.formattedSize, style: theme.textTheme.bodySmall),
            ],
          ),
          if (isDownloading && transfer != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: transfer.progress,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
      trailing: _buildTrailingWidget(file, transfer, isDownloaded, isFailed),
      onTap: isDownloading || isDownloaded
          ? null
          : () => _toggleSelection(file.url),
    );
  }

  Widget _buildLeadingWidget(SampleFile file, TransferEntity? transfer, bool isSelected) {
    if (transfer?.isRunning == true) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: transfer!.progress,
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

    if (transfer?.isComplete == true) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check_circle, color: Colors.green),
      );
    }

    return Checkbox(
      value: isSelected,
      onChanged: (_) => _toggleSelection(file.url),
    );
  }

  Widget _buildTrailingWidget(
    SampleFile file,
    TransferEntity? transfer,
    bool isDownloaded,
    bool isFailed,
  ) {
    if (transfer?.isRunning == true) {
      return IconButton(
        icon: const Icon(Icons.cancel),
        onPressed: () async {
          await _controller.cancel(transfer!.id);
          await _loadExistingTransfers();
        },
      );
    }

    if (isFailed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final result = await _controller.retry(transfer!.id);
              final stream = result.valueOrNull;
              if (stream != null) {
                stream.listen((entity) {
                  if (mounted) {
                    setState(() => _transfers[file.url] = entity);
                  }
                });
              }
            },
          ),
        ],
      );
    }

    if (isDownloaded) {
      return IconButton(
        icon: const Icon(Icons.open_in_new),
        onPressed: () => _controller.openFile(transfer!.id),
      );
    }

    return Icon(
      _getTypeIcon(file.type),
      color: _getTypeColor(file.type),
    );
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

  Color _getTypeColor(FileType type) {
    switch (type) {
      case FileType.image:
        return Colors.blue;
      case FileType.video:
        return Colors.purple;
      case FileType.audio:
        return Colors.orange;
      case FileType.document:
        return Colors.red;
      case FileType.archive:
        return Colors.brown;
      case FileType.other:
        return Colors.grey;
    }
  }
}
