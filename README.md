# file_system_management

[![pub package](https://img.shields.io/pub/v/file_system_management.svg)](https://pub.dev/packages/file_system_management)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Live Demo](https://img.shields.io/badge/Live_Demo-View_Demo-blue?logo=github)](https://geniussystems24.github.io/file_system_management)


A comprehensive Flutter package for managing file transfers with progress tracking, queue management, social media-inspired UI widgets, and injectable handlers. Built on top of `background_downloader` ^9.4.3.

## Features

| Feature | Description |
|---------|-------------|
| **Parallel Downloads** | Split large files into chunks for faster downloads |
| **Queue Management** | Control concurrent transfers with priority queuing |
| **Batch Operations** | Download/upload multiple files efficiently |
| **Message Widgets** | Ready-to-use widgets for chat applications |
| **Video Player** | Download and play videos with Chewie integration |
| **Display Modes** | Inline or fullscreen playback (like Telegram) |
| **Social Media Themes** | WhatsApp, Telegram, Instagram-inspired designs |
| **Injectable Handlers** | Use your own upload/download providers |
| **Background Downloads** | Continue downloads when app is in background |
| **Foreground Mode** | Run in foreground on Android for longer tasks |
| **Resume Failed** | Continue downloads from failure point |
| **Shared Storage** | Move files to Downloads folder |
| **Caching** | Automatic file caching with URL recognition |
| **Permissions** | Built-in permissions helper |
| **RTL Support** | Full right-to-left language support |

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
| ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |

---

## Table of Contents

- [Installation](#installation)
- [What's New in 1.0.0](#whats-new-in-100)
- [Getting Started](#getting-started)
- [Usage Scenarios](#usage-scenarios)
  - [Scenario 1: Basic File Download](#scenario-1-basic-file-download)
  - [Scenario 2: Parallel Downloads](#scenario-2-parallel-downloads)
  - [Scenario 3: Batch Operations](#scenario-3-batch-operations)
  - [Scenario 4: Chat Application with Message Widgets](#scenario-4-chat-application-with-message-widgets)
  - [Scenario 5: Video Download & Player](#scenario-5-video-download--player)
  - [Scenario 6: Queue Management](#scenario-6-queue-management)
  - [Scenario 7: Upload Operations](#scenario-7-upload-operations)
  - [Scenario 8: Database & Task Management](#scenario-8-database--task-management)
  - [Scenario 9: Shared Storage](#scenario-9-shared-storage)
  - [Scenario 10: Permissions Handling](#scenario-10-permissions-handling)
  - [Scenario 11: Social Media Theming](#scenario-11-social-media-theming)
- [API Reference](#api-reference)
- [Example App](#example-app)
- [Migration Guide](#migration-guide)

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  file_system_management: ^1.0.1
```

**Requirements:**

- Dart SDK: ^3.5.0
- Flutter: >=3.24.0

Then run:

```bash
flutter pub get
```

---

## What's New in 1.0.0

### ⚠️ Breaking Changes

- Minimum Dart SDK upgraded to 3.5.0
- Minimum Flutter SDK upgraded to 3.24.0
- Updated `background_downloader` to ^9.4.3

### New Features

| Feature | Description |
|---------|-------------|
| **Parallel Downloads** | `createParallelDownloadTask()` for faster large file downloads |
| **Resume Failed** | `resumeFailedDownload()` continues from failure point |
| **Reschedule Tasks** | `rescheduleMissingTasks()` recovers tasks after crash |
| **Skip Existing** | Skip downloads if file already exists |
| **Foreground Mode** | Run in foreground on Android for longer tasks |
| **Request Timeout** | Configurable timeout duration |
| **Storage Check** | `availableSpace()` before downloading large files |
| **Permissions** | `permissions` getter for notifications/storage |
| **Batch Operations** | `downloadBatch()` and `uploadBatch()` |
| **Shared Storage** | `moveToSharedStorage()` to Downloads folder |
| **Database Access** | Full task record management |
| **Task Hold/Release** | Control task execution timing |
| **Binary Upload** | Raw bytes upload without multipart |
| **Clean Architecture** | Restructured codebase with domain, data, infrastructure layers |

### Clean Architecture

The package now follows Clean Architecture principles:

```
lib/src/
├── domain/                 # Domain Layer (Business Logic)
│   ├── entities/           # Business entities (TransferEntity, TransferConfigEntity)
│   ├── repositories/       # Abstract repository interfaces
│   ├── usecases/           # Business operations (EnqueueDownload, PauseTransfer, etc.)
│   └── failures/           # Domain-specific error types
│
├── data/                   # Data Layer (Implementation)
│   ├── datasources/        # External data source wrappers (DownloaderDataSource)
│   ├── repositories/       # Repository implementations
│   └── models/             # Data transfer objects (TransferModel)
│
├── infrastructure/         # Infrastructure Layer (Cross-cutting)
│   ├── cache/              # File caching (FileCacheManager)
│   └── storage/            # File storage (AppDirectory)
│
├── presentation/           # Presentation Layer
│   ├── controllers/        # State controllers (TransferController)
│   ├── widgets/            # UI widgets
│   └── theme/              # Theming
│
└── core/                   # Core Utilities
    ├── extensions/         # Dart extensions
    └── utils/              # Utilities
```

#### Using Clean Architecture API

```dart
// Initialize the clean architecture controller
await TransferController.instance.initialize();

// Download using Result pattern
final result = await TransferController.instance.download(
  url: 'https://example.com/file.pdf',
);

// Handle result functionally
result.fold(
  onSuccess: (stream) => stream.listen((entity) {
    print('Progress: ${entity.progressPercent}%');
    print('Speed: ${entity.speed} bytes/s');
  }),
  onFailure: (failure) => print('Error: ${failure.message}'),
);
```

#### Direct Use Case Access

```dart
// Create use cases with dependency injection
final repository = TransferRepositoryImpl(...);
final enqueueDownload = EnqueueDownloadUseCase(repository);

// Execute use case
final result = await enqueueDownload(EnqueueDownloadParams(
  url: 'https://example.com/file.pdf',
  config: TransferConfigEntity(
    maxRetries: 3,
    parallelChunks: 4,
  ),
));
```

| **Multi Upload** | Upload multiple files in single request |
| **Data Upload** | Upload data from memory |
| **Task Options** | Lifecycle callbacks (onTaskStart, onTaskFinished) |
| **Pause/Resume/Cancel** | Individual download controls |

---

## Getting Started

### 1. Initialize the Package

```dart
import 'package:file_system_management/file_system_management.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize directories
  await AppDirectory.init();

  // Initialize with new v1.0.0 options
  await FileSystemController.instance.initialize(
    skipExistingFiles: true,           // Skip if file exists
    skipExistingFilesMinSize: 1024,    // Only skip files > 1KB
    runInForeground: true,             // Android foreground mode
    requestTimeout: Duration(seconds: 30),
  );

  runApp(MyApp());
}
```

### 2. Check Permissions

```dart
// Check notification permission
final status = await FileSystemController.instance.permissions.status(
  PermissionType.notifications,
);

if (status != PermissionStatus.granted) {
  await FileSystemController.instance.permissions.request(
    PermissionType.notifications,
  );
}
```

### 3. Apply Theme (Optional)

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [SocialTransferThemeData.whatsapp()],
  ),
)
```

---

## Usage Scenarios

### Scenario 1: Basic File Download

Download a file with progress tracking and caching:

```dart
// Create a download task with new options
final task = createDownloadTask(
  url: 'https://example.com/document.pdf',
  directory: 'downloads',
  baseDirectory: BaseDirectory.applicationDocuments,
  priority: 8,               // Higher priority (0-10)
  requiresWiFi: false,       // Allow mobile data
  retries: 3,                // Auto-retry 3 times
  options: createTaskOptions(
    onTaskStart: (task) async {
      print('Starting: ${task.filename}');
      return task;  // Return null to cancel
    },
    onTaskFinished: (task, status) {
      print('Finished: ${task.filename} - $status');
    },
  ),
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
    // Download already in progress
    controller.stream.listen((item) => print(item.progressText));

  case EnqueuePending(:final controller):
    // Download queued
    print('Download pending...');
}
```

### Scenario 2: Parallel Downloads

Speed up large file downloads by splitting into chunks:

```dart
// Create parallel download task (4 chunks by default)
final parallelTask = createParallelDownloadTask(
  url: 'https://example.com/large-file.zip',
  chunks: 8,                    // Split into 8 parallel chunks
  filename: 'large-file.zip',
  directory: 'downloads',
  baseDirectory: BaseDirectory.applicationDocuments,
  priority: 10,                 // Highest priority
);

// Enqueue like a regular download
final result = await FileSystemController.instance.enqueueDownload(parallelTask);
```

#### Using Multiple URLs/Mirrors

```dart
// Use multiple URLs for different chunks
final parallelTask = createParallelDownloadTask(
  url: 'https://mirror1.example.com/file.zip',
  urls: [
    'https://mirror1.example.com/file.zip',
    'https://mirror2.example.com/file.zip',
    'https://mirror3.example.com/file.zip',
  ],
  chunks: 6,
);
```

### Scenario 3: Batch Operations

Download or upload multiple files efficiently:

```dart
// Create multiple download tasks
final tasks = [
  createDownloadTask(url: 'https://example.com/file1.pdf'),
  createDownloadTask(url: 'https://example.com/file2.pdf'),
  createDownloadTask(url: 'https://example.com/file3.pdf'),
  createDownloadTask(url: 'https://example.com/file4.pdf'),
  createDownloadTask(url: 'https://example.com/file5.pdf'),
];

// Download batch with progress tracking
final batch = await FileSystemController.instance.downloadBatch(
  tasks,
  onProgress: (succeeded, failed, total) {
    print('Progress: $succeeded/$total succeeded, $failed failed');
  },
  onTaskComplete: (task, status) {
    print('${task.filename}: $status');
  },
);

print('Batch complete: ${batch.succeeded}/${batch.total} succeeded');
```

#### Batch Uploads

```dart
final uploadTasks = [
  createUploadTask(url: uploadUrl, filePath: '/path/to/file1.jpg'),
  createUploadTask(url: uploadUrl, filePath: '/path/to/file2.jpg'),
];

final batch = await FileSystemController.instance.uploadBatch(
  uploadTasks,
  onProgress: (succeeded, failed, total) {
    print('Uploaded: $succeeded/$total');
  },
);
```

### Scenario 4: Chat Application with Message Widgets

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
    allowPauseResume: true,
  ),
  onDownload: (payload) async* {
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
```

### Scenario 5: Video Download & Player

Download videos with progress tracking and play them with a beautiful player:

#### Inline Mode (Default)

Play videos within the widget, like WhatsApp:

```dart
VideoDownloadPlayerWidget(
  url: 'https://example.com/video.mp4',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  fileName: 'video.mp4',
  fileSize: 10 * 1024 * 1024, // 10 MB
  duration: Duration(minutes: 2, seconds: 30),
  config: VideoPlayerConfig(
    displayMode: VideoDisplayMode.inline,
    autoPlay: true,
    showControls: true,
    looping: false,
  ),
  themeData: SocialTransferThemeData.telegram(),
  onDownload: (payload) => downloadService.download(payload),
  onDownloadComplete: (path) => print('Downloaded: $path'),
  onPlayStart: () => print('Video started'),
  onPlayComplete: () => print('Video finished'),
)
```

#### Fullscreen Mode (Like Telegram)

Open a dedicated fullscreen player when tapped:

```dart
VideoDownloadPlayerWidget(
  url: 'https://example.com/video.mp4',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  title: 'My Video',
  subtitle: 'Video description',
  config: VideoPlayerConfig(
    displayMode: VideoDisplayMode.fullscreen,  // Opens fullscreen player
    autoPlay: true,
    showCloseButton: true,
    hideStatusBarInFullscreen: true,
  ),
  onDownload: (payload) => downloadService.download(payload),
)
```

#### Direct Fullscreen Player

Open fullscreen player programmatically:

```dart
// Using static method
await FullscreenVideoPlayer.open(
  context,
  url: 'https://example.com/video.mp4',
  title: 'Video Title',
  subtitle: 'Video description',
  config: VideoPlayerConfig(
    autoPlay: true,
    looping: true,
  ),
  themeData: SocialTransferThemeData.whatsApp(),
);

// Or as a widget
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => FullscreenVideoPlayer(
      url: 'https://example.com/video.mp4',
      title: 'My Video',
    ),
  ),
);
```

#### Video Player Configuration

```dart
VideoPlayerConfig(
  // Display Mode
  displayMode: VideoDisplayMode.inline,     // or .fullscreen

  // Playback
  autoStartDownload: false,                 // Auto-start download
  autoPlay: true,                           // Auto-play after download
  looping: false,                           // Loop video
  showControls: true,                       // Show player controls

  // Fullscreen Options
  showCloseButton: true,                    // Show close button
  hideStatusBarInFullscreen: true,          // Hide status bar
  fullscreenBackgroundColor: Colors.black,  // Background color

  // Advanced
  aspectRatio: 16 / 9,                      // Custom aspect ratio
  allowFullScreen: true,                    // Allow fullscreen toggle
  allowPlaybackSpeedChanging: true,         // Speed controls
  allowMuting: true,                        // Mute controls
)
```

### Scenario 6: Queue Management

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

// Monitor queue state
queue.stateStream.listen((state) {
  print('Running: ${state.runningCount}/${state.maxConcurrent}');
  print('Pending: ${state.pendingCount}');
  print('Progress: ${(state.overallProgress * 100).toStringAsFixed(1)}%');
});

// Queue control operations
queue.pause();
queue.start();
queue.cancel('download_id');
queue.cancelAll();
queue.retry('download_id');
queue.moveToFront('download_id');
queue.changePriority('id', TransferPriority.urgent);
queue.maxConcurrent = 5;  // Adjust dynamically

// Wait for all downloads
final results = await queue.waitForAll();
```

#### Individual Pause/Resume/Cancel

```dart
final provider = RealDownloadProvider(maxConcurrent: 3);

// Start download
provider.enqueueDownload(url: 'https://example.com/file.zip');

// Pause specific download
await provider.pauseDownload('https://example.com/file.zip');

// Check if paused
final isPaused = provider.isDownloadPaused('https://example.com/file.zip');

// Resume download
await provider.resumeDownload('https://example.com/file.zip');

// Cancel download
provider.cancel('https://example.com/file.zip');
```

### Scenario 7: Upload Operations

#### Standard Upload (Multipart)

```dart
final task = createUploadTask(
  url: 'https://api.example.com/upload',
  filePath: '/path/to/file.jpg',
  filename: 'photo.jpg',
  mimeType: 'image/jpeg',
  headers: {'Authorization': 'Bearer token'},
  fields: {'description': 'My photo', 'album': 'vacation'},
  priority: 8,
  retries: 2,
);

await FileSystemController.instance.enqueueUpload(task);
```

#### Binary Upload (Raw bytes)

```dart
// For APIs expecting raw file content in request body
final task = createBinaryUploadTask(
  url: 'https://api.example.com/upload',
  filePath: '/path/to/file.bin',
  httpRequestMethod: 'PUT',
  mimeType: 'application/octet-stream',
);

await FileSystemController.instance.enqueueUpload(task);
```

#### Multi-File Upload

```dart
// Upload multiple files in a single request
final task = createMultiUploadTask(
  url: 'https://api.example.com/upload',
  files: [
    ('photo1', '/path/to/image1.jpg'),
    ('photo2', '/path/to/image2.jpg'),
    ('document', '/path/to/file.pdf'),
  ],
  fields: {'album': 'vacation'},
);

await FileSystemController.instance.enqueueUpload(task);
```

#### Data Upload (From Memory)

```dart
// Upload generated data or small payloads
final task = createDataUploadTask(
  url: 'https://api.example.com/data',
  data: jsonEncode({'name': 'John', 'age': 30}),
  contentType: 'application/json',
  httpRequestMethod: 'POST',
);

await FileSystemController.instance.enqueueUpload(task);
```

#### Authenticated Upload

```dart
final task = createUploadTask(
  url: 'https://api.example.com/upload',
  filePath: '/path/to/file.jpg',
  options: createAuthenticatedOptions(
    username: 'user',
    password: 'pass',
    onTaskFinished: (task, status) {
      print('Upload finished: $status');
    },
  ),
);
```

### Scenario 8: Database & Task Management

#### Resume Failed Downloads

```dart
final controller = FileSystemController.instance;

// Get failed downloads
final failedRecords = await controller.getRecordsByStatus(TaskStatus.failed);

for (final record in failedRecords) {
  final item = TransferItem.fromRecord(record);

  // Resume from where it stopped (requires server ETag support)
  final success = await controller.resumeFailedDownload(item);
  print('Resume ${item.filename}: $success');
}
```

#### Reschedule Missing Tasks (After Crash)

```dart
// Recover tasks after app restart/crash
final (succeeded, failed) = await FileSystemController.instance.rescheduleMissingTasks();

print('Rescheduled ${succeeded.length} tasks');
print('Failed to reschedule ${failed.length} tasks');
```

#### Database Operations

```dart
final controller = FileSystemController.instance;

// Get all records
final allRecords = await controller.getAllRecords();

// Get record by ID
final record = await controller.getRecordById('task-id');

// Get records by status
final completedRecords = await controller.getRecordsByStatus(TaskStatus.complete);
final runningRecords = await controller.getRecordsByStatus(TaskStatus.running);

// Delete specific record
await controller.deleteRecord('task-id');

// Delete all records
await controller.deleteAllRecords();

// Delete by status
await controller.deleteRecordsByStatus(TaskStatus.failed);
```

#### Task Hold/Release

```dart
final controller = FileSystemController.instance;

// Create task but don't start yet
final task = createDownloadTask(url: 'https://example.com/file.zip');

// Hold the task (prevents execution)
await controller.holdTask(task);

// Enqueue (won't start because it's held)
await controller.enqueueDownload(task);

// Later, release the task to start
await controller.releaseTask(task);

// Or release all held tasks in a group
await controller.releaseHeldTasks(group: 'my-group');
```

#### Task Queries

```dart
final controller = FileSystemController.instance;

// Get all tracked tasks
final allTasks = await controller.getAllTasks();

// Get tasks in a specific group
final groupTasks = await controller.getTasksByGroup('downloads');

// Get task by ID
final task = await controller.getTaskById('task-id');

// Reset (cancel all and clear database)
await controller.reset();
```

### Scenario 9: Shared Storage

Move completed downloads to public Downloads folder:

```dart
final controller = FileSystemController.instance;

// After download completes
final result = await controller.enqueueDownload(task);

if (result case EnqueueStarted(:final controller)) {
  controller.stream.listen((item) async {
    if (item.isComplete) {
      // Move to Downloads folder
      final sharedPath = await FileSystemController.instance.moveToSharedStorage(
        item,
        destination: SharedStorage.downloads,
        directory: 'MyApp',  // Creates MyApp folder in Downloads
        mimeType: 'application/pdf',
      );

      print('File moved to: $sharedPath');
    }
  });
}

// Check if file is in shared storage
final isShared = await controller.isInSharedStorage(filePath);

// Open file from path
await controller.openFileByPath(filePath, mimeType: 'application/pdf');
```

#### Check Available Space

```dart
// Check space before downloading large file
final availableBytes = await FileSystemController.instance.availableSpace(
  baseDirectory: BaseDirectory.applicationDocuments,
);

final requiredBytes = 500 * 1024 * 1024;  // 500 MB

if (availableBytes != null && availableBytes > requiredBytes) {
  // Safe to download
  await controller.enqueueDownload(largeFileTask);
} else {
  // Warn user about insufficient space
  showInsufficientSpaceDialog();
}
```

### Scenario 10: Permissions Handling

```dart
final permissions = FileSystemController.instance.permissions;

// Check notification permission
final notifStatus = await permissions.status(PermissionType.notifications);

if (notifStatus != PermissionStatus.granted) {
  final result = await permissions.request(PermissionType.notifications);
  print('Notification permission: $result');
}

// Check storage permission (Android)
final storageStatus = await permissions.status(PermissionType.storage);

if (storageStatus == PermissionStatus.denied) {
  await permissions.request(PermissionType.storage);
}
```

### Scenario 11: Social Media Theming

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
```

---

## API Reference

### FileSystemController

Main controller for file operations.

#### Initialization

| Method | Description |
|--------|-------------|
| `initialize()` | Initialize the controller with options |
| `dispose()` | Cleanup resources |

**Initialize Options:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `skipExistingFiles` | `bool` | `false` | Skip if file exists |
| `skipExistingFilesMinSize` | `int?` | `null` | Min size for skipping |
| `runInForeground` | `bool` | `false` | Android foreground mode |
| `requestTimeout` | `Duration?` | `null` | Request timeout |

#### Download Operations

| Method | Description |
|--------|-------------|
| `enqueueDownload(task)` | Enqueue a download task |
| `pause(item)` | Pause a download |
| `resume(item)` | Resume a download |
| `cancel(item)` | Cancel a download |
| `retry(item)` | Retry a failed download |
| `resumeFailedDownload(item)` | Resume from failure point |
| `openFile(item)` | Open completed file |

#### Batch Operations

| Method | Description |
|--------|-------------|
| `downloadBatch(tasks)` | Download multiple files |
| `uploadBatch(tasks)` | Upload multiple files |
| `pauseAll(items)` | Pause multiple transfers |
| `resumeAll(items)` | Resume multiple transfers |
| `cancelAll(items)` | Cancel multiple transfers |

#### Shared Storage

| Method | Description |
|--------|-------------|
| `moveToSharedStorage(item)` | Move to Downloads folder |
| `isInSharedStorage(path)` | Check if in shared storage |
| `openFileByPath(path)` | Open file by path |
| `availableSpace()` | Check available storage |

#### Database Operations

| Method | Description |
|--------|-------------|
| `getAllRecords()` | Get all task records |
| `getRecordById(id)` | Get record by ID |
| `getRecordsByStatus(status)` | Get records by status |
| `deleteRecord(id)` | Delete a record |
| `deleteAllRecords()` | Delete all records |
| `deleteRecordsByStatus(status)` | Delete by status |

#### Task Management

| Method | Description |
|--------|-------------|
| `holdTask(task)` | Hold task from executing |
| `releaseTask(task)` | Release held task |
| `releaseHeldTasks()` | Release all held tasks |
| `getAllTasks()` | Get all tracked tasks |
| `getTasksByGroup(group)` | Get tasks by group |
| `getTaskById(id)` | Get task by ID |
| `rescheduleMissingTasks()` | Recover tasks after crash |
| `reset()` | Cancel all and clear database |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `permissions` | `Permissions` | Permissions helper |
| `isInitialized` | `bool` | Initialization state |
| `activeTransfers` | `Map<String, TransferItem>` | Active transfers |
| `completedPaths` | `Map<String, String>` | Cached file paths |

### Task Factory Functions

| Function | Description |
|----------|-------------|
| `createDownloadTask()` | Create standard download task |
| `createParallelDownloadTask()` | Create parallel download task |
| `createUploadTask()` | Create multipart upload task |
| `createBinaryUploadTask()` | Create binary upload task |
| `createMultiUploadTask()` | Create multi-file upload task |
| `createDataUploadTask()` | Create data upload task |
| `createTaskOptions()` | Create task lifecycle options |
| `createAuthenticatedOptions()` | Create authenticated options |

### createDownloadTask Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | `String` | required | Download URL |
| `filename` | `String?` | URL hash | File name |
| `directory` | `String` | `""` | Subdirectory |
| `baseDirectory` | `BaseDirectory` | `temporary` | Base directory |
| `allowPause` | `bool` | `true` | Allow pausing |
| `updates` | `Updates` | `statusAndProgress` | Update type |
| `group` | `String?` | default | Task group |
| `headers` | `Map<String, String>?` | `null` | HTTP headers |
| `metaData` | `String?` | `null` | Custom metadata |
| `priority` | `int` | `5` | Priority (0-10) |
| `requiresWiFi` | `bool` | `false` | Require WiFi |
| `retries` | `int` | `0` | Auto-retry count |
| `options` | `TaskOptions?` | `null` | Task options |

### createParallelDownloadTask Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | `String` | required | Primary URL |
| `urls` | `List<String>?` | `null` | Mirror URLs |
| `chunks` | `int` | `4` | Parallel chunks |
| Plus all standard download options |

### Queue Classes

| Class | Description |
|-------|-------------|
| `TransferQueueManager<T>` | Generic queue manager |
| `DownloadQueueManager` | Specialized download queue |
| `UploadQueueManager` | Specialized upload queue |
| `QueuedTransferProvider` | Widget integration provider |
| `RealDownloadProvider` | Production download provider |

### Message Widgets

| Widget | Use Case |
|--------|----------|
| `AudioMessageTransferWidget` | Voice messages, audio files |
| `ImageMessageTransferWidget` | Photos, images |
| `VideoMessageTransferWidget` | Videos with download in chat |
| `FileMessageTransferWidget` | Generic files (ZIP, APK, etc.) |
| `DocumentMessageTransferWidget` | PDF, DOCX, XLSX, PPTX |

### Video Player Widgets

| Widget | Use Case |
|--------|----------|
| `VideoDownloadPlayerWidget` | Download and play videos with Chewie |
| `FullscreenVideoPlayer` | Standalone fullscreen player |

### Video Player Enums & Config

| Class | Description |
|-------|-------------|
| `VideoDisplayMode` | Enum: `inline`, `fullscreen` |
| `VideoPlayerState` | Enum: `idle`, `downloading`, `paused`, `failed`, `ready`, `initializing`, `playing`, `playbackError` |
| `VideoPlayerConfig` | Configuration for display mode, playback, and controls |

### Transfer Types

| Class | Description |
|-------|-------------|
| `TransferProgress` | Progress information (bytes, speed, ETA) |
| `TransferResult` | Sealed: `TransferSuccess`, `TransferFailure`, `TransferCancelled` |
| `TransferStatus` | Enum: `pending`, `running`, `paused`, `completed`, `failed`, `cancelled` |
| `TransferPriority` | Enum: `urgent`, `high`, `normal`, `low` |
| `TransferItem` | Transfer state wrapper |

---

## Example App

The package includes a comprehensive example app demonstrating:

- **Chat Demo**: Message widgets with different file types
- **Queue Demo**: Queue management with priority control
- **Queued Chat Demo**: WhatsApp-like interface with real downloads
- **Video/Audio Playback**: Media playback after download
- **Settings**: Theme switching, dark mode, RTL toggle

Run the example:

```bash
cd example
flutter run
```

---

## Migration Guide

### From 0.2.x to 1.0.0

1. **Update SDK requirements**

   ```yaml
   environment:
     sdk: ^3.5.0
     flutter: ">=3.24.0"
   ```

2. **New initialization options**

   ```dart
   // Old
   await FileSystemController.instance.initialize();

   // New (with options)
   await FileSystemController.instance.initialize(
     skipExistingFiles: true,
     runInForeground: true,
     requestTimeout: Duration(seconds: 30),
   );
   ```

3. **New download task options**

   ```dart
   // Old
   final task = createDownloadTask(url: url);

   // New (with priority, retries, options)
   final task = createDownloadTask(
     url: url,
     priority: 8,
     requiresWiFi: false,
     retries: 3,
     options: createTaskOptions(
       onTaskStart: (task) async => task,
       onTaskFinished: (task, status) {},
     ),
   );
   ```

4. **Parallel downloads**

   ```dart
   // New in 1.0.0
   final task = createParallelDownloadTask(
     url: url,
     chunks: 8,
   );
   ```

5. **Batch operations**

   ```dart
   // New in 1.0.0
   await controller.downloadBatch(tasks, onProgress: ...);
   await controller.uploadBatch(tasks, onProgress: ...);
   ```

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
   // Use pre-built widgets
   AudioMessageTransferWidget(...)
   ImageMessageTransferWidget(...)
   ```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `background_downloader` | Background download support (^9.4.3) |
| `cached_network_image` | Network image caching |
| `video_player` | Video playback (^2.9.2) |
| `chewie` | Video player UI controls (^1.8.5) |
| `path_provider` | System directories |
| `crypto` | Hash generation |

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) before submitting a pull request.

## Support

- [GitHub Issues](https://github.com/GeniusSystems24/file_system_management/issues)
- [Documentation](https://pub.dev/packages/file_system_management)
