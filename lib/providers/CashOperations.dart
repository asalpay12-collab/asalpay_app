import 'dart:convert';
import 'package:asalpay/services/tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../services/api_urls.dart';
class CountryMoDelFill with ChangeNotifier {
  final String id;
  final String name;
  final String image;

  CountryMoDelFill({
    required this.id,
    required this.name,
    required this.image,
  });
}

class WalletBankTransfer with ChangeNotifier {
  final String? country_id;
  final String? wallet_accounts_id_fro;
  final String? bank_name;
  final String? acc_holder_name;
  final String? amt_accounts_no;
  final String? acc_holder_phone;
  final String? currency_id_fro;
  final String? amount_fro;
  final String? currency_id_to;
  final String? partiner_id;
  final String? total_payin; //

  WalletBankTransfer({
    this.country_id,
    this.wallet_accounts_id_fro,
    this.bank_name,
    this.acc_holder_name,
    this.amt_accounts_no,
    this.acc_holder_phone,
    this.currency_id_fro,
    this.amount_fro,
    this.currency_id_to,
    this.partiner_id,
    this.total_payin,
  });
}

//send RealTime
class SaveReallyTimeData with ChangeNotifier {
  // final String? country_id;
  final String wallet_accounts_id_fro; 
  final String beneficiary_name; 
  final String remit_channel; 
  final String description; 
  final String currency_id_fro; 
  final String amount_from; 
  final String currency_to_id; 
  final String partiner_id; 
  final String reciveAmount; 
  final String receiverNumber; 
  final String? accountNumber; 
  final String? totalpayin; 

    // final String partiner_tag; 


SaveReallyTimeData({

  
    // this.country_id,
    required this.wallet_accounts_id_fro,
    required this.beneficiary_name,
    required this.remit_channel,
    required this.description,
    required this.currency_id_fro,
    required this.amount_from,
    required this.currency_to_id,
    required this.partiner_id,
    required this.reciveAmount,
    required this.receiverNumber,
    this.accountNumber,
    this.totalpayin,

    // required this.partiner_tag,
  });

SaveReallyTimeData copyWith({
    String? walletAccountsIdFro,
    String? beneficiaryName,
    String? remitChannel, 
    String? description,
    String? currencyIdFro,
    String? amountFrom,
    String? currencyToId,
    String? partnerId, 
    String? reciveAmount,
    String? receiverNumber,
    String? accountNumber,
    String? totalpayin,
  }) {
    return SaveReallyTimeData(
      wallet_accounts_id_fro: walletAccountsIdFro ?? wallet_accounts_id_fro,
      beneficiary_name: beneficiaryName ?? beneficiary_name,
      remit_channel: remitChannel ?? remit_channel,
      description: description ?? this.description,
      currency_id_fro: currencyIdFro ?? currency_id_fro,
      amount_from: amountFrom ?? amount_from,
      currency_to_id: currencyToId ?? currency_to_id,
      partiner_id: partnerId ?? partiner_id,
      reciveAmount: reciveAmount ?? this.reciveAmount,
      receiverNumber: receiverNumber ?? this.receiverNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      totalpayin: totalpayin ?? this.totalpayin,

      // partiner_tag: partnerId ?? this.partiner_id,
    );
  }
}

//send cashcolect
class SaveCashCollect with ChangeNotifier {
  final String? country_id;
  final String? city_id_to;
  final String? branch_to;
  final String? currency_fro_id;
  final String? amount_from;
  final String? currency_to_id;
  final String? net_payble_amount;
  final String? remittance_comission;
  final String? remittance_rate;
  final String? benificary_name;
  final String? beneficiary_phone;
  final String? account_no;

  SaveCashCollect({
    this.country_id,
    this.city_id_to,
    this.branch_to,
    this.currency_fro_id,
    this.amount_from,
    this.currency_to_id,
    this.net_payble_amount,
    this.remittance_comission,
    this.remittance_rate,
    this.benificary_name,
    this.beneficiary_phone,
    this.account_no,
  });
}

class ChannelTypesModel with ChangeNotifier {
  final String channel_type_id;
  final String type_name;
  final String tag;
  final String country_id;

  ChannelTypesModel({
    required this.channel_type_id,
    required this.type_name,
    required this.tag,
    required this.country_id,
  });
}

class RemitChannelTypeModel with ChangeNotifier {
  final String channel_type_id;
  final String type_name;
  final String tag;
  final String country_id;
  final String remittance_channel_no;
  final String partiner_id;
  final String? partiner_tag;

  RemitChannelTypeModel({
    required this.channel_type_id,
    required this.type_name,
    required this.tag,
    required this.country_id,
    required this.remittance_channel_no,
    required this.partiner_id,
     this.partiner_tag,
  });
}

class CashOperations with ChangeNotifier {


Map<String, dynamic> prepareBasicData(
      String country, String walletAccountsId, String type) {
    return {
      "country_id": country,
      "wallet_accounts_id": walletAccountsId,
      "type": type,
    };
  }


    // Create an instance of TokenClass
  TokenClass tokenClass = TokenClass();


  List<CountryMoDelFill> _countryfill = [];
  List<CountryMoDelFill> get countryfill {
    return [..._countryfill];
  }

  List<ChannelTypesModel> _FillChannelTypes = [];
  List<ChannelTypesModel> get FillChannelTypes {
    return [..._FillChannelTypes];
  }

  List<RemitChannelTypeModel> _FillRemitChannelTypes = [];
  List<RemitChannelTypeModel> get FillRemitChannelTypes {
    return [..._FillRemitChannelTypes];
  }

  RemitChannelTypeModel findById(String id) {
    return _FillRemitChannelTypes.firstWhere(
        (info) => info.remittance_channel_no == id);
  }

  Future<List<CountryMoDelFill>> fetchAndSetCountryFill() async {

    
// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");

  
    var url = "${ApiUrls.BASE_URL}Walletremit/get_remit_countries";
    try {
      final response = await http.get(Uri.parse(url), headers: {
       
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        final List<CountryMoDelFill> loadedcountryfill = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedcountryfill.add(
            CountryMoDelFill(
              id: extractedData['result'][i]['country_id'],
              name: extractedData['result'][i]['country_name'],
              image: extractedData['result'][i]['country_img'],
            ),
          );
        }
        _countryfill = loadedcountryfill.toList();
        return _countryfill;
      } else {
       
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  Future<List<ChannelTypesModel>> fetchAndSetFillChannelTypes(
      String countryId) async {

    
// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");


    var url = "${ApiUrls.BASE_URL}Walletremit/channel_types";
    try {
      final response = await http.post(Uri.parse(url),
          headers: {
            
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
          },
          body: json.encode({"country_id": countryId}));
      if (response.statusCode == 200) {
        final List<ChannelTypesModel> loadedFillChannelTypes = [];
        final extractedData = json.decode(response.body);
        print(extractedData);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedFillChannelTypes.add(
            ChannelTypesModel(
              channel_type_id: extractedData['result'][i]['channel_type_id'],
              type_name: extractedData['result'][i]['type_name'],
              tag: extractedData['result'][i]['tag'],
              country_id: extractedData['result'][i]['country_id'],
            ),
          );
        }
        _FillChannelTypes = loadedFillChannelTypes.toList();
        return _FillChannelTypes;
      } else {
        
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  Future getAsalExchange(
    String countryId,
    String currencyIdFro,
    String amountFrom,
    String partinerId,
  ) async {


// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");

    final url = "${ApiUrls.BASE_URL}Walletremit/asal_currency_converter";
    try {
      print("country_id");
      print(countryId);
      print("currency_id_fro");
      print(currencyIdFro);
      print(amountFrom);
      final response = await http.post(
        Uri.parse(url),
        headers: {
          
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
        },
        body: json.encode({
          "country_id": countryId,
          "currency_id_fro": currencyIdFro,
           "amount_from": amountFrom,
          "wallet_partner_id": partinerId

          // "country_id": "13",
          // "currency_id_fro": "3",
          // "amount_from": "100"
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


  /// shift_currency_converet
  Future getShiftCurrencyConveret(
      String countryId,
      String currencyIdFro,
      String amountFrom,
      String remitChannel,
      String partinerId,

      ) async {


// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");

    final url = "${ApiUrls.BASE_URL}/Walletremit/shift_currency_converet";
    try {
      print("country_id");
      print(countryId);
      print("currency_id_fro");
      print(currencyIdFro);
      print("Amount from");
      print(amountFrom);

      print("Chanel");
      print(remitChannel);
      final response = await http.post(
        Uri.parse(url),
        headers: {
          
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
        },
        body: json.encode({
          "amount_from": amountFrom,
          "currency_id_fro":currencyIdFro,
          "remit_channel":remitChannel,
          "country_id":countryId,
          "wallet_partner_id":partinerId,

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



  Future getOnafriqCurrencyConveret(
  String countryId,
  String currencyIdFro,
  String amountFrom,
  String remitChannel,
  String partnerId,
) async {


// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");

  final url = "${ApiUrls.BASE_URL}/Onafriq_controller/fetchRateonafriq";
  try {
    print("country_id: $countryId");
    print("currency_id_fro: $currencyIdFro");
    print("amount_from: $amountFrom");
    print("remit_channel: $remitChannel");
    print("partner_id: $partnerId");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "wallet_accounts_id_fro": countryId,
        "amount_from": amountFrom,
        "currency_id_fro": currencyIdFro,
        "currency_to_id": remitChannel,
        "country_id": int.parse(countryId),
        "wallet_partner_id": partnerId,
      }),
    );

    var message = jsonDecode(response.body);
    print(message);
    return message; 

   
    notifyListeners();
  } catch (error) {
    print(error);
    rethrow;
  }
}


//cashcolectexchange
  Future CashCollectExchange(
    String countryId,
    String currencyFroId,
    String amountFrom,
  ) async {


// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");

    final url = "${ApiUrls.BASE_URL}Walletremit/get_cash_collect_com";
    try {
      print("Inside Function");
      print(countryId);
      print(currencyFroId);
      print(amountFrom);
      final response = await http.post(
        Uri.parse(url),
        headers: {
          
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
        },
        body: json.encode({
          "country_id": countryId,
          "currency_fro_id": currencyFroId,
          "amount_from": amountFrom,

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



  Future<void> addSaveCashCollect(
      SaveCashCollect saveCashCollect, String walletAccountsIdFro
      // Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? imga,File? doc,
      ) async {


// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");

    print("daabac SaveCashCollect");
    final url = "${ApiUrls.BASE_URL}Walletremit/send_by_cash_collect";
    try {
      
      print("daabac SaveReallyTimeData");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
        },
        body: json.encode({

          "country_id": saveCashCollect.country_id,
          "city_id_to": saveCashCollect.city_id_to,
          "branch_to": saveCashCollect.branch_to,
          "currency_fro_id": saveCashCollect.currency_fro_id,
          "amount_from": saveCashCollect.amount_from,
          "currency_to_id": saveCashCollect.currency_to_id,
          "net_payble_amount": saveCashCollect.net_payble_amount,
          "remittance_comission": saveCashCollect.remittance_comission,
          "remittance_rate": saveCashCollect.remittance_rate,
          "benificary_name": saveCashCollect.benificary_name,
          "beneficiary_phone": saveCashCollect.beneficiary_phone,
          "account_no":walletAccountsIdFro

        }),
      );

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

//remit channel types;
  Future<List<RemitChannelTypeModel>> fetchAndSetRemitChannelTypes(
      String countryId, String tag) async {


// Get the token
  String token = tokenClass.getToken();
  // Print the token
  print("Token: $token");
  
    var url = "${ApiUrls.BASE_URL}Walletremit/remit_channels";
    try {
      final response = await http.post(Uri.parse(url),
          headers: {
            
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          "API-KEY": tokenClass.key,
          "Authorization": "Bearer $token",
          },
          body: json.encode({
            "country_id": countryId,
            "tag": tag,
          }));
      if (response.statusCode == 200) {
        final List<RemitChannelTypeModel> loadedFillRemitChannelTypes = [];
        final extractedData = json.decode(response.body);
        print(extractedData);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedFillRemitChannelTypes.add(
            RemitChannelTypeModel(
              channel_type_id: extractedData['result'][i]
                  ['remittance_channel_no'],
              type_name: extractedData['result'][i]['sub_partiners_name'],
              tag: extractedData['result'][i]['tag'],
              partiner_id: extractedData['result'][i]['wallet_partiner_id'],
              country_id: extractedData['result'][i]['country_id'],
              remittance_channel_no: extractedData['result'][i]
                  ['remittance_channel_no'],
              partiner_tag: extractedData['result'][i]
              ['partiner_tag'],
            ),
          );
        }
        _FillRemitChannelTypes = loadedFillRemitChannelTypes.toList();
        return _FillRemitChannelTypes;
      } else {
        
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      rethrow;
    }
  }
}
