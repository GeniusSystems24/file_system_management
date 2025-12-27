import 'dart:io';
import 'dart:math';

import 'package:chewie/chewie.dart';
import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';

import '../providers/real_download_provider.dart';

/// Demo screen showing how to use the queue manager with real downloads.
///
/// This demonstrates:
/// - WhatsApp-like chat design
/// - Real file downloads with caching
/// - Video and audio playback
/// - Queue management
class QueuedChatDemoScreen extends StatefulWidget {
  const QueuedChatDemoScreen({super.key});

  @override
  State<QueuedChatDemoScreen> createState() => _QueuedChatDemoScreenState();
}

class _QueuedChatDemoScreenState extends State<QueuedChatDemoScreen> {
  late RealDownloadProvider _provider;

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _provider = RealDownloadProvider();
    _generateMessages();
  }

  void _generateMessages() {
    _messages.addAll([
      // Firebase Storage Images
      _ChatMessage(
        type: MessageType.image,
        url:
            'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F127.jpg?alt=media&token=66ae3024-0f25-45d7-8796-84852ee02cd6',
        fileName: 'منتج_127.jpg',
        isOutgoing: false,
        fileSize: 150 * 1024,
        time: '10:30 ص',
      ),
      _ChatMessage(
        type: MessageType.image,
        url:
            'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F131.jpg?alt=media&token=82580148-4fe5-4f0c-9c58-b069119dbca6',
        fileName: 'منتج_131.jpg',
        isOutgoing: true,
        fileSize: 200 * 1024,
        time: '10:32 ص',
      ),

      // Sample audio
      _ChatMessage(
        type: MessageType.audio,
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        fileName: 'رسالة_صوتية.mp3',
        fileSize: 5 * 1024 * 1024,
        duration: const Duration(minutes: 6, seconds: 13),
        isOutgoing: true,
        time: '10:35 ص',
      ),

      // More images
      _ChatMessage(
        type: MessageType.image,
        url:
            'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F71.jpg?alt=media&token=d50f640d-9b18-4f38-a711-d8b0aa726423',
        fileName: 'منتج_71.jpg',
        isOutgoing: false,
        fileSize: 180 * 1024,
        time: '10:40 ص',
      ),

      // Sample video
      _ChatMessage(
        type: MessageType.video,
        url:
            'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
        fileName: 'فيديو_مضحك.mp4',
        fileSize: 1 * 1024 * 1024,
        duration: const Duration(seconds: 5),
        isOutgoing: false,
        time: '10:45 ص',
      ),

      // PDF document
      _ChatMessage(
        type: MessageType.document,
        url: 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
        fileName: 'التقرير_السنوي.pdf',
        fileSize: 50 * 1024,
        isOutgoing: true,
        time: '10:50 ص',
      ),

      // More images
      _ChatMessage(
        type: MessageType.image,
        url:
            'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F82.jpg?alt=media&token=2f152d4c-c601-4437-806d-c9e2a85d14bc',
        fileName: 'منتج_82.jpg',
        isOutgoing: true,
        fileSize: 160 * 1024,
        time: '10:55 ص',
      ),

      // ZIP file
      _ChatMessage(
        type: MessageType.file,
        url:
            'https://github.com/nicehorse06/flappy-bird-pygame/archive/refs/heads/master.zip',
        fileName: 'مشروع_برمجي.zip',
        fileSize: 100 * 1024,
        isOutgoing: false,
        time: '11:00 ص',
      ),

      // Another audio
      _ChatMessage(
        type: MessageType.audio,
        url:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        fileName: 'مقطع_موسيقي.mp3',
        fileSize: 4 * 1024 * 1024,
        duration: const Duration(minutes: 5, seconds: 25),
        isOutgoing: false,
        time: '11:05 ص',
      ),

      // Random images from Picsum
      _ChatMessage(
        type: MessageType.image,
        url: 'https://picsum.photos/800/600',
        fileName: 'صورة_عشوائية.jpg',
        fileSize: 300 * 1024,
        isOutgoing: true,
        time: '11:10 ص',
      ),

      _ChatMessage(
        type: MessageType.image,
        url:
            'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/primary_sys%2F%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA%2F67.jpg?alt=media&token=26880404-9820-4159-b730-7282cbc5d943',
        fileName: 'منتج_67.jpg',
        isOutgoing: false,
        fileSize: 140 * 1024,
        time: '11:15 ص',
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
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: DecoratedBox(
        // WhatsApp-like chat background
        decoration: const BoxDecoration(
          color: Color(0xFFECE5DD),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
          itemCount: _messages.length,
          itemBuilder: (context, index) => _buildMessage(
            _messages[index],
            index,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF075E54),
      foregroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.group, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مجموعة التنزيلات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'أنت و 10 مشاركين آخرين',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _downloadAll,
          tooltip: 'تنزيل الكل',
        ),
      ],
    );
  }

  Widget _buildMessage(_ChatMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment:
            message.isOutgoing
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
        child: _ChatBubble(
          message: message,
          provider: _provider,
        ),
      ),
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

/// Chat bubble widget with WhatsApp-like design.
class _ChatBubble extends StatefulWidget {
  final _ChatMessage message;
  final RealDownloadProvider provider;

  const _ChatBubble({
    required this.message,
    required this.provider,
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  String? _cachedPath;
  bool _isDownloading = false;
  bool _isPaused = false;
  double _progress = 0;
  String? _error;

  // Media players
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _checkCache() async {
    final path = await widget.provider.getCachedPath(widget.message.url);
    if (path != null && mounted) {
      setState(() => _cachedPath = path);
      _initializePlayer(path);
    }
  }

  Future<void> _initializePlayer(String path) async {
    if (widget.message.type == MessageType.video) {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF25D366),
          handleColor: const Color(0xFF075E54),
          bufferedColor: Colors.grey[300]!,
          backgroundColor: Colors.grey[200]!,
        ),
      );
      if (mounted) setState(() {});
    } else if (widget.message.type == MessageType.audio) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setFilePath(path);
      _audioDuration = _audioPlayer!.duration ?? Duration.zero;

      _audioPlayer!.positionStream.listen((position) {
        if (mounted) setState(() => _audioPosition = position);
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _audioPosition = Duration.zero;
              _audioPlayer?.seek(Duration.zero);
              _audioPlayer?.pause();
            }
          });
        }
      });

      if (mounted) setState(() {});
    }
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _isPaused = false;
      _error = null;
    });

    widget.provider
        .enqueueDownload(
          url: widget.message.url,
          fileName: widget.message.fileName,
          expectedSize: widget.message.fileSize,
        )
        .listen(
          (progress) {
            if (mounted) {
              setState(() {
                _progress = progress.progress;
                _isPaused = progress.status == TransferStatus.paused;
              });
            }
          },
          onDone: () {
            if (mounted) {
              final path =
                  widget.provider.getCompletedPath(widget.message.url);
              setState(() {
                _isDownloading = false;
                _isPaused = false;
                _cachedPath = path;
              });
              if (path != null) {
                _initializePlayer(path);
              }
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _isPaused = false;
                _error = e.toString();
              });
            }
          },
        );
  }

  Future<void> _pauseDownload() async {
    final result = await widget.provider.pauseDownload(widget.message.url);
    if (result && mounted) {
      setState(() => _isPaused = true);
    }
  }

  Future<void> _resumeDownload() async {
    final result = await widget.provider.resumeDownload(widget.message.url);
    if (result && mounted) {
      setState(() => _isPaused = false);
    }
  }

  void _cancelDownload() {
    widget.provider.cancelDownload(widget.message.url);
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isPaused = false;
        _progress = 0;
      });
    }
  }

  void _toggleAudioPlayback() async {
    if (_audioPlayer == null) return;

    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play();
    }
  }

  Future<void> _openFile(String path) async {
    await OpenFilex.open(path);
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoing = widget.message.isOutgoing;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: isOutgoing ? const Color(0xFFDCF8C6) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isOutgoing ? 12 : 0),
          bottomRight: Radius.circular(isOutgoing ? 0 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContent(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.message.type) {
      case MessageType.image:
        return _buildImageContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.audio:
        return _buildAudioContent();
      case MessageType.document:
      case MessageType.file:
        return _buildFileContent();
    }
  }

  Widget _buildImageContent() {
    if (_cachedPath != null) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(_cachedPath!),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Image.file(
            File(_cachedPath!),
            width: 280,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.broken_image),
          ),
        ),
      );
    }

    return _buildDownloadableMedia(Icons.image, 200);
  }

  Widget _buildVideoContent() {
    if (_cachedPath != null && _chewieController != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: SizedBox(
          width: 280,
          height: 200,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildDownloadableMedia(Icons.videocam, 200),
        if (widget.message.duration != null && !_isDownloading)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(widget.message.duration!),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioContent() {
    if (_cachedPath != null && _audioPlayer != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Play/Pause button
            GestureDetector(
              onTap: _toggleAudioPlayback,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Waveform / Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Waveform visualization
                  SizedBox(
                    height: 32,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        progress: _audioDuration.inMilliseconds > 0
                            ? _audioPosition.inMilliseconds /
                                _audioDuration.inMilliseconds
                            : 0,
                        isPlaying: _isPlaying,
                      ),
                      size: const Size(double.infinity, 32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Duration
                  Text(
                    '${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Not downloaded yet
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Download/Pause/Resume button
          GestureDetector(
            onTap: _isDownloading
                ? (_isPaused ? _resumeDownload : _pauseDownload)
                : _startDownload,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isDownloading
                    ? (_isPaused ? Colors.orange : Colors.grey[300])
                    : const Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: _isDownloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            _isPaused ? Colors.orange : const Color(0xFF075E54),
                          ),
                        ),
                        Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          size: 20,
                          color: _isPaused ? Colors.white : const Color(0xFF075E54),
                        ),
                      ],
                    )
                  : const Icon(Icons.download, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 32,
                  child: CustomPaint(
                    painter: _WaveformPainter(progress: _isDownloading ? _progress : 0, isPlaying: false),
                    size: const Size(double.infinity, 32),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _isDownloading
                          ? (_isPaused ? 'متوقف' : '${(_progress * 100).toInt()}%')
                          : (widget.message.duration != null
                              ? _formatDuration(widget.message.duration!)
                              : _formatBytes(widget.message.fileSize ?? 0)),
                      style: TextStyle(
                        fontSize: 11,
                        color: _isPaused ? Colors.orange : Colors.grey[600],
                      ),
                    ),
                    if (_isDownloading) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: _cancelDownload,
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    final isDocument = widget.message.type == MessageType.document;
    final iconData = isDocument ? Icons.description : Icons.insert_drive_file;
    final color = isDocument ? Colors.red : Colors.orange;
    final ext = widget.message.fileName.split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // File icon with progress
          GestureDetector(
            onTap: _isDownloading
                ? (_isPaused ? _resumeDownload : _pauseDownload)
                : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isDownloading)
                    Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: color,
                      size: 24,
                    )
                  else
                    Icon(iconData, color: color, size: 28),
                  if (_isDownloading)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          _isPaused ? Colors.orange : color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ext,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isDownloading
                          ? (_isPaused
                              ? 'متوقف'
                              : '${(_progress * 100).toInt()}%')
                          : _formatBytes(widget.message.fileSize ?? 0),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isPaused ? Colors.orange : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          if (_cachedPath != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Color(0xFF075E54)),
              onPressed: () => _openFile(_cachedPath!),
            )
          else if (!_isDownloading)
            IconButton(
              icon: const Icon(Icons.download, color: Color(0xFF25D366)),
              onPressed: _startDownload,
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: _cancelDownload,
              tooltip: 'إلغاء',
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadableMedia(IconData icon, double height) {
    return Container(
      width: 280,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[500]),
          if (_isDownloading)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator with pause/resume button
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(
                          _isPaused ? Colors.orange : const Color(0xFF25D366),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isPaused ? _resumeDownload : _pauseDownload,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: _isPaused
                                ? const Color(0xFF25D366)
                                : const Color(0xFF075E54),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Progress text and cancel button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isPaused
                            ? 'متوقف'
                            : '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _cancelDownload,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: _startDownload,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              bottom: 8,
              child: GestureDetector(
                onTap: _startDownload,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 280,
      height: 200,
      color: Colors.grey[300],
      child: Icon(icon, size: 48, color: Colors.grey[500]),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message.time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          if (widget.message.isOutgoing) ...[
            const SizedBox(width: 4),
            Icon(
              _cachedPath != null ? Icons.done_all : Icons.done,
              size: 16,
              color: _cachedPath != null ? const Color(0xFF34B7F1) : Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenImage(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

/// Waveform painter for audio visualization.
class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Random _random = Random(42);

  _WaveformPainter({
    required this.progress,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 40;
    final barWidth = size.width / barCount - 1;
    final maxHeight = size.height;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 1);
      final heightFactor = 0.3 + 0.7 * _random.nextDouble();
      final barHeight = maxHeight * heightFactor;

      final isPlayed = i / barCount < progress;

      final paint = Paint()
        ..color = isPlayed
            ? const Color(0xFF25D366)
            : Colors.grey[400]!
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      canvas.drawLine(
        Offset(x + barWidth / 2, (maxHeight - barHeight) / 2),
        Offset(x + barWidth / 2, (maxHeight + barHeight) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
  }
}

enum MessageType { image, video, audio, document, file }

class _ChatMessage {
  final MessageType type;
  final String url;
  final String fileName;
  final int? fileSize;
  final Duration? duration;
  final bool isOutgoing;
  final String time;

  const _ChatMessage({
    required this.type,
    required this.url,
    required this.fileName,
    this.fileSize,
    this.duration,
    required this.isOutgoing,
    required this.time,
  });
}
