# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-12-30

### Added

#### Video Download & Player Widget
- **VideoDownloadPlayerWidget** - All-in-one widget for downloading and playing videos
  - Download progress with speed and percentage display
  - Integrated Chewie player for beautiful video controls
  - Thumbnail support with cached network images
  - Duration badge overlay
  - Theme integration with `SocialTransferThemeData`

#### Display Modes
- **VideoDisplayMode** enum with two modes:
  - `inline` - Play video within the card widget (like WhatsApp)
  - `fullscreen` - Open dedicated fullscreen player (like Telegram)

#### Fullscreen Video Player
- **FullscreenVideoPlayer** widget and static `open()` method
  - Immersive fullscreen experience
  - Custom controls overlay with gradient backgrounds
  - Title and subtitle support in top bar
  - Close button and more options menu
  - Progress slider with time labels
  - Play/pause center controls
  - Landscape/portrait rotation support
  - Auto-hide status bar option
  - Configurable background color

#### VideoPlayerConfig Options
- `displayMode` - Choose inline or fullscreen mode
- `autoStartDownload` - Auto-start download on widget init
- `autoPlay` - Auto-play after download completes
- `looping` - Loop video playback
- `showControls` - Show/hide player controls
- `showCloseButton` - Show close button in fullscreen
- `hideStatusBarInFullscreen` - Hide status bar in fullscreen
- `fullscreenBackgroundColor` - Background color for fullscreen
- `aspectRatio` - Custom aspect ratio
- `allowFullScreen` - Allow fullscreen toggle
- `allowPlaybackSpeedChanging` - Speed controls
- `allowMuting` - Mute controls
- `progressColors` - Custom Chewie progress colors

#### New Dependencies
- `video_player: ^2.9.2` - Official Flutter video player
- `chewie: ^1.8.5` - Beautiful video player UI wrapper

### Changed

- Updated example app with Video Player demo screen
- Added display mode examples showing inline vs fullscreen
- Updated home screen with Video Player feature card

---

## [1.0.0] - 2025-12-27

### ⚠️ Breaking Changes

- Minimum Dart SDK upgraded to 3.5.0
- Minimum Flutter SDK upgraded to 3.24.0
- Updated `background_downloader` to ^9.4.3

### Added

#### Clean Architecture Restructuring
- **Domain Layer** - Pure business logic without external dependencies
  - `TransferEntity` - Core transfer business entity
  - `TransferConfigEntity` - Transfer configuration entity
  - `TransferRepository` - Abstract repository interface
  - `StorageRepository` - Storage operations interface
  - `CacheRepository` - Cache operations interface
  - `PermissionRepository` - Permission handling interface
  - `Result<T>` - Functional error handling with `Success`/`Fail`
  - Sealed `Failure` classes: `NetworkFailure`, `StorageFailure`, `CancelledFailure`, etc.
  - Use cases: `EnqueueDownloadUseCase`, `EnqueueParallelDownloadUseCase`, `EnqueueUploadUseCase`, `PauseTransferUseCase`, `ResumeTransferUseCase`, `CancelTransferUseCase`, `GetTransferUseCase`, `GetAllTransfersUseCase`, `CheckAvailableSpaceUseCase`

- **Data Layer** - Repository implementations
  - `DownloaderDataSource` - Wrapper for background_downloader
  - `TransferRepositoryImpl` - Full repository implementation
  - `TransferModel` - Data transfer object with mapping

- **Infrastructure Layer** - Cross-cutting concerns
  - `FileCacheManager` - LRU cache with stale entry cleanup
  - `AppDirectory` - Application directory management

- **Presentation Layer** - UI components
  - `TransferController` - Facade controller with clean API
  - Maintains existing widgets and themes

- **Core Module** - Shared utilities
  - Extensions, mutex, queue managers

#### New background_downloader Features
- **Parallel Downloads** - `createParallelDownloadTask()` for faster large file downloads
  - Split files into multiple chunks for simultaneous download
  - Support for multiple URLs/mirrors
  - Configurable chunk count
- **Resume Failed Downloads** - `resumeFailedDownload()` continues from failure point
  - Works even without `allowPause` enabled
  - Requires server ETag support
- **Reschedule Missing Tasks** - `rescheduleMissingTasks()` recovers tasks after crash
  - Compares database with native downloader
  - Returns success/failure lists
- **Skip Existing Files** - `Config.skipExistingFiles` option
  - Skip downloads if file already exists
  - Optional minimum size threshold
- **Foreground Mode** - Run in foreground on Android for longer tasks
- **Request Timeout** - Configurable timeout duration
- **Storage Space Check** - `availableSpace()` before downloading large files
- **Permissions Helper** - `permissions` getter for notifications/storage permissions

#### Enhanced FileSystemController
- New `initialize()` parameters:
  - `skipExistingFiles` - Skip if file exists
  - `skipExistingFilesMinSize` - Size threshold for skipping
  - `runInForeground` - Android foreground mode
  - `requestTimeout` - Request timeout duration

#### Enhanced createDownloadTask
- `priority` - Task priority (0-10)
- `requiresWiFi` - Require WiFi connection
- `retries` - Auto-retry count
- `options` - Advanced TaskOptions (onTaskStart, onTaskFinished, auth)

#### Individual Download Controls
- `pauseDownload(url)` - Pause specific download
- `resumeDownload(url)` - Resume specific download
- `isDownloadPaused(url)` - Check pause state
- UI controls in example app for pause/resume/cancel

### Changed

- Improved concurrency on mobile (JSON encoding in isolate)
- Better thread safety with job queue for message execution

---

## [0.2.1] - 2025-12-27

### Added

#### Queue Management System with Custom Executors
- `QueuedTransferProvider` - Flexible provider with multiple integration options
  - Constructor with optional `downloadExecutor` callback
  - `QueuedTransferProvider.withHandler()` - Integration with `DownloadHandler` classes
  - `QueuedTransferProvider.withCallback()` - Simple callback-based integration
  - `createDownloadCallback()` for widget integration
- `RealDownloadProvider` - Production-ready provider using `FileSystemController`
  - Real file downloads with progress tracking
  - Automatic file caching with URL recognition
  - Cache lookup with `getCachedPath()` and `getCompletedPath()`
  - Full queue management with pause/resume/cancel/retry
  - Integration with `background_downloader` package

#### WhatsApp-like Example App
- Redesigned `QueuedChatDemoScreen` with WhatsApp-inspired UI
  - Chat bubble styling with incoming/outgoing message differentiation
  - Green color scheme matching WhatsApp theme
  - Timestamps and read receipts (blue ticks)
  - Arabic RTL support
- Video playback integration using `video_player` and `chewie`
  - Full video controls after download
  - Aspect ratio preservation
  - WhatsApp-style progress colors
- Audio playback integration using `just_audio`
  - Waveform visualization with progress indicator
  - Play/pause controls
  - Duration and position display
- Full-screen image viewer with zoom support
- Document/file opening with `open_filex`
- Download progress shown inside circular buttons

#### Queue Management System
- `TransferQueueManager<T>` - Generic queue manager with configurable concurrency
  - Priority-based queue (urgent, high, normal, low)
  - Configurable `maxConcurrent` transfers
  - Auto-retry support with configurable `maxRetries`
  - Pause/resume queue operations
  - Cancel individual or all transfers
  - Change priority of queued transfers
  - Move transfers to front of queue
  - Stream-based state updates
  - Overall progress tracking
- `DownloadQueueManager` - Specialized download queue
  - Integration with `FileSystemController`
  - Add by URL or `DownloadTask`
  - Add multiple URLs at once
  - Progress tracking per download
  - Pause/resume individual downloads
  - Wait for specific or all downloads
- `UploadQueueManager` - Specialized upload queue
  - Similar API to `DownloadQueueManager`
  - Add files by path or `UploadTask`
- `QueuedTransfer<T>` - Individual transfer wrapper
  - Progress stream
  - Future completion
  - Cancellation token
  - Queue position tracking
  - Metadata support
- `TransferPriority` enum - Priority levels for queue ordering
- `QueuedTransferStatus` enum - Status tracking for queued transfers
- `TransferQueueState<T>` - Queue state snapshot with statistics
- `TransferQueueResult<T>` - Result wrapper for completed transfers

#### Queue Integration with Message Widgets
- `QueuedTransferProvider` - Provider for integrating queue with message widgets
  - `enqueueDownload()` - Enqueue downloads from widget callbacks
  - `createDownloadCallback()` - Create reusable download callbacks
  - Queue position tracking per widget
  - Priority support for widget downloads
- `QueuedChatDemoScreen` - Example screen demonstrating queue with widgets
  - Real-time queue status display
  - Dynamic concurrent limit adjustment
  - Queue position indicators per message
  - Move to front / cancel controls
  - Real Firebase Storage URLs demonstration
  - Multiple file types (images, PDF, video, audio, ZIP)

### Changed

- `DownloadPayload` now includes `headers` property for custom request headers
- `TransferQueueManager` now exposes `allTransfers` getter for accessing all queued transfers
- Improved generic type handling in `TransferQueueState<T>` stream

## [0.2.0] - 2025-12-26

### Added

#### Injectable Upload/Download Handlers
- `UploadHandler` and `DownloadHandler` abstract classes for custom backend integration
- `TransferProgress` model with comprehensive progress tracking (bytes, speed, ETA)
- `TransferResult` sealed class with `TransferSuccess`, `TransferFailure`, `TransferCancelled`
- `CancellationToken` for fine-grained transfer control
- `TransferConfig` for configuring headers, timeouts, retries
- `UploadPayload` and `DownloadPayload` for transfer parameters
- `TransferBuilder` for fluent API with callbacks

#### Social Media Skins & Theming
- `SocialTransferThemeData` with comprehensive theming support
- `SocialTransferTheme` InheritedWidget for theme propagation
- `SocialSkin` enum: `whatsapp`, `telegram`, `instagram`, `custom`
- Pre-built themes:
  - `SocialTransferThemeData.whatsapp()` - WhatsApp-inspired design
  - `SocialTransferThemeData.telegram()` - Telegram-inspired design
  - `SocialTransferThemeData.instagram()` - Instagram-inspired design
- Dark mode support for all skins (`isDark: true`)
- RTL support built-in
- Customizable colors, typography, shapes, icons, animations

#### Message Transfer Widgets
- `AudioMessageTransferWidget` - Audio/voice message transfers
  - Waveform visualization
  - Duration display
  - Play/pause controls
  - Playback progress
- `ImageMessageTransferWidget` - Image message transfers
  - Thumbnail preview with blur overlay
  - Full image display after completion
  - Caption support
  - Full-screen preview
- `VideoMessageTransferWidget` - Video message transfers
  - Thumbnail preview
  - Duration badge
  - Play button overlay
  - Mute indicator
- `FileMessageTransferWidget` - Generic file transfers
  - Auto-detected file type icons
  - Extension badge
  - Multiple file type support
- `DocumentMessageTransferWidget` - Document transfers (PDF, DOCX, etc.)
  - Document type icons with colors
  - Page count display
  - Thumbnail preview option

#### Base Widget System
- `BaseMessageTransferWidget` abstract class for common functionality
- `TransferWidgetState` enum for UI states
- `TransferWidgetConfig` for widget configuration
- `BubbleDirection` enum for incoming/outgoing messages
- Built-in state management
- Progress tracking
- Pause/resume/cancel/retry support

### Changed

- Enhanced `TransferItem` with more status helpers
- Updated main library exports to include new modules
- Improved documentation with comprehensive examples

### Deprecated

- `TaskItem` - Use `TransferItem` instead (still exported for compatibility)

## [0.1.0] - Initial Release

### Added

- File download with progress tracking
- Pause, resume, and cancel downloads
- Background download support
- Notification support for download status
- Thumbnail preview for media files
- Stream-based progress updates
- `FileSystemController` singleton for global access
- Mutex-based locking to prevent duplicate operations
- Automatic file caching with URL recognition
- `MediaDownloadCard` widget
- `DocumentDownloadCard` widget
- `TransferCard` widget
- `TransferProgressIndicator` widget
- `TransferItem` model with comprehensive properties
- `FileModel` for file metadata
- `FileTypeEnum` for file categorization
- Core utilities: `AppDirectory`, `FileCacheManager`, `TaskMutex`
- String and path extensions
