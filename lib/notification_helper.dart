// // notification_helper.dart
// import 'dart:convert';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:asalpay/firebase/firebase_messaging_setup.dart' show FCMCommandCache, tryShowPendingPinCommand;
// import 'package:asalpay/firebase/fcm_command_cache.dart';

// final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();

// InitializationSettings initSettings = const InitializationSettings(
//   android: AndroidInitializationSettings('@mipmap/ic_launcher'),
// );

// Future<void> initLocalNotifications() async {
//   await localNotif.initialize(
//     initSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse r) {
//       if (r.payload?.isNotEmpty ?? false) {
//         // put the cached data back and try to show dialog
//         FCMCommandCache.setPendingData(jsonDecode(r.payload!));
//         tryShowPendingPinCommand();
//       }
//     },
//   );
// }
