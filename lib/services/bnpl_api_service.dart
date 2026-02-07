import 'dart:convert';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/services/252pay_api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

/// BNPL (252Pay) API Service for handling BNPL related API calls
class BnplApiService {
  final TokenClass tokenClass = TokenClass();

  // Base URL for local testing (eligibility endpoint exists on local, not dev2)

  static String get _baseUrl {
    String b = ApiService.baseUrl;
    if (b.endsWith('/')) return b;
    return '$b/';
  }

  void appLog(String message) {
    debugPrint("🟢[BNPL] $message");
  }

  /// Helper method to build URL correctly for local endpoints
  String _buildLocalUrl(String endpoint) {
    String base = _baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }
    return '$base$endpoint';
  }

  /// Get BNPL Products
  Future<List<Map<String, dynamic>>> getProducts({int? categoryId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/products'),
      headers: headers,
      body: jsonEncode({'category_id': categoryId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load BNPL products');
    }
  }

  /// Check Order Eligibility for BNPL
  Future<Map<String, dynamic>> checkEligibility({
    required double totalOrderAmount,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    // Eligibility endpoint exists on local server, not dev2
    final url = _buildLocalUrl('api/wallet/bnpl/check_eligibility');
    appLog("📡 Checking eligibility: $url");
    appLog("📦 Request body: {'total_order_amount': $totalOrderAmount}");

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'total_order_amount': totalOrderAmount}),
    );

    appLog("📥 Response status: ${response.statusCode}");
    appLog("📥 Response body: ${response.body}");

    // Handle empty response body
    if (response.body.isEmpty || response.body.trim().isEmpty) {
      final errorMsg =
          'Server returned empty response. Status: ${response.statusCode}';
      appLog("❌ $errorMsg");
      throw Exception(errorMsg);
    }

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> result = jsonDecode(response.body);
        // Handle both response formats
        if (result['status'] == false || result['status'] == 'False') {
          final errorMsg = result['message'] ??
              result['error'] ??
              'Eligibility check failed';
          throw Exception(errorMsg);
        }
        appLog(
            "✅ Eligibility check successful: ${result['data']?['eligible']}");
        return result;
      } catch (e) {
        appLog("❌ Error parsing eligibility response: $e");
        throw Exception('Failed to parse eligibility response: $e');
      }
    } else {
      // Try to parse error response
      try {
        if (response.body.isNotEmpty) {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);
          final errorMsg = errorBody['message'] ??
              errorBody['error'] ??
              'Failed to check BNPL eligibility. Status: ${response.statusCode}';
          appLog("❌ $errorMsg");
          throw Exception(errorMsg);
        }
      } catch (e) {
        // If parsing fails, use generic error
      }
      final errorMsg =
          'Failed to check BNPL eligibility. Status: ${response.statusCode}';
      appLog("❌ $errorMsg");
      throw Exception(errorMsg);
    }
  }

  /// Get Product Rules (for calculating deposit)
  Future<Map<String, dynamic>> getProductRules({
    required String incomeCategory,
    required double productPrice,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/product_rules'),
      headers: headers,
      body: jsonEncode({
        'income_category': incomeCategory,
        'product_price': productPrice,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get product rules');
    }
  }

  /// Get Regions
  Future<List<Map<String, dynamic>>> getRegions() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/regions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load regions');
    }
  }

  /// Get Districts
  Future<List<Map<String, dynamic>>> getDistricts({int? regionId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/districts'),
      headers: headers,
      body: jsonEncode({'region_id': regionId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load districts');
    }
  }

  /// Get Banks
  Future<List<Map<String, dynamic>>> getBanks() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/banks'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load banks');
    }
  }

  /// Create BNPL Application
  Future<Map<String, dynamic>> createApplication({
    required Map<String, dynamic> applicationData,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/create_application'),
      headers: headers,
      body: jsonEncode(applicationData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to create BNPL application';
      throw Exception(errorMessage);
    }
  }

  /// Get My BNPL Applications
  Future<List<Map<String, dynamic>>> getMyApplications({
    required String walletAccount,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/my_applications'),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );

    if (response.statusCode == 200) {
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
        return [];
      }
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to load BNPL applications';
      throw Exception(errorMessage);
    }
  }

  /// Get BNPL Application Details
  Future<Map<String, dynamic>> getApplicationDetails({
    required int applicationId,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/application_details'),
      headers: headers,
      body: jsonEncode({'application_id': applicationId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load BNPL application details');
    }
  }

  /// Upload Document
  Future<Map<String, dynamic>> uploadDocument({
    required String walletAccount,
    required String documentType,
    required String filePath,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
    };

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/upload_document'),
    );

    request.headers.addAll(headers);
    request.fields['wallet_account'] = walletAccount;
    request.fields['document_type'] = documentType;
    request.files.add(await http.MultipartFile.fromPath('document', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload document');
    }
  }

  /// Get Repayment Schedules
  Future<List<Map<String, dynamic>>> getRepaymentSchedules({
    required String walletAccount,
    int? applicationId,
    String? paymentStatus,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/repayment_schedules'),
      headers: headers,
      body: jsonEncode({
        'wallet_account': walletAccount,
        if (applicationId != null) 'application_id': applicationId,
        if (paymentStatus != null) 'payment_status': paymentStatus,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load repayment schedules');
    }
  }

  /// Make Payment
  Future<Map<String, dynamic>> makePayment({
    required int scheduleId,
    required String walletAccount,
    required double amount,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/make_payment'),
      headers: headers,
      body: jsonEncode({
        'schedule_id': scheduleId,
        'wallet_account': walletAccount,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to make payment';
      throw Exception(errorMessage);
    }
  }

  /// Negotiate Price
  Future<Map<String, dynamic>> negotiatePrice({
    required int productId,
    required double originalPrice,
    required double requestedPrice,
    String? customerMessage,
    int? applicationId,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/negotiate_price'),
      headers: headers,
      body: jsonEncode({
        'product_id': productId,
        'original_price': originalPrice,
        'requested_price': requestedPrice,
        if (customerMessage != null) 'customer_message': customerMessage,
        if (applicationId != null) 'application_id': applicationId,
      }),
    );

    final body = response.body.trim();
    if (body.isEmpty) {
      if (response.statusCode == 200) {
        return {
          'status': false,
          'data': {'can_negotiate': false},
          'message': 'Server returned no response. Please try again.',
        };
      }
      throw Exception(
        'Server returned empty response (${response.statusCode}). Please try again.',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(body) as Map<String, dynamic>? ?? {};
    } catch (e) {
      appLog('negotiatePrice parse error: $e');
      throw Exception(
        'Invalid response from server. Please try again.',
      );
    }

    if (response.statusCode == 200) {
      return decoded;
    } else {
      final errorMessage = decoded['message']?.toString() ??
          decoded['messages']?['error']?.toString() ??
          'Failed to negotiate price';
      throw Exception(errorMessage);
    }
  }

  /// Get Price Negotiation
  Future<Map<String, dynamic>> getPriceNegotiation({
    required int applicationId,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/get_price_negotiation'),
      headers: headers,
      body: jsonEncode({
        'application_id': applicationId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to get price negotiation';
      throw Exception(errorMessage);
    }
  }

  /// Accept Price Offer
  Future<Map<String, dynamic>> acceptPriceOffer({
    required int negotiationId,
    required int applicationId,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}api/wallet/bnpl/accept_price_offer'),
      headers: headers,
      body: jsonEncode({
        'negotiation_id': negotiationId,
        'application_id': applicationId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to accept price offer';
      throw Exception(errorMessage);
    }
  }
}
