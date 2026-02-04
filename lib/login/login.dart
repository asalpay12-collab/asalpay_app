import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/OTP/PasswordOPT.dart';
import 'package:asalpay/home/homescreen.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../OTP/register.dart';
import '../constants/Constant.dart';
import '../models/http_exception.dart';
import '../providers/auth.dart';
import 'dart:io' show Platform;
import 'package:asalpay/services/api_urls.dart';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';


import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asalpay/firebase/fcm_token_manager.dart';
import 'package:asalpay/firebase/device_registration_service.dart';

class KeyboardDismissOnTap extends StatelessWidget {
  final Widget child;

  const KeyboardDismissOnTap({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus(); 
        }
      },
      child: child,
    );
  }
}


class Login extends StatefulWidget {
 


  const Login({super.key, required});
  static const routeName = '/Login';
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

BalanceDisplayModel? homeCurrentBalance;

HomeTransactionModel? homeCurrentTransaction;

StreamSubscription<List<HomeTransactionModel>>? _transactionSubscription;
  List<HomeTransactionModel> _transactions = [];
  

  static const routeName = '/auth';
  final Map<String, String> _authData = {
    'phone': '',
    'password': '',
    "version":''
  };

    bool canNavigate = false;


  //6/1/24


  Future<void> _subscribeToTransactions(String accountId) async {
    _transactionSubscription?.cancel();
    _transactionSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndStreamAllTransactions()
      .listen((transactions) {
        if (!mounted) return;
        if (transactions.isNotEmpty) {
          setState(() {
            _transactions = transactions;
            homeCurrentTransaction = transactions.first; 
          });
        }
        print("New transactions received: $transactions");
      }, onError: (error) {
        if (!mounted) return;
        print("Error receiving transaction data: $error");
      });
  }


  Future<void> _subscribeToBalance(String accountId) async {
  _balanceSubscription?.cancel();  
  _balanceSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
    .fetchAndDisplayBalance(accountId)
    .listen((balances) {
      if (!mounted) return;
      if (balances.isNotEmpty) {
        setState(() {
          //_balances = balances;

          homeCurrentBalance = balances.first;  
          
        });
      }
      print("New balances received: $balances");
    }, onError: (error) {
      if (!mounted) return;
      
      print("Error receiving balance data: $error");
    });
}

  // 22/05/24

  Future<void> prefetchImages(List<HomeSliderModel> sliderModels, BuildContext context) async {
  for (var model in sliderModels) {
    if (!mounted) return; 
    try {
      String fullImageUrl = '${ApiUrls.BASE_URL}${model.imageUrl}'; 
      final cacheManager = CachedNetworkImageProvider(fullImageUrl);
      await precacheImage(cacheManager, context);
    } catch (e) {
      print("Failed to cache image: ${model.imageUrl}, Error: $e");
    }
  }
}
  //from here streamBuilder, 4/7/2024


StreamSubscription<List<BalanceDisplayModel>>? _balanceSubscription;
  bool _isLoading = true;

  void _subscribeToBalanceStream() {
  
  final phone = _authData['phone'];
  if (phone != null && phone.isNotEmpty) {
    _balanceSubscription = Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndDisplayBalance(phone) 
      .listen(
        (balances) {
          setState(() {
            
            _isLoading = false;
          });
        }, onError: (error) {
         
          setState(() {
            _isLoading = false;
          });
        }
      );
  } else {
    
    setState(() {
      _isLoading = false;
     
    });
  }
}


  @override
  void dispose() {
    _balanceSubscription?.cancel();
    super.dispose();
  }


  //to here




  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController PasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController textEditingController = TextEditingController();
  late FlCountryCodePicker countrycodePicker;
  // final countrycodePicker = FlCountryCodePicker();
  // CountryCode? countryCode;
  CountryCode? _countryCode;
  // String _selectedCountryCode = "+252";
  bool isloading = false;
  bool ischeck = false;
  bool obsecure = true;
  bool isConnected = false;
  late String? statusText = "";
  late Box box1;

  RegExp pass_valid = RegExp(r"(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W)");
  //A function that validate user entered password
  bool validatePassword(String pass) {
    String password = pass.trim();
    if (pass_valid.hasMatch(password)) {
      return true;
    } else {
      return false;
    }
  }

  late String _phoneNumber;



  @override
  void initState() {

    //20/7/2024

    _checkNetworkStatus();

    //here 4/7/24

    // _subscribeToBalanceStream();


    // TODO: favorite first lists;
    final favoriteCountries = ['SO', 'KE', 'UG', 'US', 'CN'];
    countrycodePicker = FlCountryCodePicker(
      favorites: favoriteCountries,
      favoritesIcon: const Icon(
        Icons.star,
        color: primaryColor,
      ),
    );
    _countryCode?.dialCode == "+252";
    super.initState();
    createBox();
  }


  Future<void> _checkNetworkStatus() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await _showNetworkMessage(context);
    }
  }

  Future<void> _showNetworkMessage(BuildContext context) async {
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
          const Text('No Connection'),
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
                // Function to open Wi-Fi settings
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
              child: const Text('Open Data'),
            ),
          ],
        ),
      ],
    ),
  );
}



  void createBox() async {
    box1 = await Hive.openBox("logindata");
    getData();
  }

  void getData() async {
    if (box1.get("phone") != null) {
      phoneController.text = box1.get("phone");
      ischeck = true;
      setState(() {});
    }

    if (box1.get("countryCode") != null) {
      var defaultCode = "+252";
      _countryCode?.dialCode ?? defaultCode;
      box1.get("countryCode");
      ischeck = true;
      setState(() {});
    }
  }




// void _showUpdateDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (ctx) => AlertDialog(
//       title: const Text('Update Required'),
//       content: const Text(
//         'This version of the app is outdated. Please update it to continue using AsalPay.',
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(ctx).pop(),
//           child: const Text('Later'),
//         ),
//         ElevatedButton(
//           onPressed: () async {
//             const url = 'https://play.google.com/store/apps/details?id=com.asal.asalpay'; 
//             if (await canLaunchUrl(Uri.parse(url))) {
//               await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//             } else {
//               print('Could not launch Play Store URL');
//             }
//           },
//           child: const Text('Update Now'),
//         ),
//       ],
//     ),
//   );
// }


void _showUpdateDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update Required'),
      content: const Text(
        'This version of the app is outdated. Please update it to continue using AsalPay.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () async {
            final androidUrl = 'https://play.google.com/store/apps/details?id=com.asal.asalpay';
            final iosUrl = 'https://apps.apple.com/ug/app/asal-pay/id6502257400';

            final url = Platform.isIOS ? iosUrl : androidUrl;

            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              print('Could not launch store URL');
            }
          },
          child: const Text('Update Now'),
        ),
      ],
    ),
  );
}

 
  @override
  Widget build(BuildContext context) {
    void ShowUpcomingAlert1() {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        title: "Upcoming",
        text: "New Service Coming Soon!",
        confirmBtnText: "WAIT!",
// backgroundColor: secondryColor.withOpacity(0.1),
        barrierDismissible: true,
        onConfirmBtnTap: () => Navigator.pop(context),
        textColor: primaryColor,
        confirmBtnColor: primaryColor,
        titleColor: secondryColor,

        confirmBtnTextStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }


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

      // Check if connected
      isConnected = !results.contains(ConnectivityResult.none);

      // Debug prints
      print('Connectivity Results: $results');
      print('Is Connected: $isConnected');
    } else {
      // Handle the case where snapshot has no data
      print('No connectivity data available.');
    }

    String statusText = isConnected ? 'Connected' : 'No Internet Connection';
    final icon = isConnected ? null : const Icon(Icons.wifi);

    if (!isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _NetworkMessage(context);
      });
    }

        return Scaffold(
          backgroundColor: secondryColor,
          body: KeyboardDismissOnTap(
          child: Padding(
            padding: EdgeInsets.only(
                top: AppBar().preferredSize.height, left: 14, right: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.height * 0.03,
                    ),
                   
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                    Center(
                                      child: Image.asset(
                                        'assets/asalpay.png',
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                      ),
                                    ),

                                  ],
                                ),
                                // SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Form(
                                    // autovalidateMode: AutovalidateMode.onUserInteraction,
                                    key: _formkey,
                                    child: Column(
                                      children: [
                                        Container(
                                          child: TextFormField(
                                            style: TextStyle(
                                              color: secondryColor,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.04,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            onSaved: (value) {
                                              var defaultCode =
                                                  "+252"; // set your default country code here
                                              var phoneNumber =
                                                  phoneController.text.trim();

                                              var countryCode =
                                                  _countryCode?.dialCode ??
                                                      defaultCode;

                                              _authData['phone'] =
                                                  '$countryCode$phoneNumber';
                                            },
                                            validator: (value) {
                                              return null;
                                            },
                                            onChanged: (value) {},
                                            autovalidateMode:
                                                AutovalidateMode.always,
                                            controller: phoneController,
                                            keyboardType: TextInputType.phone,
                                            textInputAction:
                                                TextInputAction.next,
                                            maxLines: 1,
                                            decoration: InputDecoration(
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                    color: primaryColor,
                                                    width: 1.5),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: secondryColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                              hintText: 'xxxxxxxxx',
                                              hintStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                      color: Colors.black45),

                                              contentPadding:
                                                  const EdgeInsets.only(top: 16),

                                              prefixIcon: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  // color: Colors.black,
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                // margin: EdgeInsets.symmetric(horizontal: 6),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () async {
                                                        final code =
                                                            await countrycodePicker
                                                                .showPicker(
                                                                    context:
                                                                        context);
                                                        setState(() {
                                                          _countryCode = code!;
                                                        });
                                                      },
                                                      child: Container(
                                                        child: Text(
                                                          // _countryCode
                                                          //         ?.dialCode ??
                                                          //     _selectedCountryCode,

                                                          _countryCode
                                                                  ?.dialCode ??
                                                              "+252",
                                                          style: TextStyle(
                                                            color:
                                                                secondryColor,
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.04,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        // child: Icon(
                                                        //   Icons.phone_iphone,
                                                        //
                                                        //   color: primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.03),

                                        //password textfield;
                                        //todo: password;
                                        TextFormField(
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          controller: PasswordController,
                                          // keyboardType: TextInputType.numberWithOptions(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(color: Colors.black45),
                                          obscureText: obsecure,
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                  color: primaryColor,
                                                  width: 1.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: secondryColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.lock,
                                              color: primaryColor,
                                            ),
                                            suffixIcon: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  obsecure = !obsecure;
                                                });
                                              },
                                              child: obsecure
                                                  ? const Icon(
                                                      FontAwesomeIcons.eyeSlash,
                                                      color: secondryColor,
                                                      size: 18,
                                                    )
                                                  : const Icon(
                                                      Icons.remove_red_eye,
                                                      color: primaryColor,
                                                    ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.only(top: 18),
                                            hintText: "Password",
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .copyWith(
                                                    color: Colors.black45),
                                          ),
                                          onSaved: (value) {
                                            _authData['password'] = value!;

                                          },
                                        ),
                                        // CommonPasswordScreen(),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.03),

                                        Row(
                                          children: [
                                            Expanded(
                                              child: CheckboxListTile(
                                                checkColor: Colors.white,
                                                activeColor: primaryColor,
                                                title: const Text(
                                                  "Remember me",
                                                  style: TextStyle(
                                                    color: secondryColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.only(left: 5),

                                                value: ischeck,
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    ischeck = newValue!;
                                                  });
                                                },
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading, //  <-- leading Checkbox
                                              ),
                                            ),
                                            InkWell(
                                              child: Text(
                                                "Forgot Password",
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  // color: secondryColor,
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const PassWordOPT()));
                                              },
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.03),
                                        //todo:NetworkChecking;
                                        // networkProvider.hasNetwork?
                                        isConnected
                                            ? Center(
                                                child: isloading
                                                    ?
                                                    // CircularProgressIndicator(
                                                    // color: primaryColor,
                                                    // )
                                                    const LogoandSpinner(
                                                        imageAssets:
                                                            'assets/asalicon.png',
                                                        reverse: true,
                                                        arcColor: primaryColor,
                                                        spinSpeed: Duration(
                                                            milliseconds: 500),
                                                      )
                                                    : InkWell(
                                                        onTap: () {
                                                          print(_authData['phone']);
                                                          print(_authData['password']);
                                                          print(_authData['version']);
                                                          _submit(context);

                                                          savedlogin();
                                                        },
                                                        child: const CommonBtn(
                                                          txt: "Login",
                                                        ),
                                                      ),
                                              )
                                            : Text(
                                                'Network Status: $statusText'),
                                        // ):Text("No internet-connection"),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.03),
                                        InkWell(

                                          child: RichText(
                                            text: TextSpan(
                                              text: "Don't have an account? ",
                                              style: TextStyle(
                                                // color:primaryColor,
                                                color: secondryColor,
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.04,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: [
                                                TextSpan(
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const Register()));
                                                        },
                                                  text: '  Register Here!',
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    // color: secondryColor,
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.04,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.03),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred!'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Okay',
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }


Future<void> _submit(BuildContext context) async {
  if (!_formkey.currentState!.validate()) {
    print("Form validation failed");
    return;
  }
  _formkey.currentState!.save();

  // Check for network connectivity
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    print("No network connection");
    await _showNetworkMessage(context); 
    return;
  }

  if (!mounted) {
    print("Widget not mounted after form save");
    return;
  }

  setState(() {
    isloading = true;
  });

  try {
    print("Attempting to login with phone: ${_authData['phone']}");
    await Provider.of<Auth>(context, listen: false).login(
      _authData['phone'], 
      _authData['password'], 
      _authData['version'], 
      context
    );





    print("Login successful");


    if (!mounted) {
      print("Widget unmounted after login");
      return;
    }




    // String walletAccountsId = _authData['phone']?.replaceAll('+', '') ?? 'default_id';

    String walletAccountsId = _authData['phone']?.replaceAll('+', '') ?? '';


final prefs = await SharedPreferences.getInstance();
await prefs.setString('wallet_accounts_id', walletAccountsId);
print("✅ Saved wallet_accounts_id to SharedPreferences: $walletAccountsId");


    final homeSliderAndTransactionProvider = Provider.of<HomeSliderAndTransaction>(context, listen: false);

    print("Fetching balances for wallet account ID: $walletAccountsId");

  
  // 2) Slider images

      print("Starting to fetch slider images");

      final List<HomeSliderModel> sliderImages = await homeSliderAndTransactionProvider.fetchAndSetSliderImages();
      print("Slider images received: ${sliderImages.length} images");

      

// 3) Recent transactions
final List<HomeTransactionModel> transactions = await homeSliderAndTransactionProvider.fetchAndSetAllTr();

// 4) Prefetch slider images into cache so HomeScreen shows immediately
await prefetchImages(sliderImages, context);



    //updating with FCM

  // FCM Registration after successful login
    try {  

        final currentToken = await FcmTokenManager.getCurrentToken();
        final savedToken = await FcmTokenManager.getSavedToken();

      if (currentToken != null && currentToken.isNotEmpty && savedToken != currentToken) {
        await DeviceRegistrationService.registerDevice(
          walletAccountsId: walletAccountsId,
          fcmToken: currentToken,
        );
        await FcmTokenManager.saveToken(currentToken);
      }
    } catch (e) {
      print("FCM Error: $e");  // Handle FCM errors separately
    }




    Completer<List<BalanceDisplayModel>> completer = Completer();
    StreamSubscription<List<BalanceDisplayModel>>? subscription;
    subscription = homeSliderAndTransactionProvider.fetchAndDisplayBalance(walletAccountsId).listen(
      (balances) {
        if (!completer.isCompleted) {
          print("Balances fetched successfully: ${balances.length} items");
          completer.complete(balances);
          subscription?.cancel();
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          print("Error fetching balances: $error");
          completer.completeError(error);
          subscription?.cancel();
        }
      }
    );

    List<BalanceDisplayModel> balances = await completer.future;

    final BalanceDisplayModel? balanceSeed =
    homeCurrentBalance ?? (balances.isNotEmpty ? balances.first : null);


// Prefetch avatar if available
final String? avatarUrl = balanceSeed?.image;
if (avatarUrl != null && avatarUrl.isNotEmpty) {
  final fullUrl = avatarUrl.startsWith('http') 
      ? avatarUrl 
      : '${ApiUrls.BASE_URL}$avatarUrl';
  await precacheImage(CachedNetworkImageProvider(fullUrl), context);
}

    // print("Starting to fetch slider images");
    // List<HomeSliderModel> sliderImages = await homeSliderAndTransactionProvider.fetchAndSetSliderImages();
    // print("Slider images received: ${sliderImages.length} images");

    if (!mounted) {
      print("Widget unmounted before navigation");
      return;
    }

    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(
    //     builder: (context) => HomeScreen(
    //       wallet_accounts_id: walletAccountsId,
    //       fromLogin: true,
    //       initialBalances: balances,
    //       initialSliderImages: sliderImages,
         
    //      initialHomeBalance: homeCurrentBalance,

    //      initialHomeTransaction: homeCurrentTransaction,

    //     ),
    //   ),
    // );


// after you computed: balances, transactions, sliderImages, balanceSeed, avatar prefetch ...

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          wallet_accounts_id: walletAccountsId,
          fromLogin: true,

          // optional (HomeScreen doesn’t read this list; harmless if kept)
          initialBalances: balances,

          // 👇 ensure these are passed
          initialSliderImages: sliderImages,
          initialTransactions: transactions,
          initialHomeBalance: balanceSeed, // <- use the seed you just computed
          initialHomeTransaction: homeCurrentTransaction ??
              (transactions.isNotEmpty ? transactions.first : null),
        ),
        settings: const RouteSettings(name: HomeScreen.routeName),
      ),
      (_) => false,
    );




    //here

    print('hello welcome');


    // } on HttpException catch (error) {
    //   var errorMessage = 'Authentication failed';
    //   if (error.toString().contains('INVALID_PHONE')) {
    //     errorMessage = 'Could not find a user with that phone .';
    //   } else if (error.toString().contains('INVALID_PASSWORD')) {
    //     errorMessage = 'Invalid password.';
    //   } else if (error.toString().contains('INACTIVE_ACCOUNT')) {
    //     errorMessage = 'Your Account Is not Active.';
    //   } else if (error.toString().contains('OP')) {
    //     errorMessage = 'operation failed .';
    //   }

    } on HttpException catch (error) {
  final errorStr = error.toString();
  print('HttpException: $errorStr');

  if (errorStr.contains('APP_VERSION_OUTDATED')) {
    _showUpdateDialog(context);
    return;
  }

  var errorMessage = 'Authentication failed';
  if (errorStr.contains('INVALID_PHONE')) {
    errorMessage = 'Could not find a user with that phone.';
  } else if (errorStr.contains('INVALID_PASSWORD')) {
    errorMessage = 'Invalid password.';
  } else if (errorStr.contains('INACTIVE_ACCOUNT')) {
    errorMessage = 'Your Account is not Active.';
  } else if (errorStr.contains('OP')) {
    errorMessage = 'Operation failed.';
  }

 


      print(error.toString());
      print('hello welcome');

      // _showErrorDialog(error.toString());

    // to here

 _showErrorDialog(errorMessage);

  } catch (error) {
    print("Error during operations: $error");
    _showErrorDialog('Error occurred. Please try again later.');
  } finally {
    if (!mounted) {
      print("Widget not mounted in finally block");
      return;
    }
    setState(() {
      isloading = false;
    });
  }
}


Future<void> _NetworkMessage(BuildContext context) async {
  final screenSize = MediaQuery.of(context).size;
  final bool isSmallScreen = screenSize.width < 600;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/WD5.png", width: screenSize.width * 0.07),
          const SizedBox(width: 08),
          Expanded(
            child: Text(
              'No Connection',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: screenSize.width * 0.145),
            ),
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
              padding: EdgeInsets.all(screenSize.width * 0.015),
              child: Icon(
                Icons.close,
                color: primaryColor,
                size: screenSize.width * 0.05,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'You are currently disconnected from the network.',
        style: TextStyle(fontSize: screenSize.width * 0.04),
      ),
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
                  EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.02,
                    horizontal: screenSize.width * 0.06,
                  ),
                ),
              ),
              child: Text(
                'Open Wi-Fi',
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: screenSize.width * 0.05),
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
                  EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.02,
                    horizontal: screenSize.width * 0.06,
                  ),
                ),
              ),
              child: Text(
                'Open Data',
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}



// //todo:Network Message;

  void savedlogin() {
    if (ischeck) {
var defaultCode = "+252";
      box1.put("phone", phoneController.text);
      // box1.put("pass", PasswordController.text);
    box1.put("countryCode", _countryCode?.dialCode ?? defaultCode);
    }
    if (!ischeck) {
      box1.delete('phone');
      // box1.delete('pass');
    }
  }
}
