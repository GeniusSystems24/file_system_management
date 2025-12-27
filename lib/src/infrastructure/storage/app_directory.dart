import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Application directory manager singleton for handling file paths.
class AppDirectory {
  static bool isInitialized = false;

  /// The instance of the AppDirectory
  ///
  /// This is a singleton class and should be initialized using the [init] method.
  static late final AppDirectory instance;

  /// Initializes the AppDirectory
  static Future<AppDirectory> init() async {
    if (isInitialized) return instance;
    instance = AppDirectory._();
    await instance._getApplicationDocumentsDirectory();
    await instance._getApplicationSupportDirectory();
    await instance._getRootDirectory();
    await instance._getTemporaryDirectory();
    await instance._getCachedDirectory();
    await instance._getThumbDirectory();
    isInitialized = true;
    return instance;
  }

  AppDirectory._();

  Directory? applicationDocumentsDirectory;
  Future<Directory> _getApplicationDocumentsDirectory() async {
    return (applicationDocumentsDirectory ??=
        await getApplicationDocumentsDirectory());
  }

  Directory? applicationSupportDirectory;
  Future<Directory> _getApplicationSupportDirectory() async {
    return (applicationSupportDirectory ??=
        await getApplicationSupportDirectory());
  }

  Directory? rootDirectory;
  Future<Directory> _getRootDirectory() async {
    return (rootDirectory ??= await getApplicationDocumentsDirectory());
  }

  Directory? temporaryDirectory;
  Future<Directory> _getTemporaryDirectory() async {
    return (temporaryDirectory ??= await getTemporaryDirectory());
  }

  Directory? cachedDir;
  Future<void> _getCachedDirectory() async {
    if (cachedDir != null) return;

    cachedDir ??= (Directory(
      '${(await _getApplicationDocumentsDirectory()).path}/cached',
    ));

    if (!cachedDir!.existsSync()) {
      cachedDir!.createSync(recursive: true);
    }
  }

  Directory? systemTemp;
  Future<void> _getThumbDirectory() async {
    systemTemp ??= await Directory.systemTemp.createTemp();
    final thumbDir = Directory('${systemTemp!.path}/thumb');

    if (!thumbDir.existsSync()) {
      thumbDir.createSync(recursive: true);
    }
  }
}
