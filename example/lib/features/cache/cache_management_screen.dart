import 'dart:io';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates cache management functionality.
///
/// Automatic file caching with URL recognition and cleanup.
class CacheManagementScreen extends StatefulWidget {
  const CacheManagementScreen({super.key});

  @override
  State<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends State<CacheManagementScreen> {
  final TransferController _controller = TransferController.instance;

  List<TransferEntity> _cachedFiles = [];
  int _totalCacheSize = 0;
  bool _isLoading = true;
  String? _testUrl;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
  }

  Future<void> _loadCacheData() async {
    setState(() => _isLoading = true);

    final result = await _controller.getAllTransfers();
    final transfers = result.valueOrNull ?? [];
    final completed = transfers.where((t) => t.isComplete).toList();

    int totalSize = 0;
    for (final transfer in completed) {
      final file = File(transfer.filePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }

    setState(() {
      _cachedFiles = completed;
      _totalCacheSize = totalSize;
      _isLoading = false;
    });
  }

  Future<void> _checkCache(String url) async {
    final result = await _controller.getCachedPath(url);

    result.fold(
      onSuccess: (path) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found in cache: $path'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => _openFile(path),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not found in cache')),
          );
        }
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.message}')),
        );
      },
    );
  }

  Future<void> _openFile(String path) async {
    // This would use open_filex or similar
  }

  Future<void> _deleteItem(TransferEntity transfer) async {
    final file = File(transfer.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    await _controller.deleteTransfer(transfer.id);
    await _loadCacheData();
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will delete all cached files. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final transfer in _cachedFiles) {
        final file = File(transfer.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await _controller.deleteTransfer(transfer.id);
      }
      await _loadCacheData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheData,
          ),
          if (_cachedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCache,
              tooltip: 'Clear Cache',
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

                // Cache Stats
                _buildStatsCard(theme),
                const SizedBox(height: 16),

                // URL Lookup
                _buildUrlLookupCard(theme),
                const SizedBox(height: 16),

                // Cached Files
                _buildCachedFilesCard(theme),
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
                Icon(Icons.cached, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Smart Caching',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Downloaded files are automatically cached with URL recognition. '
              'When you request a file that\'s already downloaded, '
              'it returns the cached version instantly.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildChip('Auto Cache', Icons.bolt),
                _buildChip('URL Lookup', Icons.search),
                _buildChip('Size Tracking', Icons.data_usage),
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

  Widget _buildStatsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              '${_cachedFiles.length}',
              'Cached Files',
              Icons.folder,
              theme,
            ),
            Container(
              width: 1,
              height: 50,
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
            ),
            _buildStat(
              _formatBytes(_totalCacheSize),
              'Total Size',
              Icons.data_usage,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlLookupCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'URL Cache Lookup',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check if a URL is already cached.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter URL to check...',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_testUrl?.isNotEmpty == true) {
                      _checkCache(_testUrl!);
                    }
                  },
                ),
              ),
              onChanged: (value) => _testUrl = value,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _checkCache(value);
                }
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: Try pasting a URL from a previously downloaded file.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedFilesCard(ThemeData theme) {
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
                  'Cached Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cachedFiles.isNotEmpty)
                  TextButton(
                    onPressed: _clearCache,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_cachedFiles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No cached files',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Downloaded files will appear here',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._cachedFiles.map((file) => _buildCacheItem(file, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheItem(TransferEntity transfer, ThemeData theme) {
    final parts = transfer.fileName.split('.');
    final ext = parts.length > 1 ? parts.last.toUpperCase() : 'FILE';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getExtColor(ext).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            ext.length > 3 ? ext.substring(0, 3) : ext,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getExtColor(ext),
            ),
          ),
        ),
      ),
      title: Text(
        transfer.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_formatBytes(transfer.expectedSize)} • ${_formatDate(transfer.createdAt)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () => _deleteItem(transfer),
        color: Colors.red,
      ),
    );
  }

  Color _getExtColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.blue;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Colors.orange;
      case 'pdf':
        return Colors.red;
      case 'zip':
      case 'rar':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
