import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/models/http_exception.dart';
import 'package:asalpay/providers/FillDropdownbyRegistreration.dart';
import 'package:asalpay/providers/Walletremit.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllinOneDropdownSearch.dart';
import 'package:asalpay/widgets/commonBtn.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../TransferReceiptLetter/Button.dart';
import '../TransferReceiptLetter/paymentPage.dart';
import '../constants/Constant.dart';
import 'dart:io' show File, Platform;

import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';


import 'dart:async'; // Import for StreamSubscription


class BbanktransferChina extends StatefulWidget {
  final String? wallet_accounts_id;
  final String? country;
  final String? type;
  const BbanktransferChina({this.wallet_accounts_id, this.country,this.type, super.key});
  static const routeName = '/BanktransferChina';
  @override
  State<BbanktransferChina> createState() => _BbanktransferChinaState();
}

class _BbanktransferChinaState extends State<BbanktransferChina> {

  // 4/8/24
StreamSubscription<List<BalanceDisplayModel>>? _balanceSubscription;


  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
  }

  final _script = TextRecognitionScript.chinese;
  String TextView = "";
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  bool _canProcess = true;
  bool _isBusy = false;
  final bool _isLoading1 = false;
  CustomPaint? _customPaint;
  String? _text;
  // var _cameraLensDirection = CameraLensDirection.back;



  final _addSaveReallyTimeData = SaveReallyTimeData(
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
   

    // partiner_tag: "",
  );

  @override
  void dispose() async {
    _canProcess = false;
     _balanceSubscription?.cancel(); 
    _textRecognizer.close();
    super.dispose();
  }


  

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processFile(pickedFile.path);
    }
  }

  Future _processFile(String path) async {
    setState(() {
      _image = File(path);
    });
    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    // widget.onImage(inputImage);
    _processImage(inputImage);
  }

  //todo: image recognition;
  Future<void> _processImage(InputImage inputImage) async {
    print('TextView11111111111111111111');
    print(TextView);
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
      // _isLoading1 = true;
    });
    print('TextView222222222222222');
    final recognizedText = await _textRecognizer.processImage(inputImage);
    print('recognizedText');
    print(recognizedText.text);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      print('Text Recognized1');

      setState(() {
        TextView = recognizedText.text;
        print('Text Recognized1 TextView');
      });

      // setState(() {
      //   _isLoading1 = false;
      // });
      accounholder.text = recognizedText.text.isNotEmpty
          ? recognizedText.text.trim()
          : "Scan or Upload Again";
      print(recognizedText.text);
    } else {
      _text = 'Recognized text:\n\n${recognizedText.text}';
      print('Text Recognized2');
      print('$_text');
      accounholder.text = recognizedText.text.isNotEmpty
          ? recognizedText.text.trim()
          : "Scan or Upload Again";
      setState(() {
        ReceiverName = recognizedText.text;
        _addWalletBankTransfer = WalletBankTransfer(
          country_id: _addWalletBankTransfer.bank_name,
          acc_holder_name: recognizedText.text,
          acc_holder_phone: _addWalletBankTransfer.acc_holder_phone,
          amount_fro: _addWalletBankTransfer.amount_fro,
          amt_accounts_no: _addWalletBankTransfer.amt_accounts_no,
          bank_name: _addWalletBankTransfer.bank_name,
          currency_id_fro: _addWalletBankTransfer.currency_id_fro,
          currency_id_to: _addWalletBankTransfer.currency_id_to,
          wallet_accounts_id_fro: _addWalletBankTransfer.wallet_accounts_id_fro,
        );
      });
      _customPaint = null;
    }
    _textRecognizer.close();
    _isBusy = false;
    if (mounted) {
      setState(() {
        // _isLoading1 = false;
      });
    }
  }

  String? currencyId;
  String? RemitChannel;
  String? partiner_tag = "";
  String? partiner_id = "";

  bool _isLoadingDrop_data = false;
  var _isLoading = false;

  var _addWalletBankTransfer = WalletBankTransfer(
    country_id: "",
    acc_holder_name: "",
    acc_holder_phone: "",
    amount_fro: "",
    amt_accounts_no: "",
    bank_name: "",
    currency_id_fro: "",
    currency_id_to: "",
    wallet_accounts_id_fro: "",
  );

  // 4/8/24

  @override
void didChangeDependencies() async {
  super.didChangeDependencies();
  setState(() {
    _isLoadingDrop_data = true;
  });

  final String? accountId = widget.wallet_accounts_id;
  if (accountId != null) {
    // Fetch and set customer account currency
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetCusAccountCurrency(accountId);

    _balanceSubscription?.cancel(); 
    _balanceSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .fetchAndDisplayBalance(accountId)
        .listen(
          (balances) {
            // Do something with the new balances data
            // print("New balances received");
          },
          onError: (error) {
            // Handle any errors from the stream
            print("Error receiving balance data: $error");
          },
        );

    // // Fetch and set remit channel types
    // await Provider.of<Walletremit>(context, listen: false)
    //     .fetchAndSetRemitChannelTypes(widget.country ?? "", widget.type ?? ""); // Null checks added


  await Provider.of<Walletremit>(context, listen: false)
    .fetchAndSetRemitChannelTypes(
  widget.country ?? "", // Country ID
  widget.type ?? "",    // Tag
  _addSaveReallyTimeData.source_id ?? "", // Source ID
  _addSaveReallyTimeData.purpose_id ?? "", // Purpose ID
  _addSaveReallyTimeData.sourceOfFunds ?? "", // Source of Funds
  _addSaveReallyTimeData.purposeOfTransfer ?? "", // Purpose of Transfer
);


  } else {
    print('Account ID is null. Subscription to balance updates is not set up.');
  }

  setState(() {
    _isLoadingDrop_data = false;
    final CusAccountCurrency = Provider.of<FillRegisterationDropdown>(context, listen: false);
    print('CusAccountCurrency: $CusAccountCurrency');
    currencyId = _getDefaultSelectedValue(CusAccountCurrency); 
  });
}


  final _Amount = FocusNode();
  final _Phone_Number = FocusNode();
  final _AccountNumber = FocusNode();
  final _accounholder = FocusNode();
  final _bankname = FocusNode();

  TextEditingController bankname = TextEditingController();
  TextEditingController accounholder = TextEditingController();
  TextEditingController Currencysearch = TextEditingController();
  TextEditingController AccountNumber = TextEditingController();
  TextEditingController Phone_Number = TextEditingController();
  TextEditingController Amount = TextEditingController();
  // TextEditingController Currencysearch = TextEditingController();
  late String CTdropdownValue;
  late String CFdropdownValue;
  String Reciveamount = "000";
  String currency_name_to = "\$";
  String currency_name_from = "";
  String currency_id_to = "";
  String amount_fro = "";
  String? RecieverAccountNumber;
  String? ReceiverAccount;
  String? ReceiverName;
  String fieldValue = '';

  var result;
  bool isConnected = true;
  late String? statusText = "";
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
                    ? const Center(child:
                // CircularProgressIndicator(),
                LogoandSpinner(
                  imageAssets:
                  'assets/asalicon.png',
                  reverse: true,
                  arcColor: primaryColor,
                  spinSpeed: Duration(
                      milliseconds: 500),
                )
                )
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
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    openSnackbar(context, 'No Internet Connection', secondryColor);
    return;
  }

  _submitted = true;
  final isValid = _form.currentState?.validate();
  if (isValid == null || !isValid) {
    return;
  }
  _form.currentState?.save();

  setState(() {
    _isLoading = true;
  });

  var errorMessage = 'SuccessFully Created';

  try {
    await Provider.of<Walletremit>(context, listen: false)
        .addWalletBankTransfer(_addWalletBankTransfer, widget.wallet_accounts_id!, widget.type);
  } on HttpException catch (error) {
    // Handle your specific error cases
    if (error.toString().contains('this account is not exist')) {
      // ...
    } else if (error.toString().contains('Email is already exit another Email')) {
      // ...
    } else if (error.toString().contains('this account is not Active')) {
      // ...
    } else if (error.toString().contains('Insufficient balance')) {
      errorMessage = 'operation failed .';
    } else if (error.toString().contains('OP')) {
      errorMessage = 'operation failed .';
    }

    print(error.toString());
    print('hello welcome');

    setState(() {
      _isLoading = false;
    });
    return;
  } catch (error) {
    openSnackbar(context, error.toString(), secondryColor);
    setState(() {
      _isLoading = false;
    });
    return;
  }

  setState(() {
    _isLoading = false;
  });

  // Fetch transactions
  await Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndSetAllTr();

  try {
    final displayBalance = Provider.of<HomeSliderAndTransaction>(context, listen: false);
    final balances =
        await displayBalance.fetchAndDisplayBalance(widget.wallet_accounts_id ?? "").first;

    if (balances.isEmpty) {
      print("Balances not received yet");
    } else {
      print("Navigating to PaymentPage");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            ReceiverAccount.toString(),
            "Acc",
            ReceiverLabelRec: "Acc",
            ReceiverAmount: currency_name_to + Reciveamount,
            ReceiverName: ReceiverName.toString(),
            senderAccount: widget.wallet_accounts_id!,
            senderAmount: currency_name_from + amount_fro,
            senderName: "${balances[0].f_name} ${balances[0].m_name}",
          ),
        ),
      );
    }
  } catch (error) {
    print('Error fetching balance data: $error');
  }

  setState(() {
    _isLoading = false;
  });

  // Reset form fields
  _submitted = false;
  Amount.text = "";
  Phone_Number.text = "";
  AccountNumber.text = "";
  accounholder.text = "";
  bankname.text = "";

  openSnackbar(context, errorMessage, secondryColor);
}

  

  String? _getDefaultSelectedValue(
      FillRegisterationDropdown CusAccountCurrency) {
    if (CusAccountCurrency.CusAccountCurrency.isNotEmpty) {
      return CusAccountCurrency.CusAccountCurrency[0].id;
    }
    return null;
  }

  @override
  String? _getDefaultSelectedBeneficiaryBank(Walletremit RemitChannelTypes) {
    if (RemitChannelTypes.FillRemitChannelTypes.isNotEmpty) {
      partiner_tag = RemitChannelTypes.FillRemitChannelTypes[0].partiner_tag;
      partiner_id = RemitChannelTypes.FillRemitChannelTypes[0].partiner_id;
      RemitChannel =
          RemitChannelTypes.FillRemitChannelTypes[0].remittance_channel_no;
      print("partiner_tag 111111111111111! ");
      print(partiner_tag);

      print("RemitChannel22222! ");
      print(RemitChannel);
      return RemitChannelTypes.FillRemitChannelTypes[0].channel_type_id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final RemitChannelTypes = Provider.of<Walletremit>(context, listen: false);
    String? defaultSelectedBeneficiaryBank =
    _getDefaultSelectedBeneficiaryBank(RemitChannelTypes);

    final CusAccountCurrency =
        Provider.of<FillRegisterationDropdown>(context, listen: false);
    String? defaultSelectedValue = _getDefaultSelectedValue(CusAccountCurrency);

    
    


        return Scaffold(
          backgroundColor: secondryColor.withOpacity(0.9),
          body: Padding(
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
                      "Bank Transfer China",
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
                                              "Bank Transfer",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: secondryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            AllformFields(
                                              ctr: bankname,
                                              focusNode: _bankname,
                                              keyboardType: TextInputType.name,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: (value) {
                                                if (_submitted &&
                                                    value!.isEmpty) {
                                                  return 'bankname Field is Required';
                                                }
                                                return null;
                                              },
                                              hintxt: "Enter Bank Name",
                                              icn: Icons.account_balance,
                                              onChanged: (value) {
                                                _addWalletBankTransfer =
                                                    WalletBankTransfer(
                                                  country_id:
                                                      _addWalletBankTransfer
                                                          .country_id,
                                                  acc_holder_name:
                                                      _addWalletBankTransfer
                                                          .acc_holder_name,
                                                  acc_holder_phone:
                                                      _addWalletBankTransfer
                                                          .acc_holder_phone,
                                                  amount_fro:
                                                      _addWalletBankTransfer
                                                          .amount_fro,
                                                  amt_accounts_no:
                                                      _addWalletBankTransfer
                                                          .amt_accounts_no,
                                                  bank_name: value,
                                                  currency_id_fro:
                                                      _addWalletBankTransfer
                                                          .currency_id_fro,
                                                  currency_id_to:
                                                      _addWalletBankTransfer
                                                          .currency_id_to,
                                                  wallet_accounts_id_fro:
                                                      _addWalletBankTransfer
                                                          .wallet_accounts_id_fro,
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 5),
                                            //todo:Account holderName;
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [

                                                      AllformFields(
                                                        maxLines: 2,
                                                        // maxLength: 4,
                                                        ctr: accounholder,
                                                        focusNode:
                                                            _accounholder,
                                                        keyboardType:
                                                            TextInputType.name,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        validator: (value) {
                                                          if (_submitted &&
                                                              value!.isEmpty) {
                                                            return 'AccountHolderName Field is Required';
                                                          }
                                                          return null;
                                                        },
                                                        hintxt:
                                                            "Account Holder Name",
                                                        icn: Icons.person,
                                                        onChanged: (value) {
                                                          ReceiverName = value;
                                                          print(
                                                              "ReceiverName11111111111111111");
                                                          print(ReceiverName);
                                                          print(
                                                              'value of china');
                                                          print(value);
                                                          _addWalletBankTransfer =
                                                              WalletBankTransfer(
                                                            country_id:
                                                                _addWalletBankTransfer
                                                                    .bank_name,
                                                            acc_holder_name:
                                                                value,
                                                            acc_holder_phone:
                                                                _addWalletBankTransfer
                                                                    .acc_holder_phone,
                                                            amount_fro:
                                                                _addWalletBankTransfer
                                                                    .amount_fro,
                                                            amt_accounts_no:
                                                                _addWalletBankTransfer
                                                                    .amt_accounts_no,
                                                            bank_name:
                                                                _addWalletBankTransfer
                                                                    .bank_name,
                                                            currency_id_fro:
                                                                _addWalletBankTransfer
                                                                    .currency_id_fro,
                                                            currency_id_to:
                                                                _addWalletBankTransfer
                                                                    .currency_id_to,
                                                            wallet_accounts_id_fro:
                                                                _addWalletBankTransfer
                                                                    .wallet_accounts_id_fro,
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Expanded(
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          _getImage(ImageSource
                                                              .gallery);
                                                        },
                                                        child: const AppButton(
                                                          icon: Icons
                                                              .image_outlined,
                                                          text: "Upload",
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          _getImage(ImageSource
                                                              .camera);
                                                        },
                                                        child: const AppButton(
                                                          icon: Icons
                                                              .document_scanner_rounded,
                                                          text: "Capture",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 10),
                                            if (_isLoading1)
                                              const Center(
                                                child:
                                                LogoandSpinner(
                                                  imageAssets:
                                                  'assets/asalicon.png',
                                                  reverse: true,
                                                  arcColor: primaryColor,
                                                  spinSpeed: Duration(
                                                      milliseconds: 500),
                                                )

                                                    // CircularProgressIndicator(),
                                              )
                                            else
                                              AllformFields(
                                                ctr: AccountNumber,
                                                focusNode: _AccountNumber,
                                                keyboardType:
                                                    TextInputType.number,
                                                textInputAction:
                                                    TextInputAction.next,
                                                validator: (value) {
                                                  if (_submitted &&
                                                      value!.isEmpty) {
                                                    return 'AccountNumber Field is Required';
                                                  }
                                                  return null;
                                                },
                                                // ctr: cardHolderName,
                                                hintxt: "Enter Account Number",
                                                icn: Icons.amp_stories,
                                                onChanged: (value) async {
                                                  ReceiverAccount = value;
                                                  print("value11111111111111");
                                                  print(value);

                                                  //todo filledFullName;
                                                  // RecipientName.text = "${TransFerD.CusAccountCurrencyRC[0].f_name} ${TransFerD.CusAccountCurrencyRC[0].m_name}";
                                                  // ToAccountID = _getDefaultSelectedValueRC(
                                                  //         TransFerD);
                                                  RecieverAccountNumber =
                                                      CusAccountCurrency
                                                          .CusAccountCurrencyRC[
                                                              0]
                                                          .wallet_accounts_id!;
                                                  setState(() {
                                                    _isLoadingDrop_data = false;
                                                    print(
                                                        "RecieverAccountNumber");
                                                    print(
                                                        RecieverAccountNumber);
                                                  });
                                                  print(accounholder.text);
                                                  _addWalletBankTransfer =
                                                      WalletBankTransfer(
                                                    country_id:
                                                        _addWalletBankTransfer
                                                            .country_id,
                                                    // acc_holder_name:
                                                    //     accounholder.text
                                                    //         .trim(),
                                                    acc_holder_name:
                                                        _addWalletBankTransfer
                                                            .acc_holder_name,
                                                    acc_holder_phone:
                                                        _addWalletBankTransfer
                                                            .acc_holder_phone,
                                                    amount_fro:
                                                        _addWalletBankTransfer
                                                            .amount_fro,
                                                    amt_accounts_no: value,
                                                    bank_name:
                                                        _addWalletBankTransfer
                                                            .bank_name,
                                                    currency_id_fro:
                                                        _addWalletBankTransfer
                                                            .currency_id_fro,
                                                    currency_id_to:
                                                        _addWalletBankTransfer
                                                            .currency_id_to,
                                                    wallet_accounts_id_fro:
                                                        _addWalletBankTransfer
                                                            .wallet_accounts_id_fro,
                                                  );
                                                  // }
                                                },
                                              ),
                                            const SizedBox(height: 10),
                                            AllformFields(
                                                ctr: Phone_Number,
                                                focusNode: _Phone_Number,
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.next,
                                                validator: (value) {
                                                  if (_submitted &&
                                                      value!.isEmpty) {
                                                    return 'PhoneNumber Field is Required';
                                                  }
                                                  return null;
                                                },
                                                // ctr: cardHolderName,
                                                hintxt: "Enter Phone Number",
                                                icn: Icons.phone_iphone,
                                                onChanged: (value) {
                                                  print("ReceiverAccount11222");
                                                  print(ReceiverAccount);
                                                  _addWalletBankTransfer =
                                                      WalletBankTransfer(
                                                    country_id:
                                                        _addWalletBankTransfer
                                                            .country_id,
                                                    acc_holder_name:
                                                        _addWalletBankTransfer
                                                            .acc_holder_name,
                                                    acc_holder_phone: value,
                                                    amount_fro:
                                                        _addWalletBankTransfer
                                                            .amount_fro,
                                                    amt_accounts_no:
                                                        _addWalletBankTransfer
                                                            .amt_accounts_no,
                                                    bank_name:
                                                        _addWalletBankTransfer
                                                            .bank_name,
                                                    currency_id_fro:
                                                        _addWalletBankTransfer
                                                            .currency_id_fro,
                                                    currency_id_to:
                                                        _addWalletBankTransfer
                                                            .currency_id_to,
                                                    wallet_accounts_id_fro:
                                                        _addWalletBankTransfer
                                                            .wallet_accounts_id_fro,
                                                  );
                                                }),
                                            const SizedBox(height: 10),
                                            const Text(
                                              "Account Currency",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: secondryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 4,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      AllinOneDropdownSearch(
                                                        onChanged:
                                                            (value) async {
                                                          currencyId = value;
                                                          print(currencyId);
                                                          if (amount_fro
                                                              .isNotEmpty) {
                                                            result = await Provider.of<
                                                                        Walletremit>(
                                                                    context,
                                                                    listen:
                                                                        false)
                                                                .getAsalExchange(
                                                                    widget
                                                                        .country
                                                                        .toString(),
                                                                    currencyId
                                                                        .toString(),
                                                                    amount_fro
                                                                        .toString(),
                                                              partiner_id.toString(),
                                                            );
                                                            setState(() {
                                                              print('amount');
                                                              print(result[
                                                                          'result']
                                                                      [
                                                                      'amount_to']
                                                                  .toString());
                                                              Reciveamount = result[
                                                                          'result']
                                                                      [
                                                                      'amount_to']
                                                                  .toStringAsFixed(
                                                                      2);
                                                              currency_name_to =
                                                                  result['result']
                                                                          [
                                                                          'currency_name_to']
                                                                      .toString();
                                                              currency_id_to =
                                                                  result['result']
                                                                          [
                                                                          'currency_id_to']
                                                                      .toString();
                                                              print('amount');
                                                            });
                                                          }
                                                          setState(() {
                                                            print("currencyId");
                                                            print(currencyId);
                                                            _addWalletBankTransfer =
                                                                WalletBankTransfer(
                                                              country_id:
                                                                  _addWalletBankTransfer
                                                                      .country_id,
                                                              acc_holder_name:
                                                                  _addWalletBankTransfer
                                                                      .acc_holder_name,
                                                              acc_holder_phone:
                                                                  _addWalletBankTransfer
                                                                      .acc_holder_phone,
                                                              amount_fro:
                                                                  _addWalletBankTransfer
                                                                      .amount_fro,
                                                              amt_accounts_no:
                                                                  _addWalletBankTransfer
                                                                      .amt_accounts_no,
                                                              bank_name:
                                                                  _addWalletBankTransfer
                                                                      .bank_name,
                                                              currency_id_fro:
                                                                  currencyId,
                                                              currency_id_to:
                                                                  _addWalletBankTransfer
                                                                      .currency_id_to,
                                                              wallet_accounts_id_fro:
                                                                  _addWalletBankTransfer
                                                                      .wallet_accounts_id_fro,
                                                            );
                                                          });
                                                        },
                                                        hintxt:
                                                            "Search Currency",
                                                        maintext:
                                                            "Pick Currency",
                                                        items: CusAccountCurrency
                                                            .CusAccountCurrency,
                                                        dropdownValue:
                                                            currencyId,
                                                        SearchCtr:
                                                            Currencysearch,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 20,
                                                ),
                                                const Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "0.000",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            AllformFields(
                                              ctr: Amount,
                                              focusNode: _Amount,
                                              // keyboardType:
                                              //     TextInputType.number,
                                              keyboardType: Platform.isIOS?
                                              const TextInputType.numberWithOptions(signed: true, decimal: true)
                                                  : TextInputType.number,
                                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
                                              textInputAction:
                                                  TextInputAction.done,
                                              validator: (value) {
                                                if (_submitted &&
                                                    value!.isEmpty) {
                                                  return 'Amount Field is Required';
                                                }
                                                return null;
                                              },
                                              hintxt: "Enter Amount",
                                              // icn: Icons.attach_money_sharp,
                                              onEditingComplete: () async {
                                                var CurrencyDataFrom = Provider
                                                        .of<FillRegisterationDropdown>(
                                                            context,
                                                            listen: false)
                                                    .findByIdTC(
                                                        currencyId.toString());

                                                result = await Provider.of<
                                                            Walletremit>(
                                                        context,
                                                        listen: false)
                                                    .getAsalExchange(
                                                  widget.country.toString(),
                                                  currencyId.toString(),
                                                  fieldValue.toString(),
                                                  partiner_id.toString(),
                                                );
                                                setState(() {
                                                  currency_name_from =
                                                      CurrencyDataFrom.name;
                                                  print('amount');
                                                  print(result['result']
                                                          ['amount_to']
                                                      .toString());
                                                  Reciveamount =
                                                      result['result']
                                                              ['amount_to']
                                                          .toStringAsFixed(3);
                                                  currency_name_to = result[
                                                              'result']
                                                          ['currency_name_to']
                                                      .toString();
                                                  currency_id_to =
                                                      result['result']
                                                              ['currency_id_to']
                                                          .toString();
                                                  print('amount');
                                                  amount_fro = fieldValue;
                                                  _addWalletBankTransfer =
                                                      WalletBankTransfer(
                                                    country_id: widget.country,
                                                    acc_holder_name:
                                                        _addWalletBankTransfer
                                                            .acc_holder_name,
                                                    acc_holder_phone:
                                                        _addWalletBankTransfer
                                                            .acc_holder_phone,
                                                    amount_fro: fieldValue,
                                                    amt_accounts_no:
                                                        ReceiverAccount,
                                                    bank_name:
                                                        _addWalletBankTransfer
                                                            .bank_name,
                                                    currency_id_fro: currencyId,
                                                    currency_id_to:
                                                        currency_id_to,
                                                    wallet_accounts_id_fro:
                                                        widget
                                                            .wallet_accounts_id,
                                                  );
                                                });
                                                _Amount.unfocus();
                                              },
                                              onChanged: (value) {
                                                fieldValue = value;
                                              },
                                            ),
                                            const SizedBox(height: 10),

                                            Text(
                                              // "${currency_name_to} ${Reciveamount}",
                                              "$currency_name_to $Reciveamount",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            isConnected
                                                ? Center(
                                                  child: _isLoading
                                                      ?
                                                  // CircularProgressIndicator()
                                                  const LogoandSpinner(
                                                    imageAssets:
                                                    'assets/asalicon.png',
                                                    reverse: true,
                                                    arcColor: primaryColor,
                                                    spinSpeed: Duration(
                                                        milliseconds: 500),
                                                  )
                                                      : InkWell(
                                                          child: const CommonBtn(
                                                              txt: "Send"),
                                                          onTap: () {
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
                                                            _showMyDialogConfirmPin();
                                                          },
                                                        ),
                                                )
                                                : Center(
                                                    child: Text(
                                                        'Network Status: $statusText'),
                                                  ),
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
