/// Sample files for download demonstrations.
///
/// These are real, publicly available files for testing downloads.
class SampleFiles {
  SampleFiles._();

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGES
  // ═══════════════════════════════════════════════════════════════════════════

  static const images = [
    SampleFile(
      name: 'Sample JPG (500KB)',
      url: 'https://sample-videos.com/img/Sample-jpg-image-500kb.jpg',
      size: 500 * 1024,
      type: SampleFileType.image,
      extension: 'jpg',
    ),
    SampleFile(
      name: 'Sample PNG (500KB)',
      url: 'https://sample-videos.com/img/Sample-png-image-500kb.png',
      size: 500 * 1024,
      type: SampleFileType.image,
      extension: 'png',
    ),
    SampleFile(
      name: 'Animated GIF',
      url: 'https://sample-videos.com/gif/1.gif',
      size: 1024 * 1024,
      type: SampleFileType.image,
      extension: 'gif',
    ),
    SampleFile(
      name: 'WebP Image',
      url: 'https://www.gstatic.com/webp/gallery/1.webp',
      size: 100 * 1024,
      type: SampleFileType.image,
      extension: 'webp',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // VIDEOS
  // ═══════════════════════════════════════════════════════════════════════════

  static const videos = [
    SampleFile(
      name: 'MP4 Video (1MB)',
      url: 'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4',
      size: 1024 * 1024,
      type: SampleFileType.video,
      extension: 'mp4',
    ),
    SampleFile(
      name: 'MP4 Video (5MB)',
      url: 'https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_5mb.mp4',
      size: 5 * 1024 * 1024,
      type: SampleFileType.video,
      extension: 'mp4',
    ),
    SampleFile(
      name: 'MP4 Video (10MB)',
      url: 'https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_10mb.mp4',
      size: 10 * 1024 * 1024,
      type: SampleFileType.video,
      extension: 'mp4',
    ),
    SampleFile(
      name: 'MP4 Video HD (20MB)',
      url: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_20mb.mp4',
      size: 20 * 1024 * 1024,
      type: SampleFileType.video,
      extension: 'mp4',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // AUDIO
  // ═══════════════════════════════════════════════════════════════════════════

  static const audio = [
    SampleFile(
      name: 'MP3 Audio',
      url: 'https://sample-videos.com/audio/mp3/crowd-cheering.mp3',
      size: 500 * 1024,
      type: SampleFileType.audio,
      extension: 'mp3',
    ),
    SampleFile(
      name: 'WAV Audio',
      url: 'https://sample-videos.com/audio/wav/crowd-cheering.wav',
      size: 5 * 1024 * 1024,
      type: SampleFileType.audio,
      extension: 'wav',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // DOCUMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const documents = [
    SampleFile(
      name: 'PDF Document',
      url: 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
      size: 100 * 1024,
      type: SampleFileType.document,
      extension: 'pdf',
    ),
    SampleFile(
      name: 'PDF Document (5MB)',
      url: 'https://sample-videos.com/pdf/Sample-pdf-5mb.pdf',
      size: 5 * 1024 * 1024,
      type: SampleFileType.document,
      extension: 'pdf',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ARCHIVES
  // ═══════════════════════════════════════════════════════════════════════════

  static const archives = [
    SampleFile(
      name: 'ZIP Archive (1MB)',
      url: 'https://sample-videos.com/zip/1mb.zip',
      size: 1024 * 1024,
      type: SampleFileType.archive,
      extension: 'zip',
    ),
    SampleFile(
      name: 'ZIP Archive (10MB)',
      url: 'https://sample-videos.com/zip/10mb.zip',
      size: 10 * 1024 * 1024,
      type: SampleFileType.archive,
      extension: 'zip',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // LARGE FILES (for parallel download demo)
  // ═══════════════════════════════════════════════════════════════════════════

  static const largeFiles = [
    SampleFile(
      name: 'Large Video (50MB)',
      url: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_50mb.mp4',
      size: 50 * 1024 * 1024,
      type: SampleFileType.video,
      extension: 'mp4',
    ),
  ];

  /// Get all sample files.
  static List<SampleFile> get all => [
        ...images,
        ...videos,
        ...audio,
        ...documents,
        ...archives,
      ];
}

/// Represents a sample file for download.
class SampleFile {
  final String name;
  final String url;
  final int size;
  final SampleFileType type;
  final String extension;

  const SampleFile({
    required this.name,
    required this.url,
    required this.size,
    required this.type,
    required this.extension,
  });

  /// Get formatted file size.
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Get file name from URL.
  String get fileName => url.split('/').last;
}

/// File type enumeration for sample files.
enum SampleFileType {
  image,
  video,
  audio,
  document,
  archive,
  other;

  String get label {
    switch (this) {
      case SampleFileType.image:
        return 'Image';
      case SampleFileType.video:
        return 'Video';
      case SampleFileType.audio:
        return 'Audio';
      case SampleFileType.document:
        return 'Document';
      case SampleFileType.archive:
        return 'Archive';
      case SampleFileType.other:
        return 'Other';
    }
  }
}
