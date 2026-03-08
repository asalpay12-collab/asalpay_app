import 'package:asalpay/deviceInfo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TokenClass {
  // Class members
  late final Map<String, String> user;
  late final JWTCodec jwtCodec;
  final String key;
  String? _currentToken;

  TokenClass()
      : key = dotenv.env['secretKey']?.toString() ?? '' {
    // Initialize user credentials
    user = {
      "user": dotenv.env['user']?.toString() ?? '',
      "pass": dotenv.env['pass']?.toString() ?? '',
    };

    // Create JWT codec
    jwtCodec = JWTCodec(key);
    
    // Generate initial token
    _currentToken = _generateToken();
    print("🆕 Initial JWT: $_currentToken");
  }

  /// CML JWT: 1 hour expiry so token does not expire while user is in app.
  String _generateToken() {
    const expirySeconds = 3600; // 1 hour
    final payload = {
      "user": user["user"],
      "pass": user["pass"],
      "exp": (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expirySeconds
    };
    return jwtCodec.encode(payload);
  }

  bool _isTokenValid(String token) {
    try {
      final decoded = jwtCodec.decode(token);
      final exp = decoded['exp'] as int;
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Refresh 5 min before expiry so user does not see "Token expired" while in app
      return expiryTime.isAfter(DateTime.now().add(const Duration(minutes: 5)));
    } catch (e) {
      print("❌ Token validation error: $e");
      return false;
    }
  }

  String getToken() {
    // Return valid token if exists
    if (_currentToken != null && _isTokenValid(_currentToken!)) {
      print("♻️ Using cached valid token");
      return _currentToken!;
    }
    
    // Generate new token if expired or invalid
    print("🔄 Generating new token (previous expired)");
    _currentToken = _generateToken();
    print("🔑 New JWT: $_currentToken");
    return _currentToken!;
  }
}