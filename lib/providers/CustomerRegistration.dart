import 'dart:convert';
import 'dart:io';
import 'package:asalpay/services/tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../services/api_urls.dart';

class NationalityModel with ChangeNotifier {
  final String id;
  final String name;
  NationalityModel({
    required this.id,
    required this.name,
  });
  String userAsString() {
    return '#${this.id} ${this.name}';
  }
  bool userFilterByCreationDate(String filter) {
    return name.toString().contains(filter);
  }
  bool isEqual(NationalityModel model) {
    return id == model.id;
  }
  @override
  String toString() => name;
}

class CustomerRegistration with ChangeNotifier {

  
    // Create an instance of TokenClass
  TokenClass tokenClass = TokenClass();


  final String? name;
  final String? surname;
  final String? national;
  final String? telphone;
  final String? preferredcontactnumber;
  final String? referralcode;
  final String? identificationtype;
  final String? identificationnumber;
  final File? imageUrl;
  final File? documentUrl;
  final String? streetname;
  final String? streetnumber;
  final String? country;
  final String? province;
  final String? city;
  final String? suburbs;
  final String? currency;
  final String? email;
  final String? password;
  final String? walletType;
  final String? PIN;


  CustomerRegistration({
    this.walletType,
    this.name,
    this.surname,
    this.national,
    this.telphone,
    this.preferredcontactnumber,
    this.referralcode,
    this.identificationtype,
    this.identificationnumber,
    this.imageUrl,
    this.documentUrl,
    this.streetname,
    this.streetnumber,
    this.province,
    this.country,
    this.city,
    this.suburbs,
    this.currency,
    this.email,
    this.password,
    this.PIN,
  });

  List<NationalityModel> _nationality = [];

  List<NationalityModel> get nationality {
    return [..._nationality];
  }

  Future<void> addCustomer(CustomerRegistration CustomerRegistration, File? image, File? doc
      ) async {


      
  // Get the token
    String token = tokenClass.getToken();

    // Print the token
    print("Token: $token");


    print("daabac image");
    final url = "${ApiUrls.BASE_URL}Wallet_registration/walletCreation";
    try {
      // preparing the fil
      print("daabac gudaha");
      List<int> imageBytes = image != null ? image.readAsBytesSync() :[];

      List<int> docBytes = doc != null ? doc.readAsBytesSync() : [];
      String baseimage = base64Encode(imageBytes);
      String basedoc = base64Encode(docBytes);
      print("Sawirka Doc");
      // print(basedoc);
      final response = await http.post(
        Uri.parse(url),
          headers: {
           'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            "API-KEY": tokenClass.key,
            "Authorization": "Bearer $token",
          },
        body: json.encode({
          'f_name': CustomerRegistration.name,
          'm_name': CustomerRegistration.surname,
          'country_id': CustomerRegistration.country,
          'phone': CustomerRegistration.telphone,
          'password': CustomerRegistration.password,
          'preferred_cn': CustomerRegistration.preferredcontactnumber,
          'referral_code': CustomerRegistration.referralcode,
          'document_type_id': CustomerRegistration.identificationtype,
          'document_no': CustomerRegistration.identificationnumber,
          'street_name': CustomerRegistration.streetname,
          'street_number': CustomerRegistration.streetnumber,
          'province_id': CustomerRegistration.province,
          'city_id': CustomerRegistration.city,
          'suburb': CustomerRegistration.suburbs,
          'wallet_type_id':CustomerRegistration.walletType,
          'email':CustomerRegistration.email,
          "currency_id":CustomerRegistration.currency,
          'imageUrl': baseimage,
          'documentUrl': basedoc,
          'pin': CustomerRegistration.PIN,
          'nationality':CustomerRegistration.national

        }),
      );

      final responseData = json.decode(response.body);
      print("responseData1");
      print(responseData);
      // if(response.body.isNotEmpty) {
      //   json.decode(response.body);
      // }
      print(responseData);
      if (responseData['status'] == "False") {
        // throw HttpException(responseData['messages']);
        throw (responseData['messages']);
      }
      print("responseData2");
      print(responseData);
      var message = jsonDecode(response.body);
      print("daabac messeges");
      print(message);
      print("daabac image");
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

  Future<List<NationalityModel>> fetchAndSetnatinality() async {


  String token = tokenClass.getToken();
  
    var url = "${ApiUrls.BASE_URL}Wallet_registration/fill_country";
    try {
      final response = await http.get(Uri.parse(url), headers: {
       'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        "API-KEY": tokenClass.key,
        "Authorization": "Bearer $token",
      });
      // final response = await http.get(Uri.parse(url));
      // print("hello");
      // print(json.decode(response.body));

      if (response.statusCode == 200) {
        final List<NationalityModel> loadednationality = [];
        final extractedData = json.decode(response.body);

        for (int i = 0; i < extractedData.length; i++) {
          loadednationality.add(
            NationalityModel(
              id: extractedData[i]['num_code'],
              name: extractedData[i]['nationality'],
            ),
          );
        }
        _nationality = loadednationality.toList();
        return _nationality;
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









