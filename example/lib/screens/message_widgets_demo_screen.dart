import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing all message transfer widgets with real content.
class MessageWidgetsDemoScreen extends StatefulWidget {
  final SocialSkin currentSkin;

  const MessageWidgetsDemoScreen({super.key, required this.currentSkin});

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

    // Thumbnails
    'thumb_1':
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100',
    'thumb_2':
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=100',

    // Videos
    'video_1mb':
        'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4',
    'video_5mb':
        'https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_5mb.mp4',

    // Audio
    'audio_mp3': 'https://sample-videos.com/audio/mp3/crowd-cheering.mp3',

    // Documents
    'pdf_small':
        'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
    'pdf_large': 'https://sample-videos.com/pdf/Sample-pdf-5mb.pdf',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ويدجت الرسائل')),
      body: ListView(
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildImageMessages() {
    return Column(
      children: [
        // Outgoing image with caption
        _buildMessageRow(
          isOutgoing: true,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_medium']!,
            thumbnailUrl: _mediaUrls['thumb_2'],
            width: 280,
            height: 200,
            caption: 'منظر طبيعي رائع!',
            showCaption: true,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Incoming image
        _buildMessageRow(
          isOutgoing: false,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_small']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 250,
            height: 180,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Portrait image
        _buildMessageRow(
          isOutgoing: true,
          child: ImageMessageTransferWidget(
            url: _mediaUrls['image_portrait']!,
            width: 200,
            height: 300,
            config: const TransferWidgetConfig(autoStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessages() {
    return Column(
      children: [
        // Outgoing video
        _buildMessageRow(
          isOutgoing: true,
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_1mb']!,
            thumbnailUrl: _mediaUrls['thumb_1'],
            width: 280,
            height: 160,
            duration: const Duration(minutes: 1, seconds: 30),
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Incoming video (larger)
        _buildMessageRow(
          isOutgoing: false,
          child: VideoMessageTransferWidget(
            url: _mediaUrls['video_5mb']!,
            thumbnailUrl: _mediaUrls['thumb_2'],
            width: 260,
            height: 180,
            duration: const Duration(minutes: 5, seconds: 45),
            hasAudio: true,
            config: const TransferWidgetConfig(autoStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioMessages() {
    return Column(
      children: [
        // Outgoing audio
        _buildMessageRow(
          isOutgoing: true,
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_mp3']!,
            duration: const Duration(seconds: 45),
            waveform: _generateWaveform(30),
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Incoming audio
        _buildMessageRow(
          isOutgoing: false,
          child: AudioMessageTransferWidget(
            url: _mediaUrls['audio_mp3']!,
            duration: const Duration(minutes: 2, seconds: 30),
            waveform: _generateWaveform(40),
            config: const TransferWidgetConfig(autoStart: false),
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
            url: 'https://sample-videos.com/zip/1mb.zip',
            fileName: 'مشروع_البرمجة.zip',
            fileSize: 1024 * 1024,
            extension: 'ZIP',
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Incoming Excel file
        _buildMessageRow(
          isOutgoing: false,
          child: FileMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'تقرير_المبيعات.xlsx',
            fileSize: 512 * 1024,
            extension: 'XLSX',
            iconColor: Colors.green,
            config: const TransferWidgetConfig(autoStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentMessages() {
    return Column(
      children: [
        // Outgoing PDF
        _buildMessageRow(
          isOutgoing: true,
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_small']!,
            fileName: 'عقد_العمل.pdf',
            fileSize: 150 * 1024,
            pageCount: 5,
            config: const TransferWidgetConfig(
              autoStart: false,
              showActionButton: true,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Incoming large PDF
        _buildMessageRow(
          isOutgoing: false,
          child: DocumentMessageTransferWidget(
            url: _mediaUrls['pdf_large']!,
            fileName: 'دليل_المستخدم.pdf',
            fileSize: 5 * 1024 * 1024,
            pageCount: 120,
            config: const TransferWidgetConfig(autoStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow({required bool isOutgoing, required Widget child}) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: child,
      ),
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
