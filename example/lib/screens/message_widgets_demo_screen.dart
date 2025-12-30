import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing all message transfer widgets with real content.
/// This screen demonstrates various widget types, states, and configurations.
class MessageWidgetsDemoScreen extends StatefulWidget {
  final SocialSkin currentSkin;

  const MessageWidgetsDemoScreen({
    super.key,
    required this.currentSkin,
  });

  @override
  State<MessageWidgetsDemoScreen> createState() =>
      _MessageWidgetsDemoScreenState();
}

class _MessageWidgetsDemoScreenState extends State<MessageWidgetsDemoScreen> {
  // Real URLs for different media types
  static const _mediaUrls = {
    // Images
    'image_small':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
    'image_medium':
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
    'image_large':
        'https://firebasestorage.googleapis.com/v0/b/skycachefiles.appspot.com/o/smart_school_system.04.png?alt=media&token=fe5ac0a7-3a7c-4a5e-a744-1c4dd15780b7',
    'image_portrait':
        'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=600',
    'image_landscape':
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=900',
    'image_nature':
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=700',

    // Thumbnails
    'thumb_1':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100',
    'thumb_2':
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=100',
    'thumb_3':
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=100',

    // Videos
    'video_1mb':
        'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4',
    'video_5mb':
        'https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_5mb.mp4',
    'video_10mb':
        'https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_10mb.mp4',

    // Audio
    'audio_mp3': 'https://sample-videos.com/audio/mp3/crowd-cheering.mp3',
    'audio_wave': 'https://sample-videos.com/audio/mp3/wave.mp3',

    // Documents
    'pdf_small':
        'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
    'pdf_large': 'https://sample-videos.com/pdf/Sample-pdf-5mb.pdf',

    // Archives
    'zip_file': 'https://sample-videos.com/zip/1mb.zip',
    'zip_large': 'https://sample-videos.com/zip/10mb.zip',
  };

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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [_themeData],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ويدجت الرسائل'),
          actions: [
            Chip(
              label: Text(_getSkinName()),
              backgroundColor: _themeData.primaryColor.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('رسائل الصور', Icons.image),
              const SizedBox(height: 8),
              _buildImageMessages(),

              const SizedBox(height: 24),
              _buildSectionHeader('رسائل الفيديو', Icons.videocam),
              const SizedBox(height: 8),
              _buildVideoMessages(),

              const SizedBox(height: 24),
              _buildSectionHeader('رسائل الصوت', Icons.audiotrack),
              const SizedBox(height: 8),
              _buildAudioMessages(),

              const SizedBox(height: 24),
              _buildSectionHeader('رسائل الملفات', Icons.insert_drive_file),
              const SizedBox(height: 8),
              _buildFileMessages(),

              const SizedBox(height: 24),
              _buildSectionHeader('رسائل المستندات', Icons.description),
              const SizedBox(height: 8),
              _buildDocumentMessages(),

              const SizedBox(height: 24),
              _buildSectionHeader('حالات التحويل المختلفة', Icons.sync),
              const SizedBox(height: 8),
              _buildTransferStatesDemo(),

              const SizedBox(height: 24),
              _buildSectionHeader('إعدادات متنوعة', Icons.settings),
              const SizedBox(height: 8),
              _buildConfigurationExamples(),

              const SizedBox(height: 32),
            ],
          ),
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

  Widget _buildImageMessages() {
    return Column(
      children: [
        // Outgoing image with caption - landscape
        _buildMessageRow(
          isOutgoing: true,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_medium']!,
            thumbnailUrl: _mediaUrls['thumb_2'],
            width: 280,
            height: 200,
            caption: 'منظر طبيعي رائع من جبال الألب!',
            showCaption: true,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming image - small
        _buildMessageRow(
          isOutgoing: false,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_small']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 250,
            height: 180,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing portrait image
        _buildMessageRow(
          isOutgoing: true,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_portrait']!,
            width: 180,
            height: 280,
            caption: 'صورة عمودية جميلة',
            showCaption: true,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming large landscape image
        _buildMessageRow(
          isOutgoing: false,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_landscape']!,
            thumbnailUrl: _mediaUrls['thumb_3'],
            width: 300,
            height: 170,
            fileSize: 2 * 1024 * 1024, // 2 MB
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showFileSize: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing nature image with full screen enabled
        _buildMessageRow(
          isOutgoing: true,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_nature']!,
            width: 260,
            height: 190,
            enableFullScreen: true,
            caption: 'غابة استوائية مذهلة',
            showCaption: true,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessages() {
    return Column(
      children: [
        // Outgoing video - short duration
        _buildMessageRow(
          isOutgoing: true,
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_1mb']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 280,
            height: 160,
            duration: const Duration(minutes: 1, seconds: 30),
            fileSize: 1024 * 1024, // 1 MB
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showFileSize: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming video - medium duration
        _buildMessageRow(
          isOutgoing: false,
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_5mb']!,
            thumbnailUrl: _mediaUrls['thumb_2'],
            width: 260,
            height: 180,
            duration: const Duration(minutes: 5, seconds: 45),
            hasAudio: true,
            fileSize: 5 * 1024 * 1024, // 5 MB
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showSpeed: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing video - long duration
        _buildMessageRow(
          isOutgoing: true,
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_10mb']!,
            thumbnailUrl: _mediaUrls['thumb_3'],
            width: 280,
            height: 158,
            duration: const Duration(minutes: 10, seconds: 15),
            hasAudio: true,
            showDuration: true,
            fileSize: 10 * 1024 * 1024, // 10 MB
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showFileSize: true,
              showSpeed: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming muted video
        _buildMessageRow(
          isOutgoing: false,
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_1mb']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 240,
            height: 135,
            duration: const Duration(seconds: 45),
            hasAudio: false,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioMessages() {
    return Column(
      children: [
        // Outgoing voice message - short
        _buildMessageRow(
          isOutgoing: true,
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_mp3']!,
            duration: const Duration(seconds: 15),
            waveform: _generateWaveform(30),
            fileSize: 150 * 1024, // 150 KB
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming voice message - medium
        _buildMessageRow(
          isOutgoing: false,
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_mp3']!,
            duration: const Duration(minutes: 1, seconds: 30),
            waveform: _generateWaveform(40),
            fileSize: 900 * 1024, // 900 KB
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showFileSize: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing voice message - long
        _buildMessageRow(
          isOutgoing: true,
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_wave']!,
            duration: const Duration(minutes: 3, seconds: 45),
            waveform: _generateWaveform(50),
            animateWaveform: true,
            fileSize: 2 * 1024 * 1024, // 2 MB
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming voice message with playback position
        _buildMessageRow(
          isOutgoing: false,
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_mp3']!,
            duration: const Duration(minutes: 2, seconds: 10),
            waveform: _generateWaveform(35),
            playbackPosition: const Duration(seconds: 45),
            isPlaying: false,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessages() {
    return Column(
      children: [
        // Outgoing ZIP file
        _buildMessageRow(
          isOutgoing: true,
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_file']!,
            fileName: 'مشروع_البرمجة.zip',
            fileSize: 1024 * 1024, // 1 MB
            extension: 'ZIP',
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming Excel file
        _buildMessageRow(
          isOutgoing: false,
          child: FileMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'تقرير_المبيعات_الشهري.xlsx',
            fileSize: 512 * 1024, // 512 KB
            extension: 'XLSX',
            iconColor: Colors.green,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing APK file
        _buildMessageRow(
          isOutgoing: true,
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_large']!,
            fileName: 'تطبيق_الموبايل_v2.0.apk',
            fileSize: 45 * 1024 * 1024, // 45 MB
            extension: 'APK',
            iconColor: const Color(0xFF3DDC84),
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showFileSize: true,
              showSpeed: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming PowerPoint file
        _buildMessageRow(
          isOutgoing: false,
          child: FileMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'عرض_تقديمي_للمشروع.pptx',
            fileSize: 8 * 1024 * 1024, // 8 MB
            extension: 'PPTX',
            iconColor: Colors.orange,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing code file
        _buildMessageRow(
          isOutgoing: true,
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_file']!,
            fileName: 'main.dart',
            fileSize: 25 * 1024, // 25 KB
            extension: 'DART',
            iconColor: const Color(0xFF0175C2),
            customIcon: Icons.code,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentMessages() {
    return Column(
      children: [
        // Outgoing small PDF
        _buildMessageRow(
          isOutgoing: true,
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'عقد_العمل_الجديد.pdf',
            fileSize: 150 * 1024, // 150 KB
            pageCount: 5,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming large PDF
        _buildMessageRow(
          isOutgoing: false,
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_large']!,
            fileName: 'دليل_المستخدم_الشامل.pdf',
            fileSize: 5 * 1024 * 1024, // 5 MB
            pageCount: 120,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showSpeed: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing Word document
        _buildMessageRow(
          isOutgoing: true,
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'تقرير_الأداء_السنوي.docx',
            fileSize: 2 * 1024 * 1024, // 2 MB
            pageCount: 35,
            documentType: DocumentType.word,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showFileSize: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Incoming Excel spreadsheet
        _buildMessageRow(
          isOutgoing: false,
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'البيانات_المالية_2024.xlsx',
            fileSize: 3 * 1024 * 1024, // 3 MB
            pageCount: 15,
            documentType: DocumentType.excel,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Outgoing PowerPoint presentation
        _buildMessageRow(
          isOutgoing: true,
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'خطة_المشروع_2025.pptx',
            fileSize: 15 * 1024 * 1024, // 15 MB
            pageCount: 50,
            documentType: DocumentType.powerpoint,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransferStatesDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'أمثلة على حالات التحويل المختلفة:',
            style: TextStyle(
              color: _themeData.subtitleColor,
              fontSize: 13,
            ),
          ),
        ),

        // Idle state - ready to download
        _buildMessageRow(
          isOutgoing: true,
          label: 'جاهز للتحميل',
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_file']!,
            fileName: 'ملف_جاهز_للتحميل.zip',
            fileSize: 5 * 1024 * 1024,
            initialState: TransferWidgetState.idle,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Pending state
        _buildMessageRow(
          isOutgoing: false,
          label: 'في الانتظار',
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_file']!,
            fileName: 'ملف_في_الانتظار.zip',
            fileSize: 3 * 1024 * 1024,
            initialState: TransferWidgetState.pending,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Completed state
        _buildMessageRow(
          isOutgoing: true,
          label: 'مكتمل',
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_small']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 200,
            height: 150,
            initialState: TransferWidgetState.completed,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Failed state
        _buildMessageRow(
          isOutgoing: false,
          label: 'فشل التحميل',
          child: DocumentMessageTransferWidget(
            url: 'https://invalid-url.example.com/file.pdf',
            fileName: 'ملف_فاشل.pdf',
            fileSize: 10 * 1024 * 1024,
            initialState: TransferWidgetState.failed,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              allowRetry: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'أمثلة على إعدادات مختلفة:',
            style: TextStyle(
              color: _themeData.subtitleColor,
              fontSize: 13,
            ),
          ),
        ),

        // Auto-start enabled
        _buildMessageRow(
          isOutgoing: true,
          label: 'تشغيل تلقائي',
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_small']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 200,
            height: 150,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: true,
              showActionButton: true,
              showSpeed: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // No action button
        _buildMessageRow(
          isOutgoing: false,
          label: 'بدون زر إجراء',
          child: FileMessageTransferWidget(
            url: _mediaUrls['zip_file']!,
            fileName: 'ملف_بدون_زر.zip',
            fileSize: 2 * 1024 * 1024,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              showActionButton: false,
              showFileSize: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Show all info (speed, ETA, size)
        _buildMessageRow(
          isOutgoing: true,
          label: 'عرض كل المعلومات',
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_5mb']!,
            thumbnailUrl: _mediaUrls['thumb_2'],
            width: 260,
            height: 146,
            duration: const Duration(minutes: 3),
            fileSize: 5 * 1024 * 1024,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              showSpeed: true,
              showFileSize: true,
              showEta: true,
              showProgress: true,
              direction: BubbleDirection.outgoing,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Pause/Resume disabled
        _buildMessageRow(
          isOutgoing: false,
          label: 'إيقاف/استئناف معطل',
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_mp3']!,
            duration: const Duration(minutes: 2),
            waveform: _generateWaveform(35),
            fileSize: 1024 * 1024,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              allowPauseResume: false,
              allowCancel: true,
              direction: BubbleDirection.incoming,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Custom action button size
        _buildMessageRow(
          isOutgoing: true,
          label: 'حجم زر مخصص',
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'ملف_بزر_كبير.pdf',
            fileSize: 1024 * 1024,
            pageCount: 10,
            themeData: _themeData,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
              actionButtonSize: 60,
              direction: BubbleDirection.outgoing,
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
                color: _themeData.subtitleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: _themeData.subtitleColor,
                ),
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
