import 'dart:io';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing cache and storage management features.
class CacheDemoScreen extends StatefulWidget {
  const CacheDemoScreen({super.key});

  @override
  State<CacheDemoScreen> createState() => _CacheDemoScreenState();
}

class _CacheDemoScreenState extends State<CacheDemoScreen> {
  final TransferController _controller = TransferController.instance;

  List<TransferEntity> _cachedTransfers = [];
  int _totalCacheSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
  }

  Future<void> _loadCacheData() async {
    setState(() => _isLoading = true);

    try {
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
        _cachedTransfers = completed;
        _totalCacheSize = totalSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الكاش'),
        content: const Text('هل تريد حذف جميع الملفات المحملة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final transfer in _cachedTransfers) {
        final file = File(transfer.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await _controller.deleteTransfer(transfer.id);
      }
      await _loadCacheData();
    }
  }

  Future<void> _deleteItem(TransferEntity transfer) async {
    final file = File(transfer.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    await _controller.deleteTransfer(transfer.id);
    await _loadCacheData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الكاش'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheData,
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _cachedTransfers.isNotEmpty ? _clearCache : null,
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildStatsCard(),
        const Divider(height: 1),
        Expanded(
          child: _cachedTransfers.isEmpty
              ? _buildEmptyState()
              : _buildCacheList(),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
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
                  'الملفات المحملة',
                  '${_cachedTransfers.length}',
                  Icons.folder,
                  Colors.blue,
                ),
                _buildStatItem(
                  'الحجم الكلي',
                  _formatSize(_totalCacheSize),
                  Icons.storage,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStorageBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

  Widget _buildStorageBar() {
    final cacheDir = AppDirectory.instance.cachedDir;
    if (cacheDir == null) return const SizedBox.shrink();

    // Assume 1GB available for demo
    const totalSpace = 1024 * 1024 * 1024;
    final usedPercent = _totalCacheSize / totalSpace;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('مساحة الكاش'),
            Text(
              '${_formatSize(_totalCacheSize)} / ${_formatSize(totalSpace)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: usedPercent,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              usedPercent > 0.8 ? Colors.red : Colors.blue,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد ملفات مخزنة',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتحميل بعض الملفات من شاشة التحميلات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheList() {
    // Group by file type
    final grouped = <String, List<TransferEntity>>{};
    for (final transfer in _cachedTransfers) {
      final parts = transfer.fileName.split('.');
      final ext = parts.length > 1 ? parts.last.toUpperCase() : 'OTHER';
      grouped.putIfAbsent(ext, () => []).add(transfer);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return _buildCategorySection(entry.key, entry.value);
      },
    );
  }

  Widget _buildCategorySection(String type, List<TransferEntity> transfers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(_getTypeIcon(type), size: 18, color: _getTypeColor(type)),
              const SizedBox(width: 8),
              Text(
                '$type (${transfers.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...transfers.map((t) => _buildCacheItem(t)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCacheItem(TransferEntity transfer) {
    final parts = transfer.fileName.split('.');
    final fileType = parts.length > 1 ? parts.last.toUpperCase() : 'OTHER';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getTypeColor(fileType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(fileType),
            color: _getTypeColor(fileType),
          ),
        ),
        title: Text(
          transfer.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              transfer.expectedSize > 0
                  ? _formatSize(transfer.expectedSize)
                  : 'غير معروف',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(transfer.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => _controller.openFile(transfer.id),
              tooltip: 'فتح',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteItem(transfer),
              tooltip: 'حذف',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'JPG':
      case 'JPEG':
      case 'PNG':
      case 'GIF':
      case 'WEBP':
        return Icons.image;
      case 'MP4':
      case 'AVI':
      case 'MKV':
        return Icons.videocam;
      case 'MP3':
      case 'WAV':
      case 'AAC':
        return Icons.audiotrack;
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'ZIP':
      case 'RAR':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'JPG':
      case 'JPEG':
      case 'PNG':
      case 'GIF':
      case 'WEBP':
        return Colors.blue;
      case 'MP4':
      case 'AVI':
      case 'MKV':
        return Colors.purple;
      case 'MP3':
      case 'WAV':
      case 'AAC':
        return Colors.orange;
      case 'PDF':
        return Colors.red;
      case 'DOC':
      case 'DOCX':
        return Colors.blue.shade700;
      case 'ZIP':
      case 'RAR':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
