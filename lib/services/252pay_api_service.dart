import 'dart:convert';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/utils/session_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_urls.dart';

class ApiService {
  // Localka physical device (smartphone): IP-ka PC-ka ee same WiFi (e.g. 192.168.1.83). Beddel IP-ka haddii PC-kuu yeesho kale.
  // static const String localBaseUrl252 =
  //     'http://192.168.1.83/asalexpress_252pay/';
  static const String localBaseUrl252 = 'https://252dev.asalxpress.com/';
  // .env BASE_URL_252PAY haddii buuxo; empty yahay isticmaal localBaseUrl252
  static String get baseUrl {
    final u = (dotenv.env['BASE_URL_252PAY'] ?? '').trim();
    final b = u.isEmpty ? localBaseUrl252 : (u.endsWith('/') ? u : '$u/');
    return b;
  }

  static String get imgURL => baseUrl;

  TokenClass tokenClass = TokenClass();

  /// Helper method to build URL correctly for 252pay endpoints
  /// Uses local baseUrl for 252pay (NOT .env BASE_URL)
  String _buildUrl(String endpoint) {
    String baseUrl252 = baseUrl;
    // Remove trailing slash if present
    if (baseUrl252.endsWith('/')) {
      baseUrl252 = baseUrl252.substring(0, baseUrl252.length - 1);
    }
    // Ensure endpoint starts with /
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }
    return '$baseUrl252$endpoint';
  }

  Future<List<Category>> fetchSubCategories(int categoryId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('wallet25Pay/categories2')),
      headers: headers,
      body: jsonEncode({'category_id': categoryId.toString()}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load subcategories');
    }
  }

  Future<List<Category>> fetchCategories() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final url = _buildUrl('wallet25Pay/mainCategories');
    appLog("📡 Fetching categories from: $url");

    final response = await http.post(Uri.parse(url), headers: headers);
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    appLog("📥 Response status: ${response.statusCode}");
    appLog("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      try {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if (jsonData['status'] == false || jsonData['status'] == 'False') {
          final errorMsg = jsonData['message'] ??
              jsonData['error'] ??
              'Failed to load categories';
          throw Exception(errorMsg);
        }
        final List data = jsonData['data'] ?? [];
        appLog("✅ Loaded ${data.length} categories");
        return data.map((e) => Category.fromJson(e)).toList();
      } catch (e) {
        appLog("❌ Error parsing response: $e");
        throw Exception('Failed to parse categories response: $e');
      }
    } else {
      final errorMsg =
          'Failed to load categories. Status: ${response.statusCode}';
      appLog("❌ $errorMsg");
      throw Exception(errorMsg);
    }
  }

  Future<List<Map<String, dynamic>>> fetchmerchantAccount() async {
    final user = dotenv.env['user'] ?? '';
    final pass = dotenv.env['pass'] ?? '';

    // Encode the credentials to Base64

    String basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": basicAuth,
      "Content-Type": "application/json",
    };
    final response = await http.post(
        Uri.parse(
            '${ApiUrls.BASE_URL}ApiAsalController/fetch252payMerchantAccount'),
        headers: headers);
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['accountInfo'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load Account');
    }
  }

  void appLog(String message) {
    debugPrint("🟢[MYAPP] $message");
  }

  Future<List<Product>> fetchProducts(int categoryId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('wallet25Pay/products')),
      headers: headers,
      body: jsonEncode({'category_id': categoryId.toString()}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    appLog("📥 Response status: ${response.statusCode}");
    appLog("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      try {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if (jsonData['status'] == false || jsonData['status'] == 'False') {
          final errorMsg = jsonData['message'] ??
              jsonData['error'] ??
              'Failed to load products';
          throw Exception(errorMsg);
        }
        final List data = jsonData['data'] ?? [];
        appLog("✅ Loaded ${data.length} products (excluding QOWS KAAB)");
        return data.map((e) => Product.fromJson(e)).toList();
      } catch (e) {
        appLog("❌ Error parsing products response: $e");
        throw Exception('Failed to parse products response: $e');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['messages']?['error'] ??
          errorBody['message'] ??
          'Failed to load products';
      appLog("❌ Error: $errorMessage");
      throw Exception(errorMessage);
    }
  }

  Future<List<Product>> fetchDiscuntProducts() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('wallet25Pay/discountProducts')),
      headers: headers,
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['messages']?['error'] ?? 'Failed to load products';
      throw Exception(errorMessage);
    }
  }

  Future<void> submitOrder({
    required String? walletAccount,
    required double totalAmount,
    required String status,
    required List<Map<String, dynamic>> items,
    required int addressId,
    required String description,
    required String phone,
    required String merchantAccount,
    required String currencyFromId,
    required String currencyToId,
    required double? amountFrom,
    required double? amountTo,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final url = Uri.parse(_buildUrl('wallet25Pay/storeOrders'));

    final body = {
      // 🛒 Order details
      "wallet_account": walletAccount,
      "total_amount": totalAmount,
      "status": status,
      "payment_status": status,
      "items": items,
      "district_id": addressId,
      "delivery_address_desc": description,
      "phone_number": phone,

      // 💸 Transaction fields
      "account": walletAccount,
      "currencyFrom": currencyFromId,
      "amountFrom": amountFrom,
      "merchantNo": merchantAccount,
      "currencyTo": currencyToId,
      "amountTo": amountTo,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode != 200) {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['messages']?['error'] ?? 'Order submission failed';
      throw Exception(errorMessage);
    }

    appLog("✅ Order submitted successfully: ${response.body}");
  }

  Future<void> cancelOrder({
    required String orderId,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final url = Uri.parse(_buildUrl('wallet25Pay/cancelOrders'));
    final body = {
      "order_id": orderId,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    print(response.body);
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode != 200) {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['messages']?['error'] ?? 'Order Cancellation failed';
      throw Exception(errorMessage);
    }
  }

  Future<List<Map<String, dynamic>>> getMyOrders(String walletAccountId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('wallet25Pay/getMyOrders')),
      headers: headers,
      body: jsonEncode({'wallet_accounts_id': walletAccountId}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<List<Map<String, dynamic>>> getAcountInfo(
      String? walletAccountId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    var url =
        "${ApiUrls.BASE_URL}Wallet_merchant_transfer/fill_customer_currency";

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'account_no': walletAccountId}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      if (jsonData['result'] is List) {
        final List resultList = jsonData['result'];
        return resultList.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Unexpected format: result is not a list');
      }
    } else {
      throw Exception('Failed to load AccountInfo');
    }
  }

  /// Fetches wallet balance(s) from the same API as My Profile (Wallet_dashboard/fill_Account_balances).
  /// Use this instead of getAcountInfo when the latter returns "This account does not exist"
  /// for valid logged-in accounts.
  Future<List<Map<String, dynamic>>> getAccountBalancesFromDashboard(
      String? accountNo) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final url = "${ApiUrls.BASE_URL}Wallet_dashboard/fill_Account_balances";

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'account_no': accountNo}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final result = jsonData['result'];
      if (result is List && result.isNotEmpty) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } else {
      final body = jsonDecode(response.body);
      final msg = body['message'] ?? body['msg'] ?? 'Failed to load balance';
      throw Exception(msg is String ? msg : 'Failed to load balance');
    }
  }

  Future<List<Map<String, dynamic>>> getMerchantInfo(
      String? merchantAccountId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    var url = "${ApiUrls.BASE_URL}Wallet_merchant_transfer/fill_merchant_info";

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'merchant_account_no': merchantAccountId}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      if (jsonData['result'] is List) {
        final List resultList = jsonData['result'];
        return resultList.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Unexpected format: result is not a list');
      }
    } else {
      throw Exception('Failed to load AccountInfo');
    }
  }

  Future<void> purchaseOrder({
    required String? walletAccount,
    required String? merchantAccount,
    required String currencyFromId,
    required String currencyToId,
    required double amountFrom,
    required double amountTo,
  }) async {
    final user = dotenv.env['user'] ?? '';
    final pass = dotenv.env['pass'] ?? '';

    // Encode the credentials to Base64

    String basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      'API-KEY': tokenClass.key,
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
    };

    var urls = "${ApiUrls.BASE_URL}ApiAsalController/purchaseOrder";
    final url = Uri.parse(urls);

    final body = {
      "account": walletAccount,
      "currencyFrom": currencyFromId,
      "amountFrom": amountFrom,
      "merchantNo": merchantAccount,
      "currencyTo": currencyToId,
      "amountTo": amountTo,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body); // for debugging

    final responseBody = jsonDecode(response.body);

    if (response.statusCode != 200) {
      // Show actual message from API if exists
      final errorMessage = responseBody['message'] ??
          responseBody['messages']?['error'] ??
          'Order payment submission failed';
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> getExchangeInfo(
      String currencyFromId, String currencyToId, double amountFrom) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    var url = "${ApiUrls.BASE_URL}Wallet_merchant_transfer/get_exchange";

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'currency_fro_id': currencyFromId,
        'currency_to_id': currencyToId,
        'amount_fro': amountFrom,
      }),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);

    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      if (jsonData.containsKey('result') &&
          jsonData['result'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(jsonData['result']);
      } else {
        throw Exception('Unexpected format: result is not a Map');
      }
    } else {
      throw Exception('Failed to load Exchange Info');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomerAddress() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('wallet25Pay/getCustomerAdress')),
      headers: headers,
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['messages']?['error'] ?? 'Failed to load Address';
      throw Exception(errorMessage);
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaymentPolicy() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('wallet25Pay/policies')),
      headers: headers,
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load Payment Policy');
    }
  }

  // ==================== BNPL API METHODS ====================

  /// Check if order is eligible for BNPL
  Future<Map<String, dynamic>> checkBnplEligibility(
      double totalOrderAmount) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/check_eligibility')),
      headers: headers,
      body: jsonEncode({'total_order_amount': totalOrderAmount}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    appLog("📥 Response status: ${response.statusCode}");
    appLog("📥 Response body: ${response.body}");

    if (response.body.isEmpty || response.body.trim().isEmpty) {
      throw Exception('Empty response from server');
    }

    try {
      if (response.statusCode == 200) {
        extendTokenExpiryIfInApp();
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return jsonData['data'] ?? {};
      } else {
        try {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['message'] ?? 'Failed to check BNPL eligibility';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
              'Failed to check BNPL eligibility: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  /// Get BNPL products
  Future<List<Map<String, dynamic>>> getBnplProducts({int? categoryId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = categoryId != null ? {'category_id': categoryId} : {};
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/products')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load BNPL products');
    }
  }

  /// Get product rules for BNPL.
  /// Pass [monthlyIncome] so backend can check income vs product price eligibility.
  /// When not eligible, returns data with eligible: false and eligibility_reason.
  Future<Map<String, dynamic>> getProductRules(
    String incomeCategory,
    double productPrice, {
    double? monthlyIncome,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = <String, dynamic>{
      'income_category': incomeCategory,
      'product_price': productPrice,
    };
    if (monthlyIncome != null) {
      body['monthly_income'] = monthlyIncome;
    }
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/product_rules')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to get product rules';
      throw Exception(errorMessage);
    }
  }

  /// Get regions
  Future<List<Map<String, dynamic>>> getBnplRegions() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/regions')),
      headers: headers,
      body: jsonEncode({}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load regions');
    }
  }

  /// Get districts
  Future<List<Map<String, dynamic>>> getBnplDistricts({int? regionId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = regionId != null ? {'region_id': regionId} : {};
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/districts')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load districts');
    }
  }

  /// Calculate location risk
  Future<Map<String, dynamic>> calculateLocationRisk(
      int districtId, int regionId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/calculate_location_risk')),
      headers: headers,
      body: jsonEncode({
        'district_id': districtId,
        'region_id': regionId,
      }),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to calculate location risk';
      throw Exception(errorMessage);
    }
  }

  /// Get credit limit
  Future<Map<String, dynamic>> getCreditLimit(String walletAccount) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/credit_limit')),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to get credit limit';
      throw Exception(errorMessage);
    }
  }

  /// Get or create customer
  Future<Map<String, dynamic>> getOrCreateCustomer(
      Map<String, dynamic> customerData) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/get_or_create_customer')),
      headers: headers,
      body: jsonEncode(customerData),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('get_or_create_customer body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to get or create customer';
      throw Exception(errorMessage);
    }
  }

  /// Get BNPL banks
  Future<List<Map<String, dynamic>>> getBnplBanks() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/banks')),
      headers: headers,
      body: jsonEncode({}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getBnplBanks body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to load banks';
      throw Exception(errorMessage);
    }
  }

  /// Create BNPL application
  Future<Map<String, dynamic>> createBnplApplication(
      Map<String, dynamic> applicationData) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final requestBody = jsonEncode(applicationData);
    appLog("📤 Request body: $requestBody");

    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/create_application')),
      headers: headers,
      body: requestBody,
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('create application body: ${response.body}');
    appLog("📥 Response status: ${response.statusCode}");
    appLog("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      try {
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          throw Exception('Empty response from server');
        }
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true && jsonData['data'] != null) {
          return jsonData['data'] as Map<String, dynamic>;
        } else {
          final errorMessage = jsonData['message'] ??
              jsonData['error'] ??
              jsonData['messages']?['error'] ??
              'Failed to create application';
          throw Exception(errorMessage);
        }
      } catch (e) {
        if (e is FormatException) {
          appLog("❌ FormatException: $e");
          throw Exception(
              'Invalid response format from server: ${response.body}');
        }
        rethrow;
      }
    } else {
      try {
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          throw Exception(
              'Server returned status ${response.statusCode} with empty body');
        }
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ??
            errorBody['error'] ??
            errorBody['messages']?['error'] ??
            errorBody['errors']?.toString() ??
            'Failed to create application (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is FormatException) {
          appLog("❌ FormatException parsing error: $e");
          throw Exception(
              'Server error (Status: ${response.statusCode}): ${response.body}');
        }
        rethrow;
      }
    }
  }

  /// Get my applications
  Future<List<Map<String, dynamic>>> getMyBnplApplications(String walletAccount,
      {String? status}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = {'wallet_account': walletAccount};
    if (status != null) body['status'] = status;
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/my_applications')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final responseData = jsonDecode(response.body);
      final data = responseData['data'];

      // Handle different response formats
      if (data == null) {
        return [];
      }

      if (data is List) {
        return data.map((e) {
          if (e is Map<String, dynamic>) {
            return e;
          } else if (e is Map) {
            return Map<String, dynamic>.from(e);
          } else {
            return <String, dynamic>{};
          }
        }).toList();
      } else {
        // If data is not a list, return empty list
        appLog("⚠️ Unexpected data format: ${data.runtimeType}");
        return [];
      }
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to load applications';
      throw Exception(errorMessage);
    }
  }

  /// Cancel BNPL application (only when status is pending or draft).
  Future<void> cancelBnplApplication(
      int applicationId, String walletAccount) async {
    final token = tokenClass.getToken();
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/cancel_application')),
      headers: headers,
      body: jsonEncode({
        'application_id': applicationId,
        'wallet_account': walletAccount,
      }),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body)) {
      throw Exception('Session expired');
    }
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to cancel application');
    }
  }

  /// Get application details (data, branches for district, items for multi-product)
  Future<Map<String, dynamic>> getApplicationDetails(int applicationId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/application_details')),
      headers: headers,
      body: jsonEncode({'application_id': applicationId}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      // Return full payload so UI can show branches and items
      final branchesRaw = jsonData['branches'];
      final itemsRaw = jsonData['items'];
      return {
        'data': jsonData['data'] ?? {},
        'branches': branchesRaw is List
            ? (branchesRaw)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : <Map<String, dynamic>>[],
        'items': itemsRaw is List
            ? (itemsRaw)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : <Map<String, dynamic>>[],
      };
    } else {
      throw Exception('Failed to load application details');
    }
  }

  /// Upload document
  Future<Map<String, dynamic>> uploadDocument({
    required int applicationId,
    required String documentType,
    required String documentName,
    required String documentBase64,
    String? expirationDate,
    String? documentNumber,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final requestBody = <String, dynamic>{
      'application_id': applicationId, // Ensure it's int
      'document_type': documentType,
      'document_name': documentName,
      'document_base64': documentBase64,
    };

    // Add document number if provided
    if (documentNumber != null && documentNumber.isNotEmpty) {
      requestBody['document_number'] = documentNumber;
    }

    if (expirationDate != null && expirationDate.isNotEmpty) {
      requestBody['expiration_date'] = expirationDate;
      appLog("📅 Expiration Date: $expirationDate");
    } else {
      appLog("⚠️ Expiration Date: NOT PROVIDED (null or empty)");
    }

    appLog("📤 Upload Document Request:");
    appLog("   - URL: ${_buildUrl('api/wallet/bnpl/upload_document')}");
    appLog("   - Application ID: $applicationId");
    appLog("   - Document Type: $documentType");
    appLog("   - Document Name: $documentName");
    appLog("   - Expiration Date: ${expirationDate ?? 'NULL'}");
    appLog("   - Base64 Length: ${documentBase64.length} characters");

    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/upload_document')),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    appLog("📥 Upload Document Response:");
    appLog("   - Status Code: ${response.statusCode}");
    appLog("   - Response Body: ${response.body}");

    print("Full Request Body: ${jsonEncode(requestBody)}");
    print("Response: ${response.body}");
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to upload document';
      throw Exception(errorMessage);
    }
  }

  /// Get repayment schedules
  Future<List<Map<String, dynamic>>> getRepaymentSchedules(String walletAccount,
      {int? applicationId, String? paymentStatus}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final Map<String, dynamic> body = {'wallet_account': walletAccount};
    if (applicationId != null)
      body['application_id'] = applicationId.toString();
    if (paymentStatus != null) body['payment_status'] = paymentStatus;
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/repayment_schedules')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load repayment schedules');
    }
  }

  /// Make payment
  Future<Map<String, dynamic>> makeBnplPayment({
    required int scheduleId,
    required String walletAccount,
    required double amount,
    required String paymentMethod,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/make_payment')),
      headers: headers,
      body: jsonEncode({
        'schedule_id': scheduleId,
        'wallet_account': walletAccount,
        'amount': amount,
        'payment_method': paymentMethod,
      }),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to make payment';
      throw Exception(errorMessage);
    }
  }

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(String walletAccount,
      {int? applicationId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final Map<String, dynamic> body = {'wallet_account': walletAccount};
    if (applicationId != null)
      body['application_id'] = applicationId.toString();
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/payment_history')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print(response.body);
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load payment history');
    }
  }

  /// Get BNPL Application Configuration
  /// When totalOrderAmount is under 400, backend may include birth_certificate as allowed document.
  Future<Map<String, dynamic>> getBnplApplicationConfiguration(
      {String? riskLevel, double? totalOrderAmount}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = <String, dynamic>{};
    if (riskLevel != null) body['risk_level'] = riskLevel;
    if (totalOrderAmount != null) body['total_order_amount'] = totalOrderAmount;
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/application_configuration')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getBnplApplicationConfiguration body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData['data'] ?? {};
      } else {
        throw Exception(
            jsonData['message'] ?? 'Failed to load application configuration');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to load application configuration';
      throw Exception(errorMessage);
    }
  }

  /// Save Application Draft
  Future<Map<String, dynamic>> saveApplicationDraft(
      Map<String, dynamic> draftData) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/save_draft')),
      headers: headers,
      body: jsonEncode(draftData),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('saveApplicationDraft body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData['data'] ?? {};
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to save draft');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to save draft';
      throw Exception(errorMessage);
    }
  }

  /// Get Application Draft
  Future<Map<String, dynamic>?> getApplicationDraft(
      String walletAccount) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/get_draft')),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getApplicationDraft body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true && jsonData['data'] != null) {
        return jsonData['data'] as Map<String, dynamic>;
      } else {
        return null;
      }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to get draft';
      throw Exception(errorMessage);
    }
  }

  /// Get Previous Application Data (for pre-fill)
  Future<Map<String, dynamic>?> getPreviousApplicationData(
      String walletAccount) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/get_previous_application_data')),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getPreviousApplicationData body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true && jsonData['data'] != null) {
        return jsonData['data'] as Map<String, dynamic>;
      } else {
        return null;
      }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to get previous application data';
      throw Exception(errorMessage);
    }
  }

  /// Check if Documents Step Can Be Skipped (check existing documents)
  Future<Map<String, dynamic>> checkDocumentsSkip(String walletAccount) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/check_documents_skip')),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('checkDocumentsSkip body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to check documents';
      throw Exception(errorMessage);
    }
  }

  // ==================== QOWS KAAB API METHODS ====================

  /// Get QOWS KAAB Products
  Future<List<Map<String, dynamic>>> getQowsKaabProducts() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = {};
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/products')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getQowsKaabProducts body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        final List data = jsonData['data'] ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(
            jsonData['message'] ?? 'Failed to load QOWS KAAB products');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to load QOWS KAAB products';
      throw Exception(errorMessage);
    }
  }

  /// Check QOWS KAAB Eligibility
  Future<Map<String, dynamic>> checkQowsKaabEligibility({
    required String walletAccount,
    required String serviceModel,
    int? familySize,
    String? usageType,
    double? monthlyIncome,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = {
      'wallet_account': walletAccount,
      'service_model': serviceModel,
      if (familySize != null) 'family_size': familySize,
      if (usageType != null) 'usage_type': usageType,
      if (monthlyIncome != null) 'monthly_income': monthlyIncome,
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/check_eligibility')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('checkQowsKaabEligibility body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonData['data'] ?? {});
      // Include top-level message so UI shows exact reason (e.g. "You already have an application", "Minimum income is \$300")
      if (jsonData['message'] != null) data['message'] = jsonData['message'];
      return data;
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to check eligibility';
      throw Exception(errorMessage);
    }
  }

  /// Create QOWS KAAB Application
  Future<Map<String, dynamic>> createQowsKaabApplication(
      Map<String, dynamic> applicationData) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/create_application')),
      headers: headers,
      body: jsonEncode(applicationData),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('createQowsKaabApplication body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData['data'] ?? {};
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to create application');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to create application';
      throw Exception(errorMessage);
    }
  }

  /// Get My QOWS KAAB Applications
  Future<List<Map<String, dynamic>>> getMyQowsKaabApplications(
      String walletAccount) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/my_applications')),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getMyQowsKaabApplications body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        final List data = jsonData['data'] ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to load applications');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to load applications';
      throw Exception(errorMessage);
    }
  }

  /// Get QOWS KAAB Application Details
  Future<Map<String, dynamic>> getQowsKaabApplicationDetails(
      int qowsKaabId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/application_details')),
      headers: headers,
      body: jsonEncode({'qows_kaab_id': qowsKaabId}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getQowsKaabApplicationDetails body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData['data'] ?? {};
      } else {
        throw Exception(
            jsonData['message'] ?? 'Failed to load application details');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to load application details';
      throw Exception(errorMessage);
    }
  }

  /// Cancel QOWS KAAB application (only when pending approval).
  Future<void> cancelQowsKaabApplication(
      int qowsKaabId, String walletAccount) async {
    final token = tokenClass.getToken();
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/cancel_application')),
      headers: headers,
      body: jsonEncode({
        'qows_kaab_id': qowsKaabId,
        'wallet_account': walletAccount,
      }),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body)) {
      throw Exception('Session expired');
    }
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to cancel application');
    }
  }

  /// Get QOWS KAAB Payment Due (returns today's payment with payment_id, amount_due, etc.)
  Future<Map<String, dynamic>> getQowsKaabPaymentDue({
    required String walletAccount,
    int? qowsKaabId,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/payment_due')),
      headers: headers,
      body: jsonEncode({
        'wallet_account': walletAccount,
        if (qowsKaabId != null) 'qows_kaab_id': qowsKaabId,
      }),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData;
      }
      throw Exception(jsonData['message'] ?? 'Failed to load payment due');
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load payment due');
    }
  }

  /// Make QOWS KAAB Payment (payment_id from getPaymentDue, amount, payment_method: 'wallet')
  Future<Map<String, dynamic>> makeQowsKaabPayment({
    required int paymentId,
    required double amount,
    String paymentMethod = 'wallet',
    String? paymentReference,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/make_payment')),
      headers: headers,
      body: jsonEncode({
        'payment_id': paymentId,
        'amount': amount,
        'payment_method': paymentMethod,
        if (paymentReference != null) 'payment_reference': paymentReference,
      }),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData;
      }
      throw Exception(jsonData['message'] ?? 'Payment failed');
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Payment failed');
    }
  }

  /// Get QOWS KAAB Payment History (for View Payment History screen)
  Future<List<Map<String, dynamic>>> getQowsKaabPaymentHistory(
      String? walletAccount,
      {int? qowsKaabId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = <String, dynamic>{'wallet_account': walletAccount};
    if (qowsKaabId != null) body['qows_kaab_id'] = qowsKaabId;
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/payment_history')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        final List data = jsonData['data'] ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw Exception(jsonData['message'] ?? 'Failed to load payment history');
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load payment history');
    }
  }

  /// Get Monthly Usage (Daily Credit service model)
  Future<Map<String, dynamic>> getMonthlyUsage(int qowsKaabId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/monthly_usage')),
      headers: headers,
      body: jsonEncode({'qows_kaab_id': qowsKaabId}),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('getMonthlyUsage body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData['data'] ?? {};
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to load monthly usage');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to load monthly usage';
      throw Exception(errorMessage);
    }
  }

  /// Add Daily Purchase (Daily Credit Only)
  Future<Map<String, dynamic>> addDailyPurchase({
    required int qowsKaabId,
    required List<String> items,
    required double amount,
    String? description,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = {
      'qows_kaab_id': qowsKaabId,
      'items': items,
      'amount': amount,
      if (description != null) 'description': description,
    };
    final response = await http.post(
      Uri.parse(_buildUrl('api/wallet/bnpl/qows_kaab/add_daily_purchase')),
      headers: headers,
      body: jsonEncode(body),
    );
    if (checkAndHandleSessionExpiry(response.statusCode, response.body))
      throw Exception('Session expired');
    print('addDailyPurchase body: ${response.body}');
    if (response.statusCode == 200) {
      extendTokenExpiryIfInApp();
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true) {
        return jsonData['data'] ?? {};
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to add daily purchase');
      }
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to add daily purchase';
      throw Exception(errorMessage);
    }
  }
}
