import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Global navigator key for accessing context from anywhere (e.g. session expiry logout).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global notifications plugin (avoids circular import with firebase_messaging_setup).
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
