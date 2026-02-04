import 'package:hive_flutter/hive_flutter.dart';

// part 'chat_message.dart';
// run:  flutter packages pub run build_runner build


// chat_message.dart
@HiveType(typeId: 5)
class ChatMessage extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String body;
  @HiveField(2) final DateTime created;
  @HiveField(3) final String account;

  ChatMessage({
    required this.id,
    required this.body,
    required this.created,
    required this.account,
  });

  factory ChatMessage.fromFCM(Map<String, dynamic> data) => ChatMessage(
        id: data['messageId'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
        body: data['message'] ?? '',
        created: DateTime.now(),
        account: data['account'] ?? '',
      );
}
