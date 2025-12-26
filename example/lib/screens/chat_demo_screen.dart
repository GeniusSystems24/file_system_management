import 'dart:typed_data';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import '../providers/mock_transfer_provider.dart';

/// Demo screen showing all message widget types in a chat-like interface.
class ChatDemoScreen extends StatefulWidget {
  final SocialSkin currentSkin;

  const ChatDemoScreen({
    super.key,
    required this.currentSkin,
  });

  @override
  State<ChatDemoScreen> createState() => _ChatDemoScreenState();
}

class _ChatDemoScreenState extends State<ChatDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MockTransferProvider _mockProvider = MockTransferProvider();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: Text(_getSkinName()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.audiotrack), text: 'صوت'),
            Tab(icon: Icon(Icons.image), text: 'صور'),
            Tab(icon: Icon(Icons.videocam), text: 'فيديو'),
            Tab(icon: Icon(Icons.insert_drive_file), text: 'ملفات'),
            Tab(icon: Icon(Icons.description), text: 'مستندات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAudioTab(),
          _buildImageTab(),
          _buildVideoTab(),
          _buildFileTab(),
          _buildDocumentTab(),
        ],
      ),
    );
  }

  String _getSkinName() {
    return switch (widget.currentSkin) {
      SocialSkin.whatsapp => 'واتساب',
      SocialSkin.telegram => 'تيليجرام',
      SocialSkin.instagram => 'انستجرام',
      SocialSkin.custom => 'مخصص',
    };
  }

  Widget _buildAudioTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('رسائل صوتية'),
        const SizedBox(height: 8),

        // Idle state
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: AudioMessageTransferWidget(
            url: 'https://example.com/audio1.mp3',
            fileName: 'voice_message.mp3',
            fileSize: 256 * 1024,
            duration: const Duration(seconds: 15),
            waveform: _generateWaveform(),
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 256 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Completed state
        _buildMessageBubble(
          direction: BubbleDirection.outgoing,
          child: AudioMessageTransferWidget(
            url: 'https://example.com/audio2.mp3',
            filePath: '/completed/audio.mp3',
            fileName: 'voice_note.mp3',
            fileSize: 512 * 1024,
            duration: const Duration(seconds: 30),
            waveform: _generateWaveform(),
            initialState: TransferWidgetState.completed,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
            ),
            onPlay: () => _showSnackBar('Playing audio...'),
          ),
        ),

        const SizedBox(height: 16),

        // Auto-start demo
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: AudioMessageTransferWidget(
            url: 'https://example.com/audio3.mp3',
            fileName: 'long_audio.mp3',
            fileSize: 1024 * 1024,
            duration: const Duration(minutes: 2, seconds: 30),
            waveform: _generateWaveform(),
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
              autoStart: true,
            ),
            onDownload: (payload) => _mockProvider.mockSlowTransfer(
              totalBytes: payload.expectedSize ?? 1024 * 1024,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('رسائل صور'),
        const SizedBox(height: 8),

        // Idle state with thumbnail
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: ImageMessageTransferWidget(
            url: 'https://example.com/image1.jpg',
            thumbnailBytes: _generatePlaceholderImage(),
            fileName: 'photo.jpg',
            fileSize: 2 * 1024 * 1024,
            width: 250,
            height: 180,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 2 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // With caption
        _buildMessageBubble(
          direction: BubbleDirection.outgoing,
          child: ImageMessageTransferWidget(
            url: 'https://example.com/image2.jpg',
            thumbnailBytes: _generatePlaceholderImage(),
            fileName: 'sunset.jpg',
            fileSize: 3 * 1024 * 1024,
            width: 250,
            height: 180,
            showCaption: true,
            caption: 'غروب الشمس الجميل في البحر 🌅',
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
              autoStart: true,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 3 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Completed
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: ImageMessageTransferWidget(
            url: 'https://example.com/image3.jpg',
            filePath: '/completed/image.jpg',
            thumbnailBytes: _generatePlaceholderImage(),
            fileName: 'nature.jpg',
            fileSize: 1 * 1024 * 1024,
            width: 250,
            height: 180,
            initialState: TransferWidgetState.completed,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
            ),
            onFullScreen: (path) => _showSnackBar('Opening full screen...'),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('رسائل فيديو'),
        const SizedBox(height: 8),

        // Video with duration
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: VideoMessageTransferWidget(
            url: 'https://example.com/video1.mp4',
            thumbnailBytes: _generatePlaceholderImage(),
            fileName: 'funny_video.mp4',
            fileSize: 15 * 1024 * 1024,
            duration: const Duration(minutes: 1, seconds: 30),
            width: 250,
            height: 180,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
            ),
            onDownload: (payload) => _mockProvider.mockSlowTransfer(
              totalBytes: payload.expectedSize ?? 15 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Muted video
        _buildMessageBubble(
          direction: BubbleDirection.outgoing,
          child: VideoMessageTransferWidget(
            url: 'https://example.com/video2.mp4',
            thumbnailBytes: _generatePlaceholderImage(),
            fileName: 'timelapse.mp4',
            fileSize: 8 * 1024 * 1024,
            duration: const Duration(seconds: 45),
            hasAudio: false,
            width: 250,
            height: 180,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
              autoStart: true,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 8 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Completed video
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: VideoMessageTransferWidget(
            url: 'https://example.com/video3.mp4',
            filePath: '/completed/video.mp4',
            thumbnailBytes: _generatePlaceholderImage(),
            fileName: 'movie.mp4',
            fileSize: 50 * 1024 * 1024,
            duration: const Duration(minutes: 5, seconds: 20),
            width: 250,
            height: 180,
            initialState: TransferWidgetState.completed,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
            ),
            onPlay: (path) => _showSnackBar('Playing video...'),
          ),
        ),
      ],
    );
  }

  Widget _buildFileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('ملفات عامة'),
        const SizedBox(height: 8),

        // ZIP file
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: FileMessageTransferWidget(
            url: 'https://example.com/archive.zip',
            fileName: 'project_files.zip',
            fileSize: 25 * 1024 * 1024,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 25 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // APK file
        _buildMessageBubble(
          direction: BubbleDirection.outgoing,
          child: FileMessageTransferWidget(
            url: 'https://example.com/app.apk',
            fileName: 'MyApp.apk',
            fileSize: 45 * 1024 * 1024,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
              autoStart: true,
            ),
            onDownload: (payload) => _mockProvider.mockSlowTransfer(
              totalBytes: payload.expectedSize ?? 45 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Failed file (with retry)
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: FileMessageTransferWidget(
            url: 'https://example.com/failed.exe',
            fileName: 'setup.exe',
            fileSize: 100 * 1024 * 1024,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
              autoStart: true,
            ),
            onDownload: (payload) => _mockProvider.mockFailingTransfer(
              totalBytes: payload.expectedSize ?? 100 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Completed file
        _buildMessageBubble(
          direction: BubbleDirection.outgoing,
          child: FileMessageTransferWidget(
            url: 'https://example.com/complete.zip',
            filePath: '/completed/archive.zip',
            fileName: 'backup.zip',
            fileSize: 50 * 1024 * 1024,
            initialState: TransferWidgetState.completed,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
            ),
            onOpen: (path) => _showSnackBar('Opening file...'),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('مستندات'),
        const SizedBox(height: 8),

        // PDF document
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: DocumentMessageTransferWidget(
            url: 'https://example.com/report.pdf',
            fileName: 'التقرير_السنوي.pdf',
            fileSize: 5 * 1024 * 1024,
            pageCount: 25,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 5 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Word document
        _buildMessageBubble(
          direction: BubbleDirection.outgoing,
          child: DocumentMessageTransferWidget(
            url: 'https://example.com/document.docx',
            fileName: 'عقد_العمل.docx',
            fileSize: 2 * 1024 * 1024,
            pageCount: 10,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
              autoStart: true,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 2 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Excel spreadsheet
        _buildMessageBubble(
          direction: BubbleDirection.incoming,
          child: DocumentMessageTransferWidget(
            url: 'https://example.com/data.xlsx',
            fileName: 'البيانات_المالية.xlsx',
            fileSize: 1 * 1024 * 1024,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.incoming,
              autoStart: true,
            ),
            onDownload: (payload) => _mockProvider.mockDownload(
              totalBytes: payload.expectedSize ?? 1 * 1024 * 1024,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // PowerPoint
        _buildMessageBubble(
          direction: BubbleDirection.outgoing,
          child: DocumentMessageTransferWidget(
            url: 'https://example.com/presentation.pptx',
            filePath: '/completed/presentation.pptx',
            fileName: 'عرض_المشروع.pptx',
            fileSize: 8 * 1024 * 1024,
            pageCount: 30,
            initialState: TransferWidgetState.completed,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
            ),
            onOpen: (path) => _showSnackBar('Opening presentation...'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required BubbleDirection direction,
    required Widget child,
  }) {
    return Align(
      alignment: direction == BubbleDirection.outgoing
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: child,
    );
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
    // Return a simple 1x1 pixel placeholder
    // In a real app, you would use actual thumbnail bytes
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x18, 0xDD,
      0x8D, 0xB5, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
      0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
