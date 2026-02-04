import 'package:asalpay/models/http_exception.dart';
import 'package:asalpay/providers/WalletOperations.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllWalletOperationDropDown.dart';
import 'package:asalpay/widgets/CommonTextView.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/Constant.dart';

class ExChangeOne extends StatefulWidget {
  final String? wallet_accounts_id;
  static const routeName = '/ExChangeOne';
  const ExChangeOne({required this.wallet_accounts_id, super.key, required});

  @override
  State<ExChangeOne> createState() => _ExChangeOneState();
}

class _ExChangeOneState extends State<ExChangeOne> {
  bool _isLoadingDrop_data = false;
  final bool _isLoadingproDrop = false;

  String? FromAccountID;
  String? ToAccountID;
  TextEditingController pin = TextEditingController();
  TextEditingController FromAccountIDSeach = TextEditingController();
  // TextEditingController cardHolderName = TextEditingController();
  TextEditingController Accountorphone = TextEditingController();
  TextEditingController RecipientName = TextEditingController();
  TextEditingController AmountReceive = TextEditingController();
  TextEditingController TransferAmount = TextEditingController();
  TextEditingController ToAccountIDSearch = TextEditingController();

  var result;
  String amountReceive = "";
  String api_rate = "";
  String com_rate = "";
  String com_value = "";
  String currency_name_fro = "";
  String currency_name_to = "";
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

  final _addSaveExchangeRegistration = SaveExchangeRegistration(
    account_no: " ",
    amount_fro: "",
    amount_to: "",
    api_rate: "",
    com_rate: "",
    com_value: "",
    currency_to_id: "",
    currency_fro_id: "",
  );


  Future<void> _saveForm() async {

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<WalletOperations>(context, listen: false)
          .addSaveTransferRegisteration(
              _addSaveTransferRegisteration, widget.wallet_accounts_id!);
    } on HttpException catch (error) {
      var errorMessage = 'Authentication failed';
      if (error.toString().contains('this account is not exist')) {
      } else if (error
          .toString()
          .contains('Email is already exit another Email')) {
      } else if (error.toString().contains('this account is not Active')) {
      } else if (error.toString().contains(
          'Insufficient balance')) {
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
      openSnackbar(context, error.toString(), secondryColor);
    }
    setState(() {
      _isLoading = false;
    });

  }

  @override
  Future<void> didChangeDependencies() async {
// TODO: implement didChangeDependencies
    super.didChangeDependencies();
    setState(() {
      _isLoadingDrop_data = true;
    });
    await Provider.of<WalletOperations>(context, listen: false)
        .fetchAndSetCusAccountCurrencyFC(widget.wallet_accounts_id.toString())
        .then((_) {});

    setState(() {
      _isLoadingDrop_data = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TransFerD = Provider.of<WalletOperations>(context, listen: false);

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
                  Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),

                      //Image;
                      Container(
                        height: 150,
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
                                      //todo:fromcAccountID
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
                                            phone: _addSaveTransferRegisteration
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
                                        items: TransFerD.CusAccountCurrencyFC,
                                      ),

                                      const SizedBox(
                                        height: 10,
                                      ),
                                      AllformFields(
                                        ctr: TransferAmount,
                                        hintxt: "Transfer Amount",
                                        // icn: Icons.attach_money_sharp,
                                        onChanged: (value) async {
                                          print("Hello Transfer Amount");
                                          print(value);
                                          var CurrencyDataFrom =
                                              Provider.of<WalletOperations>(
                                                      context,
                                                      listen: false)
                                                  .findByIdFC(
                                                      FromAccountID.toString());
                                          var CurrencyDataTo =
                                              Provider.of<WalletOperations>(
                                                      context,
                                                      listen: false)
                                                  .findByIdTC(
                                                      ToAccountID.toString());

                                          print("CurrencyDataFrom");
                                          print(CurrencyDataFrom.currency_name);
                                          print("CurrencyDataTo");
                                          print(CurrencyDataTo.currency_name);
                                          print(CurrencyDataTo.currency_id);
                                          if (value.isNotEmpty) {
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
                                              ToAccountID
                                                  .toString(), //ToAccountID
                                              FromAccountID
                                                  .toString(), //FromAccountID
                                            );
                                            setState(() {
                                              amountReceive =
                                                  result['resultAmount']
                                                      .toString();
                                              // AmountReceive.text = amountReceive.toString();
                                              AmountReceive.text =
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
                                              amountReceive = "000";
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
                                            phone: _addSaveTransferRegisteration
                                                .phone,
                                            amount_fro: value,
                                            amount_to: amountReceive,
                                            api_rate: api_rate,
                                            com_rate: com_rate,
                                            com_value: com_value,
                                            currency_to_id:
                                                _addSaveTransferRegisteration
                                                    .currency_to_id,
                                            currency_fro_id:
                                                _addSaveTransferRegisteration
                                                    .currency_fro_id,
                                          );
                                          print("Value of Amount From");
                                          print(value);
                                        },
                                      ),
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      const Text(
                                        "Currency to To",
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
                                      _isLoadingproDrop
                                          ? const CircularProgressIndicator()
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
                                              maintext: "Pick any Account",
                                              SearchCtr: ToAccountIDSearch,
                                              dropdownValue: ToAccountID,
                                              items: TransFerD
                                                  .CusAccountCurrencyRC,
                                              // items: TransFerD.CusAccountCurrencyFC,
                                            ),
                                      const SizedBox(
                                        height: 10,
                                      ),

                                      CommonTextView(
                                        ctr: AmountReceive,
                                        hintxt: "Recipient Name",
                                        // icn: Icons.attach_money_sharp,
                                      ),

                                      const SizedBox(
                                        height: 20,
                                      ),
                                      InkWell(
                                          onTap: () {
                                            // _showSheet();
                                            _saveForm();
                                          },
                                          child: const CommonBtn(txt: "Send")),
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
