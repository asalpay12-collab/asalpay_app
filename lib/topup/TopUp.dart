import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/constants/Constant.dart';
//import 'package:asalpay/providers/WalletOperations.dart';
import 'package:asalpay/providers/TransferOperations.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllWalletOperationDropDown.dart';
import 'package:asalpay/widgets/commonBtn.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key, });
  static const routeName = '/TopUpScreen';

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  String? FromAccountID;
  String? ToAccountID;
  String? BankAccountsID;
  final _TopUpAmount = FocusNode();
  final _TopUpReference = FocusNode();
  final _TopUpProvidername = FocusNode();
  TextEditingController TopupAmount = TextEditingController();
  TextEditingController Provider_Name = TextEditingController();
  TextEditingController TopupReference = TextEditingController();
  TextEditingController FromAccountIDSeach = TextEditingController();
  TextEditingController BankAccountsIDSeach = TextEditingController();
  TextEditingController ToAccountIDSearch = TextEditingController();
  bool _isLoadingDrop_data = false;
  final bool _isLoadingproDrop = false;
  bool _isLoading = false;
  bool isConnected = true;
  late String? statusText = "";

  var _addSaveTopUpRegistration = SaveTopUpRegistration(
    reference: " ",
    provider_name: " ",
    currency_fro_id: " ",
    bank_account_no: " ",
    amount_to: " ",
    amount_fro: "",
    currency_to_id: "",
    account_no: " ",
  );

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<Auth>(context, listen: false);
    setState(() {
      auth.autoLogout(context);
    });
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
            child: const Text('Okay', style: TextStyle(color: primaryColor)),
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
    setState(() {
      isloading1 = true;
      ModelErrorMessage = "";
      print("setState");
      print(isloading1);
    });
    var errorMessage = 'successfully Sent!';
    try {
      final auth = Provider.of<Auth>(context, listen: false);
      await Provider.of<HomeSliderAndTransaction>(context, listen: false).LoginPIN(
        auth.phone!,
        pinNumber,
      );
      print('CheckPhoneNumberAndPinNumberand');
      print(auth.phone!);
      print(pinNumber);
    } on HttpException catch (error) {
      if (error.toString().contains('INVALID_PHONE')) {
        errorMessage = 'Could not find a user with that phone .';
        ModelErrorMessage = errorMessage;
        _showErrorDialog(error.toString());
        return;
      } else if (error.toString().contains('INVALID_PIN')) {
        errorMessage = 'Invalid password.';
        ModelErrorMessage = errorMessage;
        print("ModelErrorMessage");
        print(ModelErrorMessage);
        return;
      } else if (error.toString().contains('INACTIVE_ACCOUNT')) {
        errorMessage = 'Your Account Is not Active.';
        ModelErrorMessage = errorMessage;
        return;
      } else if (error.toString().contains('OP')) {
        errorMessage = 'operation failed .';
        ModelErrorMessage = errorMessage;
        return;
      }
      print(error.toString());
      print('hello welcome');
      return;
    } catch (error) {
      print("ModelErrorMessage");
      setState(() {
        ModelErrorMessage = error.toString();
      });
      print(ModelErrorMessage);
      _showErrorDialog(error.toString());
      setState(() {
        isloading1 = false;
        print("setState");
        print(isloading1);
      });
      return;
    }
    setState(() {
      isloading1 = false;
      print("setState");
      print(isloading1);
    });
    _submitted1 = false;
    ModelErrorMessage = "";
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
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 20),
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
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16),
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
                Center(
                  child: isloading1
                      ? const LogoandSpinner(
                          imageAssets: 'assets/asalicon.png',
                          reverse: true,
                          arcColor: primaryColor,
                          spinSpeed: Duration(milliseconds: 500),
                        )
                      : InkWell(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            if (_submitted == false) {
                              Navigator.pop(context);
                            } else {
                              _CheckPinNumber();
                            }
                          },
                          child: const CommonBtn(txt: "Confirm Pin"),
                        ),
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
  _submitted = true;

  // 1. Validate form
  final isValid = _form.currentState?.validate();
  if (!isValid!) {
    return;
  }
  _form.currentState?.save();

  setState(() {
    _isLoading = true;
  });

  var errorMessage = 'Successfully Requested!';

  // 2. Check Internet Connectivity
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    setState(() {
      _isLoading = false;
    });
    openSnackbar(context, 'No Internet Connection', secondryColor);
    return;
  }

  // 3. Attempt to save top-up registration
  try {
    await Provider.of<TransferOperations>(context, listen: false)
        .addSaveTopUpRegistration(_addSaveTopUpRegistration, "");
  } on HttpException catch (error) {
    if (error.toString().contains('this account is not exist')) {
      errorMessage = 'This account does not exist.';
    } else if (error.toString().contains('Email is already exit another Email')) {
      errorMessage = 'Email is already in use.';
    } else if (error.toString().contains('this account is not Active')) {
      errorMessage = 'This account is not active.';
    } else if (error.toString().contains('Insufficient balance')) {
      errorMessage = 'Operation failed: Insufficient balance.';
    } else if (error.toString().contains('OP')) {
      errorMessage = 'Operation failed.';
    }

    print('HTTP Exception: $error');
    openSnackbar(context, errorMessage, secondryColor);

    setState(() {
      _isLoading = false;
    });
    return;
  } catch (error) {
    print('Error: $error');
    openSnackbar(context, error.toString(), secondryColor);

    setState(() {
      _isLoading = false;
    });
    return;
  }

  // 4. Fetch and update transactions after successful request
  try {
    await Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .fetchAndSetAllTr();
  } catch (error) {
    print('Error fetching transaction data: $error');
  }

  // 5. Reset form fields and show success message
  setState(() {
    _isLoading = false;
  });
  _submitted = false;
  TopupAmount.text = "";
  Provider_Name.text = "";
  TopupReference.text = "";

  openSnackbar(context, errorMessage, secondryColor);
}

  // Future<void> _saveForm() async {
  //   _submitted = true;
  //   final isValid = _form.currentState?.validate();
  //   if (!isValid!) {
  //     return;
  //   }
  //   _form.currentState?.save();
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   var errorMessage = 'Successfully Requested!';
  //   try {
  //     await Provider.of<TransferOperations>(context, listen: false)
  //         .addSaveTopUpRegistration(_addSaveTopUpRegistration, "");
  //   } on HttpException catch (error) {
  //     if (error.toString().contains('this account is not exist')) {
  //     } else if (error.toString().contains('Email is already exit another Email')) {
  //     } else if (error.toString().contains('this account is not Active')) {
  //     } else if (error.toString().contains('Insufficient balance')) {
  //       errorMessage = 'operation failed .';
  //     } else if (error.toString().contains('OP')) {
  //       errorMessage = 'operation failed .';
  //     }
  //     print(error.toString());
  //     print('hello welcome');
  //   } catch (error) {
  //     openSnackbar(context, error.toString(), secondryColor);
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     return;
  //   }
  //   setState(() {
  //     _isLoading = false;
  //   });
  //   await Provider.of<HomeSliderAndTransaction>(context, listen: false)
  //       .fetchAndSetAllTr()
  //       .then((_) {});
  //   _submitted = false;
  //   TopupAmount.text = "";
  //   Provider_Name.text = "";
  //   TopupReference.text = "";
  //   openSnackbar(context, errorMessage.toString(), secondryColor);
  // }

  String? _getDefaultSelectedValue(TransferOperations TransFerD) {
    if (TransFerD.CusAccountCurrencyFC.isNotEmpty) {
      return TransFerD.CusAccountCurrencyFC[0].currency_id;
    }
    return null;
  }

  String? _getDefaultSelectedValue1(TransferOperations TransFerD) {
    if (TransFerD.FillTopupAccount.isNotEmpty) {
      return TransFerD.FillTopupAccount[0].currency_id;
    }
    return null;
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    setState(() {
      _isLoadingDrop_data = true;
    });
    await Provider.of<TransferOperations>(context, listen: false)
        .fetchAndSetCusAccountCurrencyFC("")
        .then((_) {});
    await Provider.of<TransferOperations>(context, listen: false)
        .fetchAndSetTopUpBankAccounts()
        .then((_) {});
    setState(() {
      _isLoadingDrop_data = false;
      final TransFerD = Provider.of<TransferOperations>(context, listen: false);
      print('FillDD: $TransFerD');
      ToAccountID = _getDefaultSelectedValue(TransFerD);
      FromAccountID = _getDefaultSelectedValue(TransFerD);
      BankAccountsID = _getDefaultSelectedValue1(TransFerD);
    });
  }

  @override
  Widget build(BuildContext context) {
    final TransFerD = Provider.of<TransferOperations>(context, listen: false);
    String? defaultSelectedValue = _getDefaultSelectedValue(TransFerD);
    String? defaultSelectedValue1 = _getDefaultSelectedValue1(TransFerD);


        return Scaffold(
          backgroundColor: secondryColor,
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
                        color: pureWhite,
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    const Text(
                      "Top up Money",
                      style: TextStyle(color: pureWhite, fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Form(
                        key: _form,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              height: 200,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage("assets/asalpayscreens.png"),
                                ),
                              ),
                            ),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                              children: [
                                                const Text(
                                                  "Accounts",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: secondryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Expanded(child: SizedBox()),
                                                InkWell(
                                                  onTap: () {},
                                                  child: const Row(
                                                    children: [
                                                      Icon(
                                                        Icons.add_circle_outline_rounded,
                                                        color: primaryColor,
                                                        size: 20,
                                                      ),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                        "Add Card",
                                                        style: TextStyle(
                                                          color: primaryColor,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AllWalletOperationDropDown(
                                              onChanged: (value) {
                                                setState(() {
                                                  BankAccountsID = value;
                                                  print('BankAccountsID: $BankAccountsID');
                                                });
                                                _addSaveTopUpRegistration = SaveTopUpRegistration(
                                                  reference: _addSaveTopUpRegistration.reference,
                                                  provider_name: _addSaveTopUpRegistration.provider_name,
                                                  currency_fro_id: _addSaveTopUpRegistration.currency_fro_id,
                                                  bank_account_no: value,
                                                  amount_to: _addSaveTopUpRegistration.amount_to,
                                                  amount_fro: _addSaveTopUpRegistration.amount_fro,
                                                  currency_to_id: _addSaveTopUpRegistration.currency_to_id,
                                                  account_no: "",
                                                );
                                              },
                                              SearchCtr: BankAccountsIDSeach,
                                              hintxt: "Search bank",
                                              maintext: "Select a bank",
                                              TransferItems: TransFerD.FillTopupAccount,
                                              dropdownValue: BankAccountsID,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AllformFields(
                                              keyboardType: TextInputType.name,
                                              focusNode: _TopUpReference,
                                              textInputAction: TextInputAction.next,
                                              ctr: TopupReference,
                                              hintxt: "Enter Topup Reference",
                                              icn: Icons.refresh,
                                              validator: (value) {
                                                if (_submitted && value!.isEmpty) {
                                                  return 'Topup Reference Field is Required';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                _addSaveTopUpRegistration = SaveTopUpRegistration(
                                                  reference: value,
                                                  provider_name: _addSaveTopUpRegistration.provider_name,
                                                  currency_fro_id: _addSaveTopUpRegistration.currency_fro_id,
                                                  bank_account_no: _addSaveTopUpRegistration.bank_account_no,
                                                  amount_to: _addSaveTopUpRegistration.amount_to,
                                                  amount_fro: _addSaveTopUpRegistration.amount_fro,
                                                  currency_to_id: _addSaveTopUpRegistration.currency_to_id,
                                                  account_no: _addSaveTopUpRegistration.account_no,
                                                );
                                              },
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AllformFields(
                                              keyboardType: TextInputType.name,
                                              focusNode: _TopUpProvidername,
                                              textInputAction: TextInputAction.next,
                                              ctr: Provider_Name,
                                              hintxt: "Enter Provider Name",
                                              icn: Icons.person,
                                              validator: (value) {
                                                if (_submitted && value!.isEmpty) {
                                                  return 'Provider Name Field is Required';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                _addSaveTopUpRegistration = SaveTopUpRegistration(
                                                  reference: _addSaveTopUpRegistration.reference,
                                                  provider_name: value,
                                                  currency_fro_id: _addSaveTopUpRegistration.currency_fro_id,
                                                  bank_account_no: _addSaveTopUpRegistration.bank_account_no,
                                                  amount_to: _addSaveTopUpRegistration.amount_to,
                                                  amount_fro: _addSaveTopUpRegistration.amount_fro,
                                                  currency_to_id: _addSaveTopUpRegistration.currency_to_id,
                                                  account_no: _addSaveTopUpRegistration.account_no,
                                                );
                                              },
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const Text(
                                              "Currency from",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: secondryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AllWalletOperationDropDown(
                                              onChanged: (value) {
                                                setState(() {
                                                  FromAccountID = value;
                                                  print('FromAccountID: $FromAccountID');
                                                });
                                                _addSaveTopUpRegistration = SaveTopUpRegistration(
                                                  reference: _addSaveTopUpRegistration.reference,
                                                  provider_name: _addSaveTopUpRegistration.provider_name,
                                                  currency_fro_id: value,
                                                  bank_account_no: _addSaveTopUpRegistration.bank_account_no,
                                                  amount_to: _addSaveTopUpRegistration.amount_to,
                                                  amount_fro: _addSaveTopUpRegistration.amount_fro,
                                                  currency_to_id: value,
                                                  account_no: _addSaveTopUpRegistration.account_no,
                                                );
                                              },
                                              SearchCtr: FromAccountIDSeach,
                                              hintxt: "Search Currency",
                                              maintext: "Select a Currency",
                                              TransferItems: TransFerD.CusAccountCurrencyFC,
                                              dropdownValue: FromAccountID,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AllformFields(
                                              ctr: TopupAmount,
                                              keyboardType: TextInputType.number,
                                              focusNode: _TopUpAmount,
                                              textInputAction: TextInputAction.done,
                                              hintxt: "TopUp Amount",
                                              validator: (value) {
                                                if (_submitted && value!.isEmpty) {
                                                  return 'TopUp Amount Field is Required';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                _addSaveTopUpRegistration = SaveTopUpRegistration(
                                                  reference: _addSaveTopUpRegistration.reference,
                                                  provider_name: _addSaveTopUpRegistration.provider_name,
                                                  currency_fro_id: FromAccountID,
                                                  bank_account_no: BankAccountsID,
                                                  amount_to: value,
                                                  amount_fro: value,
                                                  currency_to_id: ToAccountID,
                                                  account_no: _addSaveTopUpRegistration.account_no,
                                                );
                                              },
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            isConnected
                                                ? Center(
                                                    child: _isLoading
                                                        ? const LogoandSpinner(
                                                            imageAssets: 'assets/asalicon.png',
                                                            reverse: true,
                                                            arcColor: primaryColor,
                                                            spinSpeed: Duration(milliseconds: 500),
                                                          )
                                                        : InkWell(
                                                            onTap: () {
                                                              _submitted = true;
                                                              final isValid = _form.currentState?.validate();
                                                              if (!isValid!) {
                                                                print("valid");
                                                                return;
                                                              }
                                                              _form.currentState?.save();
                                                              _showMyDialogConfirmPin();
                                                            },
                                                            child: const CommonBtn(txt: "Request"),
                                                          ),
                                                  )
                                                : Center(
                                                    child: Text('Network Status: $statusText'),
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

  Future<void> _NetworkMessage(BuildContext context) async {
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
                  backgroundColor: WidgetStateProperty.all<Color>(primaryColor),
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
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
                  backgroundColor: WidgetStateProperty.all<Color>(primaryColor),
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
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
