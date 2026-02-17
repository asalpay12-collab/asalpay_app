import 'dart:convert';
import 'dart:io';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/utils/session_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../services/api_urls.dart';

//send todo: TopUpRegistration
class SaveTopUpRegistration with ChangeNotifier {
  final String? bank_account_no;
  final String? account_no;
  final String? amount_fro;
  final String? currency_fro_id;
  final String? amount_to;
  final String? currency_to_id;
  final String? reference;
  final String? provider_name;

  SaveTopUpRegistration({
    this.bank_account_no,
    this.account_no,
    this.currency_to_id,
    this.amount_fro,
    this.currency_fro_id,
    this.amount_to,
    this.reference,
    this.provider_name,
  });
}

//send todo: ExchangeRegistration
class SaveExchangeRegistration with ChangeNotifier {
  final String? account_no;
  final String? amount_fro;
  final String? amount_to;
  final String? api_rate;
  final String? com_rate;
  final String? com_value;
  final String? currency_to_id;
  final String? currency_fro_id;

  SaveExchangeRegistration({
    this.account_no,
    this.amount_fro,
    this.amount_to,
    this.api_rate,
    this.com_rate,
    this.com_value,
    this.currency_to_id,
    this.currency_fro_id,
  });
}
//todo:FundMovingRegistration
class SaveFundMovingRegistration with ChangeNotifier {
  final String? current_account_no;
  // final String? account_saving_no;
  final String? balance_type_id_fro;
  final String? balance_type_id_to;
  final String? amount_fro;
  final String? amount_to;
  final String? api_rate;
  final String? com_rate;
  final String? com_value;
  final String? currency_to_id;
  final String? currency_fro_id;

  SaveFundMovingRegistration({
    this.current_account_no,
    // this.account_saving_no,
    this.balance_type_id_fro,
    this.balance_type_id_to,
    this.amount_fro,
    this.amount_to,
    this.api_rate,
    this.com_rate,
    this.com_value,
    this.currency_to_id,
    this.currency_fro_id,
  });
}
//todo:TransferRegisteration
class SaveTransferRegistration with ChangeNotifier {
  final String? account_no_from;
  final String? account_no_to;
  final String? phone;
  final String? amount_fro;
  final String? amount_to;
  final String? api_rate;
  final String? com_rate;
  final String? com_value;
  final String? currency_to_id;
  final String? currency_fro_id;

  SaveTransferRegistration({
    this.account_no_from,
    this.account_no_to,
    this.phone,
    this.amount_fro,
    this.amount_to,
    this.api_rate,
    this.com_rate,
    this.com_value,
    this.currency_to_id,
    this.currency_fro_id,
  });
}

class WalletOperationModel with ChangeNotifier {

  TokenClass tokenClass = TokenClass();
  
  final String? wallet_accounts_id;
  final String? f_name;
  final String? m_name;
  final String? typeName;
  final String? typeID;
  final String? balance;
 
  final String? currency_id;
  final String? currency_name;
  

  WalletOperationModel({
    this.wallet_accounts_id,
    this.f_name,
    this.m_name,
    this.typeName,
    this.typeID,
    this.balance,
  
    this.currency_id,
    this.currency_name,
   
  });
}


//todo:merchant Registeration;
class MerchantRegisteration with ChangeNotifier{
  final String? account_no_from;
  final String? merchant_account_no;
  final String? currency_fro_id;
  final String? amount_fro;
  final String? currency_to_id;
  final String? amount_to;
  final String? balance_type_id;

  MerchantRegisteration({
    this.account_no_from,
    this.merchant_account_no,
    this.currency_fro_id,
    this.amount_fro,
    this.currency_to_id,
    this.amount_to,
    this.balance_type_id,
  });

}

class WalletOperations with ChangeNotifier {


    // Create an instance of TokenClass
  TokenClass tokenClass = TokenClass();


final String? walletid;
final String? token;
  WalletOperations(
      this.walletid,
      this.token,
      );
  List<WalletOperationModel> _CusAccountCurrencyFC = [];
  List<WalletOperationModel> get CusAccountCurrencyFC {
    return [..._CusAccountCurrencyFC];
  }

  List<WalletOperationModel> _CusAccountCurrencyRC = [];
  List<WalletOperationModel> get CusAccountCurrencyRC {
    return [..._CusAccountCurrencyRC];
  }
  

//todo:topupBankaccounts;
  List<WalletOperationModel> _FillTopupAccount = [];
  List<WalletOperationModel> get FillTopupAccount {
    return [..._FillTopupAccount];
  }

//todo:fundMovingfillcustomercurrency
  List<WalletOperationModel> _FundMovingFillCustomerCurrency = [];
  List<WalletOperationModel> get FundMovingFillCustomerCurrency {
    return [..._FundMovingFillCustomerCurrency];
  }

  List<WalletOperationModel> _FillFundMovingAccountSaving = [];
  List<WalletOperationModel> get FillFundMovingAccountSaving {
    return [..._FillFundMovingAccountSaving];
  }

  WalletOperationModel findByIdFC(String id) {
    return _CusAccountCurrencyFC.firstWhere((info) => info.currency_id == id);
  }


  WalletOperationModel findByIdTC(String id) {
    return _CusAccountCurrencyRC.firstWhere((info) => info.currency_id == id);
  }

  WalletOperationModel findByTypeSaving(String id) {
    return _FillFundMovingAccountSaving.firstWhere((info) => info.currency_id == id);
  }
  WalletOperationModel findByTypeCurrent(String id) {
    return _FundMovingFillCustomerCurrency.firstWhere((info) => info.currency_id == id);
  }
//todo:fill merchant_info
  List<WalletOperationModel> _FillmerchantInfo = [];
  List<WalletOperationModel> get FillmerchantInfo {
    return [..._FillmerchantInfo];
  }

  //todo: Merchant_customer_Currency
  List<WalletOperationModel> _MerchantCusAccountCurrency = [];
  List<WalletOperationModel> get MerchantCusAccountCurrency {
    return [..._MerchantCusAccountCurrency];
  }
  //todo:findcurrencyid_of_merchant
  WalletOperationModel findByCurrencyMerchantID(String id) {
    return _FillmerchantInfo.firstWhere((info) => info.currency_id == id);
  }
  //todo:findcurrencyid_of_merchant
  WalletOperationModel findByIdFromMerchantCurrency(String id) {
    return _MerchantCusAccountCurrency.firstWhere((info) => info.currency_id == id);
  }

  //owneraccount;
  Future<List<WalletOperationModel>> fetchAndSetCusAccountCurrencyFC(
      String? accountNo) async {

    
// Get the token
  String token = tokenClass.getToken();

  // Print the token
  print("Token: $token");


    var url = "${ApiUrls.BASE_URL}Wallet_transfer/fill_customer_currency";
    try {

    print("walletid");
    print(walletid);
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'account_no': walletid
              // "account_no":"252614435151"
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
           "API-KEY": tokenClass.key,
          });
     
      print(response.body);
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return _CusAccountCurrencyFC;
      if (response.statusCode == 200) {
        final List<WalletOperationModel> loadedCusAccountCurrencyFT = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedCusAccountCurrencyFT.add(
            WalletOperationModel(
              wallet_accounts_id: extractedData['result'][i]
                  ['wallet_accounts_id'],
              currency_name: extractedData['result'][i]['currency_name'],
              currency_id: extractedData['result'][i]['currency_id'],
              f_name: extractedData['result'][i]['f_name'],
              m_name: extractedData['result'][i]['m_name'],
            ),
          );
        }
        _CusAccountCurrencyFC = loadedCusAccountCurrencyFT.toList();
        return _CusAccountCurrencyFC;
      } else {
        
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_province);
      rethrow;
    }
  }

  //recieveAccount
  Future<List<WalletOperationModel>> fetchAndSetCusAccountCurrencyRC(
      String accountNo) async {
    var url = "${ApiUrls.BASE_URL}Wallet_transfer/fill_receiver_currency";
    try {
      print("outside body");
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'account_no': accountNo
              // "account_no":"252614435151",
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
             "API-KEY": tokenClass.key,
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print("Inside body");

      print(response.body);
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return _CusAccountCurrencyRC;
      if (response.statusCode == 200) {
        final List<WalletOperationModel> loadedCusAccountCurrencyRC = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          // print(extractedData['result'][i]
          // ['wallet_customers_id']);
          loadedCusAccountCurrencyRC.add(
            WalletOperationModel(
              wallet_accounts_id: extractedData['result'][i]
                  ['wallet_accounts_id'],
              currency_id: extractedData['result'][i]['currency_id'],
              currency_name: extractedData['result'][i]['currency_name'],
              f_name: extractedData['result'][i]['f_name'],
              m_name: extractedData['result'][i]['m_name'],
            ),
          );
        }
        _CusAccountCurrencyRC = loadedCusAccountCurrencyRC.toList();
        return _CusAccountCurrencyRC;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      print("_CusAccountCurrencyRC");
      // print(_CusAccountCurrencyRC);
      rethrow;
    }
  }

  //cashcolectexchange
  Future TransferExchange(
    String amountFro,
    String currencyNameTo,
    String currencyNameFro,
    String currencyToId,
    String currencyFroId,
  ) async {
    final url = "${ApiUrls.BASE_URL}Wallet_transfer/get_exchange";
    try {
      print("Inside Function");
      print(amountFro);
      print(currencyNameTo);
      print(currencyNameFro);
      print(currencyFroId);
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          // "API-KEY": "ASAL-0014480cb3f2eed05b6c2a4",
          "API-KEY": tokenClass.key,
        },
        body: json.encode({
          "amount_fro": amountFro,
          "currency_name_to": currencyNameTo,
          "currency_name_fro": currencyNameFro,
          "currency_to_id": currencyToId,
          "currency_fro_id": currencyFroId,

         
        }),
      );
      var message = jsonDecode(response.body);
      print(message);
      // print(selectedValue);
      return message;

      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  //TopupBanksAccounts
  Future<List<WalletOperationModel>> fetchAndSetTopUpBankAccounts() async {
    var url = "${ApiUrls.BASE_URL}Wallet_top_up/fill_bank_accounts";
    try {

      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
         "API-KEY": tokenClass.key,
      });
      
      print(response.body);
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return [];
      if (response.statusCode == 200) {
        final List<WalletOperationModel> loadedFillTopupAccount = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedFillTopupAccount.add(
            WalletOperationModel(
              wallet_accounts_id: extractedData['result'][i]['id'],
              currency_name: extractedData['result'][i]['acc_name'],
              currency_id: extractedData['result'][i]['account_id'],
              f_name: extractedData['result'][i]['acc_des'],
              m_name: extractedData['result'][i]['acc_set'],
            ),
          );
        }
        _FillTopupAccount = loadedFillTopupAccount.toList();
        return _FillTopupAccount;
      } else {
       
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_province);
      rethrow;
    }
  }

  //savetopupbanksdata
  //todo:saving TopUpData
  Future<void> addSaveTopUpRegistration(
      SaveTopUpRegistration saveTopUpRegistration, String walletAccountsIdFro
      // Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? imga,File? doc,
      ) async {
    print("daabac SaveTopUpRegistration");
    final url = "${ApiUrls.BASE_URL}Wallet_top_up/top_up_registration";
    try {
      // preparing the fil
      print("daabac SaveReallyTimeData");

      final response = await http.post(
        Uri.parse(url),
        headers: {
           'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            // "API-KEY": "ASAL-0014480cb3f2eed05b6c2a4",
            "API-KEY": tokenClass.key,
        },
        body: json.encode({
          "bank_account_no": saveTopUpRegistration.bank_account_no,
          "amount_fro": saveTopUpRegistration.amount_fro,
          "currency_fro_id": saveTopUpRegistration.currency_fro_id,
          "amount_to": saveTopUpRegistration.amount_to,
          "currency_to_id": saveTopUpRegistration.currency_to_id,
          "reference": saveTopUpRegistration.reference,
          "provider_name": saveTopUpRegistration.provider_name,
          "account_no": walletid,
        }),
      );

      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return;
      final responseData = json.decode(response.body);
      if (responseData['status']!= "True") {
        // throw HttpException(responseData['messages']);
        throw (responseData['messages']);
      }
      var message = jsonDecode(response.body);
      // print("daabac image");
      print(message);
    
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  //FundMovingFillCustomerCurrency;
  Future<List<WalletOperationModel>> fetchAndSetFillFundMovingCustomerCurrency(
      String currentAccountNo, String balanceTypeIdFro) async {
    var url =
        "${ApiUrls.BASE_URL}Wallet_funds_moving/fill_customer_current_currency";
    try {
      print("account_saving_no Saving");
      print(currentAccountNo);
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'current_account_no': currentAccountNo,
              "balance_type_id_fro": balanceTypeIdFro,
              // "current_account_no": "252615837893",
              // "balance_type_id_fro": "1"
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
             "API-KEY": tokenClass.key,
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return [];
      if (response.statusCode == 200) {
        final List<WalletOperationModel> loadedFundMovingFillCustomerCurrency =
            [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedFundMovingFillCustomerCurrency.add(
            WalletOperationModel(
              currency_name: extractedData['result'][i]['currency_name'],
              currency_id: extractedData['result'][i]['currency_id'],
              f_name: extractedData['result'][i]['f_name'],
              m_name: extractedData['result'][i]['m_name'],
              typeName: extractedData['result'][i]['balance_type_name'],
              typeID: extractedData['result'][i]['balance_type_id'],
              balance: extractedData['result'][i]['balance'],
            ),
          );
        }
        _FundMovingFillCustomerCurrency =
            loadedFundMovingFillCustomerCurrency.toList();
        return _FundMovingFillCustomerCurrency;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_province);
      rethrow;
    }
  }

  //FillFundMoving AccountSaving;
  Future<List<WalletOperationModel>> fetchAndSetFillFundMovingAccountSaving(
      String accountSavingNo, String balanceTypeIdFro) async {
    var url =
        "${ApiUrls.BASE_URL}Wallet_funds_moving/fill_customer_saving_currency";
    try {
      print("account_saving_no Saving");
      print(accountSavingNo);
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {

              'account_saving_no': accountSavingNo,
              "balance_type_id_fro": balanceTypeIdFro,
              // "account_saving_no": "252615837893"
              // "balance_type_id_fro": "1"
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
             "API-KEY": tokenClass.key,
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return [];
      if (response.statusCode == 200) {
        final List<WalletOperationModel>
            loadedFundMovingFillFundMovingAccountSaving = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedFundMovingFillFundMovingAccountSaving.add(
            WalletOperationModel(
              currency_name: extractedData['result'][i]['currency_name'],
              currency_id: extractedData['result'][i]['currency_id'],
              typeName: extractedData['result'][i]['balance_type_name'],
              typeID: extractedData['result'][i]['balance_type_id'],
              balance: extractedData['result'][i]['balance'],
            ),
          );
        }
        _FillFundMovingAccountSaving =
            loadedFundMovingFillFundMovingAccountSaving.toList();
        return _FillFundMovingAccountSaving;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_province);
      rethrow;
    }
  }
  //todo: FundMovingRegistration;
  Future<void> addSaveFundMovingRegistration(
      SaveFundMovingRegistration saveFundMovingRegistration,
      String walletAccountsIdFro
      // Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? imga,File? doc,
      ) async {
    print("daabac banaanka FundMovingRegistration");
    final url = "${ApiUrls.BASE_URL}Wallet_funds_moving/fund_moving_registration";
    try {
      // preparing the fil
      print("daabac gudaha FundMovingRegistration");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          // "API-KEY": "ASAL-0014480cb3f2eed05b6c2a4",
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "current_account_no":walletAccountsIdFro,
          "account_saving_no":walletAccountsIdFro,
          "balance_type_id_fro":saveFundMovingRegistration.balance_type_id_fro,
          "balance_type_id_to":saveFundMovingRegistration.balance_type_id_to,
          "amount_fro": saveFundMovingRegistration.amount_fro,
          "amount_to": saveFundMovingRegistration.amount_to,
          "api_rate": saveFundMovingRegistration.api_rate,
          "com_rate": saveFundMovingRegistration.com_rate,
          "com_value": saveFundMovingRegistration.com_value,
          "currency_to_id": saveFundMovingRegistration.currency_to_id,
          "currency_fro_id": saveFundMovingRegistration.currency_fro_id,
        }),
      );
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return;
      final responseData = json.decode(response.body);
      if (responseData['status'] != "True") {
        // throw HttpException(responseData['messages']);
        throw (responseData['messages']);
      }
      var message = jsonDecode(response.body);
      // print("daabac image");
      print(message);
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }
  //todo:saving TransferRegisteration
  Future<void> addSaveTransferRegisteration(
      SaveTransferRegistration saveTransferRegistration,
      String walletAccountsIdFro
      // Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? imga,File? doc,
      ) async {

        String token = tokenClass.getToken();

    print("daabac banaanka TransferRegisteration");
    // final url = "${ApiUrls.BASE_URL}Wallet_transfer/transfer_registration";
    final url = "${ApiUrls.BASE_URL}Wallet_transfer/transfer_Process";
    try {
      // preparing the fil
      print("daabac gudaha TransferRegisteration");

      final response = await http.post(
        Uri.parse(url),
        headers: {
           "API-KEY": tokenClass.key,
           "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "account_no_from": walletAccountsIdFro,// c
          "account_no_to": saveTransferRegistration.account_no_to,//C
          "phone": saveTransferRegistration.phone,//C
          "amount_fro": saveTransferRegistration.amount_fro,
          "amount_to": saveTransferRegistration.amount_to,
          "api_rate": saveTransferRegistration.api_rate,
          "com_rate": saveTransferRegistration.com_rate,
          "com_value": saveTransferRegistration.com_value,
          "currency_to_id": saveTransferRegistration.currency_to_id,
          "currency_fro_id": saveTransferRegistration.currency_fro_id,
        }),
      );
      final responseData = json.decode(response.body);
      print("daabac responsega");
      print(responseData);
      if (responseData['status'] != "True") {
        // throw HttpException(responseData['messages']);
        throw (responseData['messages']);
      }
      var message = jsonDecode(response.body);
      print(message);
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }
  //todo:saving ExchangeData
  Future<void> addSaveExchangeRegistration(
      SaveExchangeRegistration saveExchangeRegistration,
      String walletAccountsIdFro
      // Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? imga,File? doc,
      ) async {
    print("daabac banaanka SavingExchangeRegistration");
    final url = "${ApiUrls.BASE_URL}Wallet_exchange/exchange_registration";
    try {
      // preparing the fil
      print("daabac gudaha SavingExchangeRegistration");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          // "API-KEY": "ASAL-0014480cb3f2eed05b6c2a4",
          "API-KEY": tokenClass.key,
        },
        body: json.encode({
          "account_no": walletAccountsIdFro,//C
          "amount_fro": saveExchangeRegistration.amount_fro,
          "amount_to": saveExchangeRegistration.amount_to,
          "api_rate": saveExchangeRegistration.api_rate,
          "com_rate": saveExchangeRegistration.com_rate,
          "com_value": saveExchangeRegistration.com_value,
          "currency_to_id": saveExchangeRegistration.currency_to_id,
          "currency_fro_id": saveExchangeRegistration.currency_fro_id,

        }),
      );
      final responseData = json.decode(response.body);
      if (responseData['status'] != true) {
        // throw HttpException(responseData['messages']);
        throw (responseData['messages']);
      }
      var message = jsonDecode(response.body);
      print(message);
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  //todo:saving merchant
  Future<void> addSavemerchantRegistration(
      MerchantRegisteration merchantRegisteration, String walletAccountsIdFro
      // Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? imga,File? doc,
      ) async {
    print(walletAccountsIdFro);
    print("daabac addSavemerchantRegistration");
    final url = "${ApiUrls.BASE_URL}Wallet_merchant_transfer/merchant_transfer_registration";
    try {
      // preparing the fil
      print("daabac merchant");

      final response = await http.post(
        Uri.parse(url),
        headers: {
           'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            // "API-KEY": "ASAL-0014480cb3f2eed05b6c2a4",
            "API-KEY": tokenClass.key,
        },
        body: json.encode({
          "account_no_from": walletAccountsIdFro,
          "merchant_account_no": merchantRegisteration.merchant_account_no,
          "currency_fro_id": merchantRegisteration.currency_fro_id,
          "amount_fro": merchantRegisteration.amount_fro,
          "currency_to_id":merchantRegisteration.currency_to_id,
          "amount_to": merchantRegisteration.amount_to,
          "balance_type_id": merchantRegisteration.balance_type_id,

        }),
      );

      final responseData = json.decode(response.body);
      if (responseData['status']!= "True") {
        // throw HttpException(responseData['messages']);
        throw (responseData['messages']);
      }
      var message = jsonDecode(response.body);
      // print("daabac image");
      print(message);
      // print("daabac image");
      // print(basedoc);
      // print(role_id);
      // print(selectedValue);
      // return baseimage;
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }


  //todo:MerchantExchange
  Future MerchantExchange(
      String amountFro,
      // String currency_name_to,
      // String currency_name_fro,
      String currencyToId,
      String currencyFroId,
      ) async {
    final url = "${ApiUrls.BASE_URL}Wallet_merchant_transfer/get_exchange";
    try {
      print("Inside Function");
      print(amountFro);
      // print(currency_name_to);
      // print(currency_name_fro);
      print(currencyFroId);
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
           "API-KEY": tokenClass.key,
        },
        body: json.encode({
          "amount_fro": amountFro,
          // // "currency_name_to": currency_name_to,
          // // "currency_name_fro": currency_name_fro,
          "currency_to_id": currencyToId,
          "currency_fro_id": currencyFroId,

        }),
      );
      var message = jsonDecode(response.body);
      print(message);
      // print(selectedValue);
      return message;

      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }


  //todo: fillMerchantinfo;
  Future<List<WalletOperationModel>> fetchAndSetfillmerchantinfo(
      String merchantAccountNo) async {
    var url = "${ApiUrls.BASE_URL}Wallet_merchant_transfer/fill_merchant_info";
    try {
      print("merchant_account_no");
      print(merchantAccountNo);
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              "merchant_account_no": merchantAccountNo,
              // "merchant_account_no": "232425",
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
             "API-KEY": tokenClass.key,
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return [];
      if (response.statusCode == 200) {
        final List<WalletOperationModel> FillmerchantInfo = [];
        final extractedData = json.decode(response.body);
        if (extractedData['status'] == "False") {
          throw HttpException(extractedData['message']);
          print(extractedData);
          throw (extractedData['message']);
        }
        for (int i = 0; i < extractedData['result'].length; i++) {
          FillmerchantInfo.add(
            WalletOperationModel(
              currency_name: extractedData['result'][i]['currency_name'],
              currency_id: extractedData['result'][i]['currency_id'],
              f_name: extractedData['result'][i]['merchant_name'],
            ),
          );
        }
        _FillmerchantInfo = FillmerchantInfo.toList();
        return _FillmerchantInfo;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_province);
      rethrow;
    }
  }
  //TODO:_MerchantCusAccountCurrency
  Future<List<WalletOperationModel>> fetchAndSetMerchantCusAccountCurrency(
      String? accountNo) async {
    var url = "${ApiUrls.BASE_URL}Wallet_merchant_transfer/fill_customer_currency";
    try {
      print("walletid");
      print(walletid);
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'account_no': walletid
              // "account_no":"252614435151"
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (checkAndHandleSessionExpiry(response.statusCode, response.body)) return [];
      if (response.statusCode == 200) {
        final List<WalletOperationModel> loadedMerchangtCusAccountCurrencyFT = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedMerchangtCusAccountCurrencyFT.add(
            WalletOperationModel(
              wallet_accounts_id: extractedData['result'][i]['wallet_accounts_id'],
              currency_name: extractedData['result'][i]['currency_name'],
              currency_id: extractedData['result'][i]['currency_id'],
              f_name: extractedData['result'][i]['f_name'],
              m_name: extractedData['result'][i]['m_name'],
            ),
          );
        }
        _MerchantCusAccountCurrency = loadedMerchangtCusAccountCurrencyFT.toList();
        return _MerchantCusAccountCurrency;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_province);
      rethrow;
    }
  }
}




