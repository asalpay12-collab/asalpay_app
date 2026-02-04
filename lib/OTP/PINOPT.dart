import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:asalpay/services/api_urls.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sms_autofill/sms_autofill.dart';

import '../constants/Constant.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../snack_bar/open_snack_bar.dart';
import '../widgets/commonBtn.dart';
import 'PINverify.dart';

import 'package:http/http.dart' as http;

class PINdOPT extends StatefulWidget {
  
  static const routeName = '/register';
  const PINdOPT({super.key});
  static String verify = "";
  static String PhonNumber = "";

  @override
  _PINdOPTState createState() => _PINdOPTState();
}


   void appLog(String message) {
  debugPrint("🟢[MYAPP] $message");
}


void startSmsListener() async {
  // SmsAutoFill().listenForCode;
}

class OtpAttemptManager {
  static const String _storageKey = 'otp_attempts';
  static const int _maxDailyAttempts = 3;

  static Future<void> recordOtpAttempt(String phoneNumber, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getStringList(_storageKey) ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final validAttempts = attempts.where((entry) {
      final parts = entry.split('|');
      return now - int.parse(parts[2]) < 24 * 60 * 60 * 1000;
    }).toList();

    validAttempts.add('$phoneNumber|$type|$now');
    await prefs.setStringList(_storageKey, validAttempts);
  }

  static Future<int> getRemainingAttempts(String phoneNumber, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getStringList(_storageKey) ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final count = attempts.where((entry) {
      final parts = entry.split('|');
      return parts[0] == phoneNumber && 
             parts[1] == type && 
             (now - int.parse(parts[2])) < 24 * 60 * 60 * 1000;
    }).length;

    return _maxDailyAttempts - count;
  }
}

class _PINdOPTState extends State<PINdOPT> {

   late TextEditingController phoneOTP;
  final FocusNode _phoneFocusNode = FocusNode();
  bool _attemptsLoaded = false;
  late FlCountryCodePicker countrycodePicker;
  CountryCode? _countryCode;
  bool _isLoading = false;
  final _form = GlobalKey<FormState>();
  String? authStatus = "";
  bool _submitted = false;
  Timer? _debounce;

  final somalia = CountryCode.fromMap({
    'name': 'Somalia',
    'code': 'SO',
    'dial_code': '+252',
  });

  @override
  void initState() {
    super.initState();

    startSmsListener();

    phoneOTP = TextEditingController();
    
  countrycodePicker = const FlCountryCodePicker(
    showDialCode: true,
    showSearchBar: true,
    favoritesIcon: Icon(Icons.star, color: primaryColor),
    favorites: ['SO', 'KE'],
  );

  _countryCode = CountryCode.fromMap({
    'name': 'Somalia',
    'code': 'SO',
    'dial_code': '252',
  });

  }

  void _onPhoneNumberChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {});
    });
  }

  void _loadInitialAttempts() async {
    final remaining = await OtpAttemptManager.getRemainingAttempts(
      _fullPhoneNumber, 
      'forget_pin'
    );
    if (mounted) setState(() => _attemptsLoaded = true);
  }




String get _fullPhoneNumber {
  final rawDialCode = _countryCode?.dialCode ?? '252';
  final dialCode = rawDialCode.startsWith('+') ? rawDialCode : '+$rawDialCode';
  final rawPhone = phoneOTP.text.trim();
  final full = "$dialCode$rawPhone";
  appLog(" [MYAPP] Full PIN Reset Phone Number: $full");
  return full;
}




  @override
  void dispose() {
    _phoneFocusNode.dispose();
    phoneOTP.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _sendPinResetOtp(BuildContext context) async {
    setState(() => _isLoading = true);
    final remainingAttempts = await OtpAttemptManager.getRemainingAttempts(
      _fullPhoneNumber, 
      'forget_pin'
    );

    if (remainingAttempts <= 0) {
      if (mounted) {
        setState(() => _isLoading = false);
        openSnackbar(context, "Maximum OTP requests reached. Try again tomorrow.", Colors.red);
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiUrls.BASE_URL}/VerificationController/createCode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': _fullPhoneNumber,
          'type': 'forget_pin',
        }),
      ); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await OtpAttemptManager.recordOtpAttempt(_fullPhoneNumber, 'forget_pin');
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => MyPINVerify(
                phoneNumber: _fullPhoneNumber,
                type: 'forget_pin',
              ),
            ));
          }
        } else {
          openSnackbar(context, data['message'] ?? "Verification failed", secondryColor);
        }
      } else {
        openSnackbar(context, "Error: ${response.reasonPhrase}", secondryColor);
      }
    } catch (e) {
      openSnackbar(context, "Connection error: $e", secondryColor);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



Future<void> _ChecKPhoneNumber() async {
  FocusScope.of(context).unfocus();
  _submitted = true;

  if (!(_form.currentState?.validate() ?? false)) {
    setState(() => _isLoading = false);
    appLog("[MYAPP] Invalid phone form");
    return;
  }

  setState(() => _isLoading = true);

  appLog("[MYAPP] Starting PIN Check for: $_fullPhoneNumber");

  try {
    await Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .checkNumber(_fullPhoneNumber);

    appLog("[MYAPP] Number exists. Proceeding to send OTP...");
    await _sendPinResetOtp(context);

  } on HttpException catch (error) {
    String errorMessage = 'An error occurred. Please try again.';
    if (error.toString().contains('not registered')) {
      errorMessage = 'This number is not registered';
    }
    appLog("[MYAPP] HttpException: $errorMessage");
    openSnackbar(context, errorMessage, secondryColor);

  } catch (error) {
    appLog("[MYAPP] Unexpected error: $error");
    openSnackbar(context, 'An unexpected error occurred', secondryColor);

  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      // backgroundColor: Color(0xfff7f6fb),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 32,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    "assets/otp2.png",
                  ),
                ),

                const Text(
                  'Reset Your Pin',
                  style: TextStyle(
                    fontSize: 22,
                    color: secondryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Add your phone number. we'll send you a verification code so we know you're real",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 28,
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        //todo: PhoneNumber;

                        Form(
                          key: _form,
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone Field is Required.';
                              } else if (value.length < 9) {
                                return "Phone should be at least 9 digits";
                              }
                              return null; // Value is valid
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onChanged: (value) {},
                            controller: phoneOTP,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            maxLines: 1,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: primaryColor, width: 1.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: secondryColor,
                                  width: 1.5,
                                ),
                              ),
                              prefixIcon: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  // color: Colors.black,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                // margin: EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final code = await countrycodePicker
                                            .showPicker(context: context);
                                        setState(() {
                                          _countryCode = code!;
                                        });
                                      },
                                      child: Container(
                                        child: Text(
                                          _countryCode?.dialCode ?? "+252",
                                          style: const TextStyle(
                                            color: secondryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              hintText: 'Enter PhoneNumber',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(color: Colors.black45),
                              contentPadding: const EdgeInsets.only(top: 16),
                            ),
                          ),
                        ),


                        const SizedBox(
                          height: 30,
                        ),
Column(
  children: [
    FutureBuilder<int>(
      future: OtpAttemptManager.getRemainingAttempts(
        _fullPhoneNumber,
        'forget_pin',
      ),
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 3;
        final validPhone = phoneOTP.text.trim().length >= 9; // Changed to 9 digits
        
        // Debug logs
        print('Current phone: ${_fullPhoneNumber}');
        print('Remaining attempts: $remaining');

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: validPhone 
              ? Text(
                  'Remaining attempts: ${remaining.clamp(0, 3)}',
                  style: TextStyle(
                    color: remaining > 0 ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : SizedBox.shrink(),
        );
      },
    ),
  ],
),


                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(
                                  child:
                                  // CircularProgressIndicator(),
                                  LogoandSpinner(
                                    imageAssets: 'assets/asalicon.png',
                                    reverse: true,
                                    arcColor: primaryColor,
                                    spinSpeed: Duration(milliseconds: 500),
                                  ),
                                )
                              : InkWell(
                                  onTap: () {
                                    // _OptVerification();
                                    _ChecKPhoneNumber();
                                  },
                                  child: const CommonBtn(
                                    txt: "Verify",
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
        ),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return ListView(
              children: [
                AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Image.asset(
                    'assets/otp4.png',
                    fit: BoxFit.contain,
                    height: 200,
                    width: 200,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Verification",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 20),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Enter 4 digit code sent to your phone number",
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
                        // borderColor: Color(0xFF512DA8),
                        borderColor: primaryColor,
                        onSubmit: (String verificationCode) {
                          //
                        },
                      ),
                      const SizedBox(
                        height: 80,
                      ),
                      Text(
                        "I didn't receive the code",
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        "Resend Code",
                        style: TextStyle(
                          color: secondryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    InkWell(
                        onTap: () {
                          Navigator.pop(context);

                        },
                        child: const CommonBtn(txt: "Verify"))
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMyDialog2() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Icon(
                Icons.check_circle,
                // color: secondryColor,
                color: primaryColor,
                size: 130,
              ),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Done",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "You Have  Successfully Verified your Number!",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 70,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                InkWell(
                    onTap: () {
                      ///Todo:calling loging;
                      // Navigator.push(context,
                      //     MaterialPageRoute(builder: (context) => SignUp()));
                    },
                    child: const CommonBtn(txt: "Create Your Account"))
              ],
            );
          },
        );
      },
    );
  }
}
