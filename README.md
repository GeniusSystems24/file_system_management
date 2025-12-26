# File System Management

A comprehensive Flutter package for managing file download and upload operations with progress tracking, customizable handlers, and social media-inspired UI widgets.

## Features

- **Injectable Upload/Download Handlers** - Use your own backend providers
- **Social Media Skins** - WhatsApp, Telegram, and Instagram-inspired designs
- **Message Widgets** - Ready-to-use widgets for Audio, Image, Video, File, and Document transfers
- **Progress Tracking** - Real-time progress with speed and ETA
- **Transfer Control** - Pause, resume, cancel, and retry operations
- **Caching** - Automatic file caching with URL recognition
- **RTL Support** - Full right-to-left language support
- **Dark Mode** - Automatic dark/light theme support
- **Background Downloads** - Continue downloads when app is in background

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  file_system_management:
    path: ../packages/file_system_management
```

## Quick Start

### 1. Initialize the Controller

```dart
import 'package:file_system_management/file_system_management.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize directories
  await AppDirectory.init();

  // Initialize the file system controller
  await FileSystemController.instance.initialize();

  runApp(MyApp());
}
```

### 2. Basic Download

```dart
// Create a download task
final task = createDownloadTask(
  url: 'https://example.com/file.pdf',
  directory: 'downloads',
  baseDirectory: BaseDirectory.applicationDocuments,
);

// Enqueue the download
final result = await FileSystemController.instance.enqueueDownload(task);

switch (result) {
  case EnqueueCached(:final filePath):
    print('File already cached at: $filePath');
  case EnqueueStarted(:final controller):
    controller.stream.listen((item) {
      print('Progress: ${item.progressText}');
      print('Speed: ${item.networkSpeedText}');
    });
  case EnqueueInProgress(:final controller):
    print('Download already in progress');
  case EnqueuePending(:final controller):
    print('Download pending');
}
```

## Message Widgets

Ready-to-use widgets for messaging applications:

### Audio Message

```dart
AudioMessageTransferWidget(
  url: 'https://example.com/audio.mp3',
  fileName: 'voice_message.mp3',
  duration: Duration(seconds: 30),
  waveform: waveformData, // Optional
  onDownload: (payload) async* {
    // Your custom download logic
    yield TransferProgress(
      bytesTransferred: bytes,
      totalBytes: total,
      status: TransferStatus.running,
    );
  },
  onPlay: () => playAudio(),
)
```

### Image Message

```dart
ImageMessageTransferWidget(
  url: 'https://example.com/image.jpg',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  width: 300,
  height: 200,
  onDownload: (payload) => myDownloadStream(payload),
  completedBuilder: (context, path) => Image.file(File(path)),
  onFullScreen: (path) => openFullScreen(path),
)
```

### Video Message

```dart
VideoMessageTransferWidget(
  url: 'https://example.com/video.mp4',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  duration: Duration(minutes: 2, seconds: 30),
  onDownload: (payload) => myDownloadStream(payload),
  onPlay: (path) => openVideoPlayer(path),
)
```

### File Message

```dart
FileMessageTransferWidget(
  url: 'https://example.com/file.zip',
  fileName: 'archive.zip',
  fileSize: 1024 * 1024 * 50, // 50 MB
  onDownload: (payload) => myDownloadStream(payload),
  onOpen: (path) => openFile(path),
)
```

### Document Message

```dart
DocumentMessageTransferWidget(
  url: 'https://example.com/document.pdf',
  fileName: 'report.pdf',
  fileSize: 1024 * 1024 * 2, // 2 MB
  pageCount: 15,
  onDownload: (payload) => myDownloadStream(payload),
  onOpen: (path) => openPdfViewer(path),
)
```

## Custom Upload/Download Handlers

Inject your own upload/download logic without being tied to any specific provider:

### Using Callbacks

```dart
ImageMessageTransferWidget(
  url: 'https://example.com/image.jpg',

  // Custom download callback
  onDownload: (DownloadPayload payload) async* {
    final response = await myHttpClient.download(payload.url);

    await for (final chunk in response.stream) {
      yield TransferProgress(
        bytesTransferred: bytesReceived,
        totalBytes: response.contentLength,
        bytesPerSecond: calculateSpeed(),
        status: TransferStatus.running,
      );
    }

    yield TransferProgress.completed(totalBytes: response.contentLength);
  },

  // Custom upload callback
  onUpload: (UploadPayload payload) async* {
    final file = File(payload.filePath!);
    final response = await myHttpClient.upload(file);

    yield TransferProgress.completed(totalBytes: file.lengthSync());
  },

  // Control callbacks
  onPause: () async => await myDownloader.pause(),
  onResume: () async => await myDownloader.resume(),
  onCancel: () async => await myDownloader.cancel(),
  onRetry: () => myDownloader.retry(),
)
```

### Using Handler Classes

```dart
// Implement your own handler
class MyUploadHandler implements UploadHandler {
  @override
  Stream<TransferProgress> upload(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    // Your implementation
  }

  @override
  Future<TransferResult> uploadAndComplete(...) async {
    // Your implementation
  }
}

// Use the handler
ImageMessageTransferWidget(
  url: 'https://example.com/image.jpg',
  uploadHandler: MyUploadHandler(),
  downloadHandler: MyDownloadHandler(),
)
```

## Theming & Skins

### Apply a Social Media Skin

```dart
// WhatsApp style
SocialTransferTheme(
  data: SocialTransferThemeData.whatsapp(),
  child: MyApp(),
)

// Telegram style
SocialTransferTheme(
  data: SocialTransferThemeData.telegram(),
  child: MyApp(),
)

// Instagram style
SocialTransferTheme(
  data: SocialTransferThemeData.instagram(),
  child: MyApp(),
)
```

### Dark Mode Support

```dart
SocialTransferTheme(
  data: SocialTransferThemeData.whatsapp(isDark: true),
  child: MyApp(),
)
```

### Custom Theme

```dart
SocialTransferTheme(
  data: SocialTransferThemeData(
    primaryColor: Colors.blue,
    secondaryColor: Colors.blueAccent,
    bubbleColor: Colors.white,
    progressForegroundColor: Colors.blue,
    bubbleBorderRadius: BorderRadius.circular(16),
    actionButtonSize: 48,
    showSpeed: true,
    showEta: true,
  ),
  child: MyApp(),
)
```

### Override Specific Properties

```dart
SocialTransferTheme(
  data: SocialTransferThemeData.whatsapp().copyWith(
    primaryColor: Colors.purple,
    actionButtonSize: 56,
    showEta: true,
  ),
  child: MyApp(),
)
```

## RTL Support

All widgets automatically support RTL when the app's text direction is RTL:

```dart
MaterialApp(
  locale: Locale('ar'), // Arabic
  localizationsDelegates: [...],
  supportedLocales: [Locale('ar'), Locale('en')],
  child: MyApp(),
)
```

## Widget Configuration

Control widget behavior with `TransferWidgetConfig`:

```dart
AudioMessageTransferWidget(
  config: TransferWidgetConfig(
    autoStart: false,           // Don't start automatically
    showActionButton: true,     // Show download/upload button
    showProgress: true,         // Show progress percentage
    showSpeed: true,            // Show transfer speed
    showFileSize: true,         // Show file size
    showEta: false,             // Hide estimated time
    allowPauseResume: true,     // Enable pause/resume
    allowRetry: true,           // Enable retry on failure
    allowCancel: true,          // Enable cancel
    showLinearProgress: true,   // Show progress bar
    direction: BubbleDirection.outgoing, // Message direction
  ),
  // ...
)
```

## Cancellation Token

Use cancellation tokens for fine-grained control:

```dart
final token = CancellationToken();

ImageMessageTransferWidget(
  url: 'https://example.com/image.jpg',
  cancellationToken: token,
)

// Cancel from outside the widget
token.cancel('User navigated away');

// Check if cancelled
if (token.isCancelled) {
  print('Transfer was cancelled: ${token.cancellationReason}');
}
```

## API Reference

### TransferProgress

| Property | Type | Description |
|----------|------|-------------|
| `bytesTransferred` | `int` | Bytes transferred so far |
| `totalBytes` | `int` | Total bytes (-1 if unknown) |
| `bytesPerSecond` | `double` | Transfer speed |
| `progress` | `double` | Progress (0.0 to 1.0) |
| `progressPercent` | `double` | Progress (0 to 100) |
| `status` | `TransferStatus` | Current status |
| `progressText` | `String` | Formatted progress |
| `speedText` | `String` | Formatted speed |
| `etaText` | `String` | Formatted ETA |

### TransferResult

| Type | Description |
|------|-------------|
| `TransferSuccess` | Transfer completed successfully |
| `TransferFailure` | Transfer failed with error |
| `TransferCancelled` | Transfer was cancelled |

### SocialSkin

| Skin | Description |
|------|-------------|
| `whatsapp` | WhatsApp-inspired design |
| `telegram` | Telegram-inspired design |
| `instagram` | Instagram-inspired design |
| `custom` | Custom design |

### TransferWidgetState

| State | Description |
|-------|-------------|
| `idle` | Ready to start |
| `pending` | Queued |
| `transferring` | In progress |
| `paused` | Paused |
| `completed` | Finished |
| `failed` | Error occurred |
| `cancelled` | User cancelled |

## Dependencies

- `background_downloader` - Background download support
- `cached_network_image` - Network image caching
- `crypto` - Hash generation
- `dashed_circular_progress_bar` - Progress indicators
- `path` - Path manipulation
- `path_provider` - System directories

## Migration from 0.0.1

If you're upgrading from version 0.0.1:

1. **TaskItem is now TransferItem** - The old name is still exported for compatibility
2. **New message widgets** - Use `AudioMessageTransferWidget`, `ImageMessageTransferWidget`, etc.
3. **Theming** - Wrap your app with `SocialTransferTheme` for consistent styling
4. **Custom handlers** - Use `onUpload`/`onDownload` callbacks for custom logic

## License

MIT License
