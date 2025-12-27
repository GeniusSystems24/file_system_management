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

## Queue Management (Concurrent Transfers)

Control concurrent transfer operations with configurable limits:

### Basic Queue Usage

```dart
// Create a download queue with max 3 concurrent downloads
final downloadQueue = DownloadQueueManager(maxConcurrent: 3);

// Add downloads - only 3 will run at a time, rest will queue
downloadQueue.addUrl('https://example.com/file1.pdf');
downloadQueue.addUrl('https://example.com/file2.pdf');
downloadQueue.addUrl('https://example.com/file3.pdf');
downloadQueue.addUrl('https://example.com/file4.pdf'); // Will queue
downloadQueue.addUrl('https://example.com/file5.pdf'); // Will queue

// Listen to queue state
downloadQueue.stateStream.listen((state) {
  print('Running: ${state.runningCount}/${state.maxConcurrent}');
  print('Pending: ${state.pendingCount}');
  print('Overall Progress: ${(state.overallProgress * 100).toStringAsFixed(1)}%');
});

// Wait for all downloads to complete
final results = await downloadQueue.waitForAll();
```

### Priority Queue

```dart
// Add with priority - higher priority downloads start first
downloadQueue.addUrl(
  'https://example.com/urgent.pdf',
  priority: TransferPriority.urgent,
);
downloadQueue.addUrl(
  'https://example.com/normal.pdf',
  priority: TransferPriority.normal,
);
downloadQueue.addUrl(
  'https://example.com/low.pdf',
  priority: TransferPriority.low,
);

// Move existing download to front of queue
downloadQueue.moveToFront(downloadId);

// Change priority of queued download
downloadQueue.changePriority(downloadId, TransferPriority.high);
```

### Queue Control

```dart
// Pause the queue (running transfers continue, no new ones start)
downloadQueue.pause();

// Resume the queue
downloadQueue.start();

// Cancel a specific download
downloadQueue.cancel(downloadId);

// Cancel all downloads
downloadQueue.cancelAll();

// Retry a failed download
downloadQueue.retry(downloadId);

// Dynamically change max concurrent
downloadQueue.maxConcurrent = 5;
```

### Upload Queue

```dart
// Upload queue works similarly
final uploadQueue = UploadQueueManager(maxConcurrent: 2);

// Add files to upload
uploadQueue.addFile(
  'https://api.example.com/upload',
  '/path/to/file.pdf',
);

// Add multiple files
for (final file in filesToUpload) {
  uploadQueue.addFile(uploadUrl, file.path);
}
```

### Generic Queue Manager

For custom transfer logic, use `TransferQueueManager`:

```dart
// Create a generic queue
final queue = TransferQueueManager<MyTask>(
  maxConcurrent: 3,
  autoRetry: true,
  maxRetries: 3,
  executor: (transfer) async* {
    // Your custom transfer logic
    final task = transfer.task;

    for (int i = 0; i <= 100; i += 10) {
      if (transfer.cancellationToken.isCancelled) {
        yield TransferProgress(status: TransferStatus.cancelled);
        return;
      }

      await Future.delayed(Duration(milliseconds: 100));
      yield TransferProgress(
        bytesTransferred: i,
        totalBytes: 100,
        status: TransferStatus.running,
      );
    }

    yield TransferProgress.completed(totalBytes: 100);
  },
);

// Add tasks
final queuedTransfer = queue.add(myTask);

// Listen to individual transfer progress
queuedTransfer.progressStream.listen((progress) {
  print('Progress: ${progress.progressPercent}%');
});

// Wait for this specific transfer
final result = await queuedTransfer.future;
```

### Queue State

```dart
// Get current state
final state = downloadQueue.state;
print('Running: ${state.runningCount}');
print('Pending: ${state.pendingCount}');
print('Is Full: ${state.isFull}');
print('Available Slots: ${state.availableSlots}');

// Access individual transfers
for (final transfer in state.runningTransfers) {
  print('${transfer.id}: ${(transfer.progress * 100).toStringAsFixed(1)}%');
}

for (final transfer in state.pendingTransfers) {
  print('${transfer.id} at position ${transfer.queuePosition}');
}
```

### Using Queue with Message Widgets

The package provides `QueuedTransferProvider` for easy integration with message widgets:

```dart
// Option 1: Use with custom download executor
final provider = QueuedTransferProvider(
  maxConcurrent: 3,
  downloadExecutor: (task, token) async* {
    // Your custom download implementation
    yield* myHttpClient.download(task.url, token);
  },
);

// Option 2: Use with DownloadHandler class
final provider = QueuedTransferProvider.withHandler(
  maxConcurrent: 3,
  handler: MyDownloadHandler(),
);

// Option 3: Use with simple callback
final provider = QueuedTransferProvider.withCallback(
  maxConcurrent: 3,
  onDownload: (payload) async* {
    yield* myDownloadStream(payload.url);
  },
);

// Use with widgets - creates download callback automatically
ImageMessageTransferWidget(
  url: 'https://example.com/image1.jpg',
  onDownload: provider.createDownloadCallback(
    priority: TransferPriority.high,
  ),
)

// Or enqueue manually
ImageMessageTransferWidget(
  url: 'https://example.com/image2.jpg',
  onDownload: (payload) => provider.enqueueDownload(
    url: payload.url,
    expectedSize: payload.expectedSize,
    priority: TransferPriority.normal,
  ),
)

// Only 3 downloads will run concurrently
// Rest will queue automatically
```

### Real Downloads with FileSystemController

For production apps, use `RealDownloadProvider` which integrates with `FileSystemController`:

```dart
import 'package:file_system_management/file_system_management.dart';

class RealDownloadProvider {
  late final TransferQueueManager<RealDownloadTask> _queue;
  final FileSystemController _controller;
  final Map<String, String> _completedPaths = {};

  RealDownloadProvider({
    int maxConcurrent = 3,
    FileSystemController? controller,
  }) : _controller = controller ?? FileSystemController.instance {
    _queue = TransferQueueManager<RealDownloadTask>(
      maxConcurrent: maxConcurrent,
      executor: _executeDownload,
    );
  }

  /// Check if file is already cached
  String? getCachedPath(String url) {
    final completed = _completedPaths[url];
    if (completed != null) return completed;
    return _controller.getCachedPath(url);
  }

  Stream<TransferProgress> _executeDownload(
    QueuedTransfer<RealDownloadTask> transfer,
  ) async* {
    final task = transfer.task;

    // Create download task
    final downloadTask = createDownloadTask(
      url: task.url,
      filename: task.fileName,
    );

    final result = await _controller.enqueueDownload(downloadTask);

    switch (result) {
      case EnqueueCached(:final filePath):
        _completedPaths[task.url] = filePath;
        yield TransferProgress.completed(totalBytes: task.expectedSize ?? 0);

      case EnqueueStarted(:final controller):
      case EnqueueInProgress(:final controller):
      case EnqueuePending(:final controller):
        await for (final item in controller.stream) {
          if (transfer.cancellationToken.isCancelled) {
            await _controller.cancel(item);
            yield TransferProgress(status: TransferStatus.cancelled);
            return;
          }

          // Convert TransferItem status to TransferProgress
          final TransferStatus status;
          if (item.isComplete) {
            status = TransferStatus.completed;
          } else if (item.isRunning) {
            status = TransferStatus.running;
          } else if (item.isPaused) {
            status = TransferStatus.paused;
          } else if (item.isFailed) {
            status = TransferStatus.failed;
          } else {
            status = TransferStatus.pending;
          }

          yield TransferProgress(
            bytesTransferred: item.transferredBytes,
            totalBytes: item.expectedFileSize,
            bytesPerSecond: item.networkSpeed,
            estimatedTimeRemaining: item.timeRemaining,
            status: status,
          );

          if (item.isComplete) {
            _completedPaths[task.url] = item.filePath;
            return;
          }
        }
    }
  }
}

// Usage
final provider = RealDownloadProvider(maxConcurrent: 3);

ImageMessageTransferWidget(
  url: 'https://example.com/image.jpg',
  onDownload: (payload) => provider.enqueueDownload(
    url: payload.url,
    expectedSize: payload.expectedSize,
  ),
  completedBuilder: (context, path) {
    // Check cache first
    final cached = provider.getCachedPath(payload.url);
    if (cached != null) {
      return Image.file(File(cached));
    }
    return Image.file(File(path));
  },
)
```

### Queue Status Display

Show queue status in your UI:

```dart
StreamBuilder<TransferQueueState>(
  stream: provider.stateStream,
  builder: (context, snapshot) {
    final state = snapshot.data;
    if (state == null) return SizedBox.shrink();

    return Row(
      children: [
        Text('Running: ${state.runningCount}/${state.maxConcurrent}'),
        Text('Queued: ${state.pendingCount}'),
        LinearProgressIndicator(value: state.overallProgress),
      ],
    );
  },
)
```

## Theming & Skins

The `SocialTransferThemeData` class extends `ThemeExtension`, integrating seamlessly with Flutter's theme system.

### Apply a Social Media Skin

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [SocialTransferThemeData.whatsapp()],
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.dark(),
    extensions: [SocialTransferThemeData.whatsapp(isDark: true)],
  ),
)
```

### Available Skins

```dart
// WhatsApp style
SocialTransferThemeData.whatsapp()
SocialTransferThemeData.whatsapp(isDark: true)

// Telegram style
SocialTransferThemeData.telegram()
SocialTransferThemeData.telegram(isDark: true)

// Instagram style
SocialTransferThemeData.instagram()
SocialTransferThemeData.instagram(isDark: true)

// From current theme context
SocialTransferThemeData.of(context)
```

### Custom Theme

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      SocialTransferThemeData(
        primaryColor: Colors.blue,
        secondaryColor: Colors.blueAccent,
        bubbleColor: Colors.white,
        progressBackgroundColor: Colors.grey.shade200,
        progressForegroundColor: Colors.blue,
        successColor: Colors.green,
        errorColor: Colors.red,
        warningColor: Colors.orange,
        pausedColor: Colors.orange,
        textColor: Colors.black87,
        subtitleColor: Colors.grey,
        iconColor: Colors.grey,
        overlayColor: Colors.black38,
        bubbleBorderRadius: BorderRadius.circular(16),
        progressBorderRadius: BorderRadius.circular(4),
        buttonBorderRadius: BorderRadius.circular(20),
        thumbnailBorderRadius: BorderRadius.circular(8),
        actionButtonSize: 48,
        showSpeed: true,
        showEta: true,
      ),
    ],
  ),
)
```

### Override Specific Properties

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      SocialTransferThemeData.whatsapp().copyWith(
        primaryColor: Colors.purple,
        actionButtonSize: 56,
        showEta: true,
      ),
    ],
  ),
)
```

### Accessing Theme in Widgets

```dart
// Using Theme.of(context).extension
final theme = Theme.of(context).extension<SocialTransferThemeData>();

// Using the convenience extension
final theme = context.socialTransferTheme;
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
3. **Theming** - Use `ThemeData.extensions` with `SocialTransferThemeData` instead of the deprecated `SocialTransferTheme` widget
4. **Custom handlers** - Use `onUpload`/`onDownload` callbacks for custom logic

## License

MIT License
