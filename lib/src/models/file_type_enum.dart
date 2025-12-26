import 'package:collection/collection.dart';

/// File type enumeration for categorizing files.
enum FileTypeEnum {
  /// Image media type.
  image(0, 'image', 'Pictures', {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'}),

  /// Video media type.
  video(1, 'video', 'Movies', {'mp4', 'avi', 'mkv', 'mov', 'wmv'}),

  /// Audio media type.
  audio(3, 'audio', 'Audios', {'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'}),

  /// File media type.
  file(2, 'document', 'Documents', {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
  });

  final int value;
  final String tag;
  final String fileName;
  final Set<String> extensions;
  const FileTypeEnum(this.value, this.tag, this.fileName, this.extensions);

  static FileTypeEnum? getOf(int? value) =>
      values.firstWhereOrNull((element) => element.value == value);
  static FileTypeEnum? getOfName(String? name) =>
      values.firstWhereOrNull((element) => element.name == name);
}
