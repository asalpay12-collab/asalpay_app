import 'dart:convert';
import 'package:asalpay/services/tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../services/api_urls.dart';

class DDownModel with ChangeNotifier {
  final String? wallet_accounts_id;
  final String? f_name;
  final String? m_name;
  final String id;
  final String name;
  DDownModel({
    this.wallet_accounts_id,
    this.f_name,
    this.m_name,
    required this.id,
    required this.name,
  });
}

class FillRegisterationDropdown with ChangeNotifier {

  
    // Create an instance of TokenClass
  TokenClass tokenClass = TokenClass();


  List<DDownModel> _documentType= [];
  List<DDownModel> get documentType {
    return [..._documentType];
  }

  List<DDownModel> _country = [];
  List<DDownModel> get country {
    return [..._country];
  }



  List<DDownModel> _province = [];
  List<DDownModel> get province {
    return [..._province];
  }

  List<DDownModel> _city = [];
  List<DDownModel> get city {
    return [..._city];
  }
  List<DDownModel> _walletType = [];
  List<DDownModel> get walletType {
    return [..._walletType];
  }

  List<DDownModel> _currency = [];
  List<DDownModel> get currency {
    return [..._currency];
  }

  List<DDownModel> _CusAccountCurrency = [];
  List<DDownModel> get CusAccountCurrency {
    return [..._CusAccountCurrency];

  }

  //remitcountry;
  List<DDownModel> _RemitCountries = [];
  List<DDownModel> get RemitCountries {
    return [..._RemitCountries];
  }
  //remitcity;
  List<DDownModel> _RemitCity = [];
  List<DDownModel> get RemitCity {
    return [..._RemitCity];
  }

  //remitcity;
  List<DDownModel> _RemitBranches = [];
  List<DDownModel> get RemitBranches {
    return [..._RemitBranches];
  }
  List<DDownModel> _CusAccountCurrencyRC = [];
  List<DDownModel> get CusAccountCurrencyRC {
    return [..._CusAccountCurrencyRC];
  }
  DDownModel findByIdFC(String id) {
    return _CusAccountCurrencyRC.firstWhere((info) => info.id == id);
  }

  DDownModel findByIdTC(String id) {
    return _CusAccountCurrency.firstWhere((info) => info.id == id);
  }



  // fill Country drop down
  Future<List<DDownModel>> fetchAndSetCountry() async {

    
// Get the token
  String token = tokenClass.getToken();

  // Print the token
  print("Token: $token");

    var url = "${ApiUrls.BASE_URL}Wallet_registration/fill_country";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "API-KEY": tokenClass.key,
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final List<DDownModel> loadedcountry = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedcountry.add(
            DDownModel(
              id: extractedData['result'][i]['country_id'],
              name: extractedData['result'][i]['country_name'],
            ),
          );
        }
        _country = loadedcountry.toList();
        return _country;
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

  // fill Province drop down
  Future<List<DDownModel>> fetchAndSetProvince(String CountryId) async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_registration/fill_province";
    try {
//       final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json',
// 'Access-Control-Allow-Origin': '*'});
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'country_id': CountryId,
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (response.statusCode == 200) {
        final List<DDownModel> loadedProvince = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedProvince.add(
            DDownModel(
              id: extractedData['result'][i]['province_id'],
              name: extractedData['result'][i]['province_name'],
            ),
          );
        }
        _province = loadedProvince.toList();
        return _province;
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


  Future<List<DDownModel>> fetchAndSetCusAccountCurrency(String accountNo) async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_transfer/fill_customer_currency";
    try {
//       final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json',
// 'Access-Control-Allow-Origin': '*'});
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'account_no': accountNo,
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (response.statusCode == 200) {
        final List<DDownModel> loadedCusAccountCurrency = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedCusAccountCurrency.add(
            DDownModel(
              wallet_accounts_id: extractedData['result'][i]['wallet_accounts_id'],
              f_name: extractedData['result'][i]['f_name'],
              m_name: extractedData['result'][i]['m_name'],
              id: extractedData['result'][i]['currency_id'],
              name: extractedData['result'][i]['currency_name'],

            ),
          );
        }
        _CusAccountCurrency = loadedCusAccountCurrency.toList();
        return _CusAccountCurrency;
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

  // fill city drop down
  Future<List<DDownModel>> fetchAndSetCity(String ProvinceId) async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_registration/fill_city";
    try {
//       final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json',
// 'Access-Control-Allow-Origin': '*'});
// 'Access-Control-Allow-Origin': '*'});
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'province_id': ProvinceId,
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (response.statusCode == 200) {
        final List<DDownModel> loadedCity = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedCity.add(
            DDownModel(
              id: extractedData['result'][i]['city_id'],
              name: extractedData['result'][i]['city_name'],
            ),
          );
        }
        _city = loadedCity.toList();
        return _city;
      } else {
      
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_city);
      rethrow;
    }
  }

  Future<List<DDownModel>> fetchAndSetWalletType() async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_registration/fill_wallet_type";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "API-KEY": tokenClass.key,
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        final List<DDownModel> loadedWalletType= [];
        final extractedData = json.decode(response.body);
        print(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedWalletType.add(
            DDownModel(
              id: extractedData['result'][i]['wallet_type_id'],
              name: extractedData['result'][i]['wallet_type_name'],
            ),
          );
        }
        _walletType = loadedWalletType.toList();
        return _walletType;
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

  // fill Currency drop down
  Future<List<DDownModel>> fetchAndSetCurrency() async {

    
// Get the token
  String token = tokenClass.getToken();


    var url = "${ApiUrls.BASE_URL}Wallet_registration/fill_currency";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "API-KEY": tokenClass.key,
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final List<DDownModel> loadedCurrency= [];
        final extractedData = json.decode(response.body);
        print(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedCurrency.add(
            DDownModel(
              id: extractedData['result'][i]['currency_id'],
              name: extractedData['result'][i]['currency_name'],
            ),
          );
        }
        _currency = loadedCurrency.toList();
        return _currency;
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

  // fill identificationTye drop down
  Future<List<DDownModel>> fetchAndSetDocumentType() async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_registration/fill_document_type";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "API-KEY": tokenClass.key,
         "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        final List<DDownModel> loadedDocumentType= [];
        final extractedData = json.decode(response.body);
        print(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedDocumentType.add(
            DDownModel(
              id: extractedData['result'][i]['document_type_id'],
              name: extractedData['result'][i]['document_type_name'],
            ),
          );
        }
        _documentType = loadedDocumentType.toList();
        return _documentType;
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

  //country;
  Future<List<DDownModel>> fetchAndSetRemitCountries() async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Walletremit/get_remit_countries";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "API-KEY": tokenClass.key,
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final List<DDownModel> loadedRemitCountries = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedRemitCountries.add(
            DDownModel(
              id: extractedData['result'][i]['country_id'],
              name: extractedData['result'][i]['country_name'],
            ),
          );
        }
        _RemitCountries = loadedRemitCountries.toList();
        return _RemitCountries;
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

  //city
  Future<List<DDownModel>> fetchAndSetRemitCities(String countryId) async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Walletremit/fill_cities";
    try {
//       final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json',
// 'Access-Control-Allow-Origin': '*'});
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'country_id': countryId,
              // 'city_id': CityId,
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
             "Authorization": "Bearer $token",
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (response.statusCode == 200) {
        final List<DDownModel> loadedRemitCity = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedRemitCity.add(
            DDownModel(
              id: extractedData['result'][i]['city_id'],
              name: extractedData['result'][i]['city_name'],
            ),
          );
        }
        _RemitCity = loadedRemitCity.toList();
        return _RemitCity;
      } else {
       
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_city);
      rethrow;
    }
  }

  //branches
  Future<List<DDownModel>> fetchAndSetRemitBranches( String CityId) async {

    
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Walletremit/fill_branches";
    try {
//       final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json',
// 'Access-Control-Allow-Origin': '*'});
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              // 'country_id': "2",
              // 'city_id': "1",
              'city_id': CityId,
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
             "Authorization": "Bearer $token",
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print(response.body);
      if (response.statusCode == 200) {
        final List<DDownModel> loadedRemitBranch = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          loadedRemitBranch.add(
            DDownModel(
              id: extractedData['result'][i]['branch_no'],
              name: extractedData['result'][i]['branch_name'],
            ),
          );
        }
        _RemitBranches = loadedRemitBranch.toList();
        return _RemitBranches;
      } else {
        
        print('Request failed with status: ${response.statusCode}.');
        throw Exception('Failed to load album');
      }
      notifyListeners();
    } catch (error) {
      print(error);
      // print(_city);
      rethrow;
    }
  }
  //recieveAccount
  Future<List<DDownModel>> fetchAndSetCusAccountCurrencyRC(

    
      String accountNo) async {

        
// Get the token
  String token = tokenClass.getToken();

    var url = "${ApiUrls.BASE_URL}Wallet_transfer/fill_receiver_currency";
    try {
      print("outside body");
      final response = await http.post(Uri.parse(url),
          body: json.encode(
            {
              'account_no': accountNo
              // "account_no":"252614435151",
              // "account_no":"252615837893",
            },
          ),
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
             "Authorization": "Bearer $token",
          });
      // final response = await http.get(Uri.parse(url));
      // _province.clear();
      print("Inside body");

      print(response.body);
      if (response.statusCode == 200) {
        final List<DDownModel> loadedCusAccountCurrencyRC = [];
        final extractedData = json.decode(response.body);
        for (int i = 0; i < extractedData['result'].length; i++) {
          // print(extractedData['result'][i]
          // ['wallet_customers_id']);
          loadedCusAccountCurrencyRC.add(
            DDownModel(
              wallet_accounts_id: extractedData['result'][i]
              ['wallet_accounts_id'],
              id: extractedData['result'][i]['currency_id'],
              name: extractedData['result'][i]['currency_name'],
              f_name: extractedData['result'][i]['f_name'],
              m_name: extractedData['result'][i]['m_name'],
            ),
          );
        }
        _CusAccountCurrencyRC = loadedCusAccountCurrencyRC.toList();
        return _CusAccountCurrencyRC;
      } else {
       
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
}

