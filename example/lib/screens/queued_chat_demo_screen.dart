import 'dart:typed_data';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import '../providers/queued_transfer_provider.dart';

/// Demo screen showing how to use the queue manager with message widgets.
///
/// This demonstrates:
/// - Controlling concurrent downloads across multiple widgets
/// - Priority-based downloading
/// - Queue state visualization
/// - Pause/resume queue operations
class QueuedChatDemoScreen extends StatefulWidget {
  const QueuedChatDemoScreen({super.key});

  @override
  State<QueuedChatDemoScreen> createState() => _QueuedChatDemoScreenState();
}

class _QueuedChatDemoScreenState extends State<QueuedChatDemoScreen> {
  late QueuedTransferProvider _provider;
  int _maxConcurrent = 2;

  // Sample messages to demonstrate
  final List<_MockMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _provider = QueuedTransferProvider(maxConcurrent: _maxConcurrent);
    _generateMessages();
  }

  void _generateMessages() {
    _messages.addAll([
      _MockMessage(
        type: _MessageType.image,
        url: 'https://example.com/photo1.jpg',
        fileName: 'صورة_١.jpg',
        fileSize: 2 * 1024 * 1024,
        isOutgoing: false,
      ),
      _MockMessage(
        type: _MessageType.image,
        url: 'https://example.com/photo2.jpg',
        fileName: 'صورة_٢.jpg',
        fileSize: 3 * 1024 * 1024,
        isOutgoing: true,
      ),
      _MockMessage(
        type: _MessageType.video,
        url: 'https://example.com/video1.mp4',
        fileName: 'فيديو_١.mp4',
        fileSize: 15 * 1024 * 1024,
        duration: const Duration(minutes: 1, seconds: 30),
        isOutgoing: false,
      ),
      _MockMessage(
        type: _MessageType.audio,
        url: 'https://example.com/audio1.mp3',
        fileName: 'رسالة_صوتية.mp3',
        fileSize: 500 * 1024,
        duration: const Duration(seconds: 25),
        isOutgoing: true,
      ),
      _MockMessage(
        type: _MessageType.document,
        url: 'https://example.com/document1.pdf',
        fileName: 'التقرير.pdf',
        fileSize: 5 * 1024 * 1024,
        pageCount: 20,
        isOutgoing: false,
      ),
      _MockMessage(
        type: _MessageType.image,
        url: 'https://example.com/photo3.jpg',
        fileName: 'صورة_٣.jpg',
        fileSize: 4 * 1024 * 1024,
        isOutgoing: false,
      ),
      _MockMessage(
        type: _MessageType.file,
        url: 'https://example.com/archive.zip',
        fileName: 'الملفات.zip',
        fileSize: 25 * 1024 * 1024,
        isOutgoing: true,
      ),
      _MockMessage(
        type: _MessageType.video,
        url: 'https://example.com/video2.mp4',
        fileName: 'فيديو_٢.mp4',
        fileSize: 20 * 1024 * 1024,
        duration: const Duration(minutes: 2),
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
        title: const Text('الطابور مع الويدجت'),
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
                return _buildMessageWidget(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatusBar() {
    return StreamBuilder<TransferQueueState<WidgetDownloadTask>>(
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

  Widget _buildMessageWidget(_MockMessage message) {
    final direction = message.isOutgoing
        ? BubbleDirection.outgoing
        : BubbleDirection.incoming;

    final config = TransferWidgetConfig(
      direction: direction,
      autoStart: false, // Manual start to demonstrate queue
    );

    Widget widget;

    switch (message.type) {
      case _MessageType.image:
        widget = ImageMessageTransferWidget(
          url: message.url,
          thumbnailBytes: _generatePlaceholderImage(),
          fileName: message.fileName,
          fileSize: message.fileSize,
          width: 220,
          height: 160,
          config: config,
          onDownload: (payload) => _provider.enqueueDownload(
            url: payload.url,
            expectedSize: payload.expectedSize,
          ),
        );
        break;

      case _MessageType.video:
        widget = VideoMessageTransferWidget(
          url: message.url,
          thumbnailBytes: _generatePlaceholderImage(),
          fileName: message.fileName,
          fileSize: message.fileSize,
          duration: message.duration ?? Duration.zero,
          width: 220,
          height: 160,
          config: config,
          onDownload: (payload) => _provider.enqueueDownload(
            url: payload.url,
            expectedSize: payload.expectedSize,
          ),
        );
        break;

      case _MessageType.audio:
        widget = AudioMessageTransferWidget(
          url: message.url,
          fileName: message.fileName,
          fileSize: message.fileSize,
          duration: message.duration ?? Duration.zero,
          waveform: _generateWaveform(),
          config: config,
          onDownload: (payload) => _provider.enqueueDownload(
            url: payload.url,
            expectedSize: payload.expectedSize,
          ),
        );
        break;

      case _MessageType.document:
        widget = DocumentMessageTransferWidget(
          url: message.url,
          fileName: message.fileName,
          fileSize: message.fileSize,
          pageCount: message.pageCount,
          config: config,
          onDownload: (payload) => _provider.enqueueDownload(
            url: payload.url,
            expectedSize: payload.expectedSize,
          ),
        );
        break;

      case _MessageType.file:
        widget = FileMessageTransferWidget(
          url: message.url,
          fileName: message.fileName,
          fileSize: message.fileSize,
          config: config,
          onDownload: (payload) => _provider.enqueueDownload(
            url: payload.url,
            expectedSize: payload.expectedSize,
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: message.isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          widget,
          const SizedBox(height: 4),
          _buildQueueInfo(message.url),
        ],
      ),
    );
  }

  Widget _buildQueueInfo(String url) {
    return StreamBuilder<TransferQueueState<WidgetDownloadTask>>(
      stream: _provider.stateStream,
      builder: (context, snapshot) {
        final position = _provider.getQueuePosition(url);
        final isDownloading = _provider.isDownloading(url);
        final isQueued = _provider.isQueued(url);

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
                onTap: () => _provider.cancel(url),
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
        expectedSize: message.fileSize,
      );
    }
  }

  List<double> _generateWaveform() {
    return List.generate(30, (i) {
      final t = i / 30;
      return 0.2 + 0.6 * (0.5 + 0.5 * _sin(t * 6.28 * 3)).abs();
    });
  }

  double _sin(double x) {
    x = x % (2 * 3.14159);
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  Uint8List _generatePlaceholderImage() {
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x18, 0xDD,
      0x8D, 0xB5, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
      0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
  }
}

enum _MessageType { image, video, audio, document, file }

class _MockMessage {
  final _MessageType type;
  final String url;
  final String fileName;
  final int fileSize;
  final Duration? duration;
  final int? pageCount;
  final bool isOutgoing;

  const _MockMessage({
    required this.type,
    required this.url,
    required this.fileName,
    required this.fileSize,
    this.duration,
    this.pageCount,
    required this.isOutgoing,
  });
}
