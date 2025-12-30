import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_system_management/file_system_management.dart';

/// Demo screen showcasing the video download and player widget.
class VideoPlayerDemoScreen extends StatefulWidget {
  const VideoPlayerDemoScreen({super.key});

  @override
  State<VideoPlayerDemoScreen> createState() => _VideoPlayerDemoScreenState();
}

class _VideoPlayerDemoScreenState extends State<VideoPlayerDemoScreen> {
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;
  SocialSkin _currentSkin = SocialSkin.whatsapp;

  // Sample video URLs from public sources
  static const _sampleVideos = [
    _VideoSample(
      title: 'Big Buck Bunny',
      url: 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
      duration: Duration(minutes: 9, seconds: 56),
      fileSize: 158008374, // ~150 MB
      description: 'A large rabbit deals with three bullying rodents.',
    ),
    _VideoSample(
      title: 'Elephant Dream',
      url: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      duration: Duration(minutes: 10, seconds: 53),
      fileSize: 168943616, // ~161 MB
      description: 'Two friends explore a weird mechanical world.',
    ),
    _VideoSample(
      title: 'Sintel',
      url: 'https://storage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
      duration: Duration(minutes: 14, seconds: 48),
      fileSize: 190612480, // ~182 MB
      description: 'A girl searches for her baby dragon.',
    ),
    _VideoSample(
      title: 'Tears of Steel',
      url: 'https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg',
      duration: Duration(minutes: 12, seconds: 14),
      fileSize: 185267200, // ~177 MB
      description: 'A group of warriors try to save the world.',
    ),
    _VideoSample(
      title: 'For Bigger Fun',
      url: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
      duration: Duration(seconds: 15),
      fileSize: 1540096, // ~1.5 MB
      description: 'Short video clip for quick testing.',
    ),
    _VideoSample(
      title: 'For Bigger Blazes',
      url: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
      duration: Duration(seconds: 15),
      fileSize: 1068564, // ~1 MB
      description: 'Another short video clip.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      final controller = TransferController.instance;
      if (!controller.isInitialized) {
        await controller.initialize();
      }
      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  SocialTransferThemeData get _themeData {
    switch (_currentSkin) {
      case SocialSkin.whatsapp:
        return SocialTransferThemeData.whatsApp();
      case SocialSkin.telegram:
        return SocialTransferThemeData.telegram();
      case SocialSkin.instagram:
        return SocialTransferThemeData.instagram();
      case SocialSkin.custom:
        return SocialTransferThemeData.custom(
          primaryColor: Colors.deepPurple,
          bubbleColor: Colors.deepPurple.shade50,
        );
    }
  }

  Stream<TransferProgress> _createDownloadStream(DownloadPayload payload) {
    final controller = StreamController<TransferProgress>();

    TransferController.instance
        .download(url: payload.url, fileName: payload.fileName)
        .then(
      (result) {
        result.fold(
          onSuccess: (stream) {
            stream.listen(
              (transfer) {
                controller.add(TransferProgress(
                  bytesTransferred:
                      (transfer.progress * (payload.expectedSize ?? 1024 * 1024))
                          .round(),
                  totalBytes: payload.expectedSize ?? 1024 * 1024,
                  bytesPerSecond: transfer.speed,
                  status: _mapStatus(transfer.status),
                  errorMessage: transfer.isFailed ? 'Download failed' : null,
                ));

                if (transfer.isComplete || transfer.isFailed) {
                  controller.close();
                }
              },
              onError: (e) {
                controller.addError(e);
                controller.close();
              },
            );
          },
          onFailure: (error) {
            controller.addError(error);
            controller.close();
          },
        );
      },
    );

    return controller.stream;
  }

  TransferStatus _mapStatus(TransferStatusEntity status) {
    switch (status) {
      case TransferStatusEntity.pending:
        return TransferStatus.pending;
      case TransferStatusEntity.running:
        return TransferStatus.running;
      case TransferStatusEntity.paused:
        return TransferStatus.paused;
      case TransferStatusEntity.complete:
        return TransferStatus.completed;
      case TransferStatusEntity.failed:
        return TransferStatus.failed;
      case TransferStatusEntity.canceled:
        return TransferStatus.cancelled;
      case TransferStatusEntity.waitingToRetry:
        return TransferStatus.waitingToRetry;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [_themeData],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Video Player Demo'),
          actions: [
            // Skin selector chip
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_currentSkin.name),
                backgroundColor: _themeData.primaryColor.withOpacity(0.2),
              ),
            ),
            PopupMenuButton<SocialSkin>(
              icon: const Icon(Icons.palette),
              onSelected: (skin) => setState(() => _currentSkin = skin),
              itemBuilder: (context) => SocialSkin.values.map((skin) {
                return PopupMenuItem(
                  value: skin,
                  child: Row(
                    children: [
                      if (skin == _currentSkin)
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(skin.name.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing transfer controller...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeController,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section header
        _buildSectionHeader(
          'Video Download & Player',
          Icons.play_circle_fill,
          'Tap on a video to download and play it',
        ),
        const SizedBox(height: 16),

        // Quick test videos (small files)
        _buildSubsectionHeader('Quick Test Videos', 'Small files for testing'),
        const SizedBox(height: 12),

        ..._sampleVideos
            .where((v) => v.fileSize < 5000000) // Less than 5 MB
            .map((video) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildVideoCard(video),
                )),

        const SizedBox(height: 24),

        // Full videos (larger files)
        _buildSubsectionHeader('Full Videos', 'Larger files with full features'),
        const SizedBox(height: 12),

        ..._sampleVideos
            .where((v) => v.fileSize >= 5000000) // 5 MB and above
            .map((video) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildVideoCard(video),
                )),

        const SizedBox(height: 24),

        // Configuration examples
        _buildSectionHeader(
          'Configuration Examples',
          Icons.settings,
          'Different player configurations',
        ),
        const SizedBox(height: 16),

        _buildConfigExample(
          'Auto Play',
          'Video starts playing automatically after download',
          VideoPlayerConfig(autoPlay: true, autoStartDownload: false),
          _sampleVideos[4], // Small video
        ),

        const SizedBox(height: 16),

        _buildConfigExample(
          'Looping',
          'Video loops continuously',
          VideoPlayerConfig(looping: true),
          _sampleVideos[5], // Small video
        ),

        const SizedBox(height: 16),

        _buildConfigExample(
          'No Controls',
          'Minimal player without controls',
          VideoPlayerConfig(showControls: false),
          _sampleVideos[4],
        ),

        const SizedBox(height: 32),

        // Display Mode Section
        _buildSectionHeader(
          'Display Modes',
          Icons.fullscreen,
          'Choose how videos are displayed',
        ),
        const SizedBox(height: 16),

        // Inline Mode
        _buildDisplayModeExample(
          'Inline Mode (Default)',
          'Video plays within the card - like WhatsApp',
          VideoDisplayMode.inline,
          _sampleVideos[4],
          Icons.picture_in_picture,
        ),

        const SizedBox(height: 16),

        // Fullscreen Mode
        _buildDisplayModeExample(
          'Fullscreen Mode',
          'Opens dedicated player screen - like Telegram',
          VideoDisplayMode.fullscreen,
          _sampleVideos[5],
          Icons.fullscreen,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeData.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _themeData.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Icon(Icons.video_library, color: _themeData.primaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoCard(_VideoSample video) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video player widget
          SizedBox(
            height: 200,
            width: double.infinity,
            child: VideoDownloadPlayerWidget(
              url: video.url,
              thumbnailUrl: video.thumbnailUrl,
              fileName: video.title.replaceAll(' ', '_').toLowerCase() + '.mp4',
              fileSize: video.fileSize,
              duration: video.duration,
              themeData: _themeData,
              width: double.infinity,
              height: 200,
              onDownload: _createDownloadStream,
              onDownloadComplete: (path) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloaded: ${video.title}'),
                    backgroundColor: _themeData.successColor,
                  ),
                );
              },
              onPlayStart: () {
                debugPrint('Playing: ${video.title}');
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $error'),
                    backgroundColor: _themeData.errorColor,
                  ),
                );
              },
            ),
          ),
          // Video info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildInfoChip(Icons.timer, _formatDuration(video.duration)),
                    _buildInfoChip(Icons.storage, _formatBytes(video.fileSize)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigExample(
    String title,
    String description,
    VideoPlayerConfig config,
    _VideoSample video,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: VideoDownloadPlayerWidget(
                  url: video.url,
                  thumbnailUrl: video.thumbnailUrl,
                  fileName: '${title.toLowerCase().replaceAll(' ', '_')}_${video.title.replaceAll(' ', '_')}.mp4',
                  fileSize: video.fileSize,
                  duration: video.duration,
                  config: config,
                  themeData: _themeData,
                  width: double.infinity,
                  height: 180,
                  onDownload: _createDownloadStream,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayModeExample(
    String title,
    String description,
    VideoDisplayMode mode,
    _VideoSample video,
    IconData modeIcon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _themeData.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(modeIcon, color: _themeData.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: VideoDownloadPlayerWidget(
                  url: video.url,
                  thumbnailUrl: video.thumbnailUrl,
                  fileName: '${mode.name}_${video.title.replaceAll(' ', '_')}.mp4',
                  fileSize: video.fileSize,
                  duration: video.duration,
                  title: video.title,
                  subtitle: video.description,
                  config: VideoPlayerConfig(
                    displayMode: mode,
                    autoPlay: true,
                  ),
                  themeData: _themeData,
                  width: double.infinity,
                  height: 180,
                  onDownload: _createDownloadStream,
                  onPlayStart: () {
                    debugPrint('Playing in $mode mode: ${video.title}');
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: mode == VideoDisplayMode.fullscreen
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode == VideoDisplayMode.fullscreen
                        ? Icons.touch_app
                        : Icons.play_circle,
                    size: 16,
                    color: mode == VideoDisplayMode.fullscreen
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mode == VideoDisplayMode.fullscreen
                        ? 'Tap to open fullscreen player'
                        : 'Tap to play inline',
                    style: TextStyle(
                      fontSize: 12,
                      color: mode == VideoDisplayMode.fullscreen
                          ? Colors.blue.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Sample video data class.
class _VideoSample {
  final String title;
  final String url;
  final String thumbnailUrl;
  final Duration duration;
  final int fileSize;
  final String description;

  const _VideoSample({
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    required this.duration,
    required this.fileSize,
    required this.description,
  });
}
