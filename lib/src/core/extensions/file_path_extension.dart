import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/storage/app_directory.dart';

/// File type enumeration for categorizing files.
enum FileType {
  image(['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'svg']),
  video(['mp4', 'avi', 'mkv', 'mov', 'wmv', 'webm', 'flv']),
  audio(['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a']),
  file([]);

  final List<String> extensions;
  const FileType(this.extensions);
}

/// Extension on String for file path operations.
extension FilePathExtension on String {
  /// Extract the file name from the file path
  ///
  /// Returns the file name
  ///
  /// ### usage example:
  /// ```dart
  /// final filePath = "/data/user/0/com.example.app/app_flutter/cached_files/c2cd89f14497153e3d.png";
  ///
  /// final fileName = filePath.extractFileName();
  ///
  /// print(fileName); // output: c2cd89f14497153e3d.png
  /// ```
  String extractFileName() {
    return path.basename(this).split('?')[0];
  }

  /// Get the file type of the file
  ///
  /// Returns the file type of the file
  ///
  /// - Returns null if the file path is empty
  /// - Returns null if the file extension is empty
  /// - Returns "image" if the file extension is ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp"
  /// - Returns "video" if the file extension is ".mp4", ".avi", ".mkv", ".mov", ".wmv"
  /// - Returns "audio" if the file extension is ".mp3", ".wav", ".aac", ".flac", ".ogg"
  /// - Returns "document" if the file extension is not one of the above
  FileType? getFileType() {
    if (isEmpty) return null;

    String extension = path.extension(this).replaceAll(".", "").toLowerCase();

    if (extension.isEmpty) return null;

    if (FileType.image.extensions.contains(extension)) {
      return FileType.image;
    } else if (FileType.video.extensions.contains(extension)) {
      return FileType.video;
    } else if (FileType.audio.extensions.contains(extension)) {
      return FileType.audio;
    } else {
      return FileType.file;
    }
  }

  /// Returns the file name from a path.
  ///
  /// Example:
  /// ```dart
  /// 'path/to/file.jpg'.fileName; // 'file.jpg'
  /// ```
  String get fileName => path.basename(this);

  /// Returns the file extension from a path.
  String get fileExtension => path.extension(split('?').first);

  /// Generates a unique File name for a file based on its URL
  ///
  /// - [url] The URL of the file to generate a File name.
  ///
  /// Returns a [String] containing the File name
  ///
  /// usage:
  /// ```dart
  /// final urlHashName = 'https://example.com/image.jpg'.toHashName(); // 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6.jpg'
  ///
  /// final filePathHashName =  "path/to/file.jpg".toHashName(); // 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6.jpg'
  /// ```
  String toHashName() {
    final bytes = utf8.encode(this);
    final hash = sha256.convert(bytes).toString();
    final extension = fileExtension;
    return '$hash$extension';
  }

  /// Generates a file path in the cached directory.
  ///
  /// usage:
  /// ```dart
  /// final url = 'image.jpg';
  /// final filePath = url.nameToCachedPath(); // 'path/to/cached/image.jpg'
  /// ```
  String toCachedPath() =>
      path.join(AppDirectory.instance.cachedDir!.path, this);

  /// Generates a file path in the thumb directory.
  ///
  /// usage:
  /// ```dart
  /// final url = 'image.jpg';
  /// final filePath = url.nameToThumbPath(); // 'path/to/thumb/image.jpg'
  /// ```
  String toThumbPath() =>
      path.join(AppDirectory.instance.systemTemp!.path, this);

  /// Generates a file path in the cached directory.
  ///
  /// usage:
  /// ```dart
  /// final url = 'image.jpg';
  /// final filePath = url.urlToCachedPath(); // 'path/to/cached/image.jpg'
  /// ```
  String urlToCachedPath() => toHashName().toCachedPath();

  /// Generates a file path in the thumb directory.
  ///
  /// usage:
  /// ```dart
  /// final url = 'image.jpg';
  /// final filePath = url.urlToThumbPath(); // 'path/to/thumb/image.jpg'
  /// ```
  String urlToThumbPath() => toHashName().toThumbPath();

  /// Returns the icon and color for the file type based on extension.
  (IconData, Color) get iconAndColor {
    if (!contains('.')) return (Icons.insert_drive_file, Colors.grey);

    final fileExtension = split('.').last.toLowerCase();

    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'svg',
      'bmp',
    ].contains(fileExtension)) {
      return (Icons.image, Colors.blue);
    } else if (fileExtension == 'pdf') {
      return (Icons.picture_as_pdf, Colors.red);
    } else if (['doc', 'docx', 'odt', 'rtf', 'txt'].contains(fileExtension)) {
      return (Icons.description, Colors.blue);
    } else if (['xls', 'xlsx', 'csv'].contains(fileExtension)) {
      return (Icons.table_chart, Colors.green);
    } else if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'flv',
    ].contains(fileExtension)) {
      return (Icons.video_file, Colors.purple);
    } else if (['mp3', 'wav', 'ogg', 'flac', 'm4a'].contains(fileExtension)) {
      return (Icons.audio_file, Colors.amber);
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(fileExtension)) {
      return (Icons.folder_zip, Colors.brown);
    } else {
      return (Icons.insert_drive_file, Colors.grey);
    }
  }
}
