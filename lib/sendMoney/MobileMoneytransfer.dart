import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/models/http_exception.dart';
import 'package:asalpay/providers/FillDropdownbyRegistreration.dart';
import 'package:asalpay/providers/Walletremit.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllRemitDropDown.dart';
import 'package:asalpay/widgets/commonBtn.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../TransferReceiptLetter/paymentPage.dart';
import '../constants/Constant.dart';
import 'dart:io' show Platform;

import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';

import 'dart:async'; 
import 'package:http/http.dart' as http;

class MobileMoneytransfer extends StatefulWidget {

  final String wallet_accounts_id;

  final String country;
  final String type;
  const MobileMoneytransfer({
    required this.wallet_accounts_id,
    required this.country,
    required this.type,
    super.key,
  });

  @override
  State<MobileMoneytransfer> createState() => _MobileMoneytransferState();
}

class _MobileMoneytransferState extends State<MobileMoneytransfer> {



TextEditingController phoneNumberController = TextEditingController();


    // Create an instance of TokenClass
  TokenClass tokenClass = TokenClass();

  List<Map<String, dynamic>> sourceOfFunds = [];
  List<Map<String, dynamic>> purposeOfTransfer = [];

  String? selectedSourceOfFunds;
  String? selectedPurposeOfTransfer;

  bool isLoadingSource = true;
  bool isLoadingPurpose = true;
  
// 4/8/24
StreamSubscription<List<BalanceDisplayModel>>? _balanceSubscription;


  // TextEditingController cardHolderName = TextEditingController();
  final _PhoneNumber = FocusNode();
  final _SendAmount = FocusNode();
  final _BeneficiaryName = FocusNode();
  final _ReasonForSending = FocusNode();
  TextEditingController PhoneNumber = TextEditingController();
  TextEditingController ReasonForSending = TextEditingController();
  TextEditingController SendAmount = TextEditingController();
  TextEditingController BeneficiaryName = TextEditingController();
  TextEditingController CurrencyIDSearch = TextEditingController();
  TextEditingController RemitChannelDSearch = TextEditingController();
  // TextEditingController AmountReceive = TextEditingController();
  String? CurrencyID;
  String? RemitChannel;

  String? partnerTag;
  // String? CFdropdownValue;
  bool _isLoadingDrop_data = false;
  bool _isLoading = false;
  bool _isLoadingExchange = false;

  String Reciveamount = "0";
  // String Reciveamount1 = "0";
  String AmountReceive = "000";
  // String AmountReceive1 = "0";
  String ReciverAccount = "";
  String currency_name_to = "";
  // String currency_name_to1 = "";

  String currency_name_fro = "";
  // String currency_name_fro1 = "";
  String currency_id_to = "";
  // String currency_id_to1 = "";
  String amount_fro = "";
  String fieldValue = '';

  String fieldValuePhone = '';

  String charge = "000";
  String rate = "000";
  double totalPayingAmount = 000;

  // String? RecieverAccountNumber;
  String? RecieverNumber;
  String? FullName;

  bool isConnected = true;
  String statusText = '';

  String partiner_id = "";
  String? partiner_tag = "";
  var result;
  // var result2;

  var _addSaveReallyTimeData = SaveReallyTimeData(
    description: "",
    amount_from: "",
    beneficiary_name: "",
    currency_id_fro: "",
    currency_to_id: "",
    remit_channel: "",
    wallet_accounts_id_fro: "",
    partiner_id: "",
    reciveAmount: "",
    receiverNumber: "",
    accountNumber: "",
    totalpayin: "",
    
  );


// 4/8/24

// again on 6/4/24

@override
  void initState() {
    super.initState();

   fetchSourceOfFunds();
   fetchPurposeOfTransfer();

    debugPrint("initState: Initial Source of Funds = ${selectedSourceOfFunds}, Source ID = ${_addSaveReallyTimeData.source_id}");
    debugPrint("initState: Initial Purpose of Transfer = ${selectedPurposeOfTransfer}, Purpose ID = ${_addSaveReallyTimeData.purpose_id}");
    

}
   
  

@override
void didChangeDependencies() async {
  super.didChangeDependencies();
  setState(() {
    _isLoadingDrop_data = true;
  });

  final String accountId = widget.wallet_accounts_id;
  
  await Provider.of<FillRegisterationDropdown>(context, listen: false)
      .fetchAndSetCusAccountCurrency(accountId);


  await Provider.of<Walletremit>(context, listen: false)
    .fetchAndSetRemitChannelTypes(
  widget.country ?? "", // Country ID
  widget.type ?? "",    // Tag
  _addSaveReallyTimeData.source_id ?? "",
  _addSaveReallyTimeData.purpose_id ?? "",
  _addSaveReallyTimeData.sourceOfFunds ?? "", 
  _addSaveReallyTimeData.purposeOfTransfer ?? "", 
);

  
  _balanceSubscription?.cancel(); 
  _balanceSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndDisplayBalance(accountId)
      .listen(
        (balances) {
          
         
        },
        onError: (error) {
          print("Error receiving balance data: $error");
        },
      );

  setState(() {
    _isLoadingDrop_data = false;
    
    final RemitChannelTypes = Provider.of<Walletremit>(context, listen: false);
    final CusAccountCurrency = Provider.of<FillRegisterationDropdown>(context, listen: false);
    
    CurrencyID = _getDefaultSelectedValue(CusAccountCurrency); 
    RemitChannel = _getDefaultSelectedBeneficiaryBank(RemitChannelTypes);

    print('CusAccountCurrency: $CusAccountCurrency');
    print("currencyId $CurrencyID");
  });
}




@override
void dispose() {
  _balanceSubscription?.cancel(); 
  super.dispose();

 
    super.dispose();

}


//here 4/6/24


Future<Map<String, dynamic>?> validateAccount(String remitChannel, String destinationNo, String partnerTag, String country_id) async {


  String token = tokenClass.getToken();

  var url  = '${ApiUrls.BASE_URL}Walletremit/validateAccount';

 
  print('Remit Channel: $remitChannel');
  print('Destination Number: $destinationNo');
  print('As of now, the Partner Tag: $partnerTag');

  Map<String, dynamic> body = {
    'remit_channel': remitChannel,
    'destinationNo': destinationNo,
    'partiner_tag': partiner_tag,
    'country_id' : country_id,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        
        
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
        
        },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to validate account. Status code: ${response.statusCode}');
      return null;  
    }
  } catch (e) {
    print('Failed to make a request: $e');
    return null;  
  }
}


//to here 4/6

// from here, 10/10/2024

  Future<Map<String, dynamic>?> validateMobileWallet(String receiverNumber, String accountNumber, int countryId) async {


  String token = tokenClass.getToken();

  var url = '${ApiUrls.BASE_URL}/Onafriq_controller/ValidateMoblieWallet';

  Map<String, dynamic> body = {
    'receiverNumber': receiverNumber,
    'country_id': countryId,
    'accountNumber': accountNumber,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        
        
      "API-KEY": tokenClass.key,
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
        
        },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to validate mobile wallet. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Failed to make a request: $e');
    return null;
  }
}



  String ModelErrorMessage = "";
  String pinNumber = "";
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message, textAlign: TextAlign.center),
        content: const Text(
          "Enter a valid pin",
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  bool isloading1 = false;
  bool _submitted1 = false;


  Future<void> _CheckPinNumber() async {
    _submitted1 = true;
    // final isValid = _form.currentState?.validate();
    // if (!isValid!) {
    //   return;
    // }
    // _form.currentState?.save();
    setState(() {
      isloading1 = true;
      ModelErrorMessage = "";
      print("setState");
      print(isloading1);
    });
    var errorMessage = 'successfully Sent!';
    try {
      final auth = Provider.of<Auth>(context, listen: false);
      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .LoginPIN(
        auth.phone!,
        pinNumber,
      );
      print('CheckPhoneNumberAndPinNumberand');
      print(auth.phone!);
      print(pinNumber);
      // print(PINControllerNew.text);
    } on HttpException catch (error) {
      if (error.toString().contains('INVALID_PHONE')) {
        errorMessage = 'Could not find a user with that phone .';
        // setState(() {
        ModelErrorMessage = errorMessage;
        // openSnackbar(context, error.toString(), secondryColor);
        _showErrorDialog(error.toString());
// });
        return;
      } else if (error.toString().contains('INVALID_PIN')) {
        errorMessage = 'Invalid password.';

        // setState(() {
        ModelErrorMessage = errorMessage;
        // });
        print("ModelErrorMessage");
        print(ModelErrorMessage);
        return;
      } else if (error.toString().contains('INACTIVE_ACCOUNT')) {
        errorMessage = 'Your Account Is not Active.';
        // setState(() {
        ModelErrorMessage = errorMessage;
// });
        return;
      } else if (error.toString().contains('OP')) {
        errorMessage = 'operation failed .';
        // setState(() {
        ModelErrorMessage = errorMessage;

// });
        return;
      }
      print(error.toString());
      print('hello welcome');
// _showErrorDialog(errorMessage);
//       openSnackbar(context, errorMessage, secondryColor);
      return;
    } catch (error) {
// _showErrorDialog(error.toString());
      print("ModelErrorMessage");
      setState(() {
        ModelErrorMessage = error.toString();
      });
      print(ModelErrorMessage);
      // openSnackbar(context, error.toString(), secondryColor);
      _showErrorDialog(error.toString());
      setState(() {
        isloading1 = false;
        print("setState");
        print(isloading1);
      });
      return;
// Navigator.push(context, Mate return;rialPageRoute(builder: (context)=>Login()));
    }
    setState(() {
      isloading1 = false;
      print("setState");
      print(isloading1);
    });
    _submitted1 = false;
// setState(() {
    ModelErrorMessage = "";
// });
    _saveForm();
  }

  Future<void> _showMyDialogConfirmPin() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Confirmation Pin",
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontSize: 20),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Enter 4-digit Pin To Send Money",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  OtpTextField(
                    numberOfFields: 4,
                    borderColor: primaryColor,
                    obscureText: true,
                    fillColor: secondryColor,
                    enabledBorderColor: primaryColor,
                    cursorColor: primaryColor,
                    disabledBorderColor: primaryColor,
                    focusedBorderColor: secondryColor,
                    onCodeChanged: (String verificationCode) {
                      pinNumber = verificationCode;
                    },
                    autoFocus: true,
                    onSubmit: (String verificationCode) {
                      pinNumber = verificationCode;
                      _CheckPinNumber();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: <Widget>[
                isloading1
                    ? const Center(
                        child:
                            // CircularProgressIndicator(),
                            LogoandSpinner(
                        imageAssets: 'assets/asalicon.png',
                        reverse: true,
                        arcColor: primaryColor,
                        spinSpeed: Duration(milliseconds: 500),
                      ))
                    : InkWell(
                        onTap: () {
                          if (_submitted == false) {
                            Navigator.pop(context);
                          } else {
                            _CheckPinNumber();
                          }
                        },
                        child: const CommonBtn(txt: "Confirm Pin"),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  bool _submitted = false;
  final _form = GlobalKey<FormState>();


  Future<void> _saveForm() async {
  debugPrint("saveForm: Initiating save form process...");


  _submitted = true;
  debugPrint("saveForm: Form submitted.");

  final isValid = _form.currentState?.validate();
  debugPrint("saveForm: Form validation result: $isValid");

  if (isValid == null || !isValid) {
    debugPrint("saveForm: Form validation failed. Exiting.");
    return;
  }

  _form.currentState?.save();
  debugPrint("saveForm: Form data saved.");

  // Extract IDs for sourceOfFunds and purposeOfTransfer
  String? sourceId = sourceOfFunds
      .firstWhere((source) => source['name'] == selectedSourceOfFunds)['id'];
  String? purposeId = purposeOfTransfer
      .firstWhere((purpose) => purpose['name'] == selectedPurposeOfTransfer)['id'];

  debugPrint("saveForm: Selected Source of Funds: $selectedSourceOfFunds");
  debugPrint("saveForm: Source ID: $sourceId");
  debugPrint("saveForm: Selected Purpose of Transfer: $selectedPurposeOfTransfer");
  debugPrint("saveForm: Purpose ID: $purposeId");

  // Update _addSaveReallyTimeData with IDs
  _addSaveReallyTimeData = _addSaveReallyTimeData.copyWith(
    source_id: sourceId,
    purpose_id: purposeId,
    sourceOfFunds: selectedSourceOfFunds,
    purposeOfTransfer: selectedPurposeOfTransfer,
    
  );

  debugPrint("saveForm: Updated SaveReallyTimeData: ${_addSaveReallyTimeData}");

  setState(() {
    _isLoading = true;
  });

  try {
    debugPrint("saveForm: Attempting to save data to Firestore.");

    await Provider.of<Walletremit>(context, listen: false).addSaveReallyTimeData(
      widget.country,
      _addSaveReallyTimeData,
      widget.wallet_accounts_id,
      widget.type,
    );

    debugPrint("saveForm: Data saved successfully.");
  } on HttpException catch (error) {
    debugPrint("saveForm: HttpException encountered: $error");

    openSnackbar(context, error.toString(), secondryColor);
    setState(() {
      _isLoading = false;
    });
    return;
  } catch (error) {
    debugPrint("saveForm: Unknown error encountered: $error");

    setState(() {
      _isLoading = false;
    });
    return;
  }

  debugPrint("saveForm: Fetching and updating transactions.");
  await Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndSetAllTr();

  _submitted = false;

  try {
    final displayBalance =
        Provider.of<HomeSliderAndTransaction>(context, listen: false);
    final balances = await displayBalance
        .fetchAndDisplayBalance(widget.wallet_accounts_id)
        .first;

    if (balances.isEmpty) {
      debugPrint("saveForm: Balances not received yet.");
    } else {
      debugPrint("saveForm: Balances fetched successfully: $balances");

      debugPrint("saveForm: Navigating to PaymentPage.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            RecieverNumber.toString(),
            "Phone",
            ReceiverLabelRec: "Acc",
            ReceiverAmount: currency_name_to + Reciveamount,
            ReceiverName: FullName.toString(),
            senderAccount: widget.wallet_accounts_id,
            senderAmount: currency_name_fro + amount_fro,
            senderName: "${balances[0].f_name} ${balances[0].m_name}",
            sourceOfFunds: selectedSourceOfFunds,
            purposeOfTransfer: selectedPurposeOfTransfer,
          ),
        ),
      );
    }
  } catch (error) {
    debugPrint('saveForm: Error fetching balance data: $error');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }

  debugPrint("saveForm: Completed process.");
}

Future<void> requestContactPermission(
    BuildContext context, ValueNotifier<TextEditingValue> phoneNumberController) async {
  // Request permission using FlutterContacts
  final bool permissionGranted = await FlutterContacts.requestPermission();

  if (permissionGranted) {
    debugPrint('Permission granted. Proceeding to fetch contacts...');
    fetchContacts(context, phoneNumberController);
  } else {
    debugPrint('Permission denied. Showing explanation dialog.');
    showPermissionDeniedDialog(context);
  }
}

Future<void> fetchContacts(
    BuildContext context, ValueNotifier<TextEditingValue> phoneNumberController) async {
  try {
    // Fetch contacts
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    debugPrint('Contacts fetched: ${contacts.length}');

    if (contacts.isNotEmpty) {
      // Show the contact picker dialog
      showContactPickerDialog(context, contacts, phoneNumberController);
    } else {
      debugPrint('No contacts found.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts found on this device.')),
      );
    }
  } catch (e) {
    debugPrint('Error fetching contacts: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching contacts: $e')),
    );
  }
}


void showContactPickerDialog(
    BuildContext context, List<Contact> contacts, ValueNotifier<TextEditingValue> phoneNumberController) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select a Contact'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return ListTile(
              title: Text(contact.displayName),
              subtitle: contact.phones.isNotEmpty
                  ? Text(contact.phones.first.number)
                  : const Text('No phone number'),
              onTap: () {
              if (contact.phones.isNotEmpty) {
                String pickedNumber = contact.phones.first.number;
                pickedNumber = pickedNumber.replaceAll(' ', '').replaceAll('+', '');

                // Update the phone number field
                phoneNumberController.value = phoneNumberController.value.copyWith(
                  text: pickedNumber,
                );

                // ALSO update your local variable
                RecieverNumber = pickedNumber;

                Navigator.of(context).pop();
              }
            },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

void showPermissionDeniedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Permission Denied"),
      content: const Text("We need access to your contacts to proceed."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

Future<void> fetchSourceOfFunds() async {
  String token = tokenClass.getToken();
  print("Token: $token");

  var url = "${ApiUrls.BASE_URL}/Walletremit/get_remit_sourceOfFunds";
  var headers = {
    "API-KEY": tokenClass.key,
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'True') {
        setState(() {
          sourceOfFunds = (data['result'] as List).map((item) {
            return {
              'id': item['source_id'].toString(),
              'name': item['source_name'].toString(),
            };
          }).toList();

          // Automatically select the first value
          if (sourceOfFunds.isNotEmpty) {
            final firstSource = sourceOfFunds[0];
            selectedSourceOfFunds = firstSource['name'];
            _addSaveReallyTimeData = _addSaveReallyTimeData.copyWith(
              sourceOfFunds: firstSource['name'], // Save name
              source_id: firstSource['id'].toString(), // Save ID
            );

            debugPrint("Initial Source of Funds: ${firstSource['name']} (${firstSource['id']})");
          }
        });
      }
    }
  } catch (e) {
    debugPrint('Error fetching Source of Funds: $e');
  } finally {
    setState(() {
      isLoadingSource = false;
    });
  }
}

Future<void> fetchPurposeOfTransfer() async {
  String token = tokenClass.getToken();
  print("Token: $token");

  var url = "${ApiUrls.BASE_URL}/Walletremit/get_remit_purposeOfTransfer";
  var headers = {
    "API-KEY": tokenClass.key,
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'True') {
        setState(() {
          purposeOfTransfer = (data['result'] as List).map((item) {
            return {
              'id': item['purpose_id'].toString(),
              'name': item['purpose_name'].toString(),
            };
          }).toList();

          // Automatically select the first value
          if (purposeOfTransfer.isNotEmpty) {
            final firstPurpose = purposeOfTransfer[0];
            selectedPurposeOfTransfer = firstPurpose['name'];
            _addSaveReallyTimeData = _addSaveReallyTimeData.copyWith(
              purposeOfTransfer: firstPurpose['name'], // Save name
              purpose_id: firstPurpose['id'].toString(), // Save ID
            );
          }
        });
      }
    }
  } catch (e) {
    debugPrint('Error fetching Purpose of Transfer: $e');
  } finally {
    setState(() {
      isLoadingPurpose = false;
    });
  }
}


  String? _getDefaultSelectedValue(
      FillRegisterationDropdown CusAccountCurrency) {
    if (CusAccountCurrency.CusAccountCurrency.isNotEmpty) {
      return CusAccountCurrency.CusAccountCurrency[0].id;
    }
    return null;
  }

  String? _getDefaultSelectedBeneficiaryBank(Walletremit RemitChannelTypes) {
    if (RemitChannelTypes.FillRemitChannelTypes.isNotEmpty) {
      partiner_id = RemitChannelTypes.FillRemitChannelTypes[0].partiner_id;
      partiner_tag = RemitChannelTypes.FillRemitChannelTypes[0].partiner_tag;

  
      print("partiner_id static! ");
      print(partiner_id);
      print("partiner_tag static! ");
      print(partiner_tag);

      print("Remit Channel 111111111111111! ");
      print(RemitChannel);
      return RemitChannelTypes.FillRemitChannelTypes[0].channel_type_id;
    }
    return null;
  }


Widget _buildLoadingIndicator() {
  return Positioned.fill(
    child: Container(
     // color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
     
      child: const Center(
        child: LogoandSpinner(
          imageAssets: 'assets/asalicon01.png', // Specify the correct asset path
          reverse: true,
            arcColor: primaryColor,
          spinSpeed: Duration(milliseconds: 500),
        ),
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    final CusAccountCurrency =
        Provider.of<FillRegisterationDropdown>(context, listen: false);
    final RemitChannelTypes = Provider.of<Walletremit>(context, listen: false);
    // final  partinerid = Provider.of<Walletremit>(context, listen: false).findById(RemitChannel.toString());
    String? defaultSelectedValue = _getDefaultSelectedValue(CusAccountCurrency);
   

        return Scaffold(
          
          backgroundColor: secondryColor.withOpacity(0.9),

         
    body: _isLoadingDrop_data
        ? const Center(
            child: CircularProgressIndicator(),
          )
     
       : Padding(
            padding: EdgeInsets.only(
              top: AppBar().preferredSize.height,
              left: 15,
              right: 15,
            ),
            
            child: Column(       
              children: [

                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    const Text(
                      "Mobile Money transfer",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Form(
                        // autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: _form,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 20,
                            ),
                            //Image;
                            Container(
                              height: 200,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage("assets/asalpayscreens.png"),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            //all fields of exchange;
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 10),
                                            const Text(
                                              "Select mobile wallet",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: secondryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),

                                            
                                            AllinOneRemitDropdownSearch(
                                              onChanged: (value) {
                                                setState(() {
                                                  RemitChannel = value;
                                                  print('The Remit Channel Value is below: ');
                                                  print(RemitChannel);
                                                  var partinerid =
                                                      Provider.of<Walletremit>(
                                                              context,
                                                              listen: false)
                                                          .findById(RemitChannel
                                                              .toString());
                                                  print("RemitChannel");
                                                  print(RemitChannel);
                                                  print("partiner_tag onchange");
                                                  print(partinerid.partiner_tag);
                                                  partiner_tag =partinerid.partiner_tag;
                                                  
                                                  print("partiner_id onchange");
                                                  print(partinerid.partiner_id);
                                                  partiner_id =partinerid.partiner_id;

                                                  _addSaveReallyTimeData = SaveReallyTimeData(
                                                      wallet_accounts_id_fro:
                                                          _addSaveReallyTimeData
                                                              .wallet_accounts_id_fro,
                                                      currency_id_fro:
                                                          _addSaveReallyTimeData
                                                              .currency_id_fro,
                                                      description:
                                                          _addSaveReallyTimeData
                                                              .description,
                                                      remit_channel: value,
                                                      currency_to_id:
                                                          _addSaveReallyTimeData
                                                              .currency_to_id,
                                                      amount_from:
                                                          _addSaveReallyTimeData
                                                              .amount_from,
                                                      beneficiary_name:
                                                          _addSaveReallyTimeData
                                                              .beneficiary_name,
                                                      partiner_id: partinerid
                                                          .partiner_id
                                                          .toString(),
                                                      reciveAmount:
                                                          _addSaveReallyTimeData
                                                              .reciveAmount,
                                                      receiverNumber:
                                                          _addSaveReallyTimeData
                                                              .receiverNumber,
                                                      accountNumber:
                                                          _addSaveReallyTimeData
                                                              .receiverNumber,
                                                    totalpayin: _addSaveReallyTimeData.totalpayin,

                                                    sourceOfFunds: selectedSourceOfFunds,
                                                    purposeOfTransfer: selectedPurposeOfTransfer,
                                                  );
                                                  // print(partiner_id.partiner_id);
                                                  // partiner_id = partiner_id.partiner_id.toString();
                                                });
                                              },
                                              maintext: "Pick Beneficiary bank",
                                              hintxt: "Search Beneficiary bank",
                                              items: RemitChannelTypes
                                                  .FillRemitChannelTypes,
                                              dropdownValue: RemitChannel,
                                              SearchCtr: RemitChannelDSearch,
                                            ),
                                            const SizedBox(height: 10),

                                            AllformFields(
                                              // ctr: PhoneNumber,
                                              ctr: phoneNumberController, // Pass the controller here
                                              focusNode: _PhoneNumber,
                                              keyboardType: TextInputType.phone,
                                              // textInputAction:partiner_tag=='SSP' ? TextInputAction.done:
                                              //     TextInputAction.next,
                                              textInputAction: (partiner_tag == 'SSP' || partiner_tag == 'Onafriq') ? TextInputAction.done : TextInputAction.next,

                                              hintxt: "Phone Number",
                                              icn: Icons.phone_iphone,
                                              validator: (value) {
                                                if (_submitted) {
                                                 
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Phone Number Field is Required';
                                                  }
                                                  
                                                  if (value.length < 5) {
                                                    return 'Enter at least 5 digits';
                                                  }
                                                }
                                                return null;
                                              },


                                          onEditingComplete: () async {
                                            String textWithoutSpacesAndPlus = fieldValuePhone.replaceAll(' ', '').replaceAll('+', '');
                                            PhoneNumber.value = PhoneNumber.value.copyWith(
                                              text: textWithoutSpacesAndPlus,
                                            );

                                            String partnerTag = partiner_tag ?? '';

                                            print('Current partner_tag is: $partnerTag');

                                            if (partnerTag == "SSP" || partnerTag == "Onafriq") {
                                              setState(() {
                                                _isLoadingDrop_data = true; 
                                              });

                                              if (partnerTag == "SSP") {
                                                var accountData = await validateAccount(RemitChannel!, textWithoutSpacesAndPlus, partnerTag, widget.country);

                                                if (accountData != null && accountData['status']) {
                                                  BeneficiaryName.text = accountData['account_name'];
                                                  _addSaveReallyTimeData = _addSaveReallyTimeData.copyWith(beneficiaryName: accountData['account_name']);
                                                  FullName = accountData['account_name'];
                                                } else {
                                                  BeneficiaryName.text = '';
                                                  FullName = '';
                                                }
                                              } else if (partnerTag == "Onafriq") {
                                                var walletData = await validateMobileWallet(textWithoutSpacesAndPlus, '808080', 43); // You can dynamically pass the accountNumber and country_id

                                                if (walletData != null && walletData['status']) {
                                                  if (walletData['message'].contains('number is active')) {
                                                    
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: const Text('Mobile Wallet Status'),
                                                          content: const Text('The phone number is active.'),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text('OK'),
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                  
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: const Text('Mobile Wallet Status'),
                                                          content: const Text('The phone number is inactive.'),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text('OK'),
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                } else {
                                                  
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text('Error'),
                                                        content: const Text('The phone number is inactive..'),
                                                        actions: [
                                                          TextButton(
                                                            child: const Text('OK'),
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              }

                                              setState(() {
                                                _isLoadingDrop_data = false;
                                              });
                                            }
                                          },
                                          
                                          onTap: () async {
                                          try {
                                            await requestContactPermission(context, phoneNumberController);
                                          } catch (e) {
                                            print('Error in onTap: $e'); // Debug log
                                          }
                                        },

                                              //to here
                                  
                                              onChanged: (value) async {
                                                // Remove spaces and "+" and update the text field

                                                fieldValuePhone = value;

                                                print('The value as of now');

                                                print(value);

                                                String
                                                    textWithoutSpacesAndPlus =
                                                    value
                                                        .replaceAll(' ', '')
                                                        .replaceAll('+', '');
                                                PhoneNumber.value =
                                                    PhoneNumber.value.copyWith(
                                                  text:
                                                      textWithoutSpacesAndPlus,

                                                      
                                                  // selection: TextSelection.collapsed(
                                                  //     offset: textWithoutSpacesAndPlus.length),
                                                );
                                                print('As of now textWithoutSpacesAndPlus ');

                                                print(textWithoutSpacesAndPlus );
                                                // Access the text without spaces
                                                RecieverNumber =
                                                    PhoneNumber.text;
                                                
                                                print('As of now RecieverNumber ');

                                                print(RecieverNumber );

                                                print(
                                                    "Removed Number $RecieverNumber");
                                                print("Removed Number $value");
                                                // Check if the phone number length is greater than 4
                                                if (PhoneNumber.text.length >
                                                    4 ) {
              

                                                  await Provider.of<
                                                      FillRegisterationDropdown>(
                                                    context,
                                                    listen: false,
                                                  ).fetchAndSetCusAccountCurrencyRC(
                                                      RecieverNumber
                                                          .toString());

                                                  
                                                  // 6/4/24
                                               

                                                 // String remitChannel = _addSaveReallyTimeData.remit_channel;
                                                   
                                                 
                                                  //6/4/24

                                                  setState(() {
                                                    _isLoadingDrop_data = false;
                                                    print(
                                                        "RecieverAccountNumber");
                                                    print(RecieverNumber);
                                                  });

                                                  ReciverAccount = value;
                                                  _addSaveReallyTimeData =
                                                      SaveReallyTimeData(
                                                    wallet_accounts_id_fro:
                                                        _addSaveReallyTimeData
                                                            .wallet_accounts_id_fro,
                                                    currency_id_fro:
                                                        _addSaveReallyTimeData
                                                            .currency_id_fro,
                                                    description:
                                                        _addSaveReallyTimeData
                                                            .description,
                                                    remit_channel:
                                                        _addSaveReallyTimeData
                                                            .remit_channel,
                                                    currency_to_id:
                                                        _addSaveReallyTimeData
                                                            .currency_to_id,
                                                    amount_from:
                                                        _addSaveReallyTimeData
                                                            .amount_from,
                                                    beneficiary_name:
                                                        _addSaveReallyTimeData
                                                            .beneficiary_name,
                                                    partiner_id:
                                                        _addSaveReallyTimeData
                                                            .partiner_id,
                                                    reciveAmount:
                                                        _addSaveReallyTimeData
                                                            .reciveAmount,
                                                    receiverNumber:
                                                        RecieverNumber
                                                            .toString(),
                                                    accountNumber:
                                                        RecieverNumber
                                                            .toString(),
                                                    totalpayin: _addSaveReallyTimeData.totalpayin,
                                                    sourceOfFunds: selectedSourceOfFunds,
                                                    purposeOfTransfer: selectedPurposeOfTransfer,
                                                  );
                                                }
                                                    
                                              },
                                            ),

                                           
                                            const SizedBox(height: 10),
                                            
                                            AllformFields(
                                              ctr: BeneficiaryName,
                                              focusNode: _BeneficiaryName,
                                              keyboardType: TextInputType.name,
                                              textInputAction:
                                                  TextInputAction.next,
                                              hintxt: "Beneficiary Full Name",
                                              icn: Icons.person,

                                                              
                                              validator: (value) {
                                                if (_submitted &&
                                                    value!.isEmpty) {
                                                  return 'Beneficiary Full Name Field is Required';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                FullName = value;
                                                _addSaveReallyTimeData = SaveReallyTimeData(
                                                    wallet_accounts_id_fro:
                                                        _addSaveReallyTimeData
                                                            .wallet_accounts_id_fro,
                                                    currency_id_fro:
                                                        _addSaveReallyTimeData
                                                            .currency_id_fro,
                                                    description:
                                                        _addSaveReallyTimeData
                                                            .description,
                                                    remit_channel:
                                                        _addSaveReallyTimeData
                                                            .remit_channel,
                                                    currency_to_id:
                                                        _addSaveReallyTimeData
                                                            .currency_to_id,
                                                    amount_from:
                                                        _addSaveReallyTimeData
                                                            .amount_from,
                                                    beneficiary_name: value,
                                                    partiner_id:
                                                        _addSaveReallyTimeData
                                                            .partiner_id,
                                                    reciveAmount:
                                                        _addSaveReallyTimeData
                                                            .reciveAmount,
                                                    receiverNumber:
                                                        _addSaveReallyTimeData
                                                            .receiverNumber,
                                                    accountNumber:
                                                        _addSaveReallyTimeData
                                                            .receiverNumber);
                                                    
                                                    sourceOfFunds: selectedSourceOfFunds;
                                                    purposeOfTransfer: selectedPurposeOfTransfer;

                                              },
                                
                                            ),


                                             const SizedBox(height: 10),

                                            Container(
  padding: const EdgeInsets.only(left: 8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey, width: 1.5),
  ),
  child: DropdownButtonHideUnderline(
    child: DropdownButton2<String>(
      isExpanded: true,
      hint: Text(
        "Pick Source of Funds",
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).hintColor,
        ),
      ),
      items: sourceOfFunds.map((source) {
        return DropdownMenuItem<String>(
          value: source['name'],
          child: Text(
            source['name'] ?? "Unknown Source",
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      value: selectedSourceOfFunds,
      onChanged: (value) {
        setState(() {
          selectedSourceOfFunds = value;

          final selectedSource = sourceOfFunds.firstWhere(
            (source) => source['name'] == value,
            orElse: () => {'id': 'unknown', 'name': 'unknown'},
          );

          _addSaveReallyTimeData = _addSaveReallyTimeData.copyWith(
            sourceOfFunds: selectedSource['name'],
            source_id: selectedSource['id'],
          );
        });

        debugPrint("Dropdown changed: Source of Funds = ${selectedSourceOfFunds}, Source ID = ${_addSaveReallyTimeData.source_id}");
      },
      buttonStyleData: const ButtonStyleData(
        height: 45,
        width: 350,
      ),
      dropdownStyleData: const DropdownStyleData(
        maxHeight: 200,
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 40,
      ),
      iconStyleData: const IconStyleData(
        iconSize: 30,
        iconEnabledColor: primaryColor,
        icon: Icon(
          Icons.arrow_drop_down_circle,
        ),
      ),
    ),
  ),
),

const SizedBox(height: 10),

/// Purpose of Transfer Dropdown
Container(
  padding: const EdgeInsets.only(left: 8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey, width: 1.5),
  ),
  child: DropdownButtonHideUnderline(
    child: DropdownButton2<String>(
      isExpanded: true,
      hint: Text(
        "Pick Purpose of Transfer",
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).hintColor,
        ),
      ),
      items: purposeOfTransfer.map((purpose) {
        return DropdownMenuItem<String>(
          value: purpose['name'],
          child: Text(
            purpose['name'] ?? "Unknown Purpose",
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      value: selectedPurposeOfTransfer,
      onChanged: (value) {
        setState(() {
          selectedPurposeOfTransfer = value;

          final selectedPurpose = purposeOfTransfer.firstWhere(
            (purpose) => purpose['name'] == value,
            orElse: () => {'id': 'unknown', 'name': 'unknown'},
          );

          _addSaveReallyTimeData = _addSaveReallyTimeData.copyWith(
            purposeOfTransfer: selectedPurpose['name'],
            purpose_id: selectedPurpose['id'],
          );
        });

        debugPrint("Dropdown changed: Purpose of Transfer = ${selectedPurposeOfTransfer}, Purpose ID = ${_addSaveReallyTimeData.purpose_id}");
      },
      buttonStyleData: const ButtonStyleData(
        height: 45,
        width: 350,
      ),
      dropdownStyleData: const DropdownStyleData(
        maxHeight: 200,
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 40,
      ),
      iconStyleData: const IconStyleData(
        iconSize: 30,
        iconEnabledColor: primaryColor,
        icon: Icon(
          Icons.arrow_drop_down_circle,
        ),
      ),
    ),
  ),
),
                                            
                                            const SizedBox(height: 10),
                                            const Text(
                                              "Amount",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: secondryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 10),
                                            AllformFields(
                                              ctr: SendAmount,
                                              focusNode: _SendAmount,
                                              // keyboardType:
                                              //     TextInputType.number,
                                              keyboardType: Platform.isIOS
                                                  ? const TextInputType
                                                      .numberWithOptions(
                                                          signed: true,
                                                          decimal: true)
                                                  : TextInputType.number,
                                              
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp('[0-9]'))
                                              ],
                                              textInputAction:
                                                  TextInputAction.done,
                                              validator: (value) {
                                                if (_submitted &&
                                                    value!.isEmpty) {
                                                  return 'SendAmount  Field is Required';
                                                }
                                                return null;
                                              },
                                              onEditingComplete: () async {
                                                if (fieldValue.isNotEmpty) {
                                                  setState(() {
                                                    _isLoadingExchange = true;
                                                  });
                                                  var CurrencyDataFrom = Provider
                                                          .of<FillRegisterationDropdown>(
                                                              context,
                                                              listen: false)
                                                      .findByIdTC(CurrencyID
                                                          .toString());

                                                  if (partiner_tag == "SHFT") {
                                                     result = await Provider.of<
                                                                Walletremit>(
                                                            context,
                                                            listen: false)
                                                        .getShiftCurrencyConveret(
                                                      widget.country.toString(),
                                                      CurrencyID.toString(),
                                                      fieldValue.toString(),
                                                      RemitChannel.toString(),
                                                      partiner_id.toString(),
                                                    );
                                                  }
                                                  else if(partiner_tag == "Onafriq")
                                                  {
                                                      result = await Provider.of<
                                                                Walletremit>(
                                                            context,
                                                            listen: false)
                                                        .getOnafriqCurrencyConveret(
                                                      widget.country.toString(),
                                                      CurrencyID.toString(),
                                                      fieldValue.toString(),
                                                      RemitChannel.toString(),
                                                      partiner_id.toString(),
                                                    );
                                                  }
                                                   else {
                                                     result = await Provider.of<
                                                                Walletremit>(
                                                            context,
                                                            listen: false)
                                                        .getAsalExchange(
                                                            widget.country
                                                                .toString(),
                                                            CurrencyID
                                                                .toString(),
                                                            fieldValue
                                                                .toString(),
                                                      partiner_id.toString(),
                                                    );
                                                  
                                                  }

                                                  if (result['status']
                                                          .toString() ==
                                                      "False") {
                                                    openSnackbar(
                                                        context,
                                                        result['messages']
                                                            .toString(),
                                                        secondryColor);
                                                    setState(() {
                                                      _isLoadingExchange =
                                                          false;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      currency_name_fro =
                                                          CurrencyDataFrom.name;
                                                      double numericValue =
                                                          double.parse(
                                                              fieldValue);
                                                      amount_fro = numericValue
                                                          .toStringAsFixed(2);
                                                      // amount_fro = value;
                                                      print(amount_fro);
                                                      print('amount');
                                                      print(result);
                                                      print(result['result']
                                                              ['amount_to']
                                                          .toString());
                                                      double amount =
                                                          double.parse(result[
                                                                      'result']
                                                                  ['amount_to']
                                                              .toString());
                                                      double truncatedAmount =
                                                          (amount * 100)
                                                                  .truncateToDouble() /
                                                              100;
                                                      Reciveamount =
                                                          truncatedAmount
                                                              .toString();
                                                      print(
                                                          "truncatedAmountString:  $Reciveamount");
                                                      charge = result['result']
                                                              ['charge']
                                                          .toString();
                                                      currency_name_to = result[
                                                                  'result'][
                                                              'currency_name_to']
                                                          .toString();
                                                      currency_id_to = result[
                                                                  'result']
                                                              ['currency_id_to']
                                                          .toString();

                                                      rate = result['result']
                                                              ['rate']
                                                          .toString();

                                                      totalPayingAmount = double
                                                              .parse(
                                                                  amount_fro) +
                                                          double.parse(charge);
                                                      AmountReceive =
                                                          "$currency_name_to $Reciveamount";

                                                      setState(() {
                                                        _isLoadingExchange =
                                                            false;
                                                      });
                                                    });
                                                  }
                                                }
                                                if (fieldValue.isEmpty) {
                                                  setState(() {
                                                    print("Reciveamount");
                                                    print(Reciveamount);
                                                    print("AmountReceive.text");
                                                    print("AmountReceive");
                                                    print(AmountReceive);
                                                    AmountReceive = '0000';
                                                    // AmountReceive.text = "000";
                                                  });
                                                }
                                                _addSaveReallyTimeData = SaveReallyTimeData(
                                                    wallet_accounts_id_fro:
                                                        _addSaveReallyTimeData
                                                            .wallet_accounts_id_fro,
                                                    currency_id_fro:
                                                        CurrencyID!,
                                                    description:
                                                        _addSaveReallyTimeData
                                                            .description,
                                                    remit_channel:
                                                        RemitChannel!,
                                                    currency_to_id:
                                                        currency_id_to,
                                                    amount_from: fieldValue,
                                                    beneficiary_name:
                                                        _addSaveReallyTimeData
                                                            .beneficiary_name,
                                                    partiner_id: partiner_id,
                                                    reciveAmount: Reciveamount,
                                                    receiverNumber:
                                                        _addSaveReallyTimeData
                                                            .receiverNumber,
                                                    accountNumber:
                                                        _addSaveReallyTimeData
                                                            .receiverNumber,
                                                    totalpayin: totalPayingAmount.toString(),

                                                    sourceOfFunds: selectedSourceOfFunds,
                                                    purposeOfTransfer: selectedPurposeOfTransfer,
                                                );
                                                _SendAmount.unfocus();

                                              },
                                              onChanged: (value) {
                                                
                                                fieldValue = value;
                                              },
                                              hintxt: "Amount",
                                              // icn: Icons.attach_money_sharp,
                                            ),
                                            const SizedBox(height: 10),

                                          
                                            Card(
                                              elevation: 5,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                side: BorderSide(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    width: 1),
                                              ),
                                              child: Column(
                                                children: [
                                                  ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 0),
                                                    title: const Text(
                                                      "Transaction Fee",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: secondryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    trailing: Text(
                                                      "$currency_name_fro $charge",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    thickness: 1,
                                                    height: 0,
                                                    indent: 16,
                                                    endIndent: 16,
                                                  ),
                                                  _isLoadingExchange
                                                      ? const Center(
                                                          child: LogoandSpinner(
                                                            imageAssets:
                                                                'assets/asalicon.png',
                                                            reverse: true,
                                                            arcColor:
                                                                primaryColor,
                                                            spinSpeed: Duration(
                                                                milliseconds:
                                                                    500),
                                                          ),
                                                        )
                                                      : ListTile(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          0),
                                                          title: const Text(
                                                            "Received Amount",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  secondryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          trailing: Text(
                                                            AmountReceive,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                  Divider(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    thickness: 1,
                                                    height: 0,
                                                    indent: 16,
                                                    endIndent: 16,
                                                  ),
                                                  ListTile(
                                                    contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 0),
                                                    title: const Text(
                                                      "Forex Rate",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: secondryColor,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                    trailing: Text(
                                                      "$currency_name_to $rate ",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: primaryColor,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    thickness: 1,
                                                    height: 0,
                                                    indent: 16,
                                                    endIndent: 16,
                                                  ),
                                                  ListTile(
                                                    contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 0),
                                                    title: const Text(
                                                      "Total Amount ",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: secondryColor,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                    trailing: Text(
                                                      " $currency_name_fro $totalPayingAmount",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: primaryColor,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            !_isLoadingExchange
                                                ? isConnected
                                                    ? _isLoading
                                                        ? const Center(
                                                            child:
                                                                // CircularProgressIndicator(),
                                                                LogoandSpinner(
                                                            imageAssets:
                                                                'assets/asalicon.png',
                                                            reverse: true,
                                                            arcColor:
                                                                primaryColor,
                                                            spinSpeed: Duration(
                                                                milliseconds:
                                                                    500),
                                                          ))
                                                        : InkWell(
                                                            onTap: () {
                                                              // _showSheet();
                                                              // _saveForm();
                                                              _submitted = true;
                                                              final isValid = _form
                                                                  .currentState
                                                                  ?.validate();
                                                              if (!isValid!) {
                                                                print("valid");
                                                                return;
                                                              }
                                                              _form.currentState
                                                                  ?.save();
                                                              print(
                                                                  "Reciveamount Before $Reciveamount");
                                                              // if(Reciveamount.isEmpty){
                                                              _showMyDialogConfirmPin();
                                                              // print("Reciveamount After $Reciveamount");
                                                              // }
                                                            },
                                                            child: const CommonBtn(
                                                              txt: "Send",
                                                            ),
                                                          )
                                                    : Center(
                                                        child: Text(
                                                            'Network Status: $statusText'),
                                                      )
                                                : Container(),
                                            const SizedBox(
                                              height: 30,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
    
  }

  void launchDataSettings() async {
    final bool isAndroid = Platform.isAndroid;
    final bool isIOS = Platform.isIOS;

    if (isAndroid) {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.DATA_USAGE_SETTINGS',
      );
      await intent.launch();
    } else if (isIOS) {
      const url = 'App-Prefs:root=MOBILE_DATA_SETTINGS_ID';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch data settings.';
      }
    } else {
      throw 'Data settings are not supported on this platform.';
    }
  }

  void launchWifiSettings() async {
    final bool isAndroid = Platform.isAndroid;
    final bool isIOS = Platform.isIOS;

    if (isAndroid) {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.WIFI_SETTINGS',
      );
      await intent.launch();
    } else if (isIOS) {
      const url = 'App-Prefs:root=WIFI';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch Wi-Fi settings.';
      }
    } else {
      throw 'Wi-Fi settings are not supported on this platform.';
    }
  }

  //todo:Network Message;
  Future<void> _NetworkMessage(BuildContext context) async {
// Get the screen size using MediaQuery
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/WD5.png", width: isSmallScreen ? 20 : 30),
            const SizedBox(width: 8),
            const Text('Network Connection'),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withOpacity(0.3),
                ),
                padding: EdgeInsets.all(isSmallScreen ? 2 : 4),
                child: Icon(
                  Icons.close,
                  color: primaryColor,
                  size: isSmallScreen ? 16 : 20,
                ),
              ),
            ),
          ],
        ),
        content: const Text('You are currently disconnected from the network.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  launchWifiSettings();
                },
                style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  backgroundColor:
                      WidgetStateProperty.all<Color>(primaryColor),
                  foregroundColor:
                      WidgetStateProperty.all<Color>(Colors.white),
                  padding: WidgetStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 24.0,
                    ),
                  ),
                ),
                child: Text(
                  'Open Wi-Fi',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14.0 : 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: isSmallScreen ? 10 : 20,
              ),
              ElevatedButton(
                onPressed: () {
                  launchDataSettings();
                },
                style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  backgroundColor:
                      WidgetStateProperty.all<Color>(primaryColor),
                  foregroundColor:
                      WidgetStateProperty.all<Color>(Colors.white),
                  padding: WidgetStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 24.0,
                    ),
                  ),
                ),
                child: const Text('Open Data!'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}