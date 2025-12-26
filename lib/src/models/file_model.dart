import 'dart:typed_data';

import '../core/extensions/file_path_extension.dart';
import '../core/extensions/string_extension.dart';
import 'file_type_enum.dart';

/// File thumbnail model for storing file metadata.
class FileThumbnailModel {
  final Map<String, dynamic> data;

  FileThumbnailModel.fromMap(this.data);
  Map<String, dynamic> toMap() => _withoutNullValues(data);

  FileThumbnailModel({
    int? size,
    int? width,
    int? height,
    Uint8List? thumbnail,
    int? durationInSeconds,
    Map<String, dynamic>? mimeType,
  }) : data = {
         sizeTag: size,
         widthTag: width,
         heightTag: height,
         thumbnailTag: thumbnail?.toList(),
         durationInSecondsTag: durationInSeconds,
         mimeTypeTag: mimeType,
       };

  /// **Getter/Setter for size**
  int? get size => _getInt(data, sizeTag);
  set size(int? value) => data[sizeTag] = value;
  static const String sizeTag = 'size';

  int? get width => _getInt(data, widthTag);
  set width(int? value) => data[widthTag] = value;
  static const String widthTag = 'width';

  int? get height => _getInt(data, heightTag);
  set height(int? value) => data[heightTag] = value;
  static const String heightTag = 'height';

  double? get aspectRatio =>
      width == null || height == null || height == 0 ? null : width! / height!;

  Uint8List? get thumbnail => _getUint8List(data, thumbnailTag);
  set thumbnail(Uint8List? value) => data[thumbnailTag] = value?.toList();
  static const String thumbnailTag = 'thumbnail';

  int? get durationInSeconds => _getInt(data, durationInSecondsTag);
  set durationInSeconds(int? value) => data[durationInSecondsTag] = value;
  static const String durationInSecondsTag = 'durationInSeconds';

  Map<String, dynamic>? get mimeType => _getMap(data, mimeTypeTag);
  set mimeType(Map<String, dynamic>? value) => data[mimeTypeTag] = value;
  static const String mimeTypeTag = 'mimeType';

  FileThumbnailModel copyWith({
    int? size,
    int? width,
    int? height,
    Uint8List? thumbnail,
    int? durationInSeconds,
    Map<String, dynamic>? mimeType,
  }) => FileThumbnailModel(
    size: size ?? this.size,
    width: width ?? this.width,
    height: height ?? this.height,
    thumbnail: thumbnail ?? this.thumbnail,
    durationInSeconds: durationInSeconds ?? this.durationInSeconds,
    mimeType: mimeType ?? this.mimeType,
  );

  @override
  String toString() {
    return 'FileThumbnailModel(size: $size, width: $width, height: $height, thumbnail: $thumbnail, durationInSeconds: $durationInSeconds, mimeType: $mimeType)';
  }
}

/// File model for storing file information and metadata.
class FileModel {
  FileModel.fromMap(this.data);
  Map<String, dynamic> toMap() {
    final map = _withoutNullValues(data);
    return map;
  }

  FileModel._({
    String? url,
    String? localPath,
    String? destinationPath,
    int? size,
    int? width,
    int? height,
    Uint8List? thumbnail,
    int? durationInSeconds,
    Map<String, dynamic>? mimeType,
    String? fileName,
  }) : data = {
         fileNameTag: fileName,
         urlTag: url,
         localPathTag: localPath,
         destinationPathTag: destinationPath,
         sizeTag: size,
         widthTag: width,
         heightTag: height,
         thumbnailTag: thumbnail?.toList(),
         durationInSecondsTag: durationInSeconds,
         mimeTypeTag: mimeType,
       };

  FileModel.local({
    required String localPath,
    String? fileName,
    String? destinationPath,
    int? size,
    int? width,
    int? height,
    Uint8List? thumbnail,
    int? durationInSeconds,
    Map<String, dynamic>? mimeType,
  }) : this._(
         fileName: fileName ?? localPath.fileName,
         localPath: localPath,
         destinationPath:
             destinationPath == null
                 ? null
                 : destinationPath.contains(".")
                 ? destinationPath
                 : "$destinationPath/${localPath.fileName}".replaceAll(
                   "//",
                   "/",
                 ),
         size: size,
         width: width,
         height: height,
         thumbnail: thumbnail,
         durationInSeconds: durationInSeconds,
         mimeType: mimeType,
       );

  FileModel.remote({
    required String url,
    String? fileName,
    String? destinationPath,
    int? size,
    int? width,
    int? height,
    Uint8List? thumbnail,
    int? durationInSeconds,
    Map<String, dynamic>? mimeType,
  }) : this._(
         fileName: fileName ?? url.extractFileName(),
         url: url,
         destinationPath: destinationPath,
         size: size,
         width: width,
         height: height,
         thumbnail: thumbnail,
         durationInSeconds: durationInSeconds,
         mimeType: mimeType,
       );

  final Map<String, dynamic> data;

  /// **Getter/Setter for localPath**
  String? get localPath => _getString(data, localPathTag);
  set localPath(String? value) => data[localPathTag] = value;
  static const String localPathTag = 'localPath';

  /// **Getter/Setter for url**
  String? get destinationPath => _getString(data, destinationPathTag);
  set destinationPath(String? value) => data[destinationPathTag] = value;
  static const String destinationPathTag = 'destinationPath';

  /// **Getter/Setter for url**
  String? get url => _getString(data, urlTag);
  set url(String? value) => data[urlTag] = value;
  static const String urlTag = 'url';

  /// **Getter/Setter for size**
  int? get size => _getInt(data, sizeTag);
  set size(int? value) => data[sizeTag] = value;
  static const String sizeTag = 'size';

  int? get width => _getInt(data, widthTag);
  set width(int? value) => data[widthTag] = value;
  static const String widthTag = 'width';

  int? get height => _getInt(data, heightTag);
  set height(int? value) => data[heightTag] = value;
  static const String heightTag = 'height';

  double? get aspectRatio =>
      width == null || height == null || height == 0 ? null : width! / height!;

  Uint8List? get thumbnail => _getUint8List(data, thumbnailTag);
  set thumbnail(Uint8List? value) => data[thumbnailTag] = value?.toList();
  static const String thumbnailTag = 'thumbnail';

  List<double>? get waveform => thumbnail?.toList().map((e) => e / 1).toList();

  int? get durationInSeconds => _getInt(data, durationInSecondsTag);
  set durationInSeconds(int? value) => data[durationInSecondsTag] = value;
  static const String durationInSecondsTag = 'durationInSeconds';

  Map<String, dynamic>? get mimeType => _getMap(data, mimeTypeTag);
  set mimeType(Map<String, dynamic>? value) => data[mimeTypeTag] = value;
  static const String mimeTypeTag = 'mimeType';

  String? get fileName {
    var name =
        _getString(data, fileNameTag)?.textOrNull ??
        (localPath?.fileName.textOrNull ?? url?.extractFileName())?.textOrNull;
    return name;
  }

  set fileName(String? value) => data[fileNameTag] = value;
  static const String fileNameTag = 'fileName';

  int? get pageCount => _getInt(data, pageCountTag);
  set pageCount(int? value) => data[pageCountTag] = value;
  static const String pageCountTag = 'pageCount';

  FileTypeEnum get fileType => fileName?.getFileType() ?? FileTypeEnum.file;

  @override
  int get hashCode => Object.hash(url, localPath);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileModel &&
          runtimeType == other.runtimeType &&
          localPath == other.localPath &&
          url == other.url;

  FileModel copyWith({
    String? url,
    String? localPath,
    String? destinationPath,
    int? size,
    int? width,
    int? height,
    Uint8List? thumbnail,
    int? durationInSeconds,
    Map<String, dynamic>? mimeType,
  }) => FileModel._(
    url: url ?? this.url,
    localPath: localPath ?? this.localPath,
    destinationPath: destinationPath ?? this.destinationPath,
    size: size ?? this.size,
    width: width ?? this.width,
    height: height ?? this.height,
    thumbnail: thumbnail ?? this.thumbnail,
    durationInSeconds: durationInSeconds ?? this.durationInSeconds,
    mimeType: mimeType ?? this.mimeType,
  );

  FileThumbnailModel get fileThumbnail => FileThumbnailModel.fromMap(data);

  @override
  String toString() {
    return 'FileModel(url: $url, localPath: $localPath, destinationPath: $destinationPath, size: $size, width: $width, height: $height, thumbnail: $thumbnail, durationInSeconds: $durationInSeconds, mimeType: $mimeType)';
  }
}

// Helper functions for data parsing
Map<String, dynamic> _withoutNullValues(Map<String, dynamic> map) {
  return Map.fromEntries(map.entries.where((entry) => entry.value != null));
}

String? _getString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String) return value;
  return null;
}

int? _getInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Uint8List? _getUint8List(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Uint8List) return value;
  if (value is List) return Uint8List.fromList(value.cast<int>());
  return null;
}

Map<String, dynamic>? _getMap(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Map<String, dynamic>) return value;
  return null;
}
