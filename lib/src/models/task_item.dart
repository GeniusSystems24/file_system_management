/// Legacy compatibility file - TaskItem is now an alias for TransferItem.
///
/// This file maintains backward compatibility with code using TaskItem.
/// For new code, use [TransferItem] directly.
library;

export 'transfer_item.dart' show TransferItem, TransferType, BaseDirectoryPath, TaskStatusUI;

// Re-export TransferItem as TaskItem for backward compatibility
import 'transfer_item.dart';

/// @Deprecated('Use TransferItem instead')
/// Legacy alias for [TransferItem].
///
/// This typedef is provided for backward compatibility.
/// New code should use [TransferItem] directly.
typedef TaskItem = TransferItem;
