import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ewareeji (crypto) API config – madax banaan, .env-ga ka qeexan.
/// Base URL, username, password waa ku diyaarin .env.
class EwareejiApiConfig {
  EwareejiApiConfig._();

  static String get baseUrl {
    final u = (dotenv.env['EWAREEJI_API_BASE_URL'] ?? '').trim();
    if (u.isEmpty) return '';
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  static String get username =>
      (dotenv.env['EWAREEJI_API_USERNAME'] ?? '').trim();

  static String get password =>
      (dotenv.env['EWAREEJI_API_PASSWORD'] ?? '').trim();

  static bool get isConfigured =>
      baseUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
}
