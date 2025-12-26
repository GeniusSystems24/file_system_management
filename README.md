# File Task Management

A Flutter package for managing file download tasks with progress tracking and notifications.

## Features

- ✅ File download with progress tracking
- ✅ Pause, resume, and cancel downloads
- ✅ Background download support
- ✅ Notification support for download status
- ✅ Thumbnail preview for media files
- ✅ Stream-based progress updates
- ✅ Singleton controller pattern

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  file_system_management:
    path: ../packages/file_system_management
```

## Usage

### Initialize the controller

```dart
import 'package:file_system_management/file_system_management.dart';

// Initialize on app startup
await AppDirectory.init();
await FileTaskController.instance.initialize();
```

### Download a file

```dart
// Create a download task
final task = createDownloadTask(
  url: 'https://example.com/file.pdf',
  directory: 'downloads',
  baseDirectory: BaseDirectory.applicationDocuments,
);

// Enqueue the download
final (filePath, streamController) = await FileTaskController.instance.enqueueOrResume(task, true);

// Listen for updates
streamController?.stream.listen((taskItem) {
  print('Progress: ${taskItem.progressText}');
  print('Status: ${taskItem.statusText}');
});
```

### Using MediaDownloadCard widget

```dart
MediaDownloadCard(
  item: taskItem,
  onStart: () => FileTaskController.instance.fileDownloader.enqueue(task),
  onPause: (item) => FileTaskController.instance.pause(item),
  onResume: (item) => FileTaskController.instance.resume(item),
  onCancel: (item) => FileTaskController.instance.cancel(item),
  completedBuilder: (context, item) => Image.file(File(item.filePath)),
  thumbnailProvider: MemoryImage(thumbnailBytes),
);
```

### Using DocumentDownloadCard widget

```dart
DocumentDownloadCard(
  item: taskItem,
  completedBuilder: (context, item) => DocumentViewer(filePath: item.filePath),
  loadingBuilder: (context, item) => LinearProgressIndicator(value: item?.progress ?? 0),
  onStart: () => FileTaskController.instance.fileDownloader.enqueue(task),
  onPause: (item) => FileTaskController.instance.pause(item),
  onResume: (item) => FileTaskController.instance.resume(item),
  onRetry: (item) => FileTaskController.instance.openFile(item),
);
```

## API Reference

### FileTaskController

The main controller for managing file tasks.

| Method | Description |
|--------|-------------|
| `initialize()` | Initialize the controller and setup listeners |
| `enqueueOrResume(task, autoStart)` | Add a task to the queue |
| `pause(taskItem)` | Pause a download |
| `resume(taskItem)` | Resume a paused download |
| `cancel(taskItem)` | Cancel a download |
| `openFile(taskItem)` | Open a downloaded file |
| `deleteFile(taskItem)` | Delete a file and its record |

### TaskItem

A model representing a download task with progress information.

| Property | Description |
|----------|-------------|
| `progress` | Download progress (0.0 to 1.0) |
| `status` | Current task status |
| `filePath` | Local path of the downloaded file |
| `progressText` | Formatted progress percentage |
| `statusText` | Localized status text |
| `networkSpeedText` | Formatted network speed |
| `fileSizeText` | Formatted file size |

### FileModel

A model for storing file information and metadata.

| Property | Description |
|----------|-------------|
| `url` | Remote URL of the file |
| `localPath` | Local path of the file |
| `fileName` | Name of the file |
| `size` | File size in bytes |
| `width` | Width (for images/videos) |
| `height` | Height (for images/videos) |
| `thumbnail` | Thumbnail data |
| `fileType` | Type of file (image, video, audio, file) |

## Dependencies

- `background_downloader`: For handling file downloads
- `cached_network_image`: For displaying network images
- `crypto`: For generating hash names
- `dashed_circular_progress_bar`: For progress indicators
- `path`: For path manipulation
- `path_provider`: For accessing system directories

## License

MIT License
