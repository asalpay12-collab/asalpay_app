import 'dart:io';

import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/utils/session_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';

import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';

//ImageSlider;
class HomeSliderModel with ChangeNotifier {
  final String image_id;
  final String imageUrl;

  HomeSliderModel({
    required this.image_id,
    required this.imageUrl,
  });
}

//from here 23/04

//TransactionModel;
class HomeTransactionModelRemittance with ChangeNotifier {
  String? trxID;
  final String tag;
  String? senderName;
  String? senderAccount;
  String? amountFro;
  String? amountTo;
  String? providerName;
  String? holderName;
  String? holderAccount;
  String? reference;
  final String startDate;
  final String endDate;
  final String date;
  final String? f_name;
  final String? m_name;
  String? image;
  String wallet_accounts_id;
  final String balance_type_name;
  final String currency_name;
  final String amount;
  final String? balance;
  final String trx_date;
  final String description;

  HomeTransactionModelRemittance({
    required this.trxID,
    required this.tag,
    required this.senderName,
    required this.senderAccount,
    required this.amountFro,
    required this.amountTo,
    required this.providerName,
    required this.holderName,
    required this.holderAccount,
    required this.reference,
    required this.startDate,
    required this.endDate,
    required this.date,
    required this.image,
    required this.wallet_accounts_id,
    required this.balance_type_name,
    required this.currency_name,
    required this.amount,
    required this.balance,
    required this.trx_date,
    required this.description,
    required this.f_name,
    required this.m_name,
  });
}

//to here 23/04

//from here 02/05/24

class WalletTransactionModel {
  final String walletTransferId;
  final String walletAccountsIdFro;
  final String senderName;
  final String amountFrom;
  final String walletAccountsIdTo;
  final String receiverName;
  final String amountTo;
  final String date;
  String? image;

  WalletTransactionModel({
    required this.walletTransferId,
    required this.walletAccountsIdFro,
    required this.senderName,
    required this.amountFrom,
    required this.walletAccountsIdTo,
    required this.receiverName,
    required this.amountTo,
    required this.date,
    required this.image,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
        walletTransferId: json['wallet_transfer_id'],
        walletAccountsIdFro: json['wallet_accounts_id_fro'],
        senderName: json['sender_name'],
        amountFrom: json['AmountFrom'],
        walletAccountsIdTo: json['wallet_accounts_id_to'],
        receiverName: json['receiver_name'],
        amountTo: json['AmountTo'],
        date: json['date'],
        image: json['image']);
  }
}

//to here 02/05/24

//TransactionModel;
class HomeTransactionModel with ChangeNotifier {
  String? transaction_id;
  final String tag;
  String? f_name;
  String? m_name;
  String? image;
  String wallet_accounts_id;
  final String balance_type_name;
  final String currency_name;
  final String amount;
  final String? balance;
  final String trx_date;
  final String description;

  HomeTransactionModel({
    required this.transaction_id,
    required this.tag,
    required this.f_name,
    required this.m_name,
    required this.image,
    required this.wallet_accounts_id,
    required this.balance_type_name,
    required this.currency_name,
    required this.amount,
    required this.balance,
    required this.trx_date,
    required this.description,
  });

// 6/1

  factory HomeTransactionModel.fromMap(Map<String, dynamic> map) {
    return HomeTransactionModel(
      transaction_id: map['transaction_id'],
      tag: map['tag'],
      f_name: map['f_name'],
      m_name: map['m_name'],
      image: map['image'],
      wallet_accounts_id: map['wallet_accounts_id'],
      balance_type_name: map['balance_type_name'],
      currency_name: map['currency_name'],
      amount: map['amount'],
      balance: map['balance'],
      trx_date: map['trx_date'],
      description: map['description'],
    );
  }
}

// 6/1
//started from her 4/7/24

class BalanceDisplayModel with ChangeNotifier {
  final String? wallet_customers_id;
  final String? wallet_accounts_id;
  final String? balance_type_name;
  final String? currency_id;
  final String? currency_name;
  final String? balance;
  final String? image;
  final String? f_name;
  final String? m_name;
  final String? tell;

  BalanceDisplayModel({
    this.balance_type_name,
    this.tell,
    this.wallet_accounts_id,
    this.currency_name,
    this.balance,
    this.currency_id,
    this.wallet_customers_id,
    this.image,
    this.f_name,
    this.m_name,
  });

  factory BalanceDisplayModel.fromMap(Map<String, dynamic> map) {
    return BalanceDisplayModel(
      balance_type_name: map['balance_type_name'],
      tell: map['tell'],
      wallet_accounts_id: map['wallet_accounts_id'],
      currency_name: map['currency_name'],
      balance: map['balance'],
      currency_id: map['currency_id'],
      wallet_customers_id: map['wallet_customers_id'],
      image: map['image'],
      f_name: map['f_name'],
      m_name: map['m_name'],
    );
  }
}

// ends to here 4/7/24

class HomeSliderAndTransaction with ChangeNotifier {
  // Create an instance of TokenClass
  TokenClass tokenClass = TokenClass();
  final String? walletid;
// 6/1/24

  List<HomeTransactionModel> _allTransactions = [];
  StreamController<List<HomeTransactionModel>> _controller =
      StreamController.broadcast();

  //   6/1 - 4:33

  StreamController<List<HomeTransactionModel>>? _controllerTwo;

  Stream<List<HomeTransactionModel>> get transactionsStream {
    _controller ??= StreamController<List<HomeTransactionModel>>.broadcast(
        onListen: fetchAndStreamAllTransactions);
    return _controller.stream;
  }

  Stream<List<HomeTransactionModel>> fetchAndStreamAllTransactions() async* {
    while (true) {
      var url = "${ApiUrls.BASE_URL}Wallet_dashboard/displayAllTransactions";

// Get the token
      String token = tokenClass.getToken();
      // Print the token
      // print("Token: $token");

      try {
        final response = await http.post(Uri.parse(url),
            body: json.encode({"wallet_accounts_no": walletid}),
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              // "API-KEY": "ASAL-0014480cb3f2eed05b6c2a4",
              "API-KEY": tokenClass.key,
              "Authorization": "Bearer $token",
            });

        if (response.statusCode == 200) {
          final List<HomeTransactionModel> newTransactions = [];
          final extractedData = json.decode(response.body);
          for (int i = 0; i < extractedData['result'].length; i++) {
            newTransactions
                .add(HomeTransactionModel.fromMap(extractedData['result'][i]));
          }

          if (_allTransactions.isEmpty ||
              !_allTransactions.equals(newTransactions)) {
            _allTransactions = newTransactions;
            _AllTransactions = newTransactions;
            _controller.add(_allTransactions);
            notifyListeners();
            yield _allTransactions;
          }
        } else {
          checkAndHandleSessionExpiry(response.statusCode, response.body);
          print('Request failed with status: ${response.statusCode}.');
        }
      } catch (error) {
        print('Error fetching transactions: $error');
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  //ends here 4:33

  HomeSliderAndTransaction(
    this.walletid,
  );
  List<HomeSliderModel> _images = [];
  List<HomeSliderModel> get images {
    return [..._images];
  }

// from here 23/04

  List<HomeTransactionModelRemittance> _AllTransactionsRemittance = [];

  List<HomeTransactionModelRemittance> get AllTransactionsRemittance {
    return [..._AllTransactionsRemittance];
  }

//02/05/24
  final List<WalletTransactionModel> _walletTransactions = [];

  List<WalletTransactionModel> get walletTransactions {
    return [..._walletTransactions];
  }

  Future<List<HomeTransactionModelRemittance>> fetchAndSetAllTrRemittance({
    required String walletId,
    required String startDate,
    required String endDate,
  }) async {
    //var url = "https://dev2.asalxpress.com/Wallet_dashboard/displayRemitAllTransactionsBetweenTwoDate";

// Get the token
    String token = tokenClass.getToken();

    var url =
        "${ApiUrls.BASE_URL}/Wallet_dashboard/displayRemitAllTransactionsBetweenTwoDate";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode({
          "wallet_accounts_no": walletId,
          "start_date": startDate,
          "end_date": endDate,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<HomeTransactionModelRemittance>
            loadedAllTransactionsRemittance = [];
        final List<dynamic> extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData.length; i++) {
          loadedAllTransactionsRemittance.add(
            HomeTransactionModelRemittance(
              trxID: extractedData[i]['trxID'] ?? '',
              tag: extractedData[i]['tag'] ?? '',
              f_name: extractedData[i]['f_name'] ?? '',
              m_name: extractedData[i]['m_name'] ?? '',
              image: extractedData[i]['image'] ?? '',
              wallet_accounts_id: extractedData[i]['wallet_accounts_id'] ?? '',
              balance_type_name: extractedData[i]['balance_type_name'] ?? '',
              currency_name: extractedData[i]['currency_name'] ?? '',
              amount: extractedData[i]['amount'] ?? '',
              balance: extractedData[i]['balance'] ?? '',
              trx_date: extractedData[i]['trx_date'] ?? '',
              description: extractedData[i]['description'] ?? '',
              senderName: extractedData[i]['sender_name'] ?? '',
              senderAccount: extractedData[i]['SenderAccount'] ?? '',
              amountFro: extractedData[i]['AmountFro'] ?? '',
              amountTo: extractedData[i]['AmountTo'] ?? '',
              providerName: extractedData[i]['ProviderName'] ?? '',
              holderName: extractedData[i]['HolderName'],
              holderAccount: extractedData[i]['HolderAccount'] ?? '',
              reference: extractedData[i]['reference'] ?? '',
              startDate: extractedData[i]['start_date'] ?? '',
              endDate: extractedData[i]['end_date'] ?? '',
              date: extractedData[i]['date'] ?? '',
            ),
          );
        }
        _AllTransactionsRemittance = loadedAllTransactionsRemittance.toList();
        return _AllTransactionsRemittance;
      } else {
        if (checkAndHandleSessionExpiry(response.statusCode, response.body)) {
          return [];
        }
        print('Request failed with status: ${response.statusCode}.');
        print('Response body: ${response.body}');
        throw Exception('Failed to load transactions');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

// 5/4/2024

  Future<List<WalletTransactionModel>> fetchAndSetWalletTransactions({
    required String walletId,
    required String startDate,
    required String endDate,
  }) async {
// Get the token
    String token = tokenClass.getToken();

    var url =
        "${ApiUrls.BASE_URL}/Wallet_dashboard/displayWalletAllTransactionsBetweenTwoDate";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode({
          "wallet_accounts_no": walletId,
          "start_date": startDate,
          "end_date": endDate,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> result = responseData['result'];

        final List<WalletTransactionModel> loadedTransactions = result
            .map((data) => WalletTransactionModel.fromJson(data))
            .toList();

        return loadedTransactions;
      } else {
        if (checkAndHandleSessionExpiry(response.statusCode, response.body)) {
          return [];
        }
        throw Exception('Failed to load transactions');
      }
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  List<HomeTransactionModel> _AllTransactions = [];
  List<HomeTransactionModel> get AllTransactions {
    return [..._AllTransactions];
  }

  final List<BalanceDisplayModel> _DisplayBalance = [];
  List<BalanceDisplayModel> get DisplayBalance {
    return [..._DisplayBalance];
  }

//Image SliderFunction;
  Future<List<HomeSliderModel>> fetchAndSetSliderImages() async {
// Get the token
    String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_dashboard/imageSlider";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "API-KEY": tokenClass.key,
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final List<HomeSliderModel> loadedSliderImages = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedSliderImages.add(
            HomeSliderModel(
              image_id: extractedData['result'][i]['image_id'],
              imageUrl: extractedData['result'][i]['image_name'],
            ),
          );
        }
        _images = loadedSliderImages.toList();
        return _images;
      } else {
        if (checkAndHandleSessionExpiry(response.statusCode, response.body)) {
          return _images;
        }
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  //All TransactionFunction;
  Future<List<HomeTransactionModel>> fetchAndSetAllTr() async {
// Get the token
    String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_dashboard/displayAllTransactions";
    try {
//       final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json',
// 'Access-Control-Allow-Origin': '*'});
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              // "wallet_accounts_no": "252615837893",
              "wallet_accounts_no": walletid
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
          });

      // print(response.body);
      if (response.statusCode == 200) {
        final List<HomeTransactionModel> loadedAllTransactions = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedAllTransactions.add(
            HomeTransactionModel(
              transaction_id: extractedData['result'][i]['image_id'],
              tag: extractedData['result'][i]['tag'],
              f_name: extractedData['result'][i]['f_name'],
              m_name: extractedData['result'][i]['m_name'],
              image: extractedData['result'][i]['image'],
              wallet_accounts_id: extractedData['result'][i]
                  ['wallet_accounts_id'],
              balance_type_name: extractedData['result'][i]
                  ['balance_type_name'],
              currency_name: extractedData['result'][i]['currency_name'],
              amount: extractedData['result'][i]['amount'],
              balance: extractedData['result'][i]['balance'],
              trx_date: extractedData['result'][i]['trx_date'],
              description: extractedData['result'][i]['description'],
            ),
          );
        }
        _AllTransactions = loadedAllTransactions.toList();
        notifyListeners();
        return _AllTransactions;
      } else {
        if (checkAndHandleSessionExpiry(response.statusCode, response.body)) {
          return _AllTransactions;
        }
        throw Exception('Failed to load album');
      }
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  void appLog(String message) {
    debugPrint("🟢[MYAPP] $message");
  }

  Future<void> checkNumber(String phoneNumber) async {
    final token = tokenClass.getToken();
    final url = "${ApiUrls.BASE_URL}Wallet_dashboard/chec_knumber";

    final requestBody = {
      "phone": phoneNumber,
    };

    appLog("[CheckNumber] URL: $url");
    appLog(
        "[CheckNumber] Headers: API-KEY: ${tokenClass.key}, Authorization: Bearer $token");
    appLog("[CheckNumber] Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(requestBody),
      );

      appLog("[CheckNumber] Status Code: ${response.statusCode}");
      appLog("[CheckNumber] Response Body: ${response.body}");

      final responseData = json.decode(response.body);

      final status = responseData['status']?.toString().toLowerCase();

      if (status == 'false') {
        appLog(" [CheckNumber] Backend rejected: ${responseData['message']}");
        throw HttpException(responseData['message']);
      }

      if (status == null || status == 'false') {
        throw HttpException('Unexpected response');
      }

      // if (responseData['status'] != "False") {
      //   debugPrint(" [CheckNumber] Backend rejected: ${responseData['message']}");
      //   throw HttpException(responseData['message']);
      // }

      appLog("[CheckNumber] Success Response: ${responseData['message']}");
      notifyListeners();
    } catch (error) {
      debugPrint("[CheckNumber] Exception: $error");
      rethrow;
    }
  }

  Future<void> checkNumberRegistration(String phoneNumber) async {
    final token = tokenClass.getToken();
    final url = "${ApiUrls.BASE_URL}Wallet_dashboard/chec_knumber";

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version; // e.g., '1.3.4'

    final requestBody = {
      "phone": phoneNumber,
      'version': currentVersion,
    };

    appLog("[CheckNumber] URL: $url");
    appLog(
        "[CheckNumber] Headers: API-KEY: ${tokenClass.key}, Authorization: Bearer $token");
    appLog("[CheckNumber] Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(requestBody),
      );

      appLog(" [CheckNumber] Status Code: ${response.statusCode}");
      appLog(" [CheckNumber] Response Body: ${response.body}");

      final responseData = json.decode(response.body);
      final status = responseData['status']?.toString().toLowerCase();

      if (status == 'true') {
        appLog(" [CheckNumber] User already registered.");
        throw HttpException('User already registered.');
      } else if (status == 'false') {
        appLog("[CheckNumber] Number not registered, proceeding.");
        return;
      } else {
        throw HttpException('Unexpected response from server.');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> checkEmailRegistration(String email) async {
    final token = tokenClass.getToken();
    final url = "${ApiUrls.BASE_URL.trim()}Wallet_dashboard/chec_email".replaceAll(' ', '');

    final requestBody = {"email": email.trim()};

    appLog("[CheckEmail] URL: $url");
    appLog("[CheckEmail] Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(requestBody),
      );

      appLog("[CheckEmail] Status Code: ${response.statusCode}");
      appLog("[CheckEmail] Response Body: ${response.body}");

      final body = response.body.trim();
      if (body.startsWith('<') || (!body.startsWith('{') && !body.startsWith('['))) {
        throw HttpException('Server temporarily unavailable. Please try again later.');
      }
      final responseData = json.decode(response.body);
      final status = responseData['status']?.toString().toLowerCase();

      if (status == 'true') {
        appLog("[CheckEmail] User already registered.");
        throw HttpException('User already registered.');
      } else if (status == 'false') {
        appLog("[CheckEmail] Email not registered, proceeding.");
        return;
      } else {
        throw HttpException('Unexpected response from server.');
      }
    } on FormatException catch (_) {
      throw HttpException('Server temporarily unavailable. Please try again later.');
    } catch (error) {
      rethrow;
    }
  }

  //changingPassword
  Future<void> ChangePassWord(
    String phoneNumber,
    String oldPassword,
    String newPassword,
  ) async {
// Get the token
    String token = tokenClass.getToken();

    final url = "${ApiUrls.BASE_URL}Wallet_dashboard/change_password";
    try {
      // preparing the fil
      // print("daabac gudaha");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "phone": phoneNumber,
          "old_password": oldPassword,
          "new_password": newPassword,
          // "phone":"+252615837893",
          // "old_password":"9090",
          // "new_password":"9191",
        }),
      );
      final responseData = json.decode(response.body);
      // print(responseData);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']);
      }
      var message = jsonDecode(response.body);
      // print("Message");
      // print(message);
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  //forgetpassword
  Future<void> ForgetPassWord(
    String phoneNumber,
    String newPassword,
  ) async {
// Get the token
    String token = tokenClass.getToken();

    final url = "${ApiUrls.BASE_URL}Wallet_dashboard/forget_password";
    try {
      // preparing the fil
      // print("daabac gudaha");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "phone": phoneNumber,
          "new_password": newPassword,
          // "phone":"+252615837893",
          // "new_password":"9191",
        }),
      );
      final responseData = json.decode(response.body);
      // print(responseData);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']);
      }
      var message = jsonDecode(response.body);
      // print("Message");
      // print(message);
      notifyListeners();
    } catch (error) {
      // print(error);
      rethrow;
    }
  }

  Future<void> ForgetPIN(String phoneNumber, String newPin) async {
    String token = tokenClass.getToken();
    final url = "${ApiUrls.BASE_URL}Wallet_dashboard/forget_pin";

    appLog(" [ForgetPIN] URL: $url");
    appLog(" [ForgetPIN] Headers: API-KEY=${tokenClass.key}, Bearer=$token");
    appLog(" [ForgetPIN] Payload: phone=$phoneNumber, new_pin=$newPin");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "phone": phoneNumber,
          "new_pin": newPin,
        }),
      );

      appLog(" [ForgetPIN] Response Code: ${response.statusCode}");
      appLog(" [ForgetPIN] Response Body: ${response.body}");

      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        appLog(" [ForgetPIN] Error in response: ${responseData['error']}");
        throw HttpException(responseData['error']);
      }

      appLog("[ForgetPIN] PIN reset successful");
      notifyListeners();
    } catch (error) {
      appLog("[ForgetPIN] Exception occurred: $error");
      rethrow;
    }
  }

  //changingPIN
  Future<void> ChangePIN(
    String phoneNumber,
    String oldPin,
    String newPin,
  ) async {
    // print('phoneNumber');
    // print(phoneNumber);

    // Get the token
    String token = tokenClass.getToken();

    final url = "${ApiUrls.BASE_URL}Wallet_dashboard/change_pin";

    appLog(" [ChangePIN] URL: $url");
    appLog(" [ChangePIN] Phone: $phoneNumber");
    appLog(" [ChangePIN] Old PIN: $oldPin → New PIN: $newPin");
    appLog(" [ChangePIN] Headers: API-KEY=${tokenClass.key}, Bearer=$token");

    try {
      // preparing the fil
      // print("daabac gudaha");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "phone": phoneNumber,
          "old_pin": oldPin,
          "new_pin": newPin,
        }),
      );

      appLog(" [ChangePIN] Response Code: ${response.statusCode}");
      appLog(" [ChangePIN] Response Body: ${response.body}");

      final responseData = json.decode(response.body);
      // print(responseData);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']);
        // print(responseData);
        // throw (responseData['message']);
      }
      var message = jsonDecode(response.body);
      // print("Message");
      // print(message);

      appLog("[ChangePIN] PIN successfully changed.");

      notifyListeners();
    } catch (error) {
      // print(error);
      rethrow;
    }
  }

  //LoginPIN
  Future<void> LoginPIN(
    String phoneNumber,
    String PIN,
  ) async {
    // print('phoneNumber');
    // print(phoneNumber);

    // Get the token
    String token = tokenClass.getToken();

    final url = "${ApiUrls.BASE_URL}Wallet_login/login_pin";
    try {
      // preparing the fil
      // print("daabac gudaha");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "phone": phoneNumber,
          "pin": PIN,
        }),
      );
      final responseData = json.decode(response.body);
      // print(responseData);
      if (responseData['error'] != null) {
        throw (responseData['message']);
      }
      var message = jsonDecode(response.body);
      // print("Message");
      // print(message);
      notifyListeners();
    } catch (error) {
      // print(error);
      rethrow;
    }
  }

  // 6/1/24

  Stream<List<BalanceDisplayModel>> fetchAndDisplayBalance(
      String accountNo) async* {
// Get the token
    String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_dashboard/fill_Account_balances";
    while (true) {
      try {
        final response = await http.post(Uri.parse(url),
            body: json.encode({"account_no": accountNo}),
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              "API-KEY": tokenClass.key,
              "Authorization": "Bearer $token",
            });
        if (checkAndHandleSessionExpiry(response.statusCode, response.body)) continue;
        if (response.statusCode == 200) {
          final List<BalanceDisplayModel> loadedAllDisplayBalancetoList = [];
          final extractedData = json.decode(response.body);
          for (int i = 0; i < extractedData['result'].length; i++) {
            loadedAllDisplayBalancetoList
                .add(BalanceDisplayModel.fromMap(extractedData['result'][i]));
          }
          yield loadedAllDisplayBalancetoList;
        } else {
          checkAndHandleSessionExpiry(response.statusCode, response.body);
          throw Exception('Failed to load balance');
        }
      } catch (error) {
        rethrow;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  //ends here

  //29/05/2024

  Future<BalanceDisplayModel> fetchUserData(String accountNo) async {
// Get the token
    String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_dashboard/fill_Account_balances";
    try {
      final response = await http.post(Uri.parse(url),
          body: json.encode({"account_no": accountNo}),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
          });
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) throw Exception('Session expired');
      if (response.statusCode == 200) {
        final extractedData = json.decode(response.body);

        if (extractedData['result'] != null &&
            extractedData['result'].isNotEmpty) {
          return BalanceDisplayModel.fromMap(extractedData['result'][0]);
        } else {
          throw Exception('No data found');
        }
      } else {
        checkAndHandleSessionExpiry(response.statusCode, response.body);
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      rethrow;
    }
  }
}
