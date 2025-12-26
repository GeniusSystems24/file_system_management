import 'package:flutter/widgets.dart';

typedef OnEventListener<T> =
    void Function(T data, {bool notify, bool didReplaced, int? index});

/// A class that extends [ValueNotifier] and provides additional functionality for managing a list of items.
class ListNotifier<T> extends ValueNotifier<List<T>> {
  /// Constructs a [ListNotifier] instance with an initial list of items.
  ListNotifier(super.initialList);

  final List<OnEventListener<T>> _onAddListener = [];
  void addOnAddListener(OnEventListener<T> listener) =>
      _onAddListener.add(listener);

  bool removeOnAddListener(OnEventListener<T> listener) =>
      _onAddListener.remove(listener);

  final List<OnEventListener<T>> _onRemoveListener = [];

  void addOnRemoveListener(OnEventListener<T> listener) =>
      _onRemoveListener.add(listener);

  bool removeOnRemoveListener(OnEventListener<T> listener) =>
      _onRemoveListener.remove(listener);

  /// Adds an item to the list and notifies listeners.
  T add(T item, {bool notify = true}) {
    value.add(item);

    for (final elementListener in _onAddListener) {
      elementListener(item, notify: notify, didReplaced: false);
    }

    if (notify) notifyListeners();
    return item;
  }

  /// Adds an item to the beginning of the list and notifies listeners.
  T addBegin(T item, {bool notify = true}) {
    final didReplaced = value.remove(item);
    value.insert(0, item);

    for (final elementListener in _onAddListener) {
      elementListener(item, notify: notify, didReplaced: didReplaced, index: 0);
    }
    if (notify) notifyListeners();
    return item;
  }

  /// Inserts an item to the list and notifies listeners.
  void insert(int index, T item, {bool notify = true}) {
    value.insert(index, item);
    for (final elementListener in _onAddListener) {
      elementListener(item, notify: notify, didReplaced: false, index: index);
    }
    if (notify) notifyListeners();
  }

  /// Adds all items to the list and notifies listeners.
  B addAll<B extends Iterable<T>>(B items, {bool notify = true}) {
    value.addAll(items);
    for (final elementListener in _onAddListener) {
      for (final item in items) {
        elementListener(item, notify: notify, didReplaced: false);
      }
    }
    if (notify) notifyListeners();
    return items;
  }

  /// Removes an item from the list and notifies listeners.
  void remove(T item, {bool notify = true}) {
    value.remove(item);
    for (final elementListener in _onRemoveListener) {
      elementListener(item, notify: notify, didReplaced: false);
    }
    if (notify) notifyListeners();
  }

  /// Removes at an item from the list and notifies listeners.
  T removeAt(int index, {bool notify = true}) {
    final item = value.removeAt(index);
    for (final elementListener in _onRemoveListener) {
      elementListener(item, notify: notify, didReplaced: false);
    }
    if (notify) notifyListeners();
    return item;
  }

  /// Removes all items from the list and notifies listeners.
  void removeAll(Iterable<T> items, {bool notify = true}) {
    value.removeWhere((element) => items.contains(element));
    for (final elementListener in _onRemoveListener) {
      for (final item in items) {
        elementListener(item, notify: notify, didReplaced: false);
      }
    }
    if (notify) notifyListeners();
  }

  /// Clears the list and notifies listeners.
  void clear({bool notify = true}) {
    for (final elementListener in _onRemoveListener) {
      for (final item in value) {
        elementListener(item, notify: notify, didReplaced: false);
      }
    }
    value = [];
    if (notify) notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}

/// A class that extends [ValueNotifier] and provides additional functionality for managing a set of items.
class SetNotifier<T> extends ValueNotifier<Set<T>> {
  /// Constructs a [SetNotifier] instance with an initial set of items.
  SetNotifier(super.initialSet);

  final List<OnEventListener<T>> _onAddListener = [];
  void addOnAddListener(OnEventListener<T> listener) =>
      _onAddListener.add(listener);

  bool removeOnAddListener(OnEventListener<T> listener) =>
      _onAddListener.remove(listener);

  final List<OnEventListener<T>> _onRemoveListener = [];

  void addOnRemoveListener(OnEventListener<T> listener) =>
      _onRemoveListener.add(listener);

  bool removeOnRemoveListener(OnEventListener<T> listener) =>
      _onRemoveListener.remove(listener);

  /// Adds an item to the set and notifies listeners.
  T add(T item, {bool notify = true}) {
    final didReplaced = value.remove(item);
    value.add(item);
    for (final elementListener in _onAddListener) {
      elementListener(item, notify: notify, didReplaced: didReplaced);
    }
    if (notify) notifyListeners();
    return item;
  }

  /// Adds an item to the beginning of the set and notifies listeners.
  T addBegin(T item, {bool notify = true}) {
    final didReplaced = value.contains(item);
    value = {item, ...value};
    for (final elementListener in _onAddListener) {
      elementListener(item, notify: notify, didReplaced: didReplaced, index: 0);
    }
    if (notify) notifyListeners();
    return item;
  }

  /// Adds all items to the beginning of the set and notifies listeners.
  B addAllBegin<B extends Iterable<T>>(B items, {bool notify = true}) {
    for (final elementListener in _onAddListener) {
      int index = 0;
      for (final item in items) {
        elementListener(
          item,
          notify: notify,
          didReplaced: value.contains(item),
          index: index++,
        );
      }
    }
    value = {...items, ...value};
    if (notify) notifyListeners();
    return items;
  }

  /// Adds all items to the set and notifies listeners.
  B addAll<B extends Iterable<T>>(B items, {bool notify = true}) {
    for (final elementListener in _onAddListener) {
      for (final item in items) {
        elementListener(
          item,
          notify: notify,
          didReplaced: value.contains(item),
        );
      }
    }
    value.removeAll(items);
    value.addAll(items);
    if (notify) notifyListeners();
    return items;
  }

  /// Removes an item from the set and notifies listeners.
  void remove(T item, {bool notify = true}) {
    value.remove(item);
    for (final elementListener in _onRemoveListener) {
      elementListener(item, notify: notify, didReplaced: false);
    }
    if (notify) notifyListeners();
  }

  /// Removes all items from the set and notifies listeners.
  void removeAll(Iterable<T> items, {bool notify = true}) {
    value.removeAll(items);
    for (final elementListener in _onRemoveListener) {
      for (final item in items) {
        elementListener(item, notify: notify, didReplaced: false);
      }
    }
    if (notify) notifyListeners();
  }

  /// Clears the set and notifies listeners.
  void clear({bool notify = true}) {
    for (final elementListener in _onRemoveListener) {
      for (final item in value) {
        elementListener(item, notify: notify, didReplaced: false);
      }
    }

    value = {};
    if (notify) notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}

/// A class that extends [ValueNotifier] and provides additional functionality for managing a map.
class MapNotifier<K, T> extends ValueNotifier<Map<K, T>> {
  /// Constructs a [MapNotifier] instance with an initial set of items.
  MapNotifier(super.initialSet);

  /// Adds an item to the set and notifies listeners.
  T add(K key, T item, {bool notify = true}) {
    value.remove(item);
    value.addAll({key: item});
    if (notify) notifyListeners();
    return item;
  }

  /// Adds all other to the set and notifies listeners.
  Map<K, T> addAll(Map<K, T> other, {bool notify = true}) {
    value.addAll(other);
    notifyListeners();
    return other;
  }

  /// Removes an item from the set and notifies listeners.
  void remove(T item, {bool notify = true}) {
    value.remove(item);
    if (notify) notifyListeners();
  }

  /// Removes all items from the set and notifies listeners.
  void removeAll(Iterable<K> keys, {bool notify = true}) {
    value.removeWhere((key, value) => keys.contains(key));
    if (notify) notifyListeners();
  }

  /// Clears the set and notifies listeners.
  void clear({bool notify = true}) {
    value = {};
    if (notify) notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}
