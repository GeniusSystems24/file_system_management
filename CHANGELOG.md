# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-26

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

## [0.0.1] - Initial Release

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
