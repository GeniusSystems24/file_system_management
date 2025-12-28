import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing real download examples for all file types.
class DownloadsDemoScreen extends StatefulWidget {
  const DownloadsDemoScreen({super.key});

  @override
  State<DownloadsDemoScreen> createState() => _DownloadsDemoScreenState();
}

class _DownloadsDemoScreenState extends State<DownloadsDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransferController _controller = TransferController.instance;

  // Real download URLs for different file types
  static const _sampleFiles = {
    'images': [
      _SampleFile(
        name: 'Sample JPG Image',
        url: 'https://sample-videos.com/img/Sample-jpg-image-500kb.jpg',
        size: '500 KB',
        type: 'JPG',
      ),
      _SampleFile(
        name: 'Sample PNG Image',
        url: 'https://sample-videos.com/img/Sample-png-image-500kb.png',
        size: '500 KB',
        type: 'PNG',
      ),
      _SampleFile(
        name: 'Animated GIF',
        url: 'https://sample-videos.com/gif/1.gif',
        size: '~1 MB',
        type: 'GIF',
      ),
      _SampleFile(
        name: 'High-Res Image',
        url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920',
        size: '~2 MB',
        type: 'JPG',
      ),
      _SampleFile(
        name: 'WebP Image',
        url: 'https://www.gstatic.com/webp/gallery/1.webp',
        size: '~100 KB',
        type: 'WebP',
      ),
    ],
    'videos': [
      _SampleFile(
        name: 'Sample MP4 (Small)',
        url: 'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4',
        size: '1 MB',
        type: 'MP4',
      ),
      _SampleFile(
        name: 'Sample MP4 (Medium)',
        url: 'https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_5mb.mp4',
        size: '5 MB',
        type: 'MP4',
      ),
      _SampleFile(
        name: 'Sample MP4 (Large)',
        url: 'https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_10mb.mp4',
        size: '10 MB',
        type: 'MP4',
      ),
      _SampleFile(
        name: 'Sample MP4 (HD)',
        url: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_20mb.mp4',
        size: '20 MB',
        type: 'MP4',
      ),
    ],
    'audio': [
      _SampleFile(
        name: 'Sample MP3 (Short)',
        url: 'https://sample-videos.com/audio/mp3/crowd-cheering.mp3',
        size: '~500 KB',
        type: 'MP3',
      ),
      _SampleFile(
        name: 'Sample WAV',
        url: 'https://sample-videos.com/audio/wav/crowd-cheering.wav',
        size: '~5 MB',
        type: 'WAV',
      ),
      _SampleFile(
        name: 'Sample AAC',
        url: 'https://sample-videos.com/audio/aac/crowd-cheering.aac',
        size: '~300 KB',
        type: 'AAC',
      ),
    ],
    'documents': [
      _SampleFile(
        name: 'Sample PDF',
        url: 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
        size: '~100 KB',
        type: 'PDF',
      ),
      _SampleFile(
        name: 'Sample PDF (Large)',
        url: 'https://sample-videos.com/pdf/Sample-pdf-5mb.pdf',
        size: '5 MB',
        type: 'PDF',
      ),
      _SampleFile(
        name: 'Sample DOCX',
        url: 'https://sample-videos.com/doc/Sample-doc-file-100kb.doc',
        size: '100 KB',
        type: 'DOC',
      ),
    ],
    'archives': [
      _SampleFile(
        name: 'Sample ZIP',
        url: 'https://sample-videos.com/zip/10mb.zip',
        size: '10 MB',
        type: 'ZIP',
      ),
      _SampleFile(
        name: 'Sample ZIP (Small)',
        url: 'https://sample-videos.com/zip/1mb.zip',
        size: '1 MB',
        type: 'ZIP',
      ),
    ],
  };

  List<TransferEntity> _transfers = [];
  String _selectedCategory = 'images';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = ['images', 'videos', 'audio', 'documents', 'archives'][_tabController.index];
        });
      }
    });
    _loadTransfers();
  }

  Future<void> _loadTransfers() async {
    final transfers = await _controller.getAllTransfers();
    setState(() => _transfers = transfers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحميلات حقيقية'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'صور'),
            Tab(icon: Icon(Icons.videocam), text: 'فيديو'),
            Tab(icon: Icon(Icons.audiotrack), text: 'صوت'),
            Tab(icon: Icon(Icons.description), text: 'مستندات'),
            Tab(icon: Icon(Icons.folder_zip), text: 'أرشيف'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransfers,
            tooltip: 'تحديث',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'pause_all':
                  for (final t in _transfers.where((t) => t.isRunning)) {
                    await _controller.pause(t.id);
                  }
                  break;
                case 'resume_all':
                  for (final t in _transfers.where((t) => t.isPaused)) {
                    await _controller.resume(t.id);
                  }
                  break;
                case 'cancel_all':
                  for (final t in _transfers.where((t) => t.isRunning || t.isPaused)) {
                    await _controller.cancel(t.id);
                  }
                  break;
                case 'clear_all':
                  await _controller.deleteAllTransfers();
                  break;
              }
              _loadTransfers();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pause_all', child: Text('إيقاف الكل')),
              const PopupMenuItem(value: 'resume_all', child: Text('استئناف الكل')),
              const PopupMenuItem(value: 'cancel_all', child: Text('إلغاء الكل')),
              const PopupMenuItem(value: 'clear_all', child: Text('مسح الكل')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFileList('images'),
          _buildFileList('videos'),
          _buildFileList('audio'),
          _buildFileList('documents'),
          _buildFileList('archives'),
        ],
      ),
    );
  }

  Widget _buildFileList(String category) {
    final files = _sampleFiles[category] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _DownloadCard(
          file: file,
          controller: _controller,
          onRefresh: _loadTransfers,
        );
      },
    );
  }
}

class _SampleFile {
  final String name;
  final String url;
  final String size;
  final String type;

  const _SampleFile({
    required this.name,
    required this.url,
    required this.size,
    required this.type,
  });
}

class _DownloadCard extends StatefulWidget {
  final _SampleFile file;
  final TransferController controller;
  final VoidCallback onRefresh;

  const _DownloadCard({
    required this.file,
    required this.controller,
    required this.onRefresh,
  });

  @override
  State<_DownloadCard> createState() => _DownloadCardState();
}

class _DownloadCardState extends State<_DownloadCard> {
  TransferEntity? _transfer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingTransfer();
  }

  Future<void> _checkExistingTransfer() async {
    final transfers = await widget.controller.getAllTransfers();
    final existing = transfers.where((t) => t.url == widget.file.url).firstOrNull;
    if (mounted) {
      setState(() => _transfer = existing);
    }
  }

  Future<void> _startDownload() async {
    setState(() => _isLoading = true);

    try {
      final stream = widget.controller.download(
        url: widget.file.url,
        fileName: widget.file.url.split('/').last,
      );

      await for (final entity in stream) {
        if (mounted) {
          setState(() => _transfer = entity);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      widget.onRefresh();
    }
  }

  Future<void> _pauseDownload() async {
    if (_transfer != null) {
      await widget.controller.pause(_transfer!.id);
      _checkExistingTransfer();
    }
  }

  Future<void> _resumeDownload() async {
    if (_transfer != null) {
      final stream = widget.controller.resume(_transfer!.id);
      await for (final entity in stream) {
        if (mounted) {
          setState(() => _transfer = entity);
        }
      }
    }
  }

  Future<void> _cancelDownload() async {
    if (_transfer != null) {
      await widget.controller.cancel(_transfer!.id);
      setState(() => _transfer = null);
      widget.onRefresh();
    }
  }

  Future<void> _retryDownload() async {
    if (_transfer != null) {
      final stream = widget.controller.retry(_transfer!.id);
      await for (final entity in stream) {
        if (mounted) {
          setState(() => _transfer = entity);
        }
      }
    }
  }

  Future<void> _openFile() async {
    if (_transfer != null && _transfer!.isComplete) {
      await widget.controller.openFile(_transfer!.id);
    }
  }

  IconData _getFileIcon() {
    switch (widget.file.type.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (widget.file.type.toLowerCase()) {
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
      case 'doc':
      case 'docx':
        return Colors.blue.shade700;
      case 'zip':
      case 'rar':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTransfer = _transfer != null;
    final isComplete = _transfer?.isComplete ?? false;
    final isRunning = _transfer?.isRunning ?? false;
    final isPaused = _transfer?.isPaused ?? false;
    final isFailed = _transfer?.isFailed ?? false;
    final progress = _transfer?.progress ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getFileIcon(), color: _getFileColor()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getFileColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.file.type,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getFileColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.file.size,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionButton(),
              ],
            ),
            if (hasTransfer && (isRunning || isPaused)) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    isPaused ? Colors.amber : _getFileColor(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (_transfer?.speed != null && _transfer!.speed! > 0)
                    Text(
                      _formatSpeed(_transfer!.speed!),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ],
            if (isFailed && _transfer?.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _transfer!.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isComplete) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم التحميل بنجاح',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openFile,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('فتح'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_transfer == null) {
      return IconButton(
        icon: const Icon(Icons.download),
        onPressed: _startDownload,
        tooltip: 'تحميل',
        color: _getFileColor(),
      );
    }

    if (_transfer!.isRunning) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: _pauseDownload,
            tooltip: 'إيقاف مؤقت',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelDownload,
            tooltip: 'إلغاء',
          ),
        ],
      );
    }

    if (_transfer!.isPaused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _resumeDownload,
            tooltip: 'استئناف',
            color: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelDownload,
            tooltip: 'إلغاء',
          ),
        ],
      );
    }

    if (_transfer!.isFailed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _retryDownload,
            tooltip: 'إعادة المحاولة',
            color: Colors.orange,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelDownload,
            tooltip: 'حذف',
          ),
        ],
      );
    }

    if (_transfer!.isComplete) {
      return IconButton(
        icon: const Icon(Icons.check_circle),
        onPressed: null,
        color: Colors.green,
      );
    }

    return const SizedBox.shrink();
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
    }
  }
}
