/// Presentation layer barrel file.
///
/// The presentation layer contains UI components and state management.
///
/// Structure:
/// - controllers/: State controllers
/// - widgets/: UI widgets
/// - theme/: Theming
/// - providers/: State providers
library;

export 'controllers/transfer_controller.dart';

// Re-export existing widgets and theme
export '../widgets/transfer_card.dart';
export '../widgets/transfer_progress_indicator.dart';
export '../widgets/media_download_card.dart';
export '../widgets/document_download_card.dart';
export '../widgets/messages/messages.dart';
export '../theme/social_transfer_theme.dart';
