// chat_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chat_message.dart';

class ChatService {
  static const _boxName = 'chat_messages';

  static Box<ChatMessage> _getBox() {
    return Hive.box<ChatMessage>(_boxName);
  }

  static Future<void> saveFCM(Map<String, dynamic> data) async {
    final box = _getBox();
    final message = ChatMessage.fromFCM(data);
    
    // Check for duplicates before saving
    if (!box.values.any((m) => m.id == message.id)) {
      await box.add(message);
    }
  }

  // ADD THIS METHOD
  static Future<List<ChatMessage>> getMessages() async {
    final box = _getBox();
    final messages = box.values.toList();
    return messages.reversed.toList(); // Newest first
  }

  // ADD THIS GETTER
  static ValueListenable<Box<ChatMessage>> get messageListenable {
    return _getBox().listenable();
  }
}