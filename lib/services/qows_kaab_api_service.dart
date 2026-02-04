import 'dart:convert';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/services/252pay_api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

/// QOWS KAAB API Service for handling QOWS KAAB related API calls
/// Uses same base URL as 252pay (asalexpress_252pay) so products/regions load correctly
class QowsKaabApiService {
  final TokenClass tokenClass = TokenClass();

  /// Base URL for wallet API (same as 252pay - includes asalexpress_252pay path)
  static String get _baseUrl {
    String b = ApiService.baseUrl;
    if (b.endsWith('/')) return b;
    return '$b/';
  }

  void appLog(String message) {
    debugPrint("🟢[QOWS_KAAB] $message");
  }

  /// Get QOWS KAAB Configuration
  Future<Map<String, dynamic>> getConfiguration({String? serviceModel}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/configuration'),
      headers: headers,
      body: jsonEncode({'service_model': serviceModel}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load QOWS KAAB configuration');
    }
  }

  /// Get QOWS KAAB Products
  Future<List<Map<String, dynamic>>> getProducts({int? categoryId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/products'),
      headers: headers,
      body: jsonEncode({'category_id': categoryId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == false) {
        throw Exception(data['message'] ?? 'Failed to load QOWS KAAB products');
      }
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load QOWS KAAB products');
    }
  }

  /// Check QOWS KAAB Eligibility
  Future<Map<String, dynamic>> checkEligibility({
    required String walletAccount,
    Map<String, dynamic>? eligibilityData,
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
      ...?eligibilityData,
    };
    print('${_baseUrl}api/wallet/qows_kaab/check_eligibility');
    print(jsonEncode(body));
    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/check_eligibility'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check QOWS KAAB eligibility');
    }
  }

  /// Create QOWS KAAB Application
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
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/create_application'),
      headers: headers,
      body: jsonEncode(applicationData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? 'Failed to create QOWS KAAB application';
      throw Exception(errorMessage);
    }
  }

  /// Get My QOWS KAAB Applications
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
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/my_applications'),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load QOWS KAAB applications');
    }
  }

  /// Get QOWS KAAB Application Details
  Future<Map<String, dynamic>> getApplicationDetails({
    required int qowsKaabId,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/application_details'),
      headers: headers,
      body: jsonEncode({'qows_kaab_id': qowsKaabId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load QOWS KAAB application details');
    }
  }

  /// Get Regions (for QOWS KAAB)
  Future<Map<String, dynamic>> getRegions() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/regions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == false) {
        throw Exception(data['message'] ?? 'Failed to load regions');
      }
      return data;
    } else {
      throw Exception('Failed to load regions');
    }
  }

  /// Get Districts (for QOWS KAAB)
  Future<Map<String, dynamic>> getDistricts({int? regionId}) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/districts'),
      headers: headers,
      body: jsonEncode({'region_id': regionId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load districts');
    }
  }

  /// Get Usage Types
  Future<Map<String, dynamic>> getUsageTypes() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/usage_types'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load usage types');
    }
  }

  /// Get usage type limits (min/max amount) from tbl_qows_kaab_usage_type_limits
  /// usage_type: household | business, service_model: daily_credit | monthly_pack
  Future<Map<String, dynamic>> getUsageTypeLimits({
    required String usageType,
    required String serviceModel,
  }) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/usage_type_limits'),
      headers: headers,
      body: jsonEncode({
        'usage_type': usageType,
        'service_model': serviceModel,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['status'] == true && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to load usage type limits');
    } else {
      final Map<String, dynamic> err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to load usage type limits');
    }
  }

  /// Get Payment Due
  Future<Map<String, dynamic>> getPaymentDue({
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
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/payment_due'),
      headers: headers,
      body: jsonEncode({
        'wallet_account': walletAccount,
        if (qowsKaabId != null) 'qows_kaab_id': qowsKaabId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payment due');
    }
  }

  /// Get customer by wallet from tbl_bnpl_customers (for form pre-fill).
  /// Returns { data_found: bool, customer: map? }.
  Future<Map<String, dynamic>> getCustomerByWallet({
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
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/customer_by_wallet'),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load customer');
  }

  /// Get Document Types from tbl_bnpl_document_types (for dropdown)
  Future<List<Map<String, dynamic>>> getDocumentTypes() async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/document_types'),
      headers: headers,
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == false) {
        throw Exception(data['message'] ?? 'Failed to load document types');
      }
      final list = data['data'];
      return list != null ? List<Map<String, dynamic>>.from(list) : [];
    } else {
      throw Exception('Failed to load document types');
    }
  }

  /// Get Customer Documents for QOWS KAAB
  Future<Map<String, dynamic>> getCustomerDocuments({
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
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/customer_documents'),
      headers: headers,
      body: jsonEncode({'wallet_account': walletAccount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load customer documents');
    }
  }

  /// Upload Document for QOWS KAAB
  Future<Map<String, dynamic>> uploadDocument({
    required int qowsKaabId,
    required String documentType,
    required String documentName,
    required String documentFile,
    required String fileExtension,
    String? documentNumber,
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
      'document_type': documentType,
      'document_name': documentName,
      'document_file': documentFile,
      'file_extension': fileExtension,
      if (documentNumber != null && documentNumber.isNotEmpty) 'document_number': documentNumber,
    };

    final response = await http.post(
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/upload_document'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to upload document';
      throw Exception(errorMessage);
    }
  }

  /// Make QOWS KAAB Payment
  Future<Map<String, dynamic>> makePayment({
    required String walletAccount,
    required int qowsKaabId,
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
      Uri.parse('${_baseUrl}api/wallet/qows_kaab/make_payment'),
      headers: headers,
      body: jsonEncode({
        'wallet_account': walletAccount,
        'qows_kaab_id': qowsKaabId,
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
}
