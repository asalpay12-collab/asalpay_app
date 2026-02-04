import 'dart:async';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/models/http_exception.dart';
import 'package:asalpay/providers/TransferOperations.dart';
import 'package:asalpay/providers/auth.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllWalletOperationDropDown.dart';
import 'package:asalpay/widgets/CommonTextView.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../TransferReceiptLetter/paymentPage.dart';
import '../constants/Constant.dart';

import 'package:mobile_scanner/mobile_scanner.dart';


// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


/// Simple full-screen scanner page
/// Full-screen QR scanner with throttling + cancel/torch controls
class _ScannerFullScreen extends StatefulWidget {
  const _ScannerFullScreen();

  @override
  State<_ScannerFullScreen> createState() => _ScannerFullScreenState();
}

class _ScannerFullScreenState extends State<_ScannerFullScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // prevents repeat callbacks
    formats: const [BarcodeFormat.qrCode],      // optional: focus on QR only
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    // Safely extract the first non-empty value
    final code = (capture.barcodes.isNotEmpty) ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    _handled = true;              // throttle
    await _controller.stop();     // stop camera before leaving
    if (!mounted) return;
    Navigator.of(context).pop<String>(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Torch toggle
          Positioned(
            bottom: 24,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.white),
                onPressed: () => _controller.toggleTorch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class Merchant extends StatefulWidget {
  final String? wallet_accounts_id;
  static const routeName = '/Merchant';
  const Merchant({required this.wallet_accounts_id, super.key, required});

  @override
  State<Merchant> createState() => _MerchantState();
}

class _MerchantState extends State<Merchant> {
  StreamSubscription<List<BalanceDisplayModel>>? _balanceSubscription;

  // Controllers & focus nodes
  final _Accountorphone = FocusNode();
  final _TransferAmount = FocusNode();
  final Accountorphone = TextEditingController();
  final FromAccountIDSeach = TextEditingController();
  final RecipientName = TextEditingController();
  final AmountReceive = TextEditingController();
  final TransferAmount = TextEditingController();
  final ToAccountIDSearch = TextEditingController();

  // State vars
  String scanBarcode = '';
  bool isloading1 = false;
  bool _isLoadingDrop_data = false;
  bool _isLoadingproDrop = false;
  bool _isLoadingExchange = false;
  bool _isLoading = false;
  bool isConnected = true;
  bool status = false;
  bool _submitted = false;
  bool _submitted1 = false;
  late String? statusText = "";
  String merchannumber = '';
  String amountReceive = '';
  String currency_name_fro = '';
  String currency_name_to = '';
  String pinNumber = '';
  String ModelErrorMessage = '';

  String? FromAccountID;
  String? ToAccountID;
  var _addSaveMerchantRegisteration = MerchantRegisteration(
    account_no_from: "", merchant_account_no: "", currency_fro_id: "", amount_fro: "",
    currency_to_id: "", amount_to: "", balance_type_id: "",
  );

  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // any init...
  }


Future<void> _ChecKMerchantAccountNumber() async {
  try {
    setState(() {
      _isLoadingproDrop = true;
      status = false;
    });

    final transferOps = Provider.of<TransferOperations>(context, listen: false);
    await transferOps.fetchAndSetfillmerchantinfo(merchannumber);

    if (transferOps.FillmerchantInfo.isNotEmpty) {
      RecipientName.text = transferOps.FillmerchantInfo[0].f_name ?? '';
      ToAccountID = transferOps.FillmerchantInfo[0].currency_id;
      setState(() => status = true);
      // If user already typed an amount, recompute
      if (TransferAmount.text.isNotEmpty) {
        _processAmount(TransferAmount.text);
      }
    } else {
      setState(() => status = false);
    }
  } on HttpException {
    setState(() => status = false);
  } catch (_) {
    setState(() => status = false);
  } finally {
    setState(() => _isLoadingproDrop = false);
  }
}


// Future<void> _ChecKMerchantAccountNumber() async {
//   var errorMessage = 'Invalid Merchant Account';
//   try {
//     await Provider.of<TransferOperations>(context, listen: false)
//         .fetchAndSetfillmerchantinfo(merchannumber);
//     setState(() {
//       status = true;
//     });
//   } on HttpException catch (error) {
//     // …your error handling…
//     setState(() {
//       status = false;
//     });
//   } catch (error) {
//     setState(() {
//       status = false;
//     });
//   }
// }



  @override
  void dispose() {
    _balanceSubscription?.cancel();
    _Accountorphone.dispose();
    _TransferAmount.dispose();
    Accountorphone.dispose();
    FromAccountIDSeach.dispose();
    RecipientName.dispose();
    AmountReceive.dispose();
    TransferAmount.dispose();
    ToAccountIDSearch.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    setState(() => _isLoadingDrop_data = true);

    final accountId = widget.wallet_accounts_id;
    if (accountId != null) {
      await Provider.of<TransferOperations>(context, listen: false)
          .fetchAndSetMerchantCusAccountCurrency(accountId);

      _balanceSubscription?.cancel();
      _balanceSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .fetchAndDisplayBalance(accountId)
          .listen((_) {}, onError: (_) {});
    }

    final TransFerD = Provider.of<TransferOperations>(context, listen: false);
    setState(() {
      FromAccountID = TransFerD.MerchantCusAccountCurrency.isNotEmpty
          ? TransFerD.MerchantCusAccountCurrency[0].currency_id
          : null;
      _isLoadingDrop_data = false;
    });
  }

  Future<void> _CheckPinNumber() async {
    _submitted1 = true;
    setState(() {
      isloading1 = true;
      ModelErrorMessage = "";
    });
    try {
      final auth = Provider.of<Auth>(context, listen: false);
      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .LoginPIN(auth.phone!, pinNumber);
    } on HttpException catch (error) {
      final msg = error.toString();
      _showErrorDialog(msg);
      setState(() => isloading1 = false);
      return;
    } catch (error) {
      _showErrorDialog(error.toString());
      setState(() => isloading1 = false);
      return;
    }
    setState(() => isloading1 = false);
    _submitted1 = false;
    _saveForm();
  }

  Future<void> _saveForm() async {
    _submitted = true;
    if (!(_form.currentState?.validate() ?? false)) return;
    _form.currentState?.save();
    setState(() => _isLoading = true);

    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      openSnackbar(context, 'No Internet Connection', secondryColor);
      setState(() => _isLoading = false);
      return;
    }

    try {
      await Provider.of<TransferOperations>(context, listen: false)
          .addSavemerchantRegistration(_addSaveMerchantRegisteration, widget.wallet_accounts_id!);
    } catch (error) {
      openSnackbar(context, error.toString(), secondryColor);
      setState(() => _isLoading = false);
      return;
    }

    try {
      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .fetchAndSetAllTr();
    } catch (_) {}

    final balances = await Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .fetchAndDisplayBalance(widget.wallet_accounts_id ?? "")
        .first;
    if (balances.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            merchannumber,
            "Phone",
            ReceiverLabelRec: "Merchant",
            ReceiverAmount: currency_name_to + amountReceive,
            ReceiverName: balances.first.f_name!,
            senderAccount: widget.wallet_accounts_id!,
            senderAmount: '$currency_name_fro${TransferAmount.text}',
            senderName: "${balances.first.f_name} ${balances.first.m_name}",
          ),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _showErrorDialog(String message) {
    showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: Text(message),
        content: const Text("Enter a valid pin"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Okay'))],
      );
    });
  }

  // Future<void> scanQR() async {
  //   String code;
  //   try {
  //     code = await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.QR);
  //   } on PlatformException {
  //     code = 'Error scanning';
  //   }
  //   if (!mounted) return;
  //   setState(() => merchannumber = code);
  //   Accountorphone.text = code;
  //   await _ChecKMerchantAccountNumber();
  // }

  Future<void> scanQR() async {
  final code = await Navigator.of(context).push<String?>(
    MaterialPageRoute(
      builder: (_) => const _ScannerFullScreen(),
    ),
  );
  if (code == null) return;             // user cancelled
  setState(() {
    merchannumber = code;
    Accountorphone.text = code;
  });
  await _ChecKMerchantAccountNumber();
}




void _processAmount(String input) async {
  if (FromAccountID == null || ToAccountID == null) return;

  final transferOps = Provider.of<TransferOperations>(context, listen: false);
  final CurrencyDataFrom = transferOps.findByIdFromMerchantCurrency(FromAccountID!);
  final CurrencyDataTo = transferOps.findByCurrencyMerchantID(ToAccountID!);

  if (CurrencyDataFrom == null || CurrencyDataTo == null) return;

  setState(() {
    currency_name_fro = CurrencyDataFrom.currency_name!;
    currency_name_to = CurrencyDataTo.currency_name!;
  });

  double? numericValue = double.tryParse(input);
  if (numericValue == null) {
    openSnackbar(context, "Invalid amount", secondryColor);
    return;
  }

  if (FromAccountID == ToAccountID) {
    setState(() {
      amountReceive = numericValue.toStringAsFixed(2);
      AmountReceive.text = "$currency_name_to $amountReceive";
    });
  } else {
    setState(() => _isLoadingExchange = true);
    try {
      final result = await transferOps.MerchantExchange(
        input,
        CurrencyDataTo.currency_id!,
        CurrencyDataFrom.currency_id!,
      );
      final raw = result?['result']?['amount_to']?.toString() ?? '0';
      final parsed = double.parse(raw.replaceAll(RegExp(r'[^0-9\.]'), ''));
      setState(() {
        amountReceive = parsed.toStringAsFixed(2);
        AmountReceive.text = "$currency_name_to $amountReceive";
      });
    } catch (e) {
      openSnackbar(context, "Error: ${e.toString()}", secondryColor);
    } finally {
      setState(() => _isLoadingExchange = false);
    }
  }

  _addSaveMerchantRegisteration = MerchantRegisteration(
    account_no_from: _addSaveMerchantRegisteration.account_no_from,
    merchant_account_no: merchannumber,
    currency_fro_id: FromAccountID,
    amount_fro: input,
    currency_to_id: ToAccountID,
    amount_to: amountReceive,
    balance_type_id: _addSaveMerchantRegisteration.balance_type_id,
  );
}

@override
Widget build(BuildContext context) {
  final TransFerD = Provider.of<TransferOperations>(context, listen: false);

  return Scaffold(
    backgroundColor: secondryColor.withOpacity(0.9),
    body: Padding(
      padding: EdgeInsets.only(top: AppBar().preferredSize.height, left: 15, right: 15),
      child: Column(
        children: [
          // Top bar
          Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white)),
            const SizedBox(width: 15),
            const Text("Merchant Pay", style: TextStyle(color: Colors.white, fontSize: 20)),
          ]),

          // Form
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              Form(
                key: _form,
                child: Column(children: [
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    decoration: const BoxDecoration(
                      image: DecorationImage(image: AssetImage("assets/asalpayscreens.png"), fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 10),
                            const Text(
                              "Merchant Account Transfer",
                              style: TextStyle(fontSize: 16, color: secondryColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),

                            AllWalletOperationDropDown(
                              hintxt: "Search Account",
                              onChanged: (value) async {
                                setState(() => FromAccountID = value);
                                if (TransferAmount.text.isNotEmpty) {
                                  _processAmount(TransferAmount.text);
                                }
                              },
                              maintext: "Pick any Account",
                              SearchCtr: FromAccountIDSeach,
                              dropdownValue: FromAccountID,
                              TransferItems: TransFerD.MerchantCusAccountCurrency,
                            ),

                            const SizedBox(height: 10),

                            // --- Merchant account entry + QR (always visible)

                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: AllformFields(
                                      ctr: Accountorphone,
                                      focusNode: _Accountorphone,
                                      hintxt: "Merchant Account",
                                      icn: Icons.account_balance_rounded,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                      textInputAction: TextInputAction.done,
                                      validator: (v) => (_submitted && (v == null || v.isEmpty)) ? 'Required' : null,
                                      onChanged: (value) async {
                                        merchannumber = value.trim();
                                        if (merchannumber.length > 5) {
                                          setState(() => _isLoadingproDrop = true);
                                          await _ChecKMerchantAccountNumber();
                                          setState(() => _isLoadingproDrop = false);
                                        } else {
                                          setState(() => status = false);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 56,
                                    child: Stack(
                                      fit: StackFit.expand, // <-- fill height
                                      children: [
                                        OutlinedButton(
                                          onPressed: scanQR,
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero, // no extra vertical padding
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Icon(Icons.qr_code_scanner),
                                        ),
                                        if (_isLoadingproDrop)
                                          const Positioned.fill(
                                            child: ColoredBox(
                                              color: Colors.white70,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 18, height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                            // Row(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Expanded(
                            //       child: AllformFields(
                            //         ctr: Accountorphone,
                            //         focusNode: _Accountorphone,
                            //         hintxt: "Merchant Account",
                            //         icn: Icons.account_balance_rounded,
                            //         keyboardType: const TextInputType.numberWithOptions(decimal: false),
                            //         textInputAction: TextInputAction.done,
                            //         validator: (v) => (_submitted && (v == null || v.isEmpty)) ? 'Required' : null,
                            //         onChanged: (value) async {
                            //           merchannumber = value.trim();
                            //           if (merchannumber.length > 5) {
                            //             setState(() => _isLoadingproDrop = true);
                            //             await _ChecKMerchantAccountNumber();
                            //             setState(() => _isLoadingproDrop = false);
                            //           } else {
                            //             setState(() => status = false);
                            //           }
                            //         },
                            //       ),
                            //     ),
                            //     const SizedBox(width: 8),
                            //     SizedBox(
                            //       width: 56,
                            //       height: 56,
                            //       child: Stack(
                            //         alignment: Alignment.center,
                            //         children: [
                            //           OutlinedButton(
                            //             onPressed: scanQR,
                            //             style: OutlinedButton.styleFrom(
                            //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            //             ),
                            //             child: const Icon(Icons.qr_code_scanner),
                            //           ),
                            //           if (_isLoadingproDrop)
                            //             const Positioned.fill(
                            //               child: ColoredBox(
                            //                 color: Colors.white70,
                            //                 child: Center(
                            //                   child: SizedBox(
                            //                     width: 18,
                            //                     height: 18,
                            //                     child: CircularProgressIndicator(strokeWidth: 2),
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),

                            const SizedBox(height: 10),

                            status
                                ? Column(children: [
                                    CommonTextView(
                                      ctr: RecipientName,
                                      hintxt: "Recipient Name",
                                      icn: Icons.person,
                                    ),
                                    const SizedBox(height: 10),
                                    AllformFields(
                                      ctr: TransferAmount,
                                      focusNode: _TransferAmount,
                                      hintxt: "Enter Amount",
                                      icn: Icons.attach_money_sharp,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      validator: (v) => (_submitted && v!.isEmpty) ? 'Required' : null,
                                      onEditingComplete: () async {
                                        final input = TransferAmount.text.trim();
                                        _TransferAmount.unfocus();
                                        if (input.isEmpty) {
                                          openSnackbar(context, "Enter amount", secondryColor);
                                          return;
                                        }
                                        _processAmount(input);
                                      },
                                    ),

                                    const SizedBox(height: 10),
                                    _isLoadingExchange
                                        ? const Center(child: CircularProgressIndicator())
                                        : CommonTextView(
                                            ctr: AmountReceive,
                                            hintxt: "Amount to Receive",
                                            icn: Icons.attach_money_sharp,
                                          ),

                                    const SizedBox(height: 20),

                                    // QR button removed here (already shown above)

                                    const SizedBox(height: 20),
                                    !_isLoadingExchange
                                        ? InkWell(
                                            onTap: () {
                                              _submitted = true;
                                              if (_form.currentState?.validate() ?? false) _CheckPinNumber();
                                            },
                                            child: const CommonBtn(txt: "Send"),
                                          )
                                        : const SizedBox(),
                                    const SizedBox(height: 30),
                                  ])
                                : SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEFEF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFC6C6)),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.error_outline, color: Colors.redAccent),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "Please enter a valid merchant code",
                                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  ]),
                ),
              ]),
          ),
        ],
      ),
    ),
  );
}
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
  