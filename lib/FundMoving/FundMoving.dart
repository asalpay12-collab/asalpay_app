import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/models/http_exception.dart';
// import 'package:asalpay/providers/WalletOperations.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllWalletOperationDropDown.dart';
import 'package:asalpay/widgets/CommonTextView.dart';
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
import '../constants/Constant.dart';
import 'dart:io' show Platform;

import 'package:asalpay/providers/TransferOperations.dart';

class FundMoving extends StatefulWidget {
  final String? wallet_accounts_id;
  const FundMoving({super.key, this.wallet_accounts_id});
  @override
  State<FundMoving> createState() => _FundMovingState();
}

class _FundMovingState extends State<FundMoving> {
  String? CurrencyTo;

  @override


  String? CurrencyFrom;
  TextEditingController CurrencyToSearchController =
      TextEditingController();
  TextEditingController CurrencyFromSearchController =
      TextEditingController();
  TextEditingController SendAmount = TextEditingController();
  TextEditingController AmountReceive = TextEditingController();

  var result;
  String amountReceive = "";
  String api_rate = "";
  String com_rate = "";
  String com_value = "";
  String currency_name_fro = "";
  String currency_name_to = "";
  bool _isLoadingDrop_data = false;
  final bool _isLoadingproDrop = false;
  bool _isLoading = false;
  bool isConnected = false;
  late String? statusText = "";
  late String? SavingCurrency = "";

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    setState(() {
      _isLoadingDrop_data = true;
    });
    await Provider.of<TransferOperations>(context, listen: false)
        .fetchAndSetFillFundMovingCustomerCurrency(
            widget.wallet_accounts_id.toString(), "")
        .then((_) {});

    await Provider.of<TransferOperations>(context, listen: false)
        .fetchAndSetFillFundMovingAccountSaving(
            widget.wallet_accounts_id.toString(), "")
        .then((_) {});

    setState(() {
      _isLoadingDrop_data = false;
      final FillDD = Provider.of<TransferOperations>(context, listen: false);
      print('FillDD: $FillDD');
      CurrencyTo = _getDefaultSelectedValuesaving(FillDD);
      CurrencyFrom = _getDefaultSelectedValuecurrent(FillDD);
    });
  }

  var _addSaveFundMovingRegistration = SaveFundMovingRegistration(
    current_account_no: " ",
    balance_type_id_fro: " ",
    balance_type_id_to: " ",
    amount_fro: " ",
    amount_to: " ",
    api_rate: " ",
    com_rate: " ",
    com_value: " ",
    currency_to_id: " ",
    currency_fro_id: " ",
  );


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
    _submitted = true;
    final isValid = _form.currentState?.validate();
    if (!isValid!) {
      return;
    }
    _form.currentState?.save();

    setState(() {
      _isLoading = true;
    });
    var errorMessage = 'successfully moved!';
    try {
      await Provider.of<TransferOperations>(context, listen: false)
          .addSaveFundMovingRegistration(
              _addSaveFundMovingRegistration, widget.wallet_accounts_id!);
    } on HttpException catch (error) {
      if (error.toString().contains('this account is not exist')) {
      } else if (error
          .toString()
          .contains('Email is already exit another Email')) {
      } else if (error.toString().contains('this account is not Active')) {
      } else if (error.toString().contains(
          'your balance is less than the amount you want to  sent it')) {
        errorMessage = 'operation failed .';
      } else if (error.toString().contains('OP')) {
        errorMessage = 'operation failed .';
      }
      print(error.toString());
      print('hello welcome');
// _showErrorDialog(error.toString());
//       openSnackbar(context, error.toString(), secondryColor);
    } catch (error) {
// _showErrorDialog(error.toString());
      openSnackbar(context, error.toString(), secondryColor);
      setState(() {
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = false;
    });
    _submitted = false;
    AmountReceive.text = "";
    SendAmount.text = "";
    openSnackbar(context, errorMessage.toString(), secondryColor);

  }

  String? _getDefaultSelectedValuesaving(TransferOperations fillDD) {
    if (fillDD.FillFundMovingAccountSaving.isNotEmpty) {
      return fillDD.FillFundMovingAccountSaving[0].currency_id;
    }
    return null;
  }

  String? _getDefaultSelectedValuecurrent(TransferOperations fillDD) {
    if (fillDD.FundMovingFillCustomerCurrency.isNotEmpty) {
      return fillDD.FundMovingFillCustomerCurrency[0].currency_id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final FillDD = Provider.of<TransferOperations>(context, listen: false);
    String? defaultSelectedValue = _getDefaultSelectedValuesaving(FillDD);
    String? defaultSelectedValue2 = _getDefaultSelectedValuecurrent(FillDD);


        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Optionally handle the waiting state
              return Center(child: CircularProgressIndicator());
            }

            bool isConnected = false; // Default to not connected

            if (snapshot.hasData && snapshot.data != null) {
              List<ConnectivityResult> results = snapshot.data!;

              // Determine if connected by checking if the list contains any connection other than 'none'
              isConnected = results.any((result) => result != ConnectivityResult.none);
            } else {
              // Handle the case where there's no data
              isConnected = false;
            }

            String statusText = isConnected ? 'Connected' : 'No Internet Connection';
            final icon = isConnected ? null : const Icon(Icons.wifi);

            if (!isConnected) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _NetworkMessage(context);
              });
            }

        return Scaffold(
          backgroundColor: secondryColor.withOpacity(0.9),
          body: Padding(
            padding: EdgeInsets.only(
              top: AppBar().preferredSize.height,
              left: 15,
              right: 15,
            ),
            child: Form(
              key: _form,
              // autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        "Fund Moving",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Column(
                          children: [
                            const SizedBox(
                              height: 20,
                            ),

                            //Image;
                            Container(
                              height: 220,
                              decoration: const BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage("assets/asalpayscreens.png"))),
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
                                child: FillDD
                                        .FillFundMovingAccountSaving.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  const Text(
                                                    "From Current",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: secondryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 4,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            //todo:currencyFrom
                                                            AllWalletOperationDropDown(
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  CurrencyFrom =
                                                                      value;
                                                                });
                                                                _addSaveFundMovingRegistration =
                                                                    SaveFundMovingRegistration(
                                                                  current_account_no:
                                                                      _addSaveFundMovingRegistration
                                                                          .current_account_no,
                                                                  balance_type_id_fro:
                                                                      _addSaveFundMovingRegistration
                                                                          .balance_type_id_fro,
                                                                  balance_type_id_to:
                                                                      _addSaveFundMovingRegistration
                                                                          .balance_type_id_to,
                                                                  amount_fro:
                                                                      _addSaveFundMovingRegistration
                                                                          .amount_fro,
                                                                  amount_to:
                                                                      _addSaveFundMovingRegistration
                                                                          .amount_to,
                                                                  api_rate:
                                                                      _addSaveFundMovingRegistration
                                                                          .api_rate,
                                                                  com_rate:
                                                                      _addSaveFundMovingRegistration
                                                                          .com_rate,
                                                                  com_value:
                                                                      _addSaveFundMovingRegistration
                                                                          .com_value,
                                                                  currency_to_id:
                                                                      _addSaveFundMovingRegistration
                                                                          .currency_to_id,
                                                                  currency_fro_id:
                                                                      value,
                                                                );
                                                              },
                                                              hintxt:
                                                                  "Search Currency",
                                                              maintext:
                                                                  "Pick any Currency",
                                                              TransferItems: FillDD
                                                                  .FundMovingFillCustomerCurrency,
                                                              dropdownValue:
                                                                  CurrencyFrom,
                                                              SearchCtr:
                                                                  CurrencyFromSearchController,
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
                                                                color: Color(
                                                                    0xFFF15C2F),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                  AllformFields(
                                                    ctr: SendAmount,
                                                    hintxt: "Amount Send",
                                                    icn: Icons
                                                        .attach_money_sharp,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    validator: (value) {
                                                      if (_submitted &&
                                                          value!.isEmpty) {
                                                        return 'Amount Field is Required';
                                                      }
                                                      return null;
                                                    },
                                                    onChanged: (value) async {
                                                      print(
                                                          "Hello Transfer Amount");
                                                      print(value);
                                                      print(CurrencyTo
                                                          .toString());
                                                      var CurrencyDataFrom = Provider
                                                              .of<TransferOperations>(
                                                                  context,
                                                                  listen: false)
                                                          .findByTypeCurrent(
                                                              CurrencyFrom
                                                                  .toString());
                                                      print(CurrencyDataFrom
                                                          .currency_name
                                                          .toString());
                                                      var CurrencyDataTo = Provider
                                                              .of<TransferOperations>(
                                                                  context,
                                                                  listen: false)
                                                          .findByTypeSaving(
                                                              CurrencyTo
                                                                  .toString());
                                                      var BalanceTypeDataTo = Provider
                                                              .of<TransferOperations>(
                                                                  context,
                                                                  listen: false)
                                                          .findByTypeSaving(
                                                              CurrencyTo
                                                                  .toString());
                                                      var BalanceTypeDataFrom =
                                                          Provider.of<TransferOperations>(
                                                                  context,
                                                                  listen: false)
                                                              .findByTypeCurrent(
                                                                  CurrencyFrom
                                                                      .toString());
                                                      print("CurrencyDataFrom");
                                                      print(CurrencyDataFrom
                                                          .currency_name);
                                                      print("CurrencyDataTo");
                                                      print(CurrencyDataTo
                                                          .currency_name);

                                                      print(
                                                          "BalanceTypeIDFrom");
                                                      print(BalanceTypeDataFrom
                                                          .typeID);
                                                      print(BalanceTypeDataFrom
                                                          .typeName);
                                                      print("BalanceTypeIDTO");
                                                      print(BalanceTypeDataTo
                                                          .typeID);
                                                      print(BalanceTypeDataTo
                                                          .typeName);
                                                      if (value.isNotEmpty) {
                                                        if (CurrencyFrom
                                                                .toString() !=
                                                            CurrencyTo
                                                                .toString()) {
                                                          result = await Provider.of<
                                                                      TransferOperations>(
                                                                  context,
                                                                  listen: false)
                                                              .TransferExchange(
                                                            value,
                                                            CurrencyDataTo
                                                                .currency_name
                                                                .toString(),
                                                            CurrencyDataFrom
                                                                .currency_name
                                                                .toString(),
                                                            CurrencyTo
                                                                .toString(), //ToAccountID
                                                            CurrencyFrom
                                                                .toString(), //FromAccountID
                                                          );
                                                          setState(() {
                                                            amountReceive =
                                                                result['resultAmount']
                                                                    .toString();
                                                            AmountReceive.text =
                                                                "$currency_name_to $amountReceive"
                                                                    .toString();
                                                            currency_name_to =
                                                                result['apiResult']
                                                                            [
                                                                            'query']
                                                                        ['to']
                                                                    .toString();
                                                            api_rate =
                                                                result['apiResult']
                                                                            [
                                                                            'info']
                                                                        [
                                                                        'quote']
                                                                    .toString();
                                                            com_rate = result[
                                                                    'commissionAmount']
                                                                .toString();
                                                            com_value = result[
                                                                    'commissionAmount']
                                                                .toString();
                                                            // Reciveamount = result['result']
                                                            // ['amount_to'].toStringAsFixed(2);
                                                            print(
                                                                amountReceive);
                                                          });
                                                        } else {
                                                          setState(() {
                                                            print(
                                                                "Hello Exchange Amount $value");
                                                            amountReceive =
                                                                value;
                                                            AmountReceive.text =
                                                                "${CurrencyDataFrom.currency_name} $amountReceive";
                                                            print(
                                                                "Hello Exchange amountReceive $amountReceive");
                                                          });
                                                        }
                                                      } else {
                                                        setState(() {
                                                          amountReceive = "000";
                                                        });
                                                      }
                                                      print(
                                                          "Value of Amount From");
                                                      print(value);
                                                      _addSaveFundMovingRegistration =
                                                          SaveFundMovingRegistration(
                                                        current_account_no: widget
                                                            .wallet_accounts_id,
                                                        balance_type_id_fro:
                                                            BalanceTypeDataFrom
                                                                .typeID,
                                                        balance_type_id_to:
                                                            BalanceTypeDataTo
                                                                .typeID,
                                                        amount_fro: value,
                                                        amount_to:
                                                            amountReceive,
                                                        api_rate: api_rate,
                                                        com_rate: com_rate,
                                                        com_value: com_value,
                                                        currency_to_id:
                                                            CurrencyTo,
                                                        currency_fro_id:
                                                            CurrencyFrom,
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  const Text(
                                                    "To Saving Account",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: secondryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  //todo:CurrencyTo

                                                  AllWalletOperationDropDown(
                                                    onChanged: (value) {
                                                      setState(() {
                                                        CurrencyTo = value;
                                                      });
                                                      _addSaveFundMovingRegistration =
                                                          SaveFundMovingRegistration(
                                                        current_account_no:
                                                            _addSaveFundMovingRegistration
                                                                .current_account_no,
                                                        balance_type_id_fro:
                                                            _addSaveFundMovingRegistration
                                                                .balance_type_id_fro,
                                                        balance_type_id_to:
                                                            _addSaveFundMovingRegistration
                                                                .balance_type_id_to,
                                                        amount_fro:
                                                            _addSaveFundMovingRegistration
                                                                .amount_fro,
                                                        amount_to:
                                                            _addSaveFundMovingRegistration
                                                                .amount_to,
                                                        api_rate:
                                                            _addSaveFundMovingRegistration
                                                                .api_rate,
                                                        com_rate:
                                                            _addSaveFundMovingRegistration
                                                                .com_rate,
                                                        com_value:
                                                            _addSaveFundMovingRegistration
                                                                .com_value,
                                                        currency_to_id: value,
                                                        currency_fro_id:
                                                            _addSaveFundMovingRegistration
                                                                .currency_fro_id,
                                                      );
                                                    },
                                                    hintxt: "Search Currency",
                                                    maintext:
                                                        "Pick any Currency",
                                                    TransferItems: FillDD
                                                        .FillFundMovingAccountSaving,
                                                    SearchCtr:
                                                        CurrencyToSearchController,
                                                    dropdownValue: CurrencyTo,
                                                  ),

                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                  CommonTextView(
                                                    ctr: AmountReceive,
                                                    hintxt: "Receiving amount",
                                                    icn: Icons
                                                        .attach_money_sharp,
                                                  ),

                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  isConnected
                                                      ? _isLoading
                                                          ? const Center(
                                                              child:
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
                                                                _showMyDialogConfirmPin();
                                                              },
                                                              child: const CommonBtn(
                                                                  txt:
                                                                      "Proccess"),
                                                            )
                                                      : Center(
                                                        child: Center(
                                                          child: Text(
                                                              'Network Status: $statusText'),
                                                        ),
                                                      ),
                                                  const SizedBox(
                                                    height: 30,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(
                                        width: 400,
                                        height: 300,
                                        child: Center(
                                          child: Text(
                                            "You can open a Savings Account easily!",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: secondryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
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
