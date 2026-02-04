import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/models/http_exception.dart';

import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllWalletOperationDropDown.dart';
import 'package:asalpay/widgets/CommonTextView.dart';
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
import 'dart:io' show Platform;


import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';

import 'package:asalpay/providers/TransferOperations.dart';

// import 'package:asalpay/providers/WalletOperations.dart';

import 'dart:async'; 


class Transfer extends StatefulWidget {
  final String? wallet_accounts_id;

  static const routeName = '/Transfer';
  const Transfer({required this.wallet_accounts_id, super.key, required});

  @override
  State<Transfer> createState() => _TransferState();
}



class _TransferState extends State<Transfer> {

  // 4/8/24

  StreamSubscription<List<BalanceDisplayModel>>? _balanceSubscription;

@override
void initState() {
  super.initState();
  _subscribeToBalance();
}

void _subscribeToBalance() {
  final String? accountId = widget.wallet_accounts_id;
  if (accountId != null) {
    
    _balanceSubscription?.cancel(); 
    _balanceSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .fetchAndDisplayBalance(accountId)
        .listen(
          (balances) {
            print('Balances updated');
          },
          onError: (error) {
            print('Error fetching balances: $error');
          },
        );
  } else {
    print('Account ID is null');
  }
}




  bool isloading1 = false;
  bool _isLoadingDrop_data = false;
  bool _isLoadingproDrop = false;
  bool _isLoadingExchange = false;

  String? FromAccountID;
  String? ToAccountID;
  String? RecieverAccountNumber;
  String? sendAmount;
  String fieldValue = '';

  final _Accountorphone = FocusNode();
  final _TransferAmount = FocusNode();
  TextEditingController Accountorphone = TextEditingController();
  TextEditingController FromAccountIDSeach = TextEditingController();
  TextEditingController RecipientName = TextEditingController();
  TextEditingController AmountReceive = TextEditingController();
  TextEditingController TransferAmount = TextEditingController();
  TextEditingController ToAccountIDSearch = TextEditingController();

  var result;
  // String fname = "";
  String fullName = " ";
  String amountReceive = "";
  String api_rate = "";
  String com_rate = "";
  String com_value = "";
  String pinNumber = "";
  String ModelErrorMessage = "";
  // String mname = "";
  String currency_name_fro = "";
  String currency_name_to = "";
  bool isConnected = true;
  late String? statusText = "";
  @override
  bool _isLoading = false;
  var _addSaveTransferRegisteration = SaveTransferRegistration(
    account_no_from: " ",
    account_no_to: "",
    phone: "",
    amount_fro: "",
    amount_to: "",
    api_rate: "",
    com_rate: "",
    com_value: "",
    currency_to_id: "",
    currency_fro_id: "",
  );
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

  bool _submitted1 = false;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
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
      
    } on HttpException catch (error) {
      if (error.toString().contains('INVALID_PHONE')) {
        errorMessage = 'Could not find a user with that phone .';
        // setState(() {
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
      openSnackbar(context, error.toString(), secondryColor);
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
    var errorMessage = 'Successfully transferred!';
    try {
      await Provider.of<TransferOperations>(context, listen: false)
          .addSaveTransferRegisteration(
              _addSaveTransferRegisteration, widget.wallet_accounts_id!);
    } on HttpException catch (error) {
      if (error.toString().contains('this account is not exist')) {
      } else if (error
          .toString()
          .contains('Email is already exit another Email')) {
      } else if (error.toString().contains('this account is not Active')) {
      } else if (error.toString().contains('Insufficient balance')) {
        errorMessage = 'operation failed .';
      } else if (error.toString().contains('OP')) {
        errorMessage = 'operation failed .';
      }
      print(error.toString());
      print('hello welcome');

      openSnackbar(context, error.toString(), secondryColor);
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
    await Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .fetchAndSetAllTr()
        .then((_) {});
    _submitted = false;
    final TransFerD = Provider.of<TransferOperations>(context, listen: false);
    
    
    try {
      
    final displayBalance = Provider.of<HomeSliderAndTransaction>(context, listen: false);
    final balances = await displayBalance.fetchAndDisplayBalance(widget.wallet_accounts_id ?? "").first;
    
    if (balances.isEmpty) {
      
      print("Balances not received yet");
     
    } else {
      
      print("Navigating to PaymentPage");

        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => PaymentPage(
                  RecieverAccountNumber.toString(),
                  "Phone",
                  ReceiverLabelRec: "Phone",
                  ReceiverAmount: currency_name_to + amountReceive,
                  ReceiverName:
                      "${TransFerD.CusAccountCurrencyRC[0].f_name} ${TransFerD.CusAccountCurrencyRC[0].m_name}",
                  senderAccount: widget.wallet_accounts_id!,
                  senderAmount: '$currency_name_fro$sendAmount',
                  senderName: "${balances[0].f_name}" " ${balances[0].m_name}",
                )));

                  }
      } catch (error) {
        
        print('Error fetching balance data: $error');
        
      }

      setState(() {
        _isLoading = false;
      });

    Accountorphone.text = "";
    RecipientName.clear();
    AmountReceive.text = "";
    TransferAmount.text = "";
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
                    readOnly: false,
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
                      ?

                      const LogoandSpinner(
                          imageAssets: 'assets/asalicon.png',
                          reverse: true,
                          arcColor: primaryColor,
                          spinSpeed: Duration(milliseconds: 500),
                        )
                      : InkWell(
                          onTap: () {
                            if (_submitted = false) {
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

  otpDialogBox(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter your Pin'),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                ),
                onChanged: (value) {
                  // otp = value;
                  pinNumber = value;
                },
              ),
            ),
            contentPadding: const EdgeInsets.all(10.0),
            actions: <Widget>[
              InkWell(
                  onTap: () {
                    // _saveForm();
                    _CheckPinNumber();
                  },
                  child: const CommonBtn(txt: "Comfirm"))
            ],
          );
        });
  }

  String? _getDefaultSelectedValueFC(TransferOperations TransFerD) {
    if (TransFerD.CusAccountCurrencyFC.isNotEmpty) {
      return TransFerD.CusAccountCurrencyFC[0].currency_id;
    }
    return null;
  }

  String? _getDefaultSelectedValueRC(TransferOperations TransFerD) {
    if (TransFerD.CusAccountCurrencyRC.isNotEmpty) {
     
      RecieverAccountNumber =
          TransFerD.CusAccountCurrencyRC[0].wallet_accounts_id!;
      return TransFerD.CusAccountCurrencyRC[0].currency_id;
    }
    return null;
  }

// 4/8/24


@override
void didChangeDependencies() async {
  super.didChangeDependencies();
  
  setState(() {
    _isLoadingDrop_data = true;
  });

  await Provider.of<TransferOperations>(context, listen: false)
      .fetchAndSetCusAccountCurrencyFC(widget.wallet_accounts_id.toString());

  
  final String? accountId = widget.wallet_accounts_id;
  if (accountId != null) {
   
    _balanceSubscription?.cancel();
    _balanceSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .fetchAndDisplayBalance(accountId) 
        .listen(
          (balances) {
            
            // print("New balances received");
          },
          onError: (error) {
            
            print("Error receiving balance data: $error");
          },
        );
  } else {
    
    print("Account ID is null. Subscription to balance updates is not set up.");
  
  }


  setState(() {
    final TransFerD = Provider.of<TransferOperations>(context, listen: false);
    print('TransFerD: $TransFerD');
    ToAccountID = _getDefaultSelectedValueRC(TransFerD);
    FromAccountID = _getDefaultSelectedValueFC(TransFerD);
    
    _isLoadingDrop_data = false;
  });
}


@override
void dispose() {
  _balanceSubscription?.cancel();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    final DisplayBalance =
        Provider.of<HomeSliderAndTransaction>(context, listen: false);
    final TransFerD = Provider.of<TransferOperations>(context, listen: false);
    String? defaultSelectedFC = _getDefaultSelectedValueFC(TransFerD);
    String? defaultSelectedRC = _getDefaultSelectedValueRC(TransFerD);



      
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
                      "Transfer Money",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
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

                            //Image;
                            Container(
                              height: 150,
                              decoration: const BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage(
                                          "assets/asalpayscreens.png"))),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            
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
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const Text(
                                              "From Account",
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
                                              hintxt: "Search Account",
                                              onChanged: (value) async {
                                                print("value");
                                                print(value);
                                                setState(() {
                                                  FromAccountID = value;
                                                });
                                                print(currency_name_fro);
                                                _addSaveTransferRegisteration =
                                                    SaveTransferRegistration(
                                                  account_no_from:
                                                      widget.wallet_accounts_id,
                                                  account_no_to:
                                                      _addSaveTransferRegisteration
                                                          .account_no_to,
                                                  phone:
                                                      _addSaveTransferRegisteration
                                                          .phone,
                                                  amount_fro:
                                                      _addSaveTransferRegisteration
                                                          .amount_fro,
                                                  amount_to:
                                                      _addSaveTransferRegisteration
                                                          .amount_to,
                                                  api_rate:
                                                      _addSaveTransferRegisteration
                                                          .api_rate,
                                                  com_rate:
                                                      _addSaveTransferRegisteration
                                                          .com_rate,
                                                  com_value:
                                                      _addSaveTransferRegisteration
                                                          .com_value,
                                                  currency_to_id:
                                                      _addSaveTransferRegisteration
                                                          .currency_to_id,
                                                  currency_fro_id: value,
                                                );
                                              },
                                              maintext: "Pick any Account",
                                              SearchCtr: FromAccountIDSeach,
                                              dropdownValue: FromAccountID,
                                              TransferItems: TransFerD
                                                  .CusAccountCurrencyFC,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AllformFields(
                                              keyboardType: TextInputType.phone,
                                              focusNode: _Accountorphone,
                                              textInputAction:
                                                  TextInputAction.done,
                                              ctr: Accountorphone,
                                              hintxt: "Account Or Phone",
                                              validator: (value) {
                                                if (_submitted &&
                                                    value!.isEmpty) {
                                                  return 'Account Or Phone Field is Required';
                                                }
                                                return null;
                                              },
                                              icn: Icons.account_circle,
                                              onChanged: (value) async {
                                               
                                                String
                                                    textWithoutSpacesAndPlus =
                                                    value
                                                        .replaceAll(' ', '')
                                                        .replaceAll('+', '');
                                                Accountorphone.value =
                                                    Accountorphone.value
                                                        .copyWith(
                                                  text:
                                                      textWithoutSpacesAndPlus,
                                                 
                                                );
                                               
                                                print(value);
                                                print("value");
                                                if (Accountorphone.text.length >
                                                    9) {
                                                  setState(() {
                                                    print(
                                                        "RecipientphoneNumber value");
                                                    _isLoadingproDrop = true;
                                                  });

                                                 
                                                  await Provider.of<
                                                              TransferOperations>(
                                                          context,
                                                          listen: false)
                                                      .fetchAndSetCusAccountCurrencyRC(
                                                          Accountorphone.text);
                                                  
                                                  RecipientName.text =
                                                      "${TransFerD.CusAccountCurrencyRC[0].f_name} ${TransFerD.CusAccountCurrencyRC[0].m_name}";
                                                  ToAccountID =
                                                      _getDefaultSelectedValueRC(
                                                          TransFerD);
                                                  setState(() {
                                                    _isLoadingproDrop = false;
                                                    print("ToAccountID");
                                                    print(ToAccountID);
                                                  });
                                                  _addSaveTransferRegisteration =
                                                      SaveTransferRegistration(
                                                    account_no_from:
                                                        _addSaveTransferRegisteration
                                                            .account_no_from,
                                                    account_no_to:
                                                        RecieverAccountNumber,
                                                    phone:
                                                        "+$RecieverAccountNumber",
                                                    amount_fro:
                                                        _addSaveTransferRegisteration
                                                            .amount_fro,
                                                    amount_to:
                                                        _addSaveTransferRegisteration
                                                            .amount_to,
                                                    api_rate:
                                                        _addSaveTransferRegisteration
                                                            .api_rate,
                                                    com_rate:
                                                        _addSaveTransferRegisteration
                                                            .com_rate,
                                                    com_value:
                                                        _addSaveTransferRegisteration
                                                            .com_value,
                                                    currency_to_id:
                                                        _addSaveTransferRegisteration
                                                            .currency_to_id,
                                                    currency_fro_id:
                                                        _addSaveTransferRegisteration
                                                            .currency_fro_id,
                                                  );
                                                }
                                              },
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            CommonTextView(
                                              ctr: RecipientName,
                                              hintxt: "Recipient Name",
                                              icn: Icons.person,
                                            ),
                                            
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            AllformFields(
                                             

                                              focusNode: _TransferAmount,
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
                                              ctr: TransferAmount,
                                              hintxt: "Transfer Amount",
                                              
                                              validator: (value) {
                                                if (_submitted &&
                                                    value!.isEmpty) {
                                                  return 'TransferAmount Field is Required';
                                                }
                                                return null;
                                              },
                                              onEditingComplete: () async {
                                                
                                                print("Hello Transfer Amount");

                                                print(
                                                    'Field value: $fieldValue');
                                                double numericValue =
                                                    double.parse(fieldValue);
                                                sendAmount = numericValue
                                                    .toStringAsFixed(2);
                                                
                                                var CurrencyDataFrom = Provider
                                                        .of<TransferOperations>(
                                                            context,
                                                            listen: false)
                                                    .findByIdFC(FromAccountID
                                                        .toString());
                                                var CurrencyDataTo = Provider
                                                        .of<TransferOperations>(
                                                            context,
                                                            listen: false)
                                                    .findByIdTC(
                                                        ToAccountID.toString());

                                                print("CurrencyDataFrom");
                                                print(CurrencyDataFrom
                                                    .currency_name);
                                                print("CurrencyDataTo");
                                                print(CurrencyDataTo
                                                    .currency_name);
                                                print(
                                                    CurrencyDataTo.currency_id);
                                                if (fieldValue.isNotEmpty) {
                                                  if (FromAccountID
                                                          .toString() !=
                                                      ToAccountID.toString()) {
                                                    setState(() {
                                                      currency_name_fro =
                                                          CurrencyDataFrom
                                                              .currency_name!;
                                                      currency_name_to =
                                                          CurrencyDataTo
                                                              .currency_name!;
                                                      _isLoadingExchange = true;
                                                    });
                                                    result = await Provider.of<
                                                                TransferOperations>(
                                                            context,
                                                            listen: false)
                                                        .TransferExchange(
                                                      fieldValue,
                                                      CurrencyDataTo
                                                          .currency_name
                                                          .toString(),
                                                      CurrencyDataFrom
                                                          .currency_name
                                                          .toString(),
                                                      ToAccountID
                                                          .toString(), 
                                                      FromAccountID
                                                          .toString(), 
                                                    );
                                                    setState(() {
                                                      amountReceive =
                                                          result['resultAmount']
                                                              .toStringAsFixed(
                                                                  2);
                                                      AmountReceive.text =
                                                          "$currency_name_to $amountReceive"
                                                              .toString();

                                                      api_rate =
                                                          result['apiResult']
                                                                      ['info']
                                                                  ['quote']
                                                              .toString();
                                                      com_rate = result[
                                                              'commissionAmount']
                                                          .toString();
                                                      com_value = result[
                                                              'commissionAmount']
                                                          .toString();

                                                      print(amountReceive);
                                                      setState(() {
                                                        _isLoadingExchange =
                                                            false;
                                                      });
                                                    });
                                                  } else {
                                                    setState(() {
                                                      print(
                                                          "Hello Transfer Amount $fieldValue");
                                                      currency_name_fro =
                                                          CurrencyDataFrom
                                                              .currency_name!;
                                                      currency_name_to =
                                                          CurrencyDataTo
                                                              .currency_name!;

                                                      double numericValue =
                                                          double.parse(
                                                              fieldValue);
                                                      amountReceive =
                                                          numericValue
                                                              .toStringAsFixed(
                                                                  2);
                                                      AmountReceive.text =
                                                          "${CurrencyDataFrom.currency_name} $amountReceive";
                                                      print(
                                                          "Hello Transfer amountReceive $amountReceive");
                                                    });
                                                  }
                                                } else {
                                                  setState(() {

                                                    AmountReceive.text = "000";
                                                  });
                                                }
                                                _addSaveTransferRegisteration =
                                                    SaveTransferRegistration(
                                                  account_no_from:
                                                      _addSaveTransferRegisteration
                                                          .account_no_from,
                                                  account_no_to:
                                                      _addSaveTransferRegisteration
                                                          .account_no_to,
                                                  phone:
                                                      _addSaveTransferRegisteration
                                                          .phone,
                                                  amount_fro: fieldValue,
                                                  amount_to: amountReceive,
                                                  api_rate: api_rate,
                                                  com_rate: com_rate,
                                                  com_value: com_value,
                                                  currency_to_id: ToAccountID,
                                                  currency_fro_id:
                                                      FromAccountID,
                                                );
                                                print("Value of Amount From");
                                                print(fieldValue);
                                                print("Value of Amount From");
                                                print(sendAmount);
                                                
                                                _TransferAmount.unfocus();
                                              },
                                              onChanged: (value) {
                                               
                                                fieldValue = value;
                                              },
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            const Text(
                                              "To Account",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: secondryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            //todo:accountID
                                            Container(
                                              child: _isLoadingproDrop
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
                                                  : AllWalletOperationDropDown(
                                                      hintxt: "Search Account",
                                                      onChanged: (value) async {
                                                        print("valueRC");
                                                        print(value);

                                                        setState(() {
                                                          ToAccountID = value;
                                                          //AmountReceive.text = "${currency_name_to} ${amountReceive}".toString();
                                                        });
                                                       
                                                        _addSaveTransferRegisteration =
                                                            SaveTransferRegistration(
                                                          account_no_from:
                                                              _addSaveTransferRegisteration
                                                                  .account_no_from,
                                                          account_no_to:
                                                              _addSaveTransferRegisteration
                                                                  .account_no_to,
                                                          phone:
                                                              _addSaveTransferRegisteration
                                                                  .phone,
                                                          amount_fro:
                                                              _addSaveTransferRegisteration
                                                                  .amount_fro,
                                                          amount_to:
                                                              _addSaveTransferRegisteration
                                                                  .amount_to,
                                                          api_rate:
                                                              _addSaveTransferRegisteration
                                                                  .api_rate,
                                                          com_rate:
                                                              _addSaveTransferRegisteration
                                                                  .com_rate,
                                                          com_value:
                                                              _addSaveTransferRegisteration
                                                                  .com_value,
                                                          currency_to_id: value,
                                                          currency_fro_id:
                                                              _addSaveTransferRegisteration
                                                                  .currency_fro_id,
                                                        );
                                                      },
                                                      maintext:
                                                          "Pick any Account",
                                                      SearchCtr:
                                                          ToAccountIDSearch,
                                                      dropdownValue:
                                                          ToAccountID,
                                                      TransferItems: TransFerD
                                                          .CusAccountCurrencyRC,
                                                    ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            
                                            Center(
                                              child: _isLoadingExchange
                                                  ?
                                                  
                                                  const LogoandSpinner(
                                                      imageAssets:
                                                          'assets/asalicon.png',
                                                      reverse: true,
                                                      arcColor: primaryColor,
                                                      spinSpeed: Duration(
                                                          milliseconds: 500),
                                                    )
                                                  : CommonTextView(
                                                      validator: (value) {
                                                        if (value!.isEmpty) {
                                                          return 'AmountReceive  Should be Filled';
                                                        }
                                                        return null;
                                                      },
                                                      ctr: AmountReceive,
                                                      hintxt: "Amount Receive",
                                                      // icn: Icons.attach_money_sharp,
                                                    ),
                                            ),
                                          
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            !_isLoadingExchange
                                                ? isConnected
                                                    ? Center(
                                                        child: _isLoading
                                                            ?
                                                           
                                                            const LogoandSpinner(
                                                                imageAssets:
                                                                    'assets/asalicon.png',
                                                                reverse: true,
                                                                arcColor:
                                                                    primaryColor,
                                                                spinSpeed: Duration(
                                                                    milliseconds:
                                                                        500),
                                                              )
                                                            : InkWell(
                                                                onTap: () {
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
                                                                    txt:
                                                                        "Send")),
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
