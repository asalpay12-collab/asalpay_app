import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:asalpay/services/api_urls.dart';

class DeviceRegistrationService {
  static Future<void> registerDevice({
    required String walletAccountsId,
    required String fcmToken,
  }) async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceUUID = 'unknown';
    String model = 'unknown';
    String brand = Platform.isAndroid ? 'Android' : 'iPhone';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceUUID = androidInfo.id ?? 'android-${DateTime.now().millisecondsSinceEpoch}';
        model = androidInfo.model ?? 'android-model';
        brand = androidInfo.brand ?? 'Android';
      } else {
        final iosInfo = await deviceInfo.iosInfo;
        deviceUUID = iosInfo.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
        model = iosInfo.utsname.machine ?? 'iOS-model';
      }
    } catch (e) {
      print('⚠️ Device info error: $e');
      deviceUUID = 'error-${DateTime.now().millisecondsSinceEpoch}';
    }

    final body = {
      "wallet_accounts_id": walletAccountsId.replaceAll('+', ''),
      "device_uuid": deviceUUID,
      "platform": Platform.isAndroid ? "android" : "ios",
      "model": model,
      "brand": brand,
      "fcm_token": fcmToken,
      "status": "active",
    };

    print('📤 Sending registration: ${jsonEncode(body)}');

    // final url = kDebugMode
    //     // ? Uri.parse("https://192.168.100.85/asalpay_erp/Wallet_merchant_transfer/registerDevice")
    //     // ? Uri.parse("https://dev2.asalxpress.com/merchantPurchase/registerDevice")
    //      ? Uri.parse("${ApiUrls.BASE_URL}/Wallet_merchant_transfer/registerDevice");

    final url = Uri.parse("${ApiUrls.BASE_URL}merchantPurchase/registerDevice");

    // final url = Uri.parse("https://192.168.100.85/asalpay_erp/merchantPurchase/registerDevice");



    final headers = {
      "Content-Type": "application/json",
      "API-KEY": "39913b5d5937728da1834df0b5d639b2",
      //  "API-KEY": "ASAL-0014480cb3f2eed05b6c2a4"
    };

    try {
      final response = await _postWithOptionalCertificateBypass(
        url: url,
        headers: headers,
        body: jsonEncode(body),
      );

      print(' Status: ${response.statusCode}');
      print(' Response: ${response.body}');

      if (response.statusCode != 200) {
        print(' Registration failed');
      } else {
        print(' Registration successful');
      }
    } catch (e) {
      print(' Registration error: $e');
    }
  }

  static Future<http.Response> _postWithOptionalCertificateBypass({
    required Uri url,
    required Map<String, String> headers,
    required String body,
  }) async {
    if (kDebugMode && url.toString().contains('192.168')) {
      final ioc = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final client = IOClient(ioc);
      return client.post(url, headers: headers, body: body);
    } else {
      return http.post(url, headers: headers, body: body);
    }
  }
}
