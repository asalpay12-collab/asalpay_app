
class FCMCommandCache {
  static Map<String, dynamic>? _pendingData;

  static void setPendingData(Map<String, dynamic>? data) {
    _pendingData = data;
  }

  static Map<String, dynamic>? getPendingData() => _pendingData;

  static void clear() => _pendingData = null;

  static bool hasPinCommand() =>
      _pendingData != null && _pendingData!['command'] == 'EnterPin';
}
