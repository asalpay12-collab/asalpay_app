import 'dart:convert';
import 'package:asalpay/models/http_exception.dart';
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
  final String? totalpayin; //


  final String? purpose_id;
  final String? source_id;


  final String? sourceOfFunds;
  final String? purposeOfTransfer;
  final String? remit_channel;

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
    this.totalpayin,


    this.source_id,
    this.purpose_id,
    this.sourceOfFunds,
    this.purposeOfTransfer, 
    this.remit_channel,
    // required String remit_channel,

  });
}

//send RealTime
class SaveReallyTimeData with ChangeNotifier {
  // final String? country_id;
  final String wallet_accounts_id_fro; //
  final String beneficiary_name; //
  final String remit_channel; //
  final String description; //
  final String currency_id_fro; //
  final String amount_from; //
  final String currency_to_id; //
  final String partiner_id; //
  final String reciveAmount; //
  final String receiverNumber; //
  final String? accountNumber; //
  final String? totalpayin; //

  final String? purpose_id;
  final String? source_id;


  final String? sourceOfFunds;
  final String? purposeOfTransfer;

    // final String partiner_tag; //


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
    this.source_id,
    this.purpose_id,
    this.sourceOfFunds,
    this.purposeOfTransfer,

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
    String? source_id,
    String? purpose_id,
    String? sourceOfFunds,
    String? purposeOfTransfer,
    
  }) {
    return SaveReallyTimeData(
      wallet_accounts_id_fro: walletAccountsIdFro ?? wallet_accounts_id_fro,
      beneficiary_name: beneficiaryName ?? beneficiary_name,
      remit_channel: remitChannel ?? remit_channel,
      currency_id_fro: currencyIdFro ?? currency_id_fro,
      amount_from: amountFrom ?? amount_from,
      currency_to_id: currencyToId ?? currency_to_id,
      partiner_id: partnerId ?? partiner_id,
      reciveAmount: reciveAmount ?? this.reciveAmount,
      receiverNumber: receiverNumber ?? this.receiverNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      totalpayin: totalpayin ?? this.totalpayin,
      purpose_id: purpose_id ?? this.purpose_id,
      source_id: source_id ?? this.source_id,
      sourceOfFunds: sourceOfFunds ?? this.sourceOfFunds,
      purposeOfTransfer: purposeOfTransfer ?? this.purposeOfTransfer,
      description: (description ?? this.description).isEmpty ? "Mobile Money Transfer" : (description ?? this.description),

      // partiner_tag: partnerId ?? this.partiner_id,
    );
  }
}

  // commented on 6/4

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
  final String? partiner_name;
  final String? sub_partiners_name;

  RemitChannelTypeModel({
    required this.channel_type_id,
    required this.type_name,
    required this.tag,
    required this.country_id,
    required this.remittance_channel_no,
    required this.partiner_id,
    required this.sub_partiners_name,
    this.partiner_tag,
    this.partiner_name
  });

  //get sub_partiners_name => null;

}

class Walletremit with ChangeNotifier {


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
        // If the server did not return a 200 OK response,
        // then throw an exception.
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



        String token = tokenClass.getToken();

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

        String token = tokenClass.getToken();

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

          // "remit_channel":"10",
          // "amount_from":10,
          // "currency_id_fro":"4",
          // "country_id":10
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


  String token = tokenClass.getToken();

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



    String token = tokenClass.getToken();

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



  Future<void> addWalletBankTransfer(
    WalletBankTransfer walletBankTransfer, String walletAccountsIdFro, String? type) async {

  String token = tokenClass.getToken();

  // API URL
  final url = "${ApiUrls.BASE_URL}Walletremit/sendByAgentBankTransfer";

  try {
    print("Sending request to API...");
    print("URL: $url");

    
    final headers = {
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = json.encode({
      
      'country_id': walletBankTransfer.country_id,
      'bank_name': walletBankTransfer.bank_name,
      'acc_holder_name': walletBankTransfer.acc_holder_name,
      'bank_accounts_no': walletBankTransfer.amt_accounts_no,
      'acc_holder_phone': walletBankTransfer.acc_holder_phone,
      'currency_id_fro': walletBankTransfer.currency_id_fro,
      'amount_from': walletBankTransfer.amount_fro,
      'currency_to_id': walletBankTransfer.currency_id_to,
      "wallet_accounts_id_fro": walletAccountsIdFro,
      //'partiner_id': walletBankTransfer.partiner_id,
      'wallet_partiner_id': walletBankTransfer.partiner_id,
      'total_payin': walletBankTransfer.totalpayin,
      'source_id': walletBankTransfer.source_id,
      'sourceOfFunds': walletBankTransfer.sourceOfFunds,
      'purpose_id': walletBankTransfer.purpose_id,
      'purposeOfTransfer': walletBankTransfer.purposeOfTransfer,


      "remit_channel": walletBankTransfer.remit_channel,
      
      
    });

    print("Headers: $headers");
    print("Body: $body");

    // Make the HTTP request
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      print("API Error: Status Code ${response.statusCode}");
      print("API Error Response: ${response.body}");
      throw Exception('Failed to send bank transfer: ${responseData['messages']}');
    }

    if (responseData['status'] != "True") {
      print("API Response Status is not 'True'.");
      throw Exception(responseData['messages']);
    }

    print("API Response Data: $responseData");
    notifyListeners();
  } catch (error) {
    print("Error occurred: $error");
    rethrow;
  }
}


// 15 May, 2025


Future<void> addSaveReallyTimeData(
  String countryId,
  SaveReallyTimeData saveReallyTimeData,
  String walletAccountsIdFro,
  String type,
) async {
  String token = tokenClass.getToken();
  final url = "${ApiUrls.BASE_URL}Walletremit/send_by_direct_bank_transfer";

  // Build request body map
  final requestBody = {
    "beneficiary_name": saveReallyTimeData.beneficiary_name,
    "beneficiary_last_name": saveReallyTimeData.beneficiary_name,
    "amount_from": saveReallyTimeData.amount_from,
    "wallet_accounts_id_fro": walletAccountsIdFro,
    "currency_id_fro": saveReallyTimeData.currency_id_fro,
    "currency_to_id": saveReallyTimeData.currency_to_id,
    "remit_channel": saveReallyTimeData.remit_channel,
    "description": saveReallyTimeData.description ?? "",
    "wallet_partner_id": saveReallyTimeData.partiner_id,
    "receiverNumber": saveReallyTimeData.receiverNumber,
    "reciveAmount": saveReallyTimeData.reciveAmount,
    "accountNumber": saveReallyTimeData.accountNumber,
    "country_id": countryId,
    "total_payin": saveReallyTimeData.totalpayin,
    "type": type,
    "source_id": saveReallyTimeData.source_id,
    "sourceOfFunds": saveReallyTimeData.sourceOfFunds,
    "purpose_id": saveReallyTimeData.purpose_id,
    "purposeOfTransfer": saveReallyTimeData.purposeOfTransfer,
  };

  debugPrint(" Sending SaveReallyTimeData to $url");
  debugPrint("Request Body:\n${jsonEncode(requestBody)}");

  // Basic validation
  final missingKeys = requestBody.entries
      .where((entry) => entry.value == null || entry.value.toString().isEmpty)
      .map((e) => e.key)
      .toList();

  if (missingKeys.isNotEmpty) {
    debugPrint("Missing required fields: $missingKeys");
    throw "Missing required fields: $missingKeys";
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "Authorization": "Bearer $token",
        "API-KEY": tokenClass.key,
      },
      body: jsonEncode(requestBody),
    );

    debugPrint("HTTP Status Code: ${response.statusCode}");

    final responseData = jsonDecode(response.body);
    debugPrint(" Response from server: $responseData");

    if (response.statusCode != 200 || responseData['status'] == "False") {
  final errorMsg = responseData['messages'] ?? 'Unknown error from server.';
  throw HttpException(errorMsg);       
}

    notifyListeners();
    debugPrint(" Data successfully saved.");
  } catch (error) {
    debugPrint(" Error in addSaveReallyTimeData: $error");
    rethrow;
  }
}

  //todo:saving CashCollectData
  Future<void> addSaveCashCollect(
      SaveCashCollect saveCashCollect, String walletAccountsIdFro
      // Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? imga,File? doc,
      ) async {
        
      String token = tokenClass.getToken();

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
          "account_no":walletAccountsIdFro,


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


//remit channel types;
  Future<List<RemitChannelTypeModel>> fetchAndSetRemitChannelTypes(
  String countryId,
  String tag,
  String sourceId,
  String purposeId,
  String sourceOfFunds,
  String purposeOfTransfer,
) async {
  String token = tokenClass.getToken();

  var url = "${ApiUrls.BASE_URL}Walletremit/remit_channels";
  try {
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
        "tag": tag,
        "source_id": sourceId,
        "purpose_id": purposeId,
        "sourceOfFunds": sourceOfFunds,
        "purposeOfTransfer": purposeOfTransfer,
      }),
    );

    if (response.statusCode == 200) {
      final List<RemitChannelTypeModel> loadedFillRemitChannelTypes = [];
      final extractedData = json.decode(response.body);
      print(extractedData);
      for (int i = 0; i < extractedData['result'].length; i++) {
        loadedFillRemitChannelTypes.add(
          RemitChannelTypeModel(
            channel_type_id: extractedData['result'][i]['remittance_channel_no'],
            type_name: extractedData['result'][i]['sub_partiners_name'],
            tag: extractedData['result'][i]['tag'],
            partiner_id: extractedData['result'][i]['wallet_partiner_id'],
            country_id: extractedData['result'][i]['country_id'],
            remittance_channel_no: extractedData['result'][i]['remittance_channel_no'],
            partiner_tag: extractedData['result'][i]['partiner_tag'],
            sub_partiners_name: extractedData['result'][i]['sub_partiners_name'],
            partiner_name: extractedData['result'][i]['partiner_name'] ?? "Unknown Bank",
          ),
        );
      }
      _FillRemitChannelTypes = loadedFillRemitChannelTypes.toList();
      return _FillRemitChannelTypes;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      throw Exception('Failed to load remit channels');
    }
  } catch (error) {
    print(error);
    rethrow;
  }
}

}
