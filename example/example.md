# file_system_management Example

This example app demonstrates all features of the `file_system_management` package.

## Features Demonstrated

### Downloads
| Feature | Description | Screen |
|---------|-------------|--------|
| **Parallel Downloads** | Split large files into chunks for faster downloads | `/parallel-downloads` |
| **Batch Downloads** | Download multiple files efficiently | `/batch-downloads` |
| **Background Downloads** | Continue downloads when app is minimized | `/background-downloads` |

### Queue Management
| Feature | Description | Screen |
|---------|-------------|--------|
| **Queue Management** | Control concurrent transfers with priority queuing | `/queue-management` |

### UI Components
| Feature | Description | Screen |
|---------|-------------|--------|
| **Message Widgets** | Ready-to-use widgets for chat applications | `/message-widgets` |
| **Social Themes** | WhatsApp, Telegram, Instagram-inspired designs | `/social-themes` |

### Advanced Features
| Feature | Description | Screen |
|---------|-------------|--------|
| **Custom Handlers** | Inject your own upload/download providers | `/custom-handlers` |
| **Shared Storage** | Move files to Downloads folder, resume failed | `/shared-storage` |
| **Cache Management** | Automatic file caching with URL recognition | `/cache-management` |

### System Features
| Feature | Description | Screen |
|---------|-------------|--------|
| **Permissions** | Built-in permissions helper | `/permissions` |
| **RTL Support** | Full right-to-left language support | `/rtl-support` |

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## Project Structure

```
example/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/
│   │   └── router.dart           # go_router configuration
│   ├── features/
│   │   ├── home/                 # Home screen
│   │   ├── downloads/            # Download features
│   │   │   ├── parallel_downloads_screen.dart
│   │   │   ├── batch_downloads_screen.dart
│   │   │   └── background_downloads_screen.dart
│   │   ├── queue/                # Queue management
│   │   ├── widgets/              # Message widgets demo
│   │   ├── themes/               # Social themes demo
│   │   ├── handlers/             # Custom handlers demo
│   │   ├── storage/              # Shared storage demo
│   │   ├── cache/                # Cache management demo
│   │   ├── permissions/          # Permissions demo
│   │   └── rtl/                  # RTL support demo
│   └── shared/
│       ├── constants/            # Sample files, constants
│       └── widgets/              # Shared widgets
└── pubspec.yaml
```

## Sample Code

### Basic Download

```dart
final controller = TransferController.instance;

// Initialize once
await controller.initialize();

// Download a file
final result = await controller.download(
  url: 'https://example.com/file.zip',
  fileName: 'file.zip',
);

final stream = result.valueOrNull;
if (stream != null) {
  await for (final entity in stream) {
    print('Progress: ${entity.progress * 100}%');
    if (entity.isComplete) {
      print('Downloaded to: ${entity.filePath}');
    }
  }
}
```

### Parallel Download

```dart
final result = await controller.downloadParallel(
  url: 'https://example.com/large-file.zip',
  chunks: 4,  // Split into 4 chunks
);
```

### With Custom Theme

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      SocialTransferThemeData.whatsapp(),
    ],
  ),
)

// In widgets:
ImageMessageTransferWidget(
  thumbnailUrl: 'https://example.com/thumb.jpg',
  fileName: 'photo.jpg',
  progress: 0.65,
  status: TransferStatus.running,
  onTap: () => openImage(),
)
```

### Custom Handler

```dart
class MyDownloadHandler implements DownloadHandler {
  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    // Your custom download logic here
    // e.g., Firebase Storage, AWS S3, etc.
  }
}
```

## Dependencies

- `go_router` - Navigation
- `file_system_management` - Core package
- `video_player` / `chewie` - Video playback
- `just_audio` - Audio playback
- `open_filex` - Open downloaded files

## Screenshots

The example app includes:
- Home screen with categorized features
- Individual demo screens for each feature
- Code snippets and usage examples
- Activity logs for debugging

## License

Same as the main package.
