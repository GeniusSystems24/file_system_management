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
  double _demoProgress = 0.45;
  bool _isPlaying = false;

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
      body: Column(
        children: [
          // Progress Slider
          _buildProgressControl(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildImageTab(),
                _buildVideoTab(),
                _buildAudioTab(),
                _buildFileTab(),
                _buildArchiveTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Text('Progress: '),
          Expanded(
            child: Slider(
              value: _demoProgress,
              onChanged: (value) => setState(() => _demoProgress = value),
            ),
          ),
          Text('${(_demoProgress * 100).toInt()}%'),
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
          'Downloading State',
          ImageMessageTransferWidget(
            thumbnailUrl: 'https://picsum.photos/400/300',
            fileName: 'vacation_photo.jpg',
            fileSize: 2.5 * 1024 * 1024,
            progress: _demoProgress,
            status: TransferStatus.running,
            onTap: () {},
            onCancel: () {},
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Completed State',
          ImageMessageTransferWidget(
            thumbnailUrl: 'https://picsum.photos/400/300',
            fileName: 'sunset.jpg',
            fileSize: 1.8 * 1024 * 1024,
            progress: 1.0,
            status: TransferStatus.completed,
            onTap: () {},
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Pending State',
          ImageMessageTransferWidget(
            thumbnailUrl: 'https://picsum.photos/400/300',
            fileName: 'mountains.png',
            fileSize: 3.2 * 1024 * 1024,
            progress: 0.0,
            status: TransferStatus.pending,
            onTap: () {},
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
ImageMessageTransferWidget(
  thumbnailUrl: 'https://example.com/thumb.jpg',
  fileName: 'photo.jpg',
  fileSize: 2.5 * 1024 * 1024,
  progress: 0.45,
  status: TransferStatus.running,
  onTap: () => openImage(),
  onCancel: () => cancelDownload(),
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
          'Downloading State',
          VideoMessageTransferWidget(
            thumbnailUrl: 'https://picsum.photos/400/225',
            fileName: 'birthday_video.mp4',
            fileSize: 25 * 1024 * 1024,
            duration: const Duration(minutes: 3, seconds: 45),
            progress: _demoProgress,
            status: TransferStatus.running,
            onTap: () {},
            onCancel: () {},
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Completed State',
          VideoMessageTransferWidget(
            thumbnailUrl: 'https://picsum.photos/400/225',
            fileName: 'tutorial.mp4',
            fileSize: 50 * 1024 * 1024,
            duration: const Duration(minutes: 10, seconds: 30),
            progress: 1.0,
            status: TransferStatus.completed,
            onTap: () {},
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
VideoMessageTransferWidget(
  thumbnailUrl: 'https://example.com/thumb.jpg',
  fileName: 'video.mp4',
  fileSize: 25 * 1024 * 1024,
  duration: Duration(minutes: 3, seconds: 45),
  progress: 0.45,
  status: TransferStatus.running,
  onTap: () => playVideo(),
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
          'Downloading State',
          AudioMessageTransferWidget(
            fileName: 'voice_message.mp3',
            fileSize: 500 * 1024,
            duration: const Duration(seconds: 45),
            waveform: _generateWaveform(),
            progress: _demoProgress,
            status: TransferStatus.running,
            isPlaying: false,
            playbackProgress: 0,
            onTap: () {},
            onCancel: () {},
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Playing State',
          AudioMessageTransferWidget(
            fileName: 'podcast.mp3',
            fileSize: 5 * 1024 * 1024,
            duration: const Duration(minutes: 5),
            waveform: _generateWaveform(),
            progress: 1.0,
            status: TransferStatus.completed,
            isPlaying: _isPlaying,
            playbackProgress: 0.35,
            onTap: () => setState(() => _isPlaying = !_isPlaying),
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
AudioMessageTransferWidget(
  fileName: 'audio.mp3',
  fileSize: 5 * 1024 * 1024,
  duration: Duration(minutes: 5),
  waveform: [0.2, 0.5, 0.8, 0.3, ...],
  progress: 1.0,
  status: TransferStatus.completed,
  isPlaying: true,
  playbackProgress: 0.35,
  onTap: () => togglePlay(),
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
            fileName: 'project_report.pdf',
            fileSize: 2.3 * 1024 * 1024,
            extension: 'pdf',
            progress: _demoProgress,
            status: TransferStatus.running,
            onTap: () {},
            onCancel: () {},
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Spreadsheet',
          FileMessageTransferWidget(
            fileName: 'budget_2024.xlsx',
            fileSize: 1.5 * 1024 * 1024,
            extension: 'xlsx',
            progress: 1.0,
            status: TransferStatus.completed,
            onTap: () {},
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Presentation',
          FileMessageTransferWidget(
            fileName: 'quarterly_review.pptx',
            fileSize: 8.7 * 1024 * 1024,
            extension: 'pptx',
            progress: 0.0,
            status: TransferStatus.pending,
            onTap: () {},
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
FileMessageTransferWidget(
  fileName: 'document.pdf',
  fileSize: 2.3 * 1024 * 1024,
  extension: 'pdf',
  progress: 0.45,
  status: TransferStatus.running,
  onTap: () => openFile(),
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
            fileName: 'photos_backup.zip',
            fileSize: 150 * 1024 * 1024,
            extension: 'zip',
            progress: _demoProgress,
            status: TransferStatus.running,
            onTap: () {},
            onCancel: () {},
          ),
        ),
        const SizedBox(height: 16),

        _buildDemoContainer(
          'Completed Archive',
          FileMessageTransferWidget(
            fileName: 'project_files.rar',
            fileSize: 45 * 1024 * 1024,
            extension: 'rar',
            progress: 1.0,
            status: TransferStatus.completed,
            onTap: () {},
          ),
        ),

        const SizedBox(height: 24),
        _buildCodeSnippet('''
FileMessageTransferWidget(
  fileName: 'archive.zip',
  fileSize: 150 * 1024 * 1024,
  extension: 'zip',
  progress: 0.45,
  status: TransferStatus.running,
  onTap: () => extractArchive(),
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
