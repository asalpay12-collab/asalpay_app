

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:asalpay/chat/chat_screen.dart';
import 'package:asalpay/chat/chat_service.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:asalpay/firebase/device_registration_service.dart';
import 'package:asalpay/firebase/fcm_token_manager.dart';
import 'package:asalpay/firebase/fcm_command_cache.dart';
import 'package:asalpay/firebase/pin_cache_store.dart';
import 'package:asalpay/PinPopUp.dart';
import 'package:asalpay/main.dart'  show navigatorKey, flutterLocalNotificationsPlugin;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accept both legacy and new command names

// const _kAcceptedCommands = {'EnterPin', 'EnterBin'};

const _kAcceptedCommands = {'EnterPin', 'EnterBin', 'ChatMsg'};


Future<void> _showLocalChatNotification(RemoteMessage msg) async {
  await flutterLocalNotificationsPlugin.show(
    2001,
    'New Message',
    msg.data['message'] ?? '',
    _chatDetails,
    payload: jsonEncode(msg.data),
  );
}


void _openChatScreenAfterBuild() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushNamed(ChatScreen.route);
  });
}

const _androidDetails = AndroidNotificationDetails(
  'high_importance_channel',
  'High Importance Notifications',
  icon: '@mipmap/launcher_icon',
  importance: Importance.high,
  priority: Priority.high,
  playSound: true,
  enableVibration: true,
);

const _iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  categoryIdentifier: 'EnterPin',
);

const AndroidNotificationDetails _chatAndroid = AndroidNotificationDetails(
  'chat_channel', 'Chat Messages',
  importance: Importance.high,
  priority: Priority.high,
  playSound: true,
);
const NotificationDetails _chatDetails =
    NotificationDetails(android: _chatAndroid);


const _platformNotification =
    NotificationDetails(android: _androidDetails, iOS: _iosDetails);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {

  await Firebase.initializeApp();


  if (msg.data['command'] != 'ChatMsg') {
  final ok = _kAcceptedCommands.contains(msg.data['command']) &&
             (msg.data['account'] ?? '').isNotEmpty &&
             (msg.data['merchantNo'] ?? '').isNotEmpty &&
             double.tryParse(msg.data['amountFrom']?.toString() ?? '0')! > 0;

  if (!ok) {
    debugPrint('⚠️  Discarded malformed push (bg): ${msg.data}');
    return;
  }
}

  


  final data = <String, dynamic>{
    'command'      : msg.data['command']      ?? '',
    'account'      : msg.data['account']      ?? '',
    'merchantNo'   : msg.data['merchantNo']   ?? '',
    'reference'    : msg.data['reference']    ?? '',
    'callback_url' : msg.data['callback_url'] ?? '',
    'description'  : msg.data['description']  ?? '',
    'merchantName' : msg.data['merchantName'] ?? '',
    'amountFrom'   : double.tryParse(
                        msg.data['amountFrom']?.toString() ??
                        msg.data['amount']?.toString() ?? '0') ?? 0,
    'currencyFrom' : int.tryParse(msg.data['currencyFrom']?.toString() ?? '0') ?? 0,
    'currencyTo'   : int.tryParse(msg.data['currencyTo']?.toString() ?? '0') ?? 0,
  };


  if (msg.data['command'] == 'ChatMsg') {
  await ChatService.saveFCM(msg.data);
  return;                  
}


  final ok = _kAcceptedCommands.contains(data['command']) &&
             data['account']   != '' &&
             data['merchantNo']!= '' &&
             (data['amountFrom'] as double) > 0;

  if (!ok) {
    debugPrint('⚠️  Discarded malformed push (bg): $data');
    return;
  }

  await savePendingPin(data);          
  FCMCommandCache.setPendingData(data); 



  if (Platform.isAndroid  ) {
    await flutterLocalNotificationsPlugin.show(
      1001,
      'AsalPay Merchant Payment Requested',
      'Tap to confirm your payment',
      _platformNotification,
      payload: jsonEncode(data),
    );
  }


  if (msg.data['command'] == 'ChatMsg' && Platform.isAndroid) {
  await flutterLocalNotificationsPlugin.show(
    2001,
    'New Message',
    msg.data['message'] ?? '',
    _chatDetails,
  );
}


}


void _registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}


Future<void> setupFirebaseMessaging() async {

    await Firebase.initializeApp();
  _registerBackgroundHandler();

  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, badge: true, sound: true);



  // 26/06/25


  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    debugPrint('🚀 getInitialMessage: ${initial.data}');
    
    final combinedData = {...initial.data};
    if (initial.notification != null) {
      combinedData['notificationTitle'] = initial.notification?.title;
      combinedData['notificationBody'] = initial.notification?.body;
    }


    if (combinedData['command'] == 'ChatMsg') {
     await ChatService.saveFCM(combinedData);
     await ChatService.getMessages();
    _openChatScreenAfterBuild();
    return;
   }


    // Immediately save to persistent storage
    await savePendingPin(combinedData);
    
    // Use delayed execution to allow app to initialize
    Future.delayed(const Duration(seconds: 1), () {
      tryShowPendingPinCommand();
    });
  }


  //ends here, 26/06/25


  // Foreground push

  // FirebaseMessaging.onMessage.listen(_onForeground);


  FirebaseMessaging.onMessage.listen((m) async {
  if (m.data['command'] == 'ChatMsg') {
    await ChatService.saveFCM(m.data);       
    _showLocalChatNotification(m);          
    return;                                 
  }
  _onForeground(m);                         
});


  FirebaseMessaging.onMessageOpenedApp.listen((m) async {
  if (m.data['command'] == 'ChatMsg') {
    await ChatService.saveFCM(m.data);   
    _openChatScreenAfterBuild();
    return;
  }
  FCMCommandCache.setPendingData(m.data);
  tryShowPendingPinCommand();
});


  // Local-notification plugin setup


   await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    ),

   onDidReceiveNotificationResponse: (r) async {
    if (r.payload == null) return;
    
    try {
      final map = jsonDecode(r.payload!);
      if (map['command'] == 'ChatMsg') {
        await ChatService.getMessages();
        _openChatScreenAfterBuild();
      } else {
        FCMCommandCache.setPendingData(map);
        tryShowPendingPinCommand();
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  },

  );


  // FCM token changes
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint(' New FCM Token: $newToken');
    await FcmTokenManager.saveToken(newToken);

    final prefs = await SharedPreferences.getInstance();
    final walletId = prefs.getString('wallet_accounts_id');
    if (walletId?.isNotEmpty ?? false) {
      await DeviceRegistrationService.registerDevice(
        walletAccountsId: walletId!,
        fcmToken: newToken,
      );
    }
  });

  // Log current FCM token
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint(' FCM token: $token');
}



Future<void> _onForeground(RemoteMessage msg) async {
  debugPrint('Foreground FCM → ${msg.data}');

  // ▸ Route chat messages first



  if (msg.data['command'] == 'ChatMsg') {
    await ChatService.saveFCM(msg.data);
    
    // Show notification for iOS in foreground
    if (Platform.isIOS) {
      _showLocalChatNotification(msg);
    }
    return;
  }


  final cmd = msg.data['command'];
  if (!_kAcceptedCommands.contains(cmd)) return;

  _showPinPopUpFromData(msg.data);
}


void _onOpenedFromTray(RemoteMessage msg){
  debugPrint(' onMessageOpenedApp → ${msg.data}');
  FCMCommandCache.setPendingData(msg.data);
  tryShowPendingPinCommand();
}


void _showPinPopUpFromData(Map<String,dynamic> data){
  final ctx = navigatorKey.currentContext;
  if(ctx!=null && ctx.mounted){
    PinPopUp.show(
      context      : ctx,
      account      : data['account']      ?? '',
      merchantNo   : data['merchantNo']   ?? '',
      amount       : double.tryParse(data['amountFrom']?.toString() ??
                                     data['amount']?.toString() ?? '0') ?? 0,
      currencyFrom : int.tryParse(data['currencyFrom']?.toString() ?? '4') ?? 4,
      currencyTo   : int.tryParse(data['currencyTo']  ?.toString() ?? '4') ?? 4,
      description  : data['description']  ?? '',
      merchantName : data['merchantName'] ?? '',
      reference    : data['reference']    ?? 'N/A',
      callbackUrl  : data['callback_url'] ?? '',
    );
  }else{
    FCMCommandCache.setPendingData(data);
  }
}


void tryShowPendingPinCommand([int attempt = 0]) async {
  // First check persistent storage
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('pending_pin_data');
  Map<String, dynamic>? data;
  
  if (jsonString != null) {
    try {
      data = jsonDecode(jsonString);
      await prefs.remove('pending_pin_data');
    } catch (e) {
      debugPrint('Error parsing pending data: $e');
    }
  }

  // Fallback to in-memory cache
  data ??= FCMCommandCache.getPendingData();
  
  if (data == null) return;

  final context = navigatorKey.currentContext;
  if (context != null && context.mounted) {
    _showPinPopUpFromData(data);
    FCMCommandCache.clear();
  } 
  // Special handling for terminated state
  else if (attempt < 5) {
    Future.delayed(const Duration(milliseconds: 500), () {
      tryShowPendingPinCommand(attempt + 1);
    });
  }
}