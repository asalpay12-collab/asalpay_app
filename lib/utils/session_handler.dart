import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asalpay/globals.dart';
import 'package:asalpay/providers/auth.dart';

/// Call when session has expired (401, invalid token, phone not found due to session).
/// Triggers logout and navigates to login/splash.
void handleSessionExpired() {
  final ctx = navigatorKey.currentContext;
  if (ctx != null && ctx.mounted) {
    try {
      Provider.of<Auth>(ctx, listen: false).logout(ctx);
    } catch (_) {}
  }
}

/// Check if API response indicates session expiry (401, or session-related error messages).
bool isSessionExpiredResponse(int statusCode, String? body) {
  if (statusCode == 401 || statusCode == 403) return true;
  if (body == null || body.isEmpty) return false;
  final lower = body.toLowerCase();
  return lower.contains('session expired') ||
      lower.contains('invalid token') ||
      lower.contains('unauthorized') ||
      (lower.contains('phone number') && lower.contains('not found')) ||
      (lower.contains('phone') && (lower.contains('malahan') || lower.contains('ma lahan') || lower.contains('lama helin'))) ||
      (lower.contains('wallet_account') && lower.contains('not found')) ||
      (lower.contains('wallet') && lower.contains('not found')) ||
      (lower.contains('login') && lower.contains('required')) ||
      lower.contains('token expired') ||
      lower.contains('authentication failed') ||
      lower.contains('session invalid');
}

/// Check response and trigger logout if session expired. Call after any API request.
/// Returns true if session expired (caller should return/stop), false otherwise.
bool checkAndHandleSessionExpiry(int statusCode, String? body) {
  if (isSessionExpiredResponse(statusCode, body)) {
    handleSessionExpired();
    return true;
  }
  return false;
}
