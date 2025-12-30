import 'dart:async';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing all message transfer widgets with REAL download functionality.
/// This screen demonstrates various widget types with actual file downloads.
class MessageWidgetsDemoScreen extends StatefulWidget {
  final SocialSkin currentSkin;

  const MessageWidgetsDemoScreen({super.key, required this.currentSkin});

  @override
  State<MessageWidgetsDemoScreen> createState() =>
      _MessageWidgetsDemoScreenState();
}

class _MessageWidgetsDemoScreenState extends State<MessageWidgetsDemoScreen> {
  final _controller = TransferController.instance;
  bool _isInitialized = false;
  String? _initError;

  // Track active downloads
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, TransferProgress> _progressMap = {};

  // Real downloadable URLs
  static const _mediaUrls = {
    // Real Images (Unsplash - direct download)
    'image_1':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
    'image_2':
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&q=80',
    'image_3':
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
    'image_4':
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
    'image_5':
        'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=600&q=80',

    // Thumbnails
    'thumb_1':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100&q=60',
    'thumb_2':
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=100&q=60',
    'thumb_3':
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=100&q=60',

    // Real Videos (sample-videos.com)
    'video_1mb':
        'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4',
    'video_2mb':
        'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_2mb.mp4',
    'video_5mb':
        'https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_5mb.mp4',

    // Real Audio
    'audio_1': 'https://sample-videos.com/audio/mp3/crowd-cheering.mp3',
    'audio_2': 'https://sample-videos.com/audio/mp3/wave.mp3',

    // Real Documents
    'pdf_1': 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
    'pdf_2': 'https://sample-videos.com/pdf/Sample-pdf-5mb.pdf',

    // Real Archives
    'zip_1mb': 'https://sample-videos.com/zip/1mb.zip',
    'zip_5mb': 'https://sample-videos.com/zip/5mb.zip',
  };

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      if (!_controller.isInitialized) {
        await _controller.initialize();
      }
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _initError = e.toString());
      }
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  /// Get theme data based on current skin
  SocialTransferThemeData get _themeData {
    switch (widget.currentSkin) {
      case SocialSkin.whatsapp:
        return SocialTransferThemeData.whatsapp();
      case SocialSkin.telegram:
        return SocialTransferThemeData.telegram();
      case SocialSkin.instagram:
        return SocialTransferThemeData.instagram();
      case SocialSkin.custom:
        return SocialTransferThemeData.of(context);
    }
  }

  /// Create real download stream using TransferController
  Stream<TransferProgress> _createDownloadStream(DownloadPayload payload) {
    final controller = StreamController<TransferProgress>();

    _controller.download(url: payload.url, fileName: payload.fileName).then((
      result,
    ) {
      result.fold(
        onSuccess: (stream) {
          stream.listen(
            (transfer) {
              controller.add(
                TransferProgress(
                  bytesTransferred:
                      (transfer.progress *
                              (payload.expectedSize ?? 1024 * 1024))
                          .round(),
                  totalBytes: payload.expectedSize ?? 1024 * 1024,
                  bytesPerSecond: transfer.speed,
                  status: _mapStatus(transfer.status),
                  errorMessage: transfer.isFailed ? 'فشل التحميل' : null,
                ),
              );

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
    });

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
      default:
        return TransferStatus.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(extensions: [_themeData]),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحميل حقيقي - ويدجت الرسائل'),
          actions: [
            Chip(
              label: Text(_getSkinName()),
              backgroundColor: _themeData.primaryColor.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'خطأ في التهيئة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_initError!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeController,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تهيئة محرك التحميل...'),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: _getBackgroundColor()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),

          const SizedBox(height: 16),
          _buildSectionHeader('صور حقيقية للتحميل', Icons.image),
          const SizedBox(height: 8),
          _buildRealImageMessages(),

          const SizedBox(height: 24),
          _buildSectionHeader('فيديوهات حقيقية للتحميل', Icons.videocam),
          const SizedBox(height: 8),
          _buildRealVideoMessages(),

          const SizedBox(height: 24),
          _buildSectionHeader('ملفات صوتية حقيقية', Icons.audiotrack),
          const SizedBox(height: 8),
          _buildRealAudioMessages(),

          const SizedBox(height: 24),
          _buildSectionHeader('ملفات حقيقية للتحميل', Icons.insert_drive_file),
          const SizedBox(height: 8),
          _buildRealFileMessages(),

          const SizedBox(height: 24),
          _buildSectionHeader('مستندات PDF حقيقية', Icons.description),
          const SizedBox(height: 8),
          _buildRealDocumentMessages(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: _themeData.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: _themeData.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'تحميل ملفات حقيقية',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _themeData.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر التحميل لبدء تحميل الملفات الحقيقية. '
              'يمكنك إيقاف/استئناف/إلغاء التحميل.',
              style: TextStyle(color: _themeData.subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  String _getSkinName() {
    switch (widget.currentSkin) {
      case SocialSkin.whatsapp:
        return 'WhatsApp';
      case SocialSkin.telegram:
        return 'Telegram';
      case SocialSkin.instagram:
        return 'Instagram';
      case SocialSkin.custom:
        return 'مخصص';
    }
  }

  Color _getBackgroundColor() {
    switch (widget.currentSkin) {
      case SocialSkin.whatsapp:
        return const Color(0xFFECE5DD);
      case SocialSkin.telegram:
        return const Color(0xFF0E1621);
      case SocialSkin.instagram:
        return const Color(0xFFFAFAFA);
      case SocialSkin.custom:
        return Theme.of(context).scaffoldBackgroundColor;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _themeData.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _themeData.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _themeData.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealImageMessages() {
    return Column(
      children: [
        // Image 1 - Landscape Mountain
        _buildMessageRow(
          isOutgoing: true,
          label: 'صورة جبال - 800x600',
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_1']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 280,
            height: 200,
            fileSize: 150 * 1024, // ~150 KB
            caption: 'منظر جبلي رائع من جبال الألب',
            showCaption: true,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Image 2 - Nature
        _buildMessageRow(
          isOutgoing: false,
          label: 'صورة طبيعة - تحميل حقيقي',
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_2']!,
            thumbnailUrl: _mediaUrls['thumb_2'],
            width: 260,
            height: 180,
            fileSize: 120 * 1024,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Image 3 - Beach
        _buildMessageRow(
          isOutgoing: true,
          label: 'صورة شاطئ استوائي',
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_3']!,
            thumbnailUrl: _mediaUrls['thumb_3'],
            width: 280,
            height: 170,
            fileSize: 180 * 1024,
            caption: 'شاطئ استوائي جميل 🏖️',
            showCaption: true,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showFileSize: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Image 4 - Forest
        _buildMessageRow(
          isOutgoing: false,
          label: 'صورة غابة',
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_4']!,
            width: 250,
            height: 190,
            fileSize: 200 * 1024,
            enableFullScreen: true,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showEta: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealVideoMessages() {
    return Column(
      children: [
        // Video 1MB
        _buildMessageRow(
          isOutgoing: true,
          label: 'فيديو 1 ميجا - Big Buck Bunny',
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_1mb']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 280,
            height: 160,
            duration: const Duration(minutes: 1, seconds: 30),
            fileSize: 1024 * 1024, // 1 MB
            hasAudio: true,
            showDuration: true,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Video 2MB
        _buildMessageRow(
          isOutgoing: false,
          label: 'فيديو 2 ميجا',
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_2mb']!,
            thumbnailUrl: _mediaUrls['thumb_2'],
            width: 260,
            height: 170,
            duration: const Duration(minutes: 2, seconds: 45),
            fileSize: 2 * 1024 * 1024,
            hasAudio: true,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showEta: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Video 5MB
        _buildMessageRow(
          isOutgoing: true,
          label: 'فيديو 5 ميجا - عالي الجودة',
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_5mb']!,
            thumbnailUrl: _mediaUrls['thumb_3'],
            width: 280,
            height: 158,
            duration: const Duration(minutes: 5, seconds: 15),
            fileSize: 5 * 1024 * 1024,
            hasAudio: true,
            showDuration: true,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              showEta: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealAudioMessages() {
    return Column(
      children: [
        // Audio 1 - Crowd Cheering
        _buildMessageRow(
          isOutgoing: true,
          label: 'صوت تشجيع الجمهور',
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_1']!,
            duration: const Duration(seconds: 27),
            waveform: _generateWaveform(35),
            fileSize: 432 * 1024,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Audio 2 - Wave Sound
        _buildMessageRow(
          isOutgoing: false,
          label: 'صوت أمواج البحر',
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_2']!,
            duration: const Duration(minutes: 1, seconds: 12),
            waveform: _generateWaveform(40),
            fileSize: 980 * 1024,
            animateWaveform: true,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showFileSize: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealFileMessages() {
    return Column(
      children: [
        // ZIP 1MB
        _buildMessageRow(
          isOutgoing: true,
          label: 'ملف مضغوط 1 ميجا',
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_1mb']!,
            fileName: 'sample_archive.zip',
            fileSize: 1024 * 1024,
            extension: 'ZIP',
            iconColor: Colors.orange,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ZIP 5MB
        _buildMessageRow(
          isOutgoing: false,
          label: 'ملف مضغوط 5 ميجا',
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_5mb']!,
            fileName: 'large_archive.zip',
            fileSize: 5 * 1024 * 1024,
            extension: 'ZIP',
            iconColor: Colors.orange,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              showEta: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealDocumentMessages() {
    return Column(
      children: [
        // PDF Small
        _buildMessageRow(
          isOutgoing: true,
          label: 'مستند PDF صغير',
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_1']!,
            fileName: 'table_document.pdf',
            fileSize: 50 * 1024,
            pageCount: 3,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // PDF 5MB
        _buildMessageRow(
          isOutgoing: false,
          label: 'مستند PDF كبير - 5 ميجا',
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_2']!,
            fileName: 'large_document.pdf',
            fileSize: 5 * 1024 * 1024,
            pageCount: 120,
            themeData: _themeData,
            onDownload: _createDownloadStream,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              showEta: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow({
    required bool isOutgoing,
    required Widget child,
    String? label,
  }) {
    return Column(
      crossAxisAlignment:
          isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_download,
                    size: 12,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  List<double> _generateWaveform(int count) {
    final random = DateTime.now().millisecond;
    return List.generate(count, (i) {
      final base = ((i + random) % 10) / 10;
      return 0.2 + base * 0.8;
    });
  }
}
