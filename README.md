# file_system_management

[![pub package](https://img.shields.io/pub/v/file_system_management.svg)](https://pub.dev/packages/file_system_management)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Flutter package for managing file transfers with progress tracking, queue management, social media-inspired UI widgets, and injectable handlers.

## Features

| Feature | Description |
|---------|-------------|
| **Queue Management** | Control concurrent transfers with priority queuing |
| **Message Widgets** | Ready-to-use widgets for chat applications |
| **Social Media Themes** | WhatsApp, Telegram, Instagram-inspired designs |
| **Injectable Handlers** | Use your own upload/download providers |
| **Background Downloads** | Continue downloads when app is in background |
| **Caching** | Automatic file caching with URL recognition |
| **RTL Support** | Full right-to-left language support |
| **Progress Tracking** | Real-time progress with speed and ETA |

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
| ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |

---

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
- [Usage Scenarios](#usage-scenarios)
  - [Scenario 1: Basic File Download](#scenario-1-basic-file-download)
  - [Scenario 2: Chat Application with Message Widgets](#scenario-2-chat-application-with-message-widgets)
  - [Scenario 3: Queue Management for Multiple Downloads](#scenario-3-queue-management-for-multiple-downloads)
  - [Scenario 4: Custom Download Handler](#scenario-4-custom-download-handler)
  - [Scenario 5: Social Media Theming](#scenario-5-social-media-theming)
- [API Reference](#api-reference)
- [Example App](#example-app)
- [Migration Guide](#migration-guide)

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  file_system_management: ^0.2.1
```

Then run:

```bash
flutter pub get
```

---

## Getting Started

### 1. Initialize the Package

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

### 2. Apply Theme (Optional)

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [SocialTransferThemeData.whatsapp()],
  ),
  // ...
)
```

---

## Usage Scenarios

### Scenario 1: Basic File Download

Download a file with progress tracking and caching:

```dart
// Create a download task
final task = createDownloadTask(
  url: 'https://example.com/document.pdf',
  directory: 'downloads',
  baseDirectory: BaseDirectory.applicationDocuments,
);

// Enqueue the download
final result = await FileSystemController.instance.enqueueDownload(task);

// Handle the result
switch (result) {
  case EnqueueCached(:final filePath):
    // File already exists in cache
    openFile(filePath);

  case EnqueueStarted(:final controller):
    // Listen to progress
    controller.stream.listen((item) {
      print('Progress: ${item.progressText}');
      print('Speed: ${item.networkSpeedText}');
      print('ETA: ${item.timeRemainingText}');

      if (item.isComplete) {
        openFile(item.filePath);
      }
    });

  case EnqueueInProgress(:final controller):
    // Download already in progress, attach to existing stream
    controller.stream.listen((item) => print(item.progressText));

  case EnqueuePending(:final controller):
    // Download queued, will start soon
    print('Download pending...');
}
```

### Scenario 2: Chat Application with Message Widgets

Build a messaging app with transfer widgets:

```dart
// Image message
ImageMessageTransferWidget(
  url: 'https://example.com/photo.jpg',
  fileName: 'photo.jpg',
  fileSize: 2 * 1024 * 1024,
  width: 250,
  height: 180,
  config: TransferWidgetConfig(
    direction: BubbleDirection.incoming,
    autoStart: false,
  ),
  onDownload: (payload) async* {
    // Your download implementation
    yield* myDownloadService.download(payload.url);
  },
  onFullScreen: (path) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ImageViewer(path)),
  ),
)

// Audio message with waveform
AudioMessageTransferWidget(
  url: 'https://example.com/voice.mp3',
  fileName: 'voice_message.mp3',
  duration: Duration(seconds: 30),
  waveform: waveformData,
  config: TransferWidgetConfig(
    direction: BubbleDirection.outgoing,
  ),
  onDownload: (payload) => downloadService.download(payload),
  onPlay: () => audioPlayer.play(),
)

// Video message
VideoMessageTransferWidget(
  url: 'https://example.com/video.mp4',
  fileName: 'funny_video.mp4',
  duration: Duration(minutes: 2, seconds: 30),
  fileSize: 15 * 1024 * 1024,
  config: TransferWidgetConfig(
    direction: BubbleDirection.incoming,
  ),
  onDownload: (payload) => downloadService.download(payload),
  onPlay: (path) => openVideoPlayer(path),
)

// Document message
DocumentMessageTransferWidget(
  url: 'https://example.com/report.pdf',
  fileName: 'Annual_Report.pdf',
  fileSize: 5 * 1024 * 1024,
  pageCount: 25,
  onDownload: (payload) => downloadService.download(payload),
  onOpen: (path) => openPdfViewer(path),
)

// Generic file message
FileMessageTransferWidget(
  url: 'https://example.com/archive.zip',
  fileName: 'project_files.zip',
  fileSize: 50 * 1024 * 1024,
  onDownload: (payload) => downloadService.download(payload),
  onOpen: (path) => shareFile(path),
)
```

### Scenario 3: Queue Management for Multiple Downloads

Control concurrent downloads with priority queuing:

```dart
// Create a queue manager
final queue = DownloadQueueManager(
  maxConcurrent: 3,      // Only 3 downloads run simultaneously
  autoRetry: true,       // Retry failed downloads
  maxRetries: 2,         // Retry up to 2 times
);

// Add downloads with priority
queue.addUrl(
  'https://example.com/urgent.pdf',
  priority: TransferPriority.urgent,  // Starts immediately
);

queue.addUrl(
  'https://example.com/normal.pdf',
  priority: TransferPriority.normal,  // Queued normally
);

queue.addUrl(
  'https://example.com/background.pdf',
  priority: TransferPriority.low,     // Downloads last
);

// Monitor queue state
queue.stateStream.listen((state) {
  print('Running: ${state.runningCount}/${state.maxConcurrent}');
  print('Pending: ${state.pendingCount}');
  print('Progress: ${(state.overallProgress * 100).toStringAsFixed(1)}%');
});

// Queue control operations
queue.pause();                              // Pause queue (running continues)
queue.start();                              // Resume queue
queue.cancel('download_id');                // Cancel specific download
queue.cancelAll();                          // Cancel all downloads
queue.retry('download_id');                 // Retry failed download
queue.moveToFront('download_id');           // Move to front of queue
queue.changePriority('id', TransferPriority.urgent);  // Change priority
queue.maxConcurrent = 5;                    // Adjust concurrency dynamically

// Wait for all downloads
final results = await queue.waitForAll();
```

#### Using Queue with Message Widgets

```dart
// Create a queued provider
final provider = QueuedTransferProvider(
  maxConcurrent: 3,
  downloadExecutor: (task, token) async* {
    yield* myDownloadService.download(task.url, token);
  },
);

// Or use with existing handler
final provider = QueuedTransferProvider.withHandler(
  maxConcurrent: 3,
  handler: MyDownloadHandler(),
);

// Use with widgets
ImageMessageTransferWidget(
  url: 'https://example.com/image1.jpg',
  onDownload: provider.createDownloadCallback(
    priority: TransferPriority.high,
  ),
)

// Show queue status in UI
StreamBuilder<TransferQueueState>(
  stream: provider.stateStream,
  builder: (context, snapshot) {
    final state = snapshot.data ?? provider.state;
    return Row(
      children: [
        Text('${state.runningCount} running'),
        Text('${state.pendingCount} queued'),
        LinearProgressIndicator(value: state.overallProgress),
      ],
    );
  },
)
```

### Scenario 4: Custom Download Handler

Implement your own download logic:

```dart
class MyDownloadHandler implements DownloadHandler {
  final HttpClient _client;

  MyDownloadHandler(this._client);

  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    final request = await _client.getUrl(Uri.parse(payload.url));

    // Add custom headers
    if (payload.headers != null) {
      payload.headers!.forEach((key, value) {
        request.headers.add(key, value);
      });
    }

    final response = await request.close();
    final totalBytes = response.contentLength;
    var bytesReceived = 0;

    await for (final chunk in response) {
      // Check for cancellation
      if (cancellationToken?.isCancelled ?? false) {
        yield TransferProgress(
          status: TransferStatus.cancelled,
          bytesTransferred: bytesReceived,
          totalBytes: totalBytes,
        );
        return;
      }

      bytesReceived += chunk.length;

      yield TransferProgress(
        bytesTransferred: bytesReceived,
        totalBytes: totalBytes,
        status: TransferStatus.running,
      );
    }

    yield TransferProgress.completed(totalBytes: totalBytes);
  }

  @override
  Future<TransferResult> downloadAndComplete(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    TransferProgress? lastProgress;

    await for (final progress in download(
      payload,
      config: config,
      cancellationToken: cancellationToken,
    )) {
      lastProgress = progress;
    }

    if (lastProgress?.isCompleted ?? false) {
      return TransferSuccess(
        localPath: payload.destinationPath ?? '',
        remoteUrl: payload.url,
      );
    }

    return TransferFailure(message: 'Download failed');
  }
}

// Use the handler
ImageMessageTransferWidget(
  url: 'https://example.com/image.jpg',
  downloadHandler: MyDownloadHandler(HttpClient()),
)
```

### Scenario 5: Social Media Theming

Apply pre-built or custom themes:

```dart
// WhatsApp theme
MaterialApp(
  theme: ThemeData(
    extensions: [SocialTransferThemeData.whatsapp()],
  ),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    extensions: [SocialTransferThemeData.whatsapp(isDark: true)],
  ),
)

// Telegram theme
MaterialApp(
  theme: ThemeData(
    extensions: [SocialTransferThemeData.telegram()],
  ),
)

// Instagram theme
MaterialApp(
  theme: ThemeData(
    extensions: [SocialTransferThemeData.instagram()],
  ),
)

// Custom theme
MaterialApp(
  theme: ThemeData(
    extensions: [
      SocialTransferThemeData(
        primaryColor: Colors.purple,
        bubbleColor: Colors.purple.shade50,
        progressForegroundColor: Colors.purple,
        successColor: Colors.green,
        errorColor: Colors.red,
        bubbleBorderRadius: BorderRadius.circular(20),
        actionButtonSize: 52,
        showSpeed: true,
        showEta: true,
      ),
    ],
  ),
)

// Customize existing theme
SocialTransferThemeData.whatsapp().copyWith(
  primaryColor: Colors.teal,
  actionButtonSize: 56,
)

// Access theme in widget
final theme = context.socialTransferTheme;
// or
final theme = Theme.of(context).extension<SocialTransferThemeData>();
```

---

## API Reference

### Core Classes

| Class | Description |
|-------|-------------|
| `FileSystemController` | Main controller for file operations |
| `TransferQueueManager<T>` | Generic queue manager for transfers |
| `DownloadQueueManager` | Specialized queue for downloads |
| `UploadQueueManager` | Specialized queue for uploads |
| `QueuedTransferProvider` | Provider for widget integration |

### Transfer Types

| Class | Description |
|-------|-------------|
| `TransferProgress` | Progress information (bytes, speed, ETA) |
| `TransferResult` | Sealed class: `TransferSuccess`, `TransferFailure`, `TransferCancelled` |
| `TransferStatus` | Enum: `pending`, `running`, `paused`, `completed`, `failed`, `cancelled` |
| `TransferPriority` | Enum: `urgent`, `high`, `normal`, `low` |

### Message Widgets

| Widget | Use Case |
|--------|----------|
| `AudioMessageTransferWidget` | Voice messages, audio files |
| `ImageMessageTransferWidget` | Photos, images |
| `VideoMessageTransferWidget` | Videos |
| `FileMessageTransferWidget` | Generic files (ZIP, APK, etc.) |
| `DocumentMessageTransferWidget` | PDF, DOCX, XLSX, PPTX |

### Handler Interfaces

| Interface | Description |
|-----------|-------------|
| `UploadHandler` | Implement for custom upload logic |
| `DownloadHandler` | Implement for custom download logic |
| `TransferHandler` | Combined upload + download handler |

### Configuration

| Class | Description |
|-------|-------------|
| `TransferWidgetConfig` | Widget behavior configuration |
| `TransferConfig` | Transfer operation configuration |
| `SocialTransferThemeData` | Theme configuration |
| `CancellationToken` | Transfer cancellation control |

### TransferProgress Properties

| Property | Type | Description |
|----------|------|-------------|
| `bytesTransferred` | `int` | Bytes transferred so far |
| `totalBytes` | `int` | Total bytes (-1 if unknown) |
| `progress` | `double` | Progress ratio (0.0 - 1.0) |
| `progressPercent` | `double` | Progress percentage (0 - 100) |
| `bytesPerSecond` | `double` | Transfer speed |
| `estimatedTimeRemaining` | `Duration?` | ETA |
| `status` | `TransferStatus` | Current status |
| `progressText` | `String` | Formatted: "5.2 MB / 10.0 MB" |
| `speedText` | `String` | Formatted: "1.5 MB/s" |
| `etaText` | `String` | Formatted: "2:30 remaining" |

### TransferWidgetConfig Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `autoStart` | `bool` | `false` | Start transfer automatically |
| `showActionButton` | `bool` | `true` | Show download/upload button |
| `showProgress` | `bool` | `true` | Show progress percentage |
| `showSpeed` | `bool` | `true` | Show transfer speed |
| `showFileSize` | `bool` | `true` | Show file size |
| `showEta` | `bool` | `false` | Show estimated time |
| `allowPauseResume` | `bool` | `true` | Enable pause/resume |
| `allowRetry` | `bool` | `true` | Enable retry on failure |
| `allowCancel` | `bool` | `true` | Enable cancel |
| `direction` | `BubbleDirection` | `outgoing` | Message direction |

---

## Example App

The package includes a comprehensive example app demonstrating:

- **Chat Demo**: Message widgets with different file types
- **Queue Demo**: Queue management with priority control
- **Queued Chat Demo**: WhatsApp-like interface with real downloads
- **Settings**: Theme switching, dark mode, RTL toggle

Run the example:

```bash
cd example
flutter run
```

### Example: WhatsApp-like Chat with Real Downloads

```dart
class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final RealDownloadProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = RealDownloadProvider(maxConcurrent: 3);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          // Queue status indicator
          StreamBuilder<TransferQueueState>(
            stream: _provider.stateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state == null || state.totalCount == 0) {
                return SizedBox.shrink();
              }
              return Chip(
                label: Text('${state.runningCount}/${state.pendingCount}'),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildMessage(message);
        },
      ),
    );
  }

  Widget _buildMessage(Message message) {
    switch (message.type) {
      case MessageType.image:
        return ImageMessageTransferWidget(
          url: message.url,
          fileName: message.fileName,
          onDownload: (payload) => _provider.enqueueDownload(
            url: payload.url,
            expectedSize: payload.expectedSize,
          ),
        );
      case MessageType.video:
        return VideoMessageTransferWidget(
          url: message.url,
          duration: message.duration,
          onDownload: (payload) => _provider.enqueueDownload(
            url: payload.url,
          ),
          onPlay: (path) => _openVideoPlayer(path),
        );
      // ... other types
    }
  }
}
```

---

## Migration Guide

### From 0.1.x to 0.2.x

1. **TaskItem renamed to TransferItem**
   ```dart
   // Old
   TaskItem item = ...;

   // New
   TransferItem item = ...;
   ```

2. **New message widgets**
   ```dart
   // Old: Manual widget creation

   // New: Use pre-built widgets
   AudioMessageTransferWidget(...)
   ImageMessageTransferWidget(...)
   VideoMessageTransferWidget(...)
   ```

3. **Theme system updated**
   ```dart
   // Old
   SocialTransferTheme(child: ...)

   // New
   ThemeData(extensions: [SocialTransferThemeData.whatsapp()])
   ```

4. **Custom handlers**
   ```dart
   // New: Use onDownload/onUpload callbacks
   ImageMessageTransferWidget(
     onDownload: (payload) async* { ... },
     onUpload: (payload) async* { ... },
   )
   ```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `background_downloader` | Background download support |
| `cached_network_image` | Network image caching |
| `path_provider` | System directories |
| `crypto` | Hash generation |

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) before submitting a pull request.

## Support

- [GitHub Issues](https://github.com/example/file_system_management/issues)
- [Documentation](https://pub.dev/packages/file_system_management)
