import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates message widgets for chat applications.
///
/// Ready-to-use widgets for displaying file transfers in chat UIs.
class MessageWidgetsScreen extends StatefulWidget {
  const MessageWidgetsScreen({super.key});

  @override
  State<MessageWidgetsScreen> createState() => _MessageWidgetsScreenState();
}

class _MessageWidgetsScreenState extends State<MessageWidgetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Message Widgets'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'Image'),
            Tab(icon: Icon(Icons.videocam), text: 'Video'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Audio'),
            Tab(icon: Icon(Icons.insert_drive_file), text: 'File'),
            Tab(icon: Icon(Icons.folder_zip), text: 'Archive'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImageTab(),
          _buildVideoTab(),
          _buildAudioTab(),
          _buildFileTab(),
          _buildArchiveTab(),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Image Message Widget'),
        const SizedBox(height: 8),
        _buildDescription(
          'Display image transfers with thumbnail preview, blur effect, '
          'and download progress overlay.',
        ),
        const SizedBox(height: 16),

        // Demo widgets
        _buildDemoContainer(
          'Image Message',
          ImageMessageTransferWidget(
            url: 'https://picsum.photos/400/300',
            thumbnailUrl: 'https://picsum.photos/400/300',
            fileName: 'vacation_photo.jpg',
            fileSize: (2.5 * 1024 * 1024).toInt(),
            width: 280,
            height: 200,
            onDownload: (_) async* {
              // Demo: Would yield TransferPayload updates
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildCodeSnippet('''
ImageMessageTransferWidget(
  url: 'https://example.com/image.jpg',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  fileName: 'photo.jpg',
  fileSize: 2500000,
  width: 280,
  height: 200,
  onDownload: (payload) async* {
    yield* controller.download(url: payload.url);
  },
)'''),
      ],
    );
  }

  Widget _buildVideoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Video Message Widget'),
        const SizedBox(height: 8),
        _buildDescription(
          'Display video transfers with thumbnail, duration badge, '
          'play button, and download progress.',
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Video Message',
          VideoMessageTransferWidget(
            url: 'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4',
            thumbnailUrl: 'https://picsum.photos/400/225',
            fileName: 'birthday_video.mp4',
            fileSize: 25 * 1024 * 1024,
            duration: const Duration(minutes: 3, seconds: 45),
            width: 280,
            height: 180,
            onDownload: (_) async* {
              // Demo: Would yield TransferPayload updates
            },
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
VideoMessageTransferWidget(
  url: 'https://example.com/video.mp4',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  fileName: 'video.mp4',
  fileSize: 25000000,
  duration: Duration(minutes: 3, seconds: 45),
  width: 280,
  height: 180,
  onPlay: (filePath) => openVideoPlayer(filePath),
  onDownload: (payload) async* {
    yield* controller.download(url: payload.url);
  },
)'''),
      ],
    );
  }

  Widget _buildAudioTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Audio Message Widget'),
        const SizedBox(height: 8),
        _buildDescription(
          'Display audio transfers with waveform visualization, '
          'playback controls, and duration.',
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Audio Message',
          AudioMessageTransferWidget(
            url: 'https://sample-videos.com/audio/mp3/crowd-cheering.mp3',
            fileName: 'voice_message.mp3',
            fileSize: 500 * 1024,
            duration: const Duration(seconds: 45),
            waveform: _generateWaveform(),
            onDownload: (_) async* {
              // Demo: Would yield TransferPayload updates
            },
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
AudioMessageTransferWidget(
  url: 'https://example.com/audio.mp3',
  fileName: 'audio.mp3',
  fileSize: 5000000,
  duration: Duration(minutes: 5),
  waveform: [0.2, 0.5, 0.8, 0.3, ...],
  isPlaying: false,
  onPlay: () => playAudio(),
  onDownload: (payload) async* {
    yield* controller.download(url: payload.url);
  },
)'''),
      ],
    );
  }

  Widget _buildFileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('File Message Widget'),
        const SizedBox(height: 8),
        _buildDescription(
          'Display generic file transfers with file type icon, '
          'name, size, and download progress.',
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'PDF Document',
          FileMessageTransferWidget(
            url: 'https://example.com/report.pdf',
            fileName: 'project_report.pdf',
            fileSize: (2.3 * 1024 * 1024).toInt(),
            extension: 'pdf',
            onDownload: (_) async* {
              // Demo: Would yield TransferPayload updates
            },
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Spreadsheet',
          FileMessageTransferWidget(
            url: 'https://example.com/budget.xlsx',
            fileName: 'budget_2024.xlsx',
            fileSize: (1.5 * 1024 * 1024).toInt(),
            extension: 'xlsx',
            onDownload: (_) async* {
              // Demo: Would yield TransferPayload updates
            },
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
FileMessageTransferWidget(
  url: 'https://example.com/document.pdf',
  fileName: 'document.pdf',
  fileSize: 2300000,
  extension: 'pdf',
  onDownload: (payload) async* {
    yield* controller.download(url: payload.url);
  },
)'''),
      ],
    );
  }

  Widget _buildArchiveTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Archive Message Widget'),
        const SizedBox(height: 8),
        _buildDescription(
          'Display archive file transfers (ZIP, RAR, etc.) with '
          'file count indicator and extraction progress.',
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'ZIP Archive',
          FileMessageTransferWidget(
            url: 'https://sample-videos.com/zip/1mb.zip',
            fileName: 'photos_backup.zip',
            fileSize: 150 * 1024 * 1024,
            extension: 'zip',
            onDownload: (_) async* {
              // Demo: Would yield TransferPayload updates
            },
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'RAR Archive',
          FileMessageTransferWidget(
            url: 'https://example.com/project.rar',
            fileName: 'project_files.rar',
            fileSize: 45 * 1024 * 1024,
            extension: 'rar',
            onDownload: (_) async* {
              // Demo: Would yield TransferPayload updates
            },
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
FileMessageTransferWidget(
  url: 'https://example.com/archive.zip',
  fileName: 'archive.zip',
  fileSize: 150000000,
  extension: 'zip',
  onDownload: (payload) async* {
    yield* controller.download(url: payload.url);
  },
)'''),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildDemoContainer(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: child,
        ),
      ],
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Usage Example',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _generateWaveform() {
    return List.generate(30, (i) => (i % 5 + 1) / 5 * 0.8 + 0.2);
  }
}
