import 'dart:io';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import '../providers/real_download_provider.dart';

/// Demo screen showing how to use the queue manager with real downloads.
///
/// This demonstrates:
/// - Real file downloads with caching
/// - Controlling concurrent downloads across multiple widgets
/// - Displaying downloaded images
/// - Queue state visualization
class QueuedChatDemoScreen extends StatefulWidget {
  const QueuedChatDemoScreen({super.key});

  @override
  State<QueuedChatDemoScreen> createState() => _QueuedChatDemoScreenState();
}

class _QueuedChatDemoScreenState extends State<QueuedChatDemoScreen> {
  late RealDownloadProvider _provider;
  int _maxConcurrent = 2;

  // Real sample files
  final List<_RealMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _provider = RealDownloadProvider(maxConcurrent: _maxConcurrent);
    _generateMessages();
  }

  void _generateMessages() {
    _messages.addAll([
      // Firebase Storage Images (from user)
      const _RealMessage(
        type: _MessageType.image,
        url: 'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F127.jpg?alt=media&token=66ae3024-0f25-45d7-8796-84852ee02cd6',
        fileName: 'منتج_127.jpg',
        isOutgoing: false,
      ),
      const _RealMessage(
        type: _MessageType.image,
        url: 'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F131.jpg?alt=media&token=82580148-4fe5-4f0c-9c58-b069119dbca6',
        fileName: 'منتج_131.jpg',
        isOutgoing: true,
      ),
      const _RealMessage(
        type: _MessageType.image,
        url: 'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F71.jpg?alt=media&token=d50f640d-9b18-4f38-a711-d8b0aa726423',
        fileName: 'منتج_71.jpg',
        isOutgoing: false,
      ),
      const _RealMessage(
        type: _MessageType.image,
        url: 'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F82.jpg?alt=media&token=2f152d4c-c601-4437-806d-c9e2a85d14bc',
        fileName: 'منتج_82.jpg',
        isOutgoing: true,
      ),
      const _RealMessage(
        type: _MessageType.image,
        url: 'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F67.jpg?alt=media&token=26880404-9820-4159-b730-7282cbc5d943',
        fileName: 'منتج_67.jpg',
        isOutgoing: false,
      ),

      // Sample PDF document
      const _RealMessage(
        type: _MessageType.document,
        url: 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
        fileName: 'sample_document.pdf',
        fileSize: 50 * 1024,
        isOutgoing: true,
      ),

      // Sample video (small)
      const _RealMessage(
        type: _MessageType.video,
        url: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
        fileName: 'sample_video.mp4',
        fileSize: 1 * 1024 * 1024,
        duration: Duration(seconds: 5),
        isOutgoing: false,
      ),

      // Sample audio
      const _RealMessage(
        type: _MessageType.audio,
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        fileName: 'sample_audio.mp3',
        fileSize: 5 * 1024 * 1024,
        duration: Duration(minutes: 6, seconds: 13),
        isOutgoing: true,
      ),

      // Sample ZIP file
      const _RealMessage(
        type: _MessageType.file,
        url: 'https://github.com/nicehorse06/flappy-bird-pygame/archive/refs/heads/master.zip',
        fileName: 'sample_project.zip',
        fileSize: 100 * 1024,
        isOutgoing: false,
      ),

      // More images
      const _RealMessage(
        type: _MessageType.image,
        url: 'https://picsum.photos/800/600',
        fileName: 'random_image_1.jpg',
        isOutgoing: true,
      ),
      const _RealMessage(
        type: _MessageType.image,
        url: 'https://picsum.photos/600/800',
        fileName: 'random_image_2.jpg',
        isOutgoing: false,
      ),
    ]);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنزيل ملفات حقيقية'),
        actions: [
          IconButton(
            icon: Icon(_provider.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              setState(() {
                if (_provider.isPaused) {
                  _provider.start();
                } else {
                  _provider.pause();
                }
              });
            },
            tooltip: _provider.isPaused ? 'استمرار' : 'إيقاف',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadAll,
            tooltip: 'تنزيل الكل',
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              _provider.cancelAll();
              setState(() {});
            },
            tooltip: 'إلغاء الكل',
          ),
        ],
      ),
      body: Column(
        children: [
          // Queue status bar
          _buildQueueStatusBar(),

          // Concurrent control
          _buildConcurrentSlider(),

          const Divider(height: 1),

          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageWidget(message, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatusBar() {
    return StreamBuilder<TransferQueueState<RealDownloadTask>>(
      stream: _provider.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _provider.state;

        return Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _buildStatusChip(
                'جاري',
                state.runningCount.toString(),
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                'في الانتظار',
                state.pendingCount.toString(),
                Colors.orange,
              ),
              const Spacer(),
              if (state.totalCount > 0) ...[
                Text(
                  '${(state.overallProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    value: state.overallProgress,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildConcurrentSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('الحد الأقصى:'),
          Expanded(
            child: Slider(
              value: _maxConcurrent.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_maxConcurrent',
              onChanged: (value) {
                setState(() {
                  _maxConcurrent = value.round();
                  _provider.maxConcurrent = _maxConcurrent;
                });
              },
            ),
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '$_maxConcurrent',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(_RealMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: message.isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _RealMessageCard(
            message: message,
            provider: _provider,
            onDownload: () {
              _provider.enqueueDownload(
                url: message.url,
                fileName: message.fileName,
                expectedSize: message.fileSize,
              );
              setState(() {});
            },
          ),
          const SizedBox(height: 4),
          _buildQueueInfo(message.url),
        ],
      ),
    );
  }

  Widget _buildQueueInfo(String url) {
    return StreamBuilder<TransferQueueState<RealDownloadTask>>(
      stream: _provider.stateStream,
      builder: (context, snapshot) {
        final position = _provider.getQueuePosition(url);
        final isDownloading = _provider.isDownloading(url);
        final isQueued = _provider.isQueued(url);
        final completedPath = _provider.getCompletedPath(url);

        if (completedPath != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'تم التنزيل',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (!isDownloading && !isQueued) {
          return const SizedBox.shrink();
        }

        String text;
        Color color;

        if (isDownloading) {
          text = 'جاري التنزيل...';
          color = Colors.blue;
        } else {
          text = 'في الطابور (الترتيب: $position)';
          color = Colors.orange;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                text,
                style: TextStyle(color: color, fontSize: 11),
              ),
            ),
            if (isQueued) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _provider.moveToFront(url),
                child: const Icon(Icons.arrow_upward, size: 16),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  _provider.cancel(url);
                  setState(() {});
                },
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ],
        );
      },
    );
  }

  void _downloadAll() {
    for (final message in _messages) {
      _provider.enqueueDownload(
        url: message.url,
        fileName: message.fileName,
        expectedSize: message.fileSize,
      );
    }
    setState(() {});
  }
}

/// Card widget for displaying real message with download functionality.
class _RealMessageCard extends StatefulWidget {
  final _RealMessage message;
  final RealDownloadProvider provider;
  final VoidCallback onDownload;

  const _RealMessageCard({
    required this.message,
    required this.provider,
    required this.onDownload,
  });

  @override
  State<_RealMessageCard> createState() => _RealMessageCardState();
}

class _RealMessageCardState extends State<_RealMessageCard> {
  String? _cachedPath;
  bool _isLoading = true;
  double _progress = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    final path = await widget.provider.getCachedPath(widget.message.url);
    if (mounted) {
      setState(() {
        _cachedPath = path;
        _isLoading = false;
      });
    }
  }

  void _startDownload() {
    setState(() => _isDownloading = true);

    widget.provider
        .enqueueDownload(
          url: widget.message.url,
          fileName: widget.message.fileName,
          expectedSize: widget.message.fileSize,
        )
        .listen(
          (progress) {
            if (mounted) {
              setState(() => _progress = progress.progress);
            }
          },
          onDone: () {
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _cachedPath = widget.provider.getCompletedPath(widget.message.url);
              });
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() => _isDownloading = false);
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isOutgoing = message.isOutgoing;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isOutgoing
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content based on type
          if (message.type == _MessageType.image)
            _buildImageContent()
          else
            _buildFileContent(),

          // File name
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  Text(
                    _formatBytes(message.fileSize!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cachedPath != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.file(
          File(_cachedPath!),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            height: 180,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.image, size: 48, color: Colors.grey),
          if (_isDownloading)
            CircularProgressIndicator(value: _progress > 0 ? _progress : null)
          else
            IconButton.filled(
              onPressed: _startDownload,
              icon: const Icon(Icons.download),
            ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    final message = widget.message;
    IconData icon;
    Color color;

    switch (message.type) {
      case _MessageType.video:
        icon = Icons.videocam;
        color = Colors.red;
      case _MessageType.audio:
        icon = Icons.audiotrack;
        color = Colors.purple;
      case _MessageType.document:
        icon = Icons.description;
        color = Colors.blue;
      case _MessageType.file:
        icon = Icons.insert_drive_file;
        color = Colors.orange;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                if (_isDownloading)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.type.name.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message.duration != null)
                  Text(
                    _formatDuration(message.duration!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (!_isDownloading && _cachedPath == null)
            IconButton(
              onPressed: _startDownload,
              icon: const Icon(Icons.download),
            )
          else if (_cachedPath != null)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

enum _MessageType { image, video, audio, document, file }

class _RealMessage {
  final _MessageType type;
  final String url;
  final String fileName;
  final int? fileSize;
  final Duration? duration;
  final bool isOutgoing;

  const _RealMessage({
    required this.type,
    required this.url,
    required this.fileName,
    this.fileSize,
    this.duration,
    required this.isOutgoing,
  });
}
