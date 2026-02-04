import 'dart:convert';
import 'package:asalpay/services/tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_urls.dart';


class ApiService {

       static const String baseUrl = 'http://asal-alb-649087458.af-south-1.elb.amazonaws.com/252/wallet25Pay';
     // static const String baseUrl = 'http://192.168.100.71/asalexpress_252pay/wallet25Pay';
     // static const String imgURL = 'http://192.168.100.71/asalexpress_252pay/';
        static const String imgURL = 'http://asal-alb-649087458.af-south-1.elb.amazonaws.com/252/';

  TokenClass tokenClass = TokenClass();

   Future<List<Category>> fetchSubCategories(int categoryId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final response = await http.post(Uri.parse('$baseUrl/categories2'),headers: headers,
      body:  jsonEncode({'category_id': categoryId.toString()}),);
    print(response.body);
    if (response.statusCode == 200) {
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

    final response = await http.post(Uri.parse('$baseUrl/mainCategories'),headers: headers);

    print(response.body);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
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
      final response = await http.post(Uri.parse('${ApiUrls.BASE_URL}ApiAsalController/fetch252payMerchantAccount'),headers: headers );
      print(response.body);
      if (response.statusCode == 200) {
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
      Uri.parse('$baseUrl/products'),
      headers:headers,
      body: jsonEncode({'category_id': categoryId.toString()}),
    );

print(response.body);
print(response.body);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['messages']?['error'] ?? 'Failed to load products';
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
      Uri.parse('$baseUrl/discountProducts'),
      headers:headers,
    );

print(response.body);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['messages']?['error'] ?? 'Failed to load products';
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

       final url = Uri.parse('$baseUrl/storeOrders');

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

       if (response.statusCode != 200) {
         final Map<String, dynamic> errorBody = jsonDecode(response.body);
         final errorMessage = errorBody['messages']?['error'] ?? 'Order submission failed';
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
    final url = Uri.parse('$baseUrl/cancelOrders');
    final body = {
      "order_id": orderId,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  print(response.body);
    if (response.statusCode != 200) {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['messages']?['error'] ?? 'Order Cancellation failed';
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
      Uri.parse('$baseUrl/getMyOrders'),
      headers:headers,
      body: jsonEncode({'wallet_accounts_id': walletAccountId}),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }

  }


  Future<List<Map<String, dynamic>>> getAcountInfo(String? walletAccountId) async {
    String token = tokenClass.getToken();
    appLog("🔑 Token: $token");

    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    var url = "${ApiUrls.BASE_URL}Wallet_merchant_transfer/fill_customer_currency";

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'account_no': walletAccountId}),
    );

    if (response.statusCode == 200) {
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

  Future<List<Map<String, dynamic>>> getMerchantInfo(String? merchantAccountId) async {
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

    if (response.statusCode == 200) {
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

  Future<Map<String, dynamic>> getExchangeInfo(String currencyFromId, String currencyToId, double amountFrom) async {
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

    print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      if (jsonData.containsKey('result') && jsonData['result'] is Map<String, dynamic>) {
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
         Uri.parse('$baseUrl/getCustomerAdress'),
         headers:headers,
       );

       print(response.body);
       if (response.statusCode == 200) {
         final List data = jsonDecode(response.body)['data'] ?? [];
         return data.map((e) => Map<String, dynamic>.from(e)).toList();
       } else {
         final Map<String, dynamic> errorBody = jsonDecode(response.body);
         final errorMessage = errorBody['messages']?['error'] ?? 'Failed to load Address';
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
       final response = await http.post(Uri.parse('$baseUrl/policies'),headers: headers,);
       print(response.body);
       if (response.statusCode == 200) {
         final List data = jsonDecode(response.body)['data'] ?? [];
         return data.map((e) => Map<String, dynamic>.from(e)).toList();
       } else {
         throw Exception('Failed to load Payment Policy');
       }
     }


}



