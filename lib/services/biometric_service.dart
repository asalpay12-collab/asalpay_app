import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for fingerprint preferences and secure storage.
class BiometricKeys {
  static const String useFingerprintLogin = 'use_fingerprint_login';
  static const String useFingerprintConfirm = 'use_fingerprint_confirm';
  static const String secureUserData = 'fingerprint_login_user_data';
  static const String securePin = 'fingerprint_confirm_pin';
}

/// Result of biometric authentication for advanced handling.
enum BiometricAuthResult { success, cancelled, failed, notAvailable, lockedOut }

/// Biometric (fingerprint/face) and secure storage helpers for login and PIN confirmations.
class BiometricService {
  /// Last platform error (code + message) for debugging; cleared on success.
  static String? lastErrorDetail;

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Returns true if the device supports biometrics and at least one is enrolled.
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      if (kDebugMode) debugPrint('BiometricService.canCheckBiometrics: $e');
      return false;
    }
  }

  /// Returns true if the device has biometric hardware and user has enrolled.
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final list = await _localAuth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('BiometricService.isBiometricAvailable: $e');
      return false;
    }
  }

  /// Advanced: authenticate with biometrics, with clear result and proper exception handling.
  /// On Android, tries biometricOnly: true first, then retries with biometricOnly: false if needed.
  static Future<BiometricAuthResult> authenticateAdvanced({
    String reason = 'Verify your identity',
  }) async {
    lastErrorDetail = null;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        lastErrorDetail = 'canCheckBiometrics: false';
        return BiometricAuthResult.notAvailable;
      }
      final list = await _localAuth.getAvailableBiometrics();
      if (list.isEmpty) {
        lastErrorDetail = 'getAvailableBiometrics: empty';
        return BiometricAuthResult.notAvailable;
      }

      for (final biometricOnly in [true, false]) {
        if (!Platform.isAndroid && biometricOnly == false) continue;
        try {
          final options = AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: biometricOnly,
          );
          final ok = await _localAuth.authenticate(
            localizedReason: reason,
            options: options,
          );
          if (ok) return BiometricAuthResult.success;
          lastErrorDetail = 'authenticate returned false';
          return BiometricAuthResult.cancelled;
        } on PlatformException catch (e) {
          final code = e.code;
          final msg = e.message;
          lastErrorDetail = 'code: $code | message: $msg';
          if (kDebugMode) debugPrint('BiometricService.authenticateAdvanced: $lastErrorDetail');
          final codeLower = code.toLowerCase();
          if (codeLower.contains('cancel') || codeLower.contains('user') || codeLower == 'timeout' || codeLower.contains('fallback')) {
            return BiometricAuthResult.cancelled;
          }
          if (codeLower.contains('lock')) return BiometricAuthResult.lockedOut;
          if (codeLower.contains('notavailable') || codeLower.contains('no_biometric') || codeLower.contains('no credential')) {
            return BiometricAuthResult.notAvailable;
          }
          if (biometricOnly && Platform.isAndroid) continue;
          return BiometricAuthResult.failed;
        }
      }
      return BiometricAuthResult.failed;
    } catch (e) {
      lastErrorDetail = e.toString();
      if (kDebugMode) debugPrint('BiometricService.authenticateAdvanced: $lastErrorDetail');
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('user')) return BiometricAuthResult.cancelled;
      if (msg.contains('lock')) return BiometricAuthResult.lockedOut;
      return BiometricAuthResult.failed;
    }
  }

  /// Authenticate with biometrics. [reason] is shown in the system dialog.
  /// Returns true on success, false on cancel/failure. Uses advanced logic.
  static Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    final result = await authenticateAdvanced(reason: reason);
    return result == BiometricAuthResult.success;
  }

  // --- Preferences (SharedPreferences) ---

  static Future<bool> getUseFingerprintLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(BiometricKeys.useFingerprintLogin) ?? false;
  }

  static Future<void> setUseFingerprintLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(BiometricKeys.useFingerprintLogin, value);
  }

  static Future<bool> getUseFingerprintConfirm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(BiometricKeys.useFingerprintConfirm) ?? false;
  }

  static Future<void> setUseFingerprintConfirm(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(BiometricKeys.useFingerprintConfirm, value);
  }

  // --- Secure storage: userData for fingerprint login ---

  static Future<void> saveUserDataForFingerprintLogin(String userDataJson) async {
    await _secureStorage.write(key: BiometricKeys.secureUserData, value: userDataJson);
  }

  static Future<String?> getUserDataForFingerprintLogin() async {
    return await _secureStorage.read(key: BiometricKeys.secureUserData);
  }

  static Future<void> clearUserDataForFingerprintLogin() async {
    await _secureStorage.delete(key: BiometricKeys.secureUserData);
  }

  // --- Secure storage: PIN for fingerprint confirmations ---

  static Future<void> savePinForFingerprintConfirm(String pin) async {
    await _secureStorage.write(key: BiometricKeys.securePin, value: pin);
  }

  static Future<String?> getPinForFingerprintConfirm() async {
    return await _secureStorage.read(key: BiometricKeys.securePin);
  }

  static Future<void> clearPinForFingerprintConfirm() async {
    await _secureStorage.delete(key: BiometricKeys.securePin);
  }
}
