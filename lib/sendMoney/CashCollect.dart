import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
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
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../TransferReceiptLetter/paymentPage.dart';
import '../constants/Constant.dart';

import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';

class CashCollect extends StatefulWidget {
  final String? wallet_accounts_id;

  final String? country;

  // final String? countryID;
  // final String? cityID;
  const CashCollect({this.wallet_accounts_id, this.country, super.key});
  @override
  State<CashCollect> createState() => _CashCollectState();
}

class _CashCollectState extends State<CashCollect> {
  final _BeneficiaryFullName = FocusNode();
  final _BeneficiaryTelephoneNumber = FocusNode();
  final _AmountNumber = FocusNode();
  TextEditingController BeneficiaryFullName = TextEditingController();
  TextEditingController BeneficiaryTelephoneNumber = TextEditingController();
  TextEditingController AmountNumber = TextEditingController();

  // bool value = false;
  bool _isLoadingDrop_data = false;
  final bool _isLoadingproDrop = false;
  bool _isLoadingproDropbranch = false;
  bool _isLoadingExchange = false;

  String? Country;
  String? Beneficiary;
  String? Branch;
  String? AccountCurrency;
  String? City;
  String? CurrencyID;

  bool isConnected = true;
  late String? statusText = "";

  TextEditingController CitySearchController = TextEditingController();
  TextEditingController CurrencySearchController = TextEditingController();
  TextEditingController CountrySearchController = TextEditingController();
  TextEditingController branchSearchController = TextEditingController();

  String Reciveamount = "000";
  String Commission = "000";
  String charge = "000";
  String sent_amount = "000";

  String amount_to = "000";
  String remittance_comission = "000";
  String remittance_rate = "000";
  // String shortenedAmount = Reciveamount.toStringAsFixed(2);

  String currency_name_to = " ";
  String currency_name_from = " ";
  String currency_name_fro = " ";
  String currency_id_to = "";
  String amount_fro = "";
  String ReceiverAccount = "";
  String ReceiverName = "";
  String fieldValue = '';

  var result;

  var _addSaveCashCollect = SaveCashCollect(
    country_id: " ",
    city_id_to: "",
    branch_to: "",
    currency_fro_id: "",
    amount_from: " ",
    currency_to_id: " ",
    net_payble_amount: "",
    remittance_comission: " ",
    remittance_rate: " ",
    benificary_name: " ",
    beneficiary_phone: " ",
    account_no: " ",
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
      barrierDismissible: true, // user must tap button!
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

  bool _isLoading = false;
  bool _submitted = false;
  final _form = GlobalKey<FormState>();

  Future<void> _saveForm() async {
  // 1. Check connectivity once at the start
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    // No internet -> show snackbar & return early
    openSnackbar(context, 'No Internet Connection', secondryColor);
    return;
  }

  // 2. Continue with your usual form logic if we have an internet connection
  _submitted = true;
  final isValid = _form.currentState?.validate();
  if (isValid == null || !isValid) {
    return;
  }
  _form.currentState?.save();

  setState(() {
    _isLoading = true;
  });

  var errorMessage = 'Successful';

  try {
    await Provider.of<Walletremit>(context, listen: false)
        .addSaveCashCollect(_addSaveCashCollect, widget.wallet_accounts_id!);
  } on HttpException catch (error) {
    // Handle various cases
    if (error.toString().contains('this account is not exist')) {
      // ...
    } else if (error
        .toString()
        .contains('Email is already exit another Email')) {
      // ...
    } else if (error.toString().contains('this account is not Active')) {
      // ...
    } else if (error.toString().contains('Insufficient balance')) {
      errorMessage = 'operation failed .';
    } else if (error.toString().contains('OP')) {
      errorMessage = 'operation failed .';
    }

    // You can optionally show a snackbar for any error condition
    // openSnackbar(context, errorMessage, secondryColor);

    print(error);
    print('hello welcome');
    setState(() {
      _isLoading = false;
    });
    return;
  } catch (error) {
    // _showErrorDialog(error.toString());
    openSnackbar(context, error.toString(), secondryColor);
    setState(() {
      _isLoading = false;
    });
    print(error.toString());
    return;
  }

  setState(() {
    _isLoading = false;
  });

  // Continue if success
  await Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndSetAllTr();

  final displayBalance =
      Provider.of<HomeSliderAndTransaction>(context, listen: false);

  // Possibly another fetch call here
  await Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndSetAllTr();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentPage(
        ReceiverAccount.toString(),
        "Phone",
        ReceiverLabelRec: "Phone",
        ReceiverAmount: currency_name_to + Reciveamount,
        ReceiverName: ReceiverName.toString(),
        senderAccount: widget.wallet_accounts_id!,
        senderAmount: currency_name_from + amount_fro,
        senderName:
            "${displayBalance.DisplayBalance[0].f_name} ${displayBalance.DisplayBalance[0].m_name}",
      ),
    ),
  );

  _submitted = false;
  BeneficiaryFullName.text = " ";
  AmountNumber.text = " ";
  BeneficiaryTelephoneNumber.text = "";

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
  //   var errorMessage = 'Successful';
  //   try {
  //     await Provider.of<Walletremit>(context, listen: false)
  //         .addSaveCashCollect(_addSaveCashCollect, widget.wallet_accounts_id!);
  //   } on HttpException catch (error) {
  //     if (error.toString().contains('this account is not exist')) {
  //     } else if (error
  //         .toString()
  //         .contains('Email is already exit another Email')) {
  //     } else if (error.toString().contains('this account is not Active')) {
  //     } else if (error.toString().contains('Insufficient balance')) {
  //       errorMessage = 'operation failed .';
  //     } else if (error.toString().contains('OP')) {
  //       errorMessage = 'operation failed .';
  //     }

  //     print(error.toString());
  //     print('hello welcome');
  //     // _showErrorDialog(error.toString());
  //     // openSnackbar(context, error.toString(), secondryColor);
  //     return;
  //   } catch (error) {
  //     // _showErrorDialog(error.toString());
  //     openSnackbar(context, error.toString(), secondryColor);
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     print(error.toString());
  //     return;
  //   }
  //   setState(() {
  //     _isLoading = false;
  //   });
  //   await Provider.of<HomeSliderAndTransaction>(context, listen: false)
  //       .fetchAndSetAllTr()
  //       .then((_) {});
  //   final DisplayBalance =
  //       Provider.of<HomeSliderAndTransaction>(context, listen: false);
  //   await Provider.of<HomeSliderAndTransaction>(context, listen: false)
  //       .fetchAndSetAllTr()
  //       .then((_) {});
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //           builder: (context) => PaymentPage(
  //                 // ReceiverAccount: ReciverAccount,
  //                 // ReceiverAccount: RecieverAccountNumber.toString(),
  //                 ReceiverAccount.toString(),
  //                 "Phone",
  //                 ReceiverLabelRec: "Phone",
  //                 ReceiverAmount: currency_name_to + Reciveamount,
  //                 ReceiverName: ReceiverName.toString(),
  //                 // ReceiverName: "${CusAccountCurrency.CusAccountCurrencyRC[0].f_name} ${CusAccountCurrency.CusAccountCurrencyRC[0].m_name}",
  //                 senderAccount: widget.wallet_accounts_id!,
  //                 senderAmount: currency_name_from + amount_fro,
  //                 senderName: "${DisplayBalance.DisplayBalance[0].f_name}" " ${DisplayBalance.DisplayBalance[0].m_name}",
  //               )));
  //   _submitted = false;
  //   BeneficiaryFullName.text = " ";
  //   AmountNumber.text = " ";
  //   BeneficiaryTelephoneNumber.text = "";
  //   openSnackbar(context, errorMessage.toString(), secondryColor);
  // }

  @override
  Future<void> didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    setState(() {
      _isLoadingDrop_data = true;
    });
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetRemitCountries()
        .then((_) {});
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetCusAccountCurrency(widget.wallet_accounts_id.toString())
        .then((_) {});
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetRemitCities(widget.country!);

    final DDCash =
        Provider.of<FillRegisterationDropdown>(context, listen: false);
    setState(() {
      _isLoadingDrop_data = false;
      print('CusAccountCurrency: $DDCash');
      City = _getDefaultSelectedValue(DDCash);
      CurrencyID = _getDefaultSelectedCash(DDCash);
      print("currencyId $CurrencyID");
      // RemitChannel = _getDefaultSelectedBeneficiaryBank(RemitChannelTypes);
    });
    setState(() {
      _isLoadingproDropbranch = true;
    });
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetRemitBranches(City!);
    setState(() {
      _isLoadingproDropbranch = false;
      Branch = _getDefaultSelectedBranch(DDCash);
    });
  }

  String? _getDefaultSelectedValue(FillRegisterationDropdown DDCash) {
    if (DDCash.RemitCity.isNotEmpty) {
      return DDCash.RemitCity[0].id;
    }
    return null;
  }

  String? _getDefaultSelectedCash(FillRegisterationDropdown DDCash) {
    if (DDCash.CusAccountCurrency.isNotEmpty) {
      return DDCash.CusAccountCurrency[0].id;
    }
    return null;
  }

  String? _getDefaultSelectedBranch(FillRegisterationDropdown DDCash) {
    if (DDCash.RemitBranches.isNotEmpty) {
      return DDCash.RemitBranches[0].id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final DDCash =
        Provider.of<FillRegisterationDropdown>(context, listen: false);
    String? defaultSelectedValue = _getDefaultSelectedValue(DDCash);
    String? defaultSelectedCash = _getDefaultSelectedCash(DDCash);
    String? defaultSelectedBranch = _getDefaultSelectedBranch(DDCash);



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
                        "Cash Collect",
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
                                height: 220,
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
                                                "Search Beneficiary",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: secondryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),

                                              const SizedBox(height: 10),
                                              AllformFields(
                                                ctr: BeneficiaryFullName,
                                                focusNode: _BeneficiaryFullName,
                                                keyboardType:
                                                    TextInputType.name,
                                                textInputAction:
                                                    TextInputAction.next,
                                                hintxt: "Beneficiary Full Name",
                                                icn: Icons.person,
                                                validator: (value) {
                                                  if (_submitted &&
                                                      value!.isEmpty) {
                                                    return 'BeneficiaryFullName Field is Required';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  ReceiverName = value;
                                                  _addSaveCashCollect = SaveCashCollect(
                                                      country_id: _addSaveCashCollect
                                                          .country_id,
                                                      city_id_to: _addSaveCashCollect
                                                          .city_id_to,
                                                      branch_to: _addSaveCashCollect
                                                          .branch_to,
                                                      currency_fro_id:
                                                          _addSaveCashCollect
                                                              .currency_fro_id,
                                                      amount_from:
                                                          _addSaveCashCollect
                                                              .amount_from,
                                                      currency_to_id:
                                                          _addSaveCashCollect
                                                              .currency_to_id,
                                                      net_payble_amount:
                                                          _addSaveCashCollect
                                                              .net_payble_amount,
                                                      remittance_comission:
                                                          _addSaveCashCollect
                                                              .remittance_comission,
                                                      remittance_rate:
                                                          _addSaveCashCollect
                                                              .remittance_rate,
                                                      benificary_name: value,
                                                      beneficiary_phone:
                                                          _addSaveCashCollect
                                                              .beneficiary_phone,
                                                      account_no:
                                                          _addSaveCashCollect
                                                              .account_no);
                                                },
                                              ),
                                              const SizedBox(height: 10),
                                              AllformFields(
                                                ctr: BeneficiaryTelephoneNumber,
                                                focusNode:
                                                    _BeneficiaryTelephoneNumber,
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.next,
                                                validator: (value) {
                                                  if (_submitted &&
                                                      value!.isEmpty) {
                                                    return 'Telephone Number Field is Required';
                                                  }
                                                  return null;
                                                },
                                                hintxt: "Telephone Number",
                                                icn: Icons.mobile_screen_share,
                                                onChanged: (value) {
                                                  ReceiverAccount = value;
                                                  _addSaveCashCollect = SaveCashCollect(
                                                      country_id: _addSaveCashCollect
                                                          .country_id,
                                                      city_id_to: _addSaveCashCollect
                                                          .city_id_to,
                                                      branch_to: _addSaveCashCollect
                                                          .branch_to,
                                                      currency_fro_id:
                                                          _addSaveCashCollect
                                                              .currency_fro_id,
                                                      amount_from:
                                                          _addSaveCashCollect
                                                              .amount_from,
                                                      currency_to_id:
                                                          _addSaveCashCollect
                                                              .currency_to_id,
                                                      net_payble_amount:
                                                          _addSaveCashCollect
                                                              .net_payble_amount,
                                                      remittance_comission:
                                                          _addSaveCashCollect
                                                              .remittance_comission,
                                                      remittance_rate:
                                                          _addSaveCashCollect
                                                              .remittance_rate,
                                                      benificary_name:
                                                          _addSaveCashCollect
                                                              .benificary_name,
                                                      beneficiary_phone: value,
                                                      account_no:
                                                          _addSaveCashCollect
                                                              .account_no);
                                                },
                                              ),
                                              const SizedBox(height: 10),

                                              const SizedBox(height: 5),
                                              //todo: country
                                              const SizedBox(height: 10),
                                              const Text(
                                                "City",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: secondryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              _isLoadingproDrop
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
                                                  : AllinOneDropdownSearch(
                                                      onChanged: (value) async {
                                                        print(value);
                                                        print("value");
                                                        setState(() {
                                                          City = value;
                                                          // selectedItem1 = value as String;

                                                          _isLoadingproDropbranch =
                                                              true;

                                                          // print(selectedItem1);
                                                        });
                                                        await Provider.of<
                                                                    FillRegisterationDropdown>(
                                                                context,
                                                                listen: false)
                                                            .fetchAndSetRemitBranches(
                                                                value);

                                                        setState(() {
                                                          _isLoadingproDropbranch =
                                                              false;
                                                          Branch =
                                                              _getDefaultSelectedBranch(
                                                                  DDCash);
                                                          // Branch= _getDefaultSelectedBranch(DDCash);
                                                        });
                                                        _addSaveCashCollect = SaveCashCollect(
                                                            country_id:
                                                                _addSaveCashCollect
                                                                    .country_id,
                                                            city_id_to: value,
                                                            branch_to:
                                                                _addSaveCashCollect
                                                                    .branch_to,
                                                            currency_fro_id:
                                                                _addSaveCashCollect
                                                                    .currency_fro_id,
                                                            amount_from:
                                                                _addSaveCashCollect
                                                                    .amount_from,
                                                            currency_to_id:
                                                                _addSaveCashCollect
                                                                    .currency_to_id,
                                                            net_payble_amount:
                                                                _addSaveCashCollect
                                                                    .net_payble_amount,
                                                            remittance_comission:
                                                                _addSaveCashCollect
                                                                    .remittance_comission,
                                                            remittance_rate:
                                                                _addSaveCashCollect
                                                                    .remittance_rate,
                                                            benificary_name:
                                                                _addSaveCashCollect
                                                                    .benificary_name,
                                                            beneficiary_phone:
                                                                _addSaveCashCollect
                                                                    .beneficiary_phone,
                                                            account_no:
                                                                _addSaveCashCollect
                                                                    .account_no);
                                                      },
                                                      hintxt: "Search City",
                                                      maintext: "Pick City",
                                                      items: DDCash.RemitCity,
                                                      dropdownValue: City,
                                                      SearchCtr:
                                                          CitySearchController,
                                                    ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                "Branch",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: secondryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              _isLoadingproDropbranch
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
                                                  : AllinOneDropdownSearch(
                                                      onChanged: (value) {
                                                        print(value);
                                                        setState(() {
                                                          Branch = value;
                                                        });
                                                        _addSaveCashCollect =
                                                            SaveCashCollect(
                                                          country_id:
                                                              _addSaveCashCollect
                                                                  .country_id,
                                                          city_id_to:
                                                              _addSaveCashCollect
                                                                  .city_id_to,
                                                          branch_to: value,
                                                          currency_fro_id:
                                                              _addSaveCashCollect
                                                                  .currency_fro_id,
                                                          amount_from:
                                                              _addSaveCashCollect
                                                                  .amount_from,
                                                          currency_to_id:
                                                              _addSaveCashCollect
                                                                  .currency_to_id,
                                                          net_payble_amount:
                                                              _addSaveCashCollect
                                                                  .net_payble_amount,
                                                          remittance_comission:
                                                              _addSaveCashCollect
                                                                  .remittance_comission,
                                                          remittance_rate:
                                                              _addSaveCashCollect
                                                                  .remittance_rate,
                                                          benificary_name:
                                                              _addSaveCashCollect
                                                                  .benificary_name,
                                                          beneficiary_phone:
                                                              _addSaveCashCollect
                                                                  .beneficiary_phone,
                                                          account_no:
                                                              _addSaveCashCollect
                                                                  .account_no,
                                                        );
                                                      },
                                                      hintxt: "Search Branch",
                                                      maintext: "Pick Branch",
                                                      items:
                                                          DDCash.RemitBranches,
                                                      dropdownValue: Branch,
                                                      SearchCtr:
                                                          CitySearchController,
                                                    ),
                                              const SizedBox(height: 10),

                                              AllformFields(
                                                ctr: AmountNumber,
                                                focusNode: _AmountNumber,
                                                // keyboardType:
                                                //     TextInputType.number,
                                                keyboardType: Platform.isIOS?
                                                const TextInputType.numberWithOptions(signed: true, decimal: true)
                                                    : TextInputType.number,
// This regex for only amount (price). you can create your own regex based on your requirement
                                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
                                                textInputAction:
                                                    TextInputAction.done,
                                                validator: (value) {
                                                  if (_submitted &&
                                                      value!.isEmpty) {
                                                    return 'AmountNumber Field is Required';
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
                                                      .findByIdTC(CurrencyID
                                                          .toString());

                                                  if (fieldValue.isNotEmpty) {
                                                    setState(() {
                                                      _isLoadingExchange = true;
                                                    });
                                                    result = await Provider.of<
                                                                Walletremit>(
                                                            context,
                                                            listen: false)
                                                        .CashCollectExchange(
                                                            widget.country
                                                                .toString(),
                                                            CurrencyID
                                                                .toString(),
                                                            fieldValue
                                                                .toString());
                                                    setState(() {
                                                      currency_name_from =
                                                          CurrencyDataFrom.name;
                                                      amount_fro = fieldValue;
                                                      sent_amount =
                                                          result['sent_amount']
                                                              .toString();
                                                      print('amount');
                                                      print(result['amount_to']
                                                          .toString());
                                                      Reciveamount =
                                                          result['amount_to']
                                                              .toString();
                                                      Commission = result['com']
                                                          .toString();
                                                      charge = result['charge']
                                                          .toStringAsFixed(2);
                                                      currency_name_to = result[
                                                              'currency_name_to']
                                                          .toString();
                                                      currency_name_fro = result[
                                                              'currency_name_fro']
                                                          .toString();
                                                      currency_id_to = result[
                                                              'currency_id_to']
                                                          .toString();
                                                      amount_to =
                                                          result['amount_to']
                                                              .toString();
                                                      remittance_comission =
                                                          result['com']
                                                              .toString();
                                                      remittance_rate = result[
                                                              'remittance_rate']
                                                          .toString();
                                                      print('amount');
                                                      print("Reciveamount");
                                                      print(Reciveamount);
                                                      print("currency_name_to");
                                                      print(currency_name_to);
                                                      print("sent_amount");
                                                      print(sent_amount);
                                                      print("charge");
                                                      print(charge);
                                                      print("currency_id_to");
                                                      print(currency_id_to);
                                                      print(
                                                          "remittance_comission");
                                                      print(
                                                          remittance_comission);
                                                      setState(() {
                                                        _isLoadingExchange =
                                                            false;
                                                      });
                                                    });
                                                  }

                                                  if (fieldValue.isEmpty) {
                                                    setState(() {
                                                      print("Reciveamount");
                                                      print(Reciveamount);
                                                      Reciveamount = "000";
                                                      charge = "000";
                                                    });
                                                  }
                                                  _addSaveCashCollect =
                                                      SaveCashCollect(
                                                    country_id: widget.country,
                                                    city_id_to: City,
                                                    branch_to: Branch,
                                                    currency_fro_id: CurrencyID,
                                                    amount_from: sent_amount,
                                                    currency_to_id:
                                                        currency_id_to,
                                                    net_payble_amount:
                                                        amount_to,
                                                    remittance_comission:
                                                        Commission,
                                                    remittance_rate:
                                                        remittance_rate,
                                                    benificary_name:
                                                        _addSaveCashCollect
                                                            .benificary_name,
                                                    beneficiary_phone:
                                                        _addSaveCashCollect
                                                            .beneficiary_phone,
                                                    account_no: widget
                                                        .wallet_accounts_id,
                                                  );
                                                  print("widget.country");
                                                  print(widget.country);
                                                  _AmountNumber.unfocus();
                                                },
                                                onChanged: (value) {
                                                  // Update the fieldValue when the text changes
                                                  fieldValue = value;
                                                },
                                              ),
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
                                                            print(
                                                                "currencyIdD");
                                                            print(CurrencyID);
                                                            print(value);
                                                            if (amount_fro
                                                                .isNotEmpty) {
                                                              result = await Provider.of<
                                                                          Walletremit>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .CashCollectExchange(
                                                                      widget
                                                                          .country
                                                                          .toString(),
                                                                      CurrencyID
                                                                          .toString(),
                                                                      amount_fro
                                                                          .toString());
                                                              setState(() {
                                                                print(
                                                                    amount_fro);
                                                                print(result[
                                                                            'result']
                                                                        [
                                                                        'amount_to']
                                                                    .toString());
                                                                sent_amount = result[
                                                                        'sent_amount']
                                                                    .toString();
                                                                print('amount');
                                                                print(result[
                                                                        'amount_to']
                                                                    .toString());
                                                                Reciveamount = result[
                                                                        'amount_to']
                                                                    .toString();
                                                                Commission = result[
                                                                        'com']
                                                                    .toString();
                                                                charge = result[
                                                                        'charge']
                                                                    .toString();
                                                                currency_name_to =
                                                                    result['currency_name_to']
                                                                        .toString();
                                                                currency_name_fro =
                                                                    result['currency_name_fro']
                                                                        .toString();
                                                                currency_id_to =
                                                                    result['currency_id_to']
                                                                        .toString();
                                                              });
                                                            }
                                                            setState(() {
                                                              CurrencyID =
                                                                  value;
                                                            });
                                                            _addSaveCashCollect =
                                                                SaveCashCollect(
                                                              country_id:
                                                                  _addSaveCashCollect
                                                                      .country_id,
                                                              city_id_to:
                                                                  _addSaveCashCollect
                                                                      .city_id_to,
                                                              branch_to:
                                                                  _addSaveCashCollect
                                                                      .branch_to,
                                                              currency_fro_id:
                                                                  value,
                                                              amount_from:
                                                                  _addSaveCashCollect
                                                                      .amount_from,
                                                              currency_to_id:
                                                                  _addSaveCashCollect
                                                                      .currency_to_id,
                                                              net_payble_amount:
                                                                  _addSaveCashCollect
                                                                      .net_payble_amount,
                                                              remittance_comission:
                                                                  _addSaveCashCollect
                                                                      .remittance_comission,
                                                              remittance_rate:
                                                                  _addSaveCashCollect
                                                                      .remittance_rate,
                                                              benificary_name:
                                                                  _addSaveCashCollect
                                                                      .benificary_name,
                                                              beneficiary_phone:
                                                                  _addSaveCashCollect
                                                                      .beneficiary_phone,
                                                              account_no:
                                                                  _addSaveCashCollect
                                                                      .account_no,
                                                            );
                                                          },
                                                          hintxt: "Search Currency",
                                                          maintext: "Pick Currency",
                                                          items: DDCash
                                                              .CusAccountCurrency,
                                                          dropdownValue:
                                                              CurrencyID,
                                                          SearchCtr:
                                                              CurrencySearchController,
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
                                                          "00",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                secondryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: <Widget>[
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  //todo:commission;
                                                  Center(
                                                    child: _isLoadingExchange
                                                        ? const LogoandSpinner(
                                                            imageAssets:
                                                                'assets/asalicon.png',
                                                            reverse: true,
                                                            arcColor:
                                                                primaryColor,
                                                            spinSpeed: Duration(
                                                                milliseconds:
                                                                    500),
                                                          )
                                                        // CircularProgressIndicator()
                                                        : RichText(
                                                            text: TextSpan(
                                                              text:
                                                                  "Commission is $currency_name_fro $charge ",
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color:
                                                                    secondryColor,
                                                              ),
                                                            ),
                                                          ),
                                                  ),

                                                ], //<Widget>[]
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              // AllformFields(
                                              //   hintxt: "Amount receive",
                                              //   icn: Icons.attach_money_sharp,
                                              // ),
                                              Text(
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
                                                                // _saveForm();
                                                                _submitted =
                                                                    true;
                                                                final isValid = _form
                                                                    .currentState
                                                                    ?.validate();
                                                                if (!isValid!) {
                                                                  print(
                                                                      "valid");
                                                                  return;
                                                                }
                                                                _form
                                                                    .currentState
                                                                    ?.save();
                                                                _showMyDialogConfirmPin();
                                                              },
                                                              child: const CommonBtn(
                                                                  txt: "Send"))
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
