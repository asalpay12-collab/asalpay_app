import 'dart:convert';
import 'dart:io';

import 'package:asalpay/globals.dart';
import 'package:asalpay/PinPopUp.dart';
import 'package:asalpay/chat/chat_message.dart';
import 'package:asalpay/chat/chat_message.g.dart';
import 'package:asalpay/chat/chat_screen.dart';
import 'package:asalpay/firebase/fcm_command_cache.dart';
import 'package:asalpay/firebase/pin_cache_store.dart';
import 'package:asalpay/firebase/test_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:asalpay/firebase/firebase_messaging_setup.dart';
import 'package:asalpay/home/homescreen.dart';
import 'package:asalpay/login/login.dart';
import 'package:asalpay/pageview/pageviewscr.dart';
import 'package:asalpay/profile/profile.dart';
import 'package:asalpay/providers/FillDropdownbyRegistreration.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart'; 
import 'package:asalpay/providers/NetworkProvider.dart';
import 'package:asalpay/providers/WalletOperations.dart';
import 'package:asalpay/providers/Walletremit.dart';
import 'package:asalpay/providers/auth.dart';
// import 'package:asalpay/sendMoney/banktransfer.dart';

import 'package:asalpay/sendMoney/banktransfer.dart' as Bbanktransfer;

import 'package:asalpay/splash/SplashScrn1.dart';
import 'package:asalpay/transfer/Transfer1.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Registration2.dart';
import 'constants/Constant.dart';
import 'topup/TopUp.dart';
import 'helper/custom_route.dart';
import 'providers/CustomerRegistration.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:asalpay/providers/TransferOperations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:asalpay/firebase/firebase_messaging_setup.dart'
    show setupFirebaseMessaging, tryShowPendingPinCommand;


import 'package:asalpay/firebase/fcm_command_cache.dart';


import 'package:flutter/services.dart';



// Define the notification channel


// const AndroidNotificationChannel channel = AndroidNotificationChannel(
//   'high_importance_channel', // id
//   'High Importance Notifications', // title
//   description: 'This channel is used for important notifications.',
//   importance: Importance.high,
// );


const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'PIN & payment alerts',
  importance: Importance.high,
);


// NEW: channel dedicated to ChatMsg banners
const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
  'chat_channel',
  'Chat Messages',
  description: 'Banners for ChatMsg pushes',
  importance: Importance.high,
);



// Single plugin instance (flutterLocalNotificationsPlugin moved to globals.dart)


  class MyHttpOverrides extends HttpOverrides {
  // Add every host you need to whitelist here
  static const _allowedHosts = {
    'production.asalxpress.com',
    'dev2.asalxpress.com',
  };

  @override
  HttpClient createHttpClient(SecurityContext? ctx) {
    final client = super.createHttpClient(ctx);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            _allowedHosts.contains(host);
    return client;
  }
}


Future<void> _requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    sound: true,
  );
  print('🔔 Permission status: ${settings.authorizationStatus}');
}





Future<void> main() async {
  


  //here for the iOS



  //ENDS IOS HERE
  
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );



  print("🚀 [MAIN] App starting");

    await Hive.initFlutter();
  Hive.registerAdapter(ChatMessageAdapter());
  await Hive.openBox<ChatMessage>('chat_messages');

  
  
  // Initialize Firebase 
  try {

    print("🔥 Initializing Firebase...");

    await Firebase.initializeApp();
    print("🔥 Firebase initialized successfully");

    await _requestNotificationPermission();      

  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  // Setup FCM
  try {
    await setupFirebaseMessaging();
    print("📡 FCM setup complete");
  } catch (e) {
    print("❌ FCM setup failed: $e");
  }


  await dotenv.load(fileName: ".env");

  HttpOverrides.global = MyHttpOverrides(); 

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(highImportanceChannel);



  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  void initState() {



    super.initState();


    FirebaseMessaging.instance.getInitialMessage().then((msg) {
  if (msg != null) {
    FCMCommandCache.setPendingData(msg.data);
   
  }
});


     // Delay to wait for navigatorKey to be ready
  WidgetsBinding.instance.addPostFrameCallback((_) {

    // _checkFCMPendingCommand();

    _checkFCMPendingCommand();
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
  tryShowPendingPinCommand(); 
  _checkDiskCache();
});



  }





Future<void> _checkDiskCache() async {
    final diskData = await takePendingPin();         
    if (diskData != null) {
      debugPrint('💾 Found pending PIN in SharedPreferences');
      FCMCommandCache.setPendingData(diskData);      
      tryShowPendingPinCommand();                    
    }
  }

   void _checkFCMPendingCommand() {
    print(" [TERMINATED CHECK] Checking for pending command");
    final data = FCMCommandCache.getPendingData();
    if (data != null && data['command'] == 'EnterPin') {
      print(" Pending EnterPin command found");
      print(" Delaying 500ms for context");
      Future.delayed(const Duration(milliseconds: 500), () {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          print("Context available from terminated state. Showing PinPopUp...");
          PinPopUp.show(
            context: ctx,
            account: data['account'] ?? '',
            merchantNo: data['merchantNo'] ?? '',
            amount: double.tryParse(data['amount'] ?? '0') ?? 0.0,
            description: data['description'] ?? '',
            merchantName: data['merchantName'] ?? '',
            reference: data['reference'] ?? '',
            callbackUrl: data['callback_url'] ?? '',
            currencyFrom: int.tryParse(data['currencyFrom']?.toString() ?? '0') ?? 0,
            currencyTo: int.tryParse(data['currencyTo']?.toString() ?? '0') ?? 0,
          );
          FCMCommandCache.clear();
        } else {
          print(" Context not available from terminated state");
        }
      });
    } else {
      print(" No pending command found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: Auth(),
          ),
          ChangeNotifierProvider.value(
            value: FillRegisterationDropdown(),
          ),
          ChangeNotifierProvider.value(
            value: CustomerRegistration(),
          ),
          ChangeNotifierProvider.value(
            value: Walletremit(),
          ),
          // ChangeNotifierProvider.value(
          //   value: HomeSliderAndTransaction(),
          // ),
          ChangeNotifierProvider.value(
            value: NetworkProvider(),
          ),
          // ChangeNotifierProvider.value(
          //   value: WalletOperations(),
          // ),
          ChangeNotifierProxyProvider<Auth, HomeSliderAndTransaction>(

          //commented on 23/04
             create: (_) => HomeSliderAndTransaction(''),

              
              update: (ctx, auth, wll) => HomeSliderAndTransaction(
                    auth.wallet_accounts_id,
                   
                  )),
          ChangeNotifierProxyProvider<Auth, WalletOperations>(
              create: (_) => WalletOperations('', ''),
              update: (ctx, auth, wll) =>
                  WalletOperations(auth.wallet_accounts_id, auth.token)),

                  ChangeNotifierProxyProvider<Auth, TransferOperations>(
          create: (_) => TransferOperations('', ''),
          update: (ctx, auth, transfer) =>
              TransferOperations(auth.wallet_accounts_id, auth.token),
        ),
        
        ],
        child: Consumer<Auth>(
          builder: (ctx, auth, _) => MaterialApp(

            navigatorKey: navigatorKey,


            title: 'Asal pay',

            debugShowCheckedModeBanner: false,
            
            
            // theme: ThemeData(
            //     // primaryColor: primaryColor,
            //     hintColor: secondryColor,
            //     pageTransitionsTheme: PageTransitionsTheme(builders: {
            //       TargetPlatform.android: CustomPageTransitionBuilder(),
            //       TargetPlatform.iOS: CustomPageTransitionBuilder(),
            //     }), colorScheme: const ColorScheme.light().copyWith(primary: primaryColor).copyWith(surface: primaryColor)),

               theme: ThemeData(
                primaryColor: primaryColor,
                hintColor: secondryColor,

                scaffoldBackgroundColor: Colors.white,

                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),

                snackBarTheme: SnackBarThemeData(
                  backgroundColor: Colors.grey.shade900,
                  contentTextStyle: const TextStyle(color: Colors.white),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                pageTransitionsTheme: PageTransitionsTheme(builders: {
                  TargetPlatform.android: CustomPageTransitionBuilder(),
                  TargetPlatform.iOS: CustomPageTransitionBuilder(),
                }),

                colorScheme: const ColorScheme.light().copyWith(
                  primary: primaryColor,
                  background: Colors.white,
                  surface: Colors.white,
                ),
              ),


            // home: widget.hasNetwork ? auth.isAuth
            home: auth.isAuth
                ?
                HomeScreen(name: auth.Name, wallet_accounts_id: auth.wallet_accounts_id.toString(), fromLogin: false)
                : FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: (ctx, authResultSnapshot) =>
                        authResultSnapshot.connectionState ==
                                ConnectionState.waiting
                            ?
                            // PageViewScreen
                            const SplashScreen1()
                            // : MyFormRemoveSpaces(),
                            : const Login(),
                    // : SignUp(),
                  ),

            // initialRoute: splash.id,
            routes: {
              HomeScreen.routeName: (ctx) => HomeScreen(
                  wallet_accounts_id: auth.wallet_accounts_id.toString(), fromLogin: true ), 
              Bbanktransfer.BbanktransferChina.routeName: (ctx) =>
              Bbanktransfer.BbanktransferChina(wallet_accounts_id: auth.wallet_accounts_id,),
              Profile.routeName: (ctx) => Profile(
                  username: auth.Name,
                  midname: auth.m_name,
                  wallet_accounts_id: auth.wallet_accounts_id),
              Transfer.routeName: (ctx) =>
                  Transfer(wallet_accounts_id: auth.wallet_accounts_id),
              TopUpScreen.routeName: (ctx) => const TopUpScreen(),
              SignUp.routeName: (ctx) => const SignUp(),
              PageViewScreen.routeName: (ctx) => const PageViewScreen(),
              Login.routeName: (ctx) => const Login(), 

              ChatScreen.route: (_) => const ChatScreen(),

              '/testScreen': (ctx) => const TestScreen(), 

            }, 
          ),
        ));
  }
}

