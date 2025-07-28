import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final Map<String, List<Function>> _listeners = {};

  void on(String event, Function callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
  }

  void off(String event, Function callback) {
    if (_listeners.containsKey(event)) {
      _listeners[event]!.remove(callback);
    }
  }

  void emit(String event, [dynamic data]) {
    if (_listeners.containsKey(event)) {
      for (final callback in _listeners[event]!) {
        try {
          if (data != null) {
            callback(data);
          } else {
            callback();
          }
        } catch (e) {
          print('Error in event callback: $e');
        }
      }
    }
  }

  void clear() {
    _listeners.clear();
  }
}

class Events {
  static const String userPointsUpdated = 'user_points_updated';
  static const String userProfileUpdated = 'user_profile_updated';
  static const String coupleUpdated = 'couple_updated';
  static const String historyUpdated = 'history_updated';
}

// Global instance
final eventBus = EventBus();
