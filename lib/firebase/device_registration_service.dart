import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/services/252pay_api_service.dart';
import 'package:asalpay/services/tokens.dart';

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

    final walletAccount = walletAccountsId.replaceAll('+', '').trim();
    final body = {
      "wallet_account": walletAccount,
      "wallet_accounts_id": walletAccount,
      "device_uuid": deviceUUID,
      "platform": Platform.isAndroid ? "android" : "ios",
      "model": model,
      "brand": brand,
      "fcm_token": fcmToken,
      "status": "active",
    };

    print('📤 Sending registration: ${jsonEncode(body)}');

    // 252pay (Path 2): same baseUrl as 252pay_api_service – diiwaangeli device (tbl_devices_info + tbl_customer_devices)
    final base252 = ApiService.baseUrl.replaceAll(RegExp(r'/$'), '');
    final url252 = Uri.parse('$base252/api/wallet/bnpl/register_device');
    print('📡 252pay register_device URL: $url252');
    final tokenClass = TokenClass();
    final headers252 = {
      "Content-Type": "application/json",
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer ${tokenClass.getToken()}",
    };
    try {
      final response252 = await _postWithOptionalCertificateBypass(
        url: url252,
        headers: headers252,
        body: jsonEncode(body),
      );
      if (response252.statusCode == 200) {
        print('✅ 252pay device registration OK – row waa la xareeyey');
      } else {
        print('❌ 252pay device registration FAILED status=${response252.statusCode} body=${response252.body}');
        if (response252.statusCode == 401) {
          print('   → 401: Hubi API-KEY iyo Bearer (c_collaboration.token + user/pass) backend-ka');
        }
      }
    } catch (e, st) {
      print('❌ 252pay registration error: $e');
      print('$st');
    }

    // DEV2 (legacy): keep so existing flows still receive notifications from DEV2 if used
    final urlDev2 = Uri.parse("${ApiUrls.BASE_URL}merchantPurchase/registerDevice");
    final headersDev2 = {
      "Content-Type": "application/json",
      "API-KEY": "39913b5d5937728da1834df0b5d639b2",
    };
    try {
      final responseDev2 = await _postWithOptionalCertificateBypass(
        url: urlDev2,
        headers: headersDev2,
        body: jsonEncode(body),
      );
      print(' DEV2 registration: ${responseDev2.statusCode}');
      if (responseDev2.statusCode != 200) {
        print(' DEV2 registration failed');
      } else {
        print(' DEV2 registration successful');
      }
    } catch (e) {
      print(' DEV2 registration error: $e');
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
