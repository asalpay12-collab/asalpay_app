
import 'package:asalpay/models/http_exception.dart';
import 'package:asalpay/providers/WalletOperations.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllWalletOperationDropDown.dart';
import 'package:asalpay/widgets/CommonTextView.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:flutter/material.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import '../constants/Constant.dart';
class Exchange1 extends StatefulWidget {
  final String? wallet_accounts_id;
  const Exchange1({
    this.wallet_accounts_id,
    super.key,
  });

  @override
  State<Exchange1> createState() => _Exchange1State();
}

class _Exchange1State extends State<Exchange1> {
  String? CurrencyTo;
  String? CurrencyFrom;

  final _Amount_Send = FocusNode();
  TextEditingController CurrencyToSearch = TextEditingController();
  TextEditingController CurrencyFromSearch = TextEditingController();
  TextEditingController Amount_Send = TextEditingController();
  TextEditingController RecieveAccount = TextEditingController();

  var result;
  String amountReceive = "";
  String api_rate = "";
  String com_rate = "";
  String com_value = "";
  String currency_name_fro = "";
  String currency_name_to = "";

  // final List<String> items = [
  //   "USD",
  //   "ZAR",
  // ];
  // String? selectedValue;
  // void initState() {
  //   super.initState();
  //   // Set your "default" value here. This example sets it to items[0]
  //   if (items.isNotEmpty) {
  //     selectedValue = items[0];
  //   }
  // }

  bool _isLoadingDrop_data = false;
  final bool _isLoadingproDrop = false;
  bool _isLoading = false;
  @override
  Future<void> didChangeDependencies() async {
// TODO: implement didChangeDependencies
    super.didChangeDependencies();
    setState(() {
      _isLoadingDrop_data = true;
    });
    await Provider.of<WalletOperations>(context, listen: false)
        .fetchAndSetCusAccountCurrencyRC(widget.wallet_accounts_id.toString())
        .then((_) {});
    setState(() {
      _isLoadingDrop_data = false;
      final FillDD = Provider.of<WalletOperations>(context, listen: false);
      print('FillDD: $FillDD');
      CurrencyTo = _getDefaultSelectedValue1(FillDD);
      CurrencyFrom = _getDefaultSelectedValue1(FillDD);
      // CurrencyFrom = _getDefaultSelectedValue2(FillDD);
    });
  }

  var _addSaveExchangeRegistration = SaveExchangeRegistration(
    account_no: " ",
    amount_fro: "",
    amount_to: "",
    api_rate: "",
    com_rate: "",
    com_value: "",
    currency_to_id: "",
    currency_fro_id: "",
  );
  bool _submitted = false;
  final _form = GlobalKey<FormState>();
  Future<void> _saveForm() async {
    _submitted = true;
    final isValid = _form.currentState?.validate();
    if (!isValid!) {
      return;
    }
    // final isValid = _form.currentState?.validate();
    // if (!isValid!) {
    //   return;
    // }
    // _form.currentState?.save();
    // _form.currentState!.reset();
// if (_pickImage! == null) {
//   return;
// }
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<WalletOperations>(context, listen: false)
          .addSaveExchangeRegistration(
              _addSaveExchangeRegistration, widget.wallet_accounts_id!);
    } on HttpException catch (error) {
      var errorMessage = 'Authentication failed';
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
      openSnackbar(context, error.toString(), secondryColor);
    } catch (error) {
// _showErrorDialog(error.toString());
      _submitted = false;
      RecieveAccount.text = "";
      Amount_Send.text = "";
      openSnackbar(context, error.toString(), secondryColor);
    }
    setState(() {
      _isLoading = false;
    });
  }

  //initial value;
  String? _getDefaultSelectedValue1(WalletOperations fillDD) {
    if (fillDD.CusAccountCurrencyRC.isNotEmpty) {
      return fillDD.CusAccountCurrencyRC[0].currency_id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final FillDD = Provider.of<WalletOperations>(context, listen: false);
    String? defaultSelectedValue1 = _getDefaultSelectedValue1(FillDD);
    // String? defaultSelectedValue2 = _getDefaultSelectedValue2(FillDD);
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
                  "Money Exchange",
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
                          height: 10,
                        ),

                        //Image;
                        Container(
                          height: 220,
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage("assets/exch1.png"))),
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
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        const Text(
                                          "Currency From",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: secondryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        //todo:currencyFrom
                                        AllWalletOperationDropDown(
                                          onChanged: (value) {
                                            setState(() {
                                              CurrencyFrom = value;
                                            });
                                            _addSaveExchangeRegistration =
                                                SaveExchangeRegistration(
                                              account_no:
                                                  _addSaveExchangeRegistration
                                                      .account_no,
                                              amount_fro:
                                                  _addSaveExchangeRegistration
                                                      .amount_fro,
                                              amount_to:
                                                  _addSaveExchangeRegistration
                                                      .amount_to,
                                              api_rate:
                                                  _addSaveExchangeRegistration
                                                      .api_rate,
                                              com_rate:
                                                  _addSaveExchangeRegistration
                                                      .com_rate,
                                              com_value:
                                                  _addSaveExchangeRegistration
                                                      .com_value,
                                              currency_to_id:
                                                  _addSaveExchangeRegistration
                                                      .currency_to_id,
                                              currency_fro_id: value,
                                            );
                                          },
                                          hintxt: "Search Currency",
                                          maintext: "Pick any Currency",
                                          items: FillDD.CusAccountCurrencyRC,
                                          SearchCtr: CurrencyFromSearch,
                                          dropdownValue: CurrencyFrom,
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        AllformFields(
                                          ctr: Amount_Send,
                                          focusNode: _Amount_Send,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          // validator: (value) {
                                          //   if (value == null || value.isEmpty) {
                                          //     return 'Amount Send Field is Required';
                                          //   }else{
                                          //     return null;
                                          //   }
                                          //   // value!.isEmpty ? 'Enter a mobile phone number' : null;
                                          // },
                                          validator: (value) {
                                            if (_submitted && value!.isEmpty) {
                                              return 'Amount Send Field is Required';
                                            }
                                            return null;
                                          },
                                          onsave: (value) {
                                            Amount_Send.text = value!;
                                          },
                                          // vaildotor

                                          hintxt: "Amount Send",
                                          icn: Icons.attach_money_sharp,
                                          onChanged: (value) async {
                                            print("Hello Transfer Amount");
                                            print(value);
                                            print(CurrencyTo.toString());
                                            var CurrencyDataFrom =
                                                Provider.of<WalletOperations>(
                                                        context,
                                                        listen: false)
                                                    .findByIdFC(
                                                        CurrencyFrom.toString());
                                            print(CurrencyDataFrom.currency_name
                                                .toString());
                                            var CurrencyDataTo =
                                                Provider.of<WalletOperations>(
                                                        context,
                                                        listen: false)
                                                    .findByIdTC(
                                                        CurrencyTo.toString());

                                            print("CurrencyDataFrom");
                                            print(CurrencyDataFrom.currency_name);
                                            print("CurrencyDataTo");
                                            print(CurrencyDataTo.currency_name);
                                            print(CurrencyDataTo.currency_id);
                                            if (value.isNotEmpty) {
                                              if (CurrencyFrom.toString() !=
                                                  CurrencyTo.toString()) {
                                                result = await Provider.of<
                                                            WalletOperations>(
                                                        context,
                                                        listen: false)
                                                    .TransferExchange(
                                                  value,
                                                  CurrencyDataTo.currency_name
                                                      .toString(),
                                                  CurrencyDataFrom.currency_name
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
                                                  RecieveAccount.text =
                                                      "$currency_name_to $amountReceive"
                                                          .toString();
                                                  currency_name_to =
                                                      result['apiResult']['query']
                                                              ['to']
                                                          .toString();
                                                  api_rate = result['apiResult']
                                                          ['info']['quote']
                                                      .toString();
                                                  com_rate =
                                                      result['commissionAmount']
                                                          .toString();
                                                  com_value =
                                                      result['commissionAmount']
                                                          .toString();
                                                  // Reciveamount = result['result']
                                                  // ['amount_to'].toStringAsFixed(2);
                                                  print(amountReceive);
                                                });
                                              } else {
                                                setState(() {
                                                  print(
                                                      "Hello Exchange Amount $value");
                                                  amountReceive = value;
                                                  RecieveAccount.text =
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
                                            print("Value of Amount From");
                                            print(value);
                                            _addSaveExchangeRegistration =
                                                SaveExchangeRegistration(
                                              account_no:
                                                  widget.wallet_accounts_id,
                                              amount_fro: value,
                                              amount_to: amountReceive,
                                              api_rate: api_rate,
                                              com_rate: com_rate,
                                              com_value: com_value,
                                              currency_to_id: CurrencyTo,
                                              currency_fro_id: CurrencyFrom,
                                            );
                                          },
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        const Text(
                                          "Currency To",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: secondryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        //todo:currencyTo;
                                        AllWalletOperationDropDown(
                                          onChanged: (value) {
                                            setState(() {
                                              CurrencyTo = value;
                                            });
                                            _addSaveExchangeRegistration =
                                                SaveExchangeRegistration(
                                              account_no:
                                                  _addSaveExchangeRegistration
                                                      .account_no,
                                              amount_fro:
                                                  _addSaveExchangeRegistration
                                                      .amount_fro,
                                              amount_to:
                                                  _addSaveExchangeRegistration
                                                      .amount_to,
                                              api_rate:
                                                  _addSaveExchangeRegistration
                                                      .api_rate,
                                              com_rate:
                                                  _addSaveExchangeRegistration
                                                      .com_rate,
                                              com_value:
                                                  _addSaveExchangeRegistration
                                                      .com_value,
                                              currency_to_id: value,
                                              currency_fro_id:
                                                  _addSaveExchangeRegistration
                                                      .currency_fro_id,
                                            );
                                          },
                                          hintxt: "Search Currency",
                                          maintext: "Pick any Currency",
                                          items: FillDD.CusAccountCurrencyRC,
                                          SearchCtr: CurrencyToSearch,
                                          dropdownValue: CurrencyTo,
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        CommonTextView(
                                          ctr: RecieveAccount,
                                          hintxt: "Recipient Name",
                                          icn: Icons.attach_money_sharp,
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        _isLoading
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
                                                  _saveForm();
                                                },
                                                child:
                                                    const CommonBtn(txt: "Proccess")),
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
}

