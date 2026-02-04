import 'dart:async';
import 'dart:convert';
import 'package:asalpay/login/login.dart';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/splash/SplashScrn1.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/http_exception.dart';
import 'package:asalpay/services/api_urls.dart';

import 'package:package_info_plus/package_info_plus.dart';


class MyApp extends StatelessWidget {

  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        auth.startInactivityTimer(context);
      },
      onPanDown: (_) {
        auth.startInactivityTimer(context);
      },
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Inactivity Timer'),
          ),
          body: const Center(
            child: Text('Content'),
          ),
        ),
      ),
    );
  }
}

class Auth with ChangeNotifier {
  
  TokenClass tokenClass = TokenClass();
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  String? _Name;
  String? _version;
  String? _m_name;
  String? _candidate_id;
  String? _wallet_accounts_id;
  String? _phone;
  Timer? _authTimer;
  Timer? _inactivityTimer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null && _expiryDate!.isAfter(DateTime.now()) && _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId => _userId;
  String? get Name => _Name;
  String? get m_name => _m_name;
  String? get candidate_id => _candidate_id;
  String? get wallet_accounts_id => _wallet_accounts_id;
  String? get phone => _phone;
  String? get version => _version;



   void appLog(String message) {
  debugPrint("🟢[MYAPP] $message");
}



Future<void> _authenticate(String email, String password, String version, BuildContext context) async {


  final url = '${ApiUrls.BASE_URL}Wallet_login/login';
  String cleanedPhone = email.replaceAll('+', '');
  appLog("📞 Cleaned phone: $cleanedPhone");




  try {


final packageInfo = await PackageInfo.fromPlatform();
final versionName = packageInfo.version; 
final buildNumber = packageInfo.buildNumber; 

    final body = json.encode({
      'phone': email,
      'password': password,
      // 'version': "1.3.7", 

      'version': versionName, 

    });

    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    appLog(" Sending login POST to $url");
    appLog(" Request headers: $headers");
    appLog(" Request body: $body");

    final response = await http.post(Uri.parse(url), body: body, headers: headers);
    appLog(" Response status: ${response.statusCode}");
    appLog(" Raw response body: ${response.body}");

    final dynamic decodedBody = json.decode(response.body);

    // Handle error responses
    if (decodedBody is List) {
      final errorMessage = decodedBody.isNotEmpty 
          ? decodedBody.first['message'] ?? 'Unknown error'
          : 'Empty error response';
      throw HttpException(errorMessage);
    } else if (decodedBody is Map) {
     

      if (decodedBody['status'] == false || decodedBody['error'] != null) {
  final errorField = decodedBody['error']?.toString().toLowerCase() ?? '';
  final messageField = decodedBody['message'];

  if (errorField.contains('update your app')) {
    throw HttpException('APP_VERSION_OUTDATED');
  }

  // Handle if message is a Map or String
  String errorMessage;
  if (messageField is String) {
    errorMessage = messageField;
  } else if (messageField is Map) {
    // If message is a map, try to extract something useful or default
    errorMessage = messageField['error']?.toString() ?? 'Authentication failed';
  } else {
    errorMessage = 'Authentication failed';
  }

  throw HttpException(errorMessage);
}


      // Validate success response structure
      if (decodedBody['res'] == null || 
          decodedBody['res']['wallet_accounts_id'] == null) {
        throw HttpException('Invalid server response structure');
      }

      // Process success response
      _token = decodedBody['token']?.toString();
      _wallet_accounts_id = decodedBody['res']['wallet_accounts_id']?.toString();
      _candidate_id = decodedBody['res']['wallet_customers_id']?.toString();
      _userId = decodedBody['res']['wallet_users_id']?.toString();
      _Name = decodedBody['res']['f_name']?.toString();
      _m_name = decodedBody['res']['m_name']?.toString();
      _version = decodedBody['res']['version']?.toString();
      _phone = email;

      if (decodedBody['expiresIn'] != null) {
        _expiryDate = DateTime.now().add(
          Duration(seconds: int.tryParse(decodedBody['expiresIn'].toString()) ?? 300),
        );
      } else {
        _expiryDate = DateTime.now().add(const Duration(seconds: 300));
      }

      appLog("Login successful. Starting autoLogout.");
      autoLogout(context);
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'candidate_id': _candidate_id,
        'userId': _userId,
        'name': _Name,
        'mName': _m_name,
        'phone': _phone,
        'version': _version,
        'wallet_accounts_id': _wallet_accounts_id,
        'expiryDate': _expiryDate!.toIso8601String(),
      });

      await prefs.setString('userData', userData);
    } else {
      throw HttpException('Unexpected response format');
    }
  } catch (error) {
    appLog("Caught error during login: $error");
    rethrow;
  }
}


  Future<void> login(String? email, String? password, String? version, BuildContext context) async {
    return _authenticate(email!, password!, version!, context);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }

    final extractedUserData = json.decode(prefs.getString('userData').toString());
    final expiryDate = DateTime.parse(extractedUserData['expiryDate'].toString());

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = extractedUserData['token'];

    _wallet_accounts_id = extractedUserData['wallet_accounts_id'];

    _candidate_id = extractedUserData['candidate_id']; 

    _userId = extractedUserData['userId'];  
    _Name = extractedUserData['name'];
    _m_name = extractedUserData['mName'];

    _phone = extractedUserData['phone'].toString();
    _version = extractedUserData['version'].toString();


    _expiryDate = expiryDate;
    notifyListeners();
    _startTimerForAutoLogout();
    return true;
  }

  void _startTimerForAutoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }

    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }

  void autoLogout(BuildContext context) {
    startInactivityTimer(context);
  }

  void startInactivityTimer(BuildContext context) {
    _cancelInactivityTimer();
    const inactivityDuration = Duration(minutes: 5);
    _inactivityTimer = Timer(inactivityDuration, () {
      if (Navigator.of(context).mounted) {
        showInactivityDialog(context);
      }
    });
  }

  void showInactivityDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return InactivityDialog(
          onStayLoggedIn: () {
            Navigator.of(dialogContext).pop();
            startInactivityTimer(context);
          },
          onLogout: () {
            Navigator.of(dialogContext).pop();
            logout(context);
          },
        );
      },
    );
  }

  void _cancelInactivityTimer() {
    if (_inactivityTimer != null) {
      _inactivityTimer!.cancel();
      _inactivityTimer = null;
    }
  }


Future<void> logout([BuildContext? context]) async {
  _cancelInactivityTimer();
  _token = null;
  _userId = null;
  _wallet_accounts_id = null;
  _candidate_id = null;
  _expiryDate = null;
  _Name = null;
  _m_name = null;
  _phone = null;
  _version = null;

  _authTimer?.cancel();
  _authTimer = null;
  _inactivityTimer?.cancel();
  _inactivityTimer = null;

  notifyListeners();
  final prefs = await SharedPreferences.getInstance();
  prefs.clear();

  if (context != null) {
    Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen1()),
          (route) => false,
        );
  }
}


  void navigateAndCheckActivity(BuildContext context, Widget nextPage) {
    startInactivityTimer(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Auth(),
      child: const MyApp(),
    ),
  );
}

class InactivityDialog extends StatefulWidget {
  final VoidCallback onStayLoggedIn;
  final VoidCallback onLogout;

  const InactivityDialog({super.key, required this.onStayLoggedIn, required this.onLogout});

  @override
  _InactivityDialogState createState() => _InactivityDialogState();
}

class _InactivityDialogState extends State<InactivityDialog> {
  int _counter = 40;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter == 0) {
        timer.cancel();
        widget.onLogout();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() {
            _counter--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Session Timeout"),
      content: Text("You will be logged out in $_counter seconds due to inactivity."),
      actions: <Widget>[
        TextButton(
          child: const Text("Stay"),
          onPressed: () {
            _countdownTimer?.cancel();
            widget.onStayLoggedIn();
          },
        ),
        TextButton(
          child: const Text("Logout"),
          onPressed: () {
            _countdownTimer?.cancel();
            widget.onLogout();
          },
        ),
      ],
    );
  }
}
