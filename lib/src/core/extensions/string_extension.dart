import 'dart:convert';

/// Extension on String for common string operations.
extension StringFunctions on String {
  /// Converts a JSON string to a Map.
  Map<String, dynamic> toMap() => json.decode(this) as Map<String, dynamic>;

  /// Converts a JSON string to a List of Maps.
  List<Map<String, dynamic>> toListMap() {
    return (json.decode(this) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Converts a JSON string to a List of type T.
  List<T> toList<T>() {
    return (json.decode(this) as List).map((e) => e as T).toList();
  }

  /// Checks if the string is an HTTP URL.
  bool get isHttpUrl => toLowerCase().startsWith('http');

  /// Returns null if the string is empty after trimming, otherwise returns the trimmed string.
  String? get textOrNull => trim().isNotEmpty ? trim() : null;
}
