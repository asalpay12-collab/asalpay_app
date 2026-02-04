import 'dart:async';
import 'dart:io';
import 'package:asalpay/services/api_urls.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sms_autofill/sms_autofill.dart';
import '../constants/Constant.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../snack_bar/open_snack_bar.dart';
import '../widgets/commonBtn.dart';
import 'Passwordverify.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class PassWordOPT extends StatefulWidget {
  static const routeName = '/register';
  const PassWordOPT({
    super.key,
  });
  static String verify = "";
  static String PhonNumber = "";


  @override
  _PassWordOPTState createState() => _PassWordOPTState();
}



class OtpAttemptManager {
  static const String _storageKey = 'otp_attempts';
  static const int _maxDailyAttempts = 10;

  static Future<void> recordOtpAttempt(String phoneNumber, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getStringList(_storageKey) ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Clean up old entries
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


class _PassWordOPTState extends State<PassWordOPT> {
  var phoneNumber = '';
  var countryCode = '';
  @override
 


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
  

//here 

String? phoneNumber1, verificationId;


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
    'dial_code': '+252',
  });

  
  phoneOTP.addListener(_onPhoneNumberChanged);

  
  _loadInitialAttempts();
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
      'forget_password'
    );
    if (mounted) setState(() => _attemptsLoaded = true);
  }


  void appLog(String message) {
  debugPrint("🟢[MYAPP] $message");
}

  
  String get _fullPhoneNumber {

  final rawCode = _countryCode?.dialCode ?? '+252';
  final digitsOnly = rawCode.replaceAll('+', '');
  return '+$digitsOnly${phoneOTP.text.trim()}';   
}

void startSmsListener() async {
}



  @override
  void dispose() {
    _phoneFocusNode.dispose();
    phoneOTP.dispose();
    _debounce?.cancel();
    super.dispose();
  }


 Future<void> _sendPasswordResetOtp(BuildContext context) async {
    setState(() => _isLoading = true);
    final remainingAttempts = await OtpAttemptManager.getRemainingAttempts(
      _fullPhoneNumber, 
      'forget_password'
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
          'type': 'forget_password',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await OtpAttemptManager.recordOtpAttempt(_fullPhoneNumber, 'forget_password');
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => MyPassVerify(
                phoneNumber: _fullPhoneNumber,
                type: 'forget_password',
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
  _submitted = true;
  final isValid = _form.currentState?.validate() ?? false;
  if (!isValid) {
    setState(() => _isLoading = false);
    return;
  }

  setState(() => _isLoading = true);
  
  try {
    final fullPhoneNumber = _fullPhoneNumber;
    appLog("Checking phone number: $fullPhoneNumber");

    appLog("[ForgotPassword] Full Phone Number: $fullPhoneNumber");


    appLog(" [ForgotPassword] Attempting check for number: $_fullPhoneNumber");

    await Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .checkNumber(fullPhoneNumber);

    await _sendPasswordResetOtp(context);

  } on HttpException catch (error) {
    String errorMessage = 'Verification failed';
    if (error.toString().contains('not found')) {
      errorMessage = 'This number is not registered';
    }
    openSnackbar(context, errorMessage, secondryColor);
  } catch (error) {
    openSnackbar(context, 'An error occurred. Please try again.', secondryColor);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


//to here


  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
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
                  'Reset Password',
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
                        //   child:
                        Form(
                          key: _form,
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone Field is Required.';
                              } else if (value.length < 7) {
                                return "Phone should be at least 7 digits";
                              }
                              return null; 
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
                                          // _countryCode?.dialCode ?? "+252",
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

                        const SizedBox(height: 30),

Column(
  children: [
    FutureBuilder<int>(
      future: OtpAttemptManager.getRemainingAttempts(
        _fullPhoneNumber,
        'forget_password',
      ),
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 3;
        final validPhone = phoneOTP.text.trim().length >= 7;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            validPhone
                ? 'Remaining attempts: ${remaining.clamp(0, 3)}'
                : '',
            style: TextStyle(
              color: validPhone
                  ? (remaining > 0 ? Colors.green : Colors.red)
                  : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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
                                    _ChecKPhoneNumber();
                                    // _OptVerification();
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
}
