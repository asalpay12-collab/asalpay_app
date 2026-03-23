import 'dart:convert';
import 'dart:typed_data';

import 'package:asalpay/services/ewareeji_api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Ewareeji (crypto) API – madax banaan, Bearer token.
/// Base URL, username, password .env-ga (EWAREEJI_API_BASE_URL, EWAREEJI_API_USERNAME, EWAREEJI_API_PASSWORD).
/// Auth: POST /api/admin/auth/login { username, password } → { success, user, tokens: { accessToken } }.
class EwareejiApiService {
  EwareejiApiService._();
  static final EwareejiApiService instance = EwareejiApiService._();

  String? _cachedToken;

  /// Last error message (debug) – clear when a call succeeds.
  String? lastError;

  String _base(String path) {
    final b = EwareejiApiConfig.baseUrl;
    if (b.isEmpty) throw StateError('EWAREEJI_API_BASE_URL not set in .env');
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }

  /// Fetch Bearer token (username/password from .env). Cached; clear on 401.
  Future<String?> getBearerToken({bool forceRefresh = false}) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set (BASE_URL, USERNAME, PASSWORD)';
      return null;
    }
    if (!forceRefresh && _cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    try {
      final url = _base('/api/admin/auth/login');
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': EwareejiApiConfig.username,
          'password': EwareejiApiConfig.password,
        }),
      );
      if (res.statusCode != 200) {
        lastError = 'Login failed: ${res.statusCode} ${res.body}';
        return null;
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      if (map == null) {
        lastError = 'Login: invalid response';
        return null;
      }
      final tokens = map['tokens'];
      final token = tokens is Map
          ? (tokens['accessToken'] as String?)
          : (map['token'] as String? ?? map['accessToken'] as String?);
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        return _cachedToken;
      }
      lastError = 'Login: no accessToken in response';
      return null;
    } catch (e) {
      lastError = 'Login error: $e';
      return null;
    }
  }

  void clearToken() {
    _cachedToken = null;
  }

  Future<Map<String, String>> _headers() async {
    final token = await getBearerToken();
    final m = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      m['Authorization'] = 'Bearer $token';
    }
    return m;
  }

  Future<List<EwareejiNetwork>> getNetworks({bool activeOnly = true}) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return [];
    }
    try {
      final q = activeOnly ? '?active=true' : '';
      final url = _base('/api/admin/crypto/networks$q');
      final res = await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Networks: 401 Unauthorized (check login)';
        return [];
      }
      if (res.statusCode != 200) {
        lastError = 'Networks: ${res.statusCode} ${res.body}';
        return [];
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! List) {
        lastError = 'Networks: response.data not a list';
        return [];
      }
      final list = data.cast<Map<String, dynamic>>();
      return list.map((e) => EwareejiNetwork.fromJson(e)).toList();
    } catch (e) {
      lastError = 'Networks error: $e';
      return [];
    }
  }

  Future<List<EwareejiWallet>> getWallets({bool activeOnly = true}) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return [];
    }
    try {
      final q = activeOnly ? '?active=true' : '';
      final res = await http.get(
        Uri.parse(_base('/api/admin/crypto/wallets$q')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Wallets: 401 Unauthorized';
        return [];
      }
      if (res.statusCode != 200) {
        lastError = 'Wallets: ${res.statusCode} ${res.body}';
        return [];
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! List) {
        lastError = 'Wallets: response.data not a list';
        return [];
      }
      final list = data.cast<Map<String, dynamic>>();
      return list.map((e) => EwareejiWallet.fromJson(e)).toList();
    } catch (e) {
      lastError = 'Wallets error: $e';
      return [];
    }
  }

  /// POST customer-wallets (mobile registration). Requires wallet_id, wallet_address, wallet_name.
  /// wallet_account_id = AsalPay wallet account of the user (qofka AsalPay ku leeyahay).
  /// wallet_name = waajib (customer_wallet_name backend); ma null noqon karo.
  /// Returns null on success, error message on failure.
  Future<String?> registerCustomerWallet(
      int walletId, String walletAddress, String walletName,
      {int walletAccountId = 0}) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return lastError;
    }
    if (walletAddress.trim().isEmpty) {
      lastError = 'Wallet address is empty';
      return lastError;
    }
    final name = walletName.trim();
    if (name.isEmpty) {
      lastError = 'Wallet name is required';
      return lastError;
    }
    try {
      // Backend stores user label in customer_wallet_name; wallet_name in response = joined wallet/network name
      final body = <String, dynamic>{
        'wallet_id': walletId,
        'wallet_address': walletAddress.trim(),
        'wallet_account_id': walletAccountId,
        'customer_wallet_name': name,
        'is_active': true,
      };
      final res = await http.post(
        Uri.parse(_base('/api/admin/crypto/customer-wallets')),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Register: 401 Unauthorized';
        return lastError;
      }
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      try {
        final map = jsonDecode(res.body) as Map<String, dynamic>?;
        lastError = map?['error']?.toString() ??
            'Register: ${res.statusCode} ${res.body}';
      } catch (_) {
        lastError = 'Register: ${res.statusCode} ${res.body}';
      }
      return lastError;
    } catch (e) {
      lastError = 'Register error: $e';
      return lastError;
    }
  }

  Future<List<EwareejiCustomerWallet>> getCustomerWallets(
      {bool activeOnly = true}) async {
    if (!EwareejiApiConfig.isConfigured) return [];
    try {
      final q = activeOnly ? '?active=true' : '';
      final res = await http.get(
        Uri.parse(_base('/api/admin/crypto/customer-wallets$q')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        return [];
      }
      if (res.statusCode != 200) return [];
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! List) return [];
      final list = data.cast<Map<String, dynamic>>();
      return list.map((e) => EwareejiCustomerWallet.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// GET customer wallets by account. GET /api/admin/crypto/customer-wallets/by-account/:wallet_account_id
  Future<List<EwareejiCustomerWallet>> getCustomerWalletsByAccount(
      String walletAccountId, {bool activeOnly = true}) async {
    if (!EwareejiApiConfig.isConfigured) return [];
    final id = walletAccountId.trim();
    if (id.isEmpty) return [];
    try {
      final q = activeOnly ? '?active=true' : '';
      final res = await http.get(
        Uri.parse(_base('/api/admin/crypto/customer-wallets/by-account/$id$q')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        return [];
      }
      if (res.statusCode != 200) return [];
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! List) return [];
      final list = data.cast<Map<String, dynamic>>();
      return list.map((e) => EwareejiCustomerWallet.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Crypto Company Wallets API ---

  /// GET /api/admin/crypto/company-wallets
  Future<List<EwareejiCompanyWallet>> getCompanyWallets(
      {bool activeOnly = true}) async {
    if (!EwareejiApiConfig.isConfigured) return [];
    try {
      final q = activeOnly ? '?active=true' : '';
      final res = await http.get(
        Uri.parse(_base('/api/admin/crypto/company-wallets$q')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        return [];
      }
      if (res.statusCode != 200) return [];
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! List) return [];
      final list = data.cast<Map<String, dynamic>>();
      return list.map((e) => EwareejiCompanyWallet.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Crypto Transactions API ---

  /// POST /api/admin/crypto/transactions. Type: 'BUY' or 'SELL'.
  /// Returns created transaction id or null on failure (check lastError).
  Future<int?> createTransaction({
    required int walletAccountId,
    required String type,
    required int customerWalletId,
    required int companyWalletId,
    required double fiatAmount,
    required double cryptoAmount,
    required double rate,
    int? rateId,
    double spreadAmount = 0,
    String status = 'pending',
  }) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return null;
    }
    final typeUpper = type.toUpperCase();
    if (typeUpper != 'BUY' && typeUpper != 'SELL') {
      lastError = 'Transaction type must be BUY or SELL';
      return null;
    }
    // Sanitize numerics so backend never receives NaN/Infinity (causes bigint parse error).
    double _num(double v) => v.isNaN || v.isInfinite ? 0.0 : v;
    final body = <String, dynamic>{
      'wallet_account_id': walletAccountId,
      'type': typeUpper,
      'customer_wallet_id': customerWalletId,
      'company_wallet_id': companyWalletId,
      'fiat_amount': _num(fiatAmount),
      'crypto_amount': _num(cryptoAmount),
      'rate': _num(rate),
      if (rateId != null) 'rate_id': rateId,
      'spread_amount': _num(spreadAmount),
      'status': status,
    };
    print('Ewareeji createTransaction body: $body');
    debugPrint('Ewareeji createTransaction body: $body');
    try {
      final res = await http.post(
        Uri.parse(_base('/api/admin/crypto/transactions')),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Create transaction: 401 Unauthorized';
        return null;
      }
      if (res.statusCode == 201 || res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>?;
        final data = map?['data'];
        if (data is Map<String, dynamic>) {
          final id = data['id'];
          if (id is int) return id;
          final n = int.tryParse(id?.toString() ?? '');
          return n;
        }
        return null;
      }
      try {
        final map = jsonDecode(res.body) as Map<String, dynamic>?;
        lastError = map?['error']?.toString() ?? 'Create transaction: ${res.statusCode} ${res.body}';
      } catch (_) {
        lastError = 'Create transaction: ${res.statusCode} ${res.body}';
      }
      return null;
    } catch (e) {
      lastError = 'Create transaction error: $e';
      return null;
    }
  }

  /// GET /api/admin/crypto/transactions?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&wallet_account_id=
  /// Returns list of transactions; empty on error (check lastError).
  Future<List<EwareejiCryptoTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? walletAccountId,
  }) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return [];
    }
    try {
      final params = <String>[];
      if (startDate != null) {
        params.add('start_date=${_formatDate(startDate)}');
      }
      if (endDate != null) {
        params.add('end_date=${_formatDate(endDate)}');
      }
      if (walletAccountId != null) {
        params.add('wallet_account_id=$walletAccountId');
      }
      final q = params.isEmpty ? '' : '?${params.join('&')}';
      final res = await http.get(
        Uri.parse(_base('/api/admin/crypto/transactions$q')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Transactions: 401 Unauthorized';
        return [];
      }
      if (res.statusCode != 200) {
        lastError = 'Transactions: ${res.statusCode} ${res.body}';
        return [];
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! List) {
        lastError = 'Transactions: response.data not a list';
        return [];
      }
      final list = data.cast<Map<String, dynamic>>();
      return list
          .map((e) => EwareejiCryptoTransaction.fromJson(e))
          .toList();
    } catch (e) {
      lastError = 'Transactions error: $e';
      return [];
    }
  }

  static String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // --- Crypto Rates API ---

  /// GET /api/admin/crypto/rates?wallet_id=&active=
  Future<List<EwareejiRate>> getRates(
      {int? walletId, bool activeOnly = false}) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return [];
    }
    try {
      final params = <String>[];
      if (walletId != null) params.add('wallet_id=$walletId');
      if (activeOnly) params.add('active=true');
      final q = params.isEmpty ? '' : '?${params.join('&')}';
      final res = await http.get(
        Uri.parse(_base('/api/admin/crypto/rates$q')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Rates: 401 Unauthorized';
        return [];
      }
      if (res.statusCode != 200) {
        lastError = 'Rates: ${res.statusCode} ${res.body}';
        return [];
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! List) {
        lastError = 'Rates: response.data not a list';
        return [];
      }
      final list = data.cast<Map<String, dynamic>>();
      return list.map((e) => EwareejiRate.fromJson(e)).toList();
    } catch (e) {
      lastError = 'Rates error: $e';
      return [];
    }
  }

  /// GET /api/admin/crypto/rates/for-amount?wallet_id=&amount=&type=buy|sell
  /// Returns the active rate for the wallet that applies to the given fiat amount. Use for transactions.
  Future<EwareejiRate?> getRateForAmount(int walletId, double amount,
      {String type = 'buy'}) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return null;
    }
    if (type != 'buy' && type != 'sell') type = 'buy';
    try {
      final uri = Uri.parse(_base('/api/admin/crypto/rates/for-amount'))
          .replace(queryParameters: {
        'wallet_id': '$walletId',
        'amount': '$amount',
        'type': type
      });
      final res = await http.get(uri, headers: await _headers());
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Rate for amount: 401 Unauthorized';
        return null;
      }
      if (res.statusCode == 404 || res.statusCode == 400) {
        try {
          final map = jsonDecode(res.body) as Map<String, dynamic>?;
          lastError =
              map?['error']?.toString() ?? '${res.statusCode} ${res.body}';
        } catch (_) {
          lastError = '${res.statusCode} ${res.body}';
        }
        return null;
      }
      if (res.statusCode != 200) {
        lastError = 'Rate for amount: ${res.statusCode} ${res.body}';
        return null;
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! Map<String, dynamic>) {
        lastError = 'Rate for amount: invalid response';
        return null;
      }
      return EwareejiRate.fromJson(data);
    } catch (e) {
      lastError = 'Rate for amount error: $e';
      return null;
    }
  }

  /// GET /api/admin/crypto/rates/:id
  Future<EwareejiRate?> getRateById(int id) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return null;
    }
    try {
      final res = await http.get(
        Uri.parse(_base('/api/admin/crypto/rates/$id')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Rate: 401 Unauthorized';
        return null;
      }
      if (res.statusCode == 404) {
        lastError = 'Rate not found';
        return null;
      }
      if (res.statusCode != 200) {
        lastError = 'Rate: ${res.statusCode} ${res.body}';
        return null;
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = map?['data'];
      if (data is! Map<String, dynamic>) return null;
      return EwareejiRate.fromJson(data);
    } catch (e) {
      lastError = 'Rate error: $e';
      return null;
    }
  }

  /// POST /api/admin/crypto/rates
  Future<String?> createRate({
    required int walletId,
    required String rateDate,
    required double buyRate,
    required double sellRate,
    double? minAmount,
    double? maxAmount,
    bool isActive = true,
  }) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return lastError;
    }
    try {
      final body = <String, dynamic>{
        'wallet_id': walletId,
        'rate_date': rateDate,
        'buy_rate': buyRate,
        'sell_rate': sellRate,
        'is_active': isActive,
      };
      if (minAmount != null) body['min_amount'] = minAmount;
      if (maxAmount != null) body['max_amount'] = maxAmount;
      final res = await http.post(
        Uri.parse(_base('/api/admin/crypto/rates')),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Create rate: 401 Unauthorized';
        return lastError;
      }
      if (res.statusCode == 201 || res.statusCode == 200) return null;
      try {
        final map = jsonDecode(res.body) as Map<String, dynamic>?;
        lastError =
            map?['error']?.toString() ?? '${res.statusCode} ${res.body}';
      } catch (_) {
        lastError = '${res.statusCode} ${res.body}';
      }
      return lastError;
    } catch (e) {
      lastError = 'Create rate error: $e';
      return lastError;
    }
  }

  /// PUT /api/admin/crypto/rates/:id
  Future<String?> updateRate(int id,
      {int? walletId,
      String? rateDate,
      double? buyRate,
      double? sellRate,
      double? minAmount,
      double? maxAmount,
      bool? isActive}) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return lastError;
    }
    try {
      final body = <String, dynamic>{};
      if (walletId != null) body['wallet_id'] = walletId;
      if (rateDate != null) body['rate_date'] = rateDate;
      if (buyRate != null) body['buy_rate'] = buyRate;
      if (sellRate != null) body['sell_rate'] = sellRate;
      if (minAmount != null) body['min_amount'] = minAmount;
      if (maxAmount != null) body['max_amount'] = maxAmount;
      if (isActive != null) body['is_active'] = isActive;
      if (body.isEmpty) return null;
      final res = await http.put(
        Uri.parse(_base('/api/admin/crypto/rates/$id')),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Update rate: 401 Unauthorized';
        return lastError;
      }
      if (res.statusCode == 404) {
        lastError = 'Rate not found';
        return lastError;
      }
      if (res.statusCode == 200) return null;
      try {
        final map = jsonDecode(res.body) as Map<String, dynamic>?;
        lastError =
            map?['error']?.toString() ?? '${res.statusCode} ${res.body}';
      } catch (_) {
        lastError = '${res.statusCode} ${res.body}';
      }
      return lastError;
    } catch (e) {
      lastError = 'Update rate error: $e';
      return lastError;
    }
  }

  /// DELETE /api/admin/crypto/rates/:id
  Future<String?> deleteRate(int id) async {
    lastError = null;
    if (!EwareejiApiConfig.isConfigured) {
      lastError = 'Ewareeji API: .env not set';
      return lastError;
    }
    try {
      final res = await http.delete(
        Uri.parse(_base('/api/admin/crypto/rates/$id')),
        headers: await _headers(),
      );
      if (res.statusCode == 401) {
        clearToken();
        lastError = 'Delete rate: 401 Unauthorized';
        return lastError;
      }
      if (res.statusCode == 404 || res.statusCode == 409) {
        try {
          final map = jsonDecode(res.body) as Map<String, dynamic>?;
          lastError =
              map?['error']?.toString() ?? '${res.statusCode} ${res.body}';
        } catch (_) {
          lastError = '${res.statusCode} ${res.body}';
        }
        return lastError;
      }
      if (res.statusCode == 200) return null;
      lastError = 'Delete rate: ${res.statusCode} ${res.body}';
      return lastError;
    } catch (e) {
      lastError = 'Delete rate error: $e';
      return lastError;
    }
  }
}

class EwareejiNetwork {
  final int id;
  final String code;
  final String name;

  EwareejiNetwork({required this.id, required this.code, required this.name});

  static EwareejiNetwork fromJson(Map<String, dynamic> j) {
    return EwareejiNetwork(
      id: (j['id'] is int)
          ? j['id'] as int
          : int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
    );
  }
}

class EwareejiWallet {
  final int id;
  final String name;
  final int networkId;
  final String? networkCode;
  final String? networkName;

  /// Base64 data URL from API (e.g. "data:image/png;base64,iVBORw0...")
  final String? icon;

  EwareejiWallet({
    required this.id,
    required this.name,
    required this.networkId,
    this.networkCode,
    this.networkName,
    this.icon,
  });

  /// Display label: network_code + " - " + name (e.g. "TRC20 - USDT")
  String get displayLabel => (networkCode != null && networkCode!.isNotEmpty)
      ? '$networkCode - $name'
      : name;

  /// Decoded icon bytes for Image.memory, or null if icon is null/invalid.
  Uint8List? get iconBytes {
    final s = icon;
    if (s == null || s.isEmpty) return null;
    final i = s.indexOf(',');
    if (i < 0) return null;
    try {
      return base64Decode(s.substring(i + 1));
    } catch (_) {
      return null;
    }
  }

  static EwareejiWallet fromJson(Map<String, dynamic> j) {
    return EwareejiWallet(
      id: (j['id'] is int)
          ? j['id'] as int
          : int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      name: (j['name'] ?? '').toString(),
      networkId: (j['network_id'] is int)
          ? j['network_id'] as int
          : int.tryParse(j['network_id']?.toString() ?? '0') ?? 0,
      networkCode: j['network_code']?.toString(),
      networkName: j['network_name']?.toString(),
      icon: j['icon']?.toString(),
    );
  }
}

class EwareejiCustomerWallet {
  final int id;
  final int walletId;
  final String walletAddress;
  final String? walletAccountId;
  final String? customerWalletName;
  final String? walletName;
  final String? networkCode;
  final String? networkName;

  EwareejiCustomerWallet({
    required this.id,
    required this.walletId,
    required this.walletAddress,
    this.walletAccountId,
    this.customerWalletName,
    this.walletName,
    this.networkCode,
    this.networkName,
  });

  /// Display for dropdown: customer_wallet_name (wallet_name network_code).
  String get displayLabel {
    final name = (customerWalletName ?? '').trim();
    final part = [walletName, networkCode].where((e) => e != null && e.toString().trim().isNotEmpty).map((e) => e.toString().trim()).join(' ');
    if (name.isEmpty && part.isEmpty) return 'Wallet #$id';
    if (name.isEmpty) return part;
    if (part.isEmpty) return name;
    return '$name ($part)';
  }

  static EwareejiCustomerWallet fromJson(Map<String, dynamic> j) {
    return EwareejiCustomerWallet(
      id: (j['id'] is int)
          ? j['id'] as int
          : int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      walletId: (j['wallet_id'] is int)
          ? j['wallet_id'] as int
          : int.tryParse(j['wallet_id']?.toString() ?? '0') ?? 0,
      walletAddress: (j['wallet_address'] ?? '').toString(),
      walletAccountId: j['wallet_account_id']?.toString(),
      customerWalletName: j['customer_wallet_name']?.toString(),
      walletName: j['wallet_name']?.toString(),
      networkCode: j['network_code']?.toString(),
      networkName: j['network_name']?.toString(),
    );
  }
}

/// True if [walletAccountIdFromApi] matches logged-in AsalPay [accountIdFromApp].
/// Handles + prefix, spaces, and numeric equality (e.g. "25261…" vs int-as-string).
bool ewareejiWalletAccountIdsMatch(
    String? accountIdFromApp, String? walletAccountIdFromApi) {
  final a = (accountIdFromApp ?? '').trim();
  final b = (walletAccountIdFromApi ?? '').trim();
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  String norm(String s) =>
      s.replaceAll(RegExp(r'\s'), '').replaceFirst(RegExp(r'^\+'), '');
  final na = norm(a);
  final nb = norm(b);
  if (na == nb) return true;
  final ia = int.tryParse(na);
  final ib = int.tryParse(nb);
  return ia != null && ib != null && ia == ib;
}

class EwareejiCompanyWallet {
  final int id;
  final int walletId;
  final String address;
  final bool isActive;

  EwareejiCompanyWallet({
    required this.id,
    required this.walletId,
    required this.address,
    this.isActive = true,
  });

  static EwareejiCompanyWallet fromJson(Map<String, dynamic> j) {
    return EwareejiCompanyWallet(
      id: (j['id'] is int) ? j['id'] as int : int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      walletId: (j['wallet_id'] is int) ? j['wallet_id'] as int : int.tryParse(j['wallet_id']?.toString() ?? '0') ?? 0,
      address: (j['address'] ?? '').toString(),
      isActive: j['is_active'] == true,
    );
  }
}

/// Single crypto transaction from GET /api/admin/crypto/transactions.
class EwareejiCryptoTransaction {
  final String id;
  final int walletAccountId;
  final String type;
  final int customerWalletId;
  final int companyWalletId;
  final double fiatAmount;
  final double cryptoAmount;
  final double rate;
  final double spreadAmount;
  final String status;
  final int? rateId;
  final String createdAt;
  final String? customerWalletName;
  final String? customerNetworkCode;
  final String? customerNetworkName;
  final String? companyWalletName;
  final String? companyNetworkCode;
  final String? companyNetworkName;

  EwareejiCryptoTransaction({
    required this.id,
    required this.walletAccountId,
    required this.type,
    required this.customerWalletId,
    required this.companyWalletId,
    required this.fiatAmount,
    required this.cryptoAmount,
    required this.rate,
    required this.spreadAmount,
    required this.status,
    this.rateId,
    required this.createdAt,
    this.customerWalletName,
    this.customerNetworkCode,
    this.customerNetworkName,
    this.companyWalletName,
    this.companyNetworkCode,
    this.companyNetworkName,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static EwareejiCryptoTransaction fromJson(Map<String, dynamic> j) {
    return EwareejiCryptoTransaction(
      id: (j['id'] ?? '').toString(),
      walletAccountId: (j['wallet_account_id'] is int)
          ? j['wallet_account_id'] as int
          : int.tryParse(j['wallet_account_id']?.toString() ?? '0') ?? 0,
      type: (j['type'] ?? '').toString().toUpperCase(),
      customerWalletId: (j['customer_wallet_id'] is int)
          ? j['customer_wallet_id'] as int
          : int.tryParse(j['customer_wallet_id']?.toString() ?? '0') ?? 0,
      companyWalletId: (j['company_wallet_id'] is int)
          ? j['company_wallet_id'] as int
          : int.tryParse(j['company_wallet_id']?.toString() ?? '0') ?? 0,
      fiatAmount: _toDouble(j['fiat_amount']),
      cryptoAmount: _toDouble(j['crypto_amount']),
      rate: _toDouble(j['rate']),
      spreadAmount: _toDouble(j['spread_amount']),
      status: (j['status'] ?? '').toString().toLowerCase(),
      rateId: j['rate_id'] != null
          ? ((j['rate_id'] is int)
              ? j['rate_id'] as int
              : int.tryParse(j['rate_id']?.toString() ?? ''))
          : null,
      createdAt: (j['created_at'] ?? '').toString(),
      customerWalletName: j['customer_wallet_name']?.toString(),
      customerNetworkCode: j['customer_network_code']?.toString(),
      customerNetworkName: j['customer_network_name']?.toString(),
      companyWalletName: j['company_wallet_name']?.toString(),
      companyNetworkCode: j['company_network_code']?.toString(),
      companyNetworkName: j['company_network_name']?.toString(),
    );
  }
}

/// Crypto rate (buy/sell) for a wallet, optionally scoped by amount range.
class EwareejiRate {
  final int id;
  final int walletId;
  final String rateDate;
  final double buyRate;
  final double sellRate;
  final double? minAmount;
  final double? maxAmount;

  /// For for-amount response: the rate to use (buy_rate or sell_rate per type).
  final double? rate;
  final bool isActive;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  EwareejiRate({
    required this.id,
    required this.walletId,
    required this.rateDate,
    required this.buyRate,
    required this.sellRate,
    this.minAmount,
    this.maxAmount,
    this.rate,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static EwareejiRate fromJson(Map<String, dynamic> j) {
    return EwareejiRate(
      id: (j['id'] is int)
          ? j['id'] as int
          : int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      walletId: (j['wallet_id'] is int)
          ? j['wallet_id'] as int
          : int.tryParse(j['wallet_id']?.toString() ?? '0') ?? 0,
      rateDate: (j['rate_date'] ?? '').toString(),
      buyRate: _toDouble(j['buy_rate']),
      sellRate: _toDouble(j['sell_rate']),
      minAmount: j['min_amount'] != null ? _toDouble(j['min_amount']) : null,
      maxAmount: j['max_amount'] != null ? _toDouble(j['max_amount']) : null,
      rate: j['rate'] != null ? _toDouble(j['rate']) : null,
      isActive: j['is_active'] == true,
      createdBy: j['created_by'] is int
          ? j['created_by'] as int
          : int.tryParse(j['created_by']?.toString() ?? ''),
      createdAt: j['created_at']?.toString(),
      updatedAt: j['updated_at']?.toString(),
    );
  }
}
