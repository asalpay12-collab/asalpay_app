import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:asalpay/OTP/verify.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/services/tokens.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/Constant.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';
import '../snack_bar/open_snack_bar.dart';
import '../widgets/commonBtn.dart';
import 'package:http/http.dart' as http;

import 'package:package_info_plus/package_info_plus.dart';


class Register extends StatefulWidget {
  static const routeName = '/register';
  const Register({super.key});
  static String verify = "";
  static String PhonNumber = "";

  @override
  _RegisterState createState() => _RegisterState();
}

class OtpAttemptManager {
  static const String _storageKey = 'otp_attempts';
  static const int _maxDailyAttempts = 3;

  /// identifier = phone (e.g. +252615123456) or email (e.g. user@example.com)
  static Future<void> recordOtpAttempt(String identifier, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getStringList(_storageKey) ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    

    final validAttempts = attempts.where((entry) {
  final parts = entry.split('|');
  if (parts.length < 3) return false;
  final timestamp = int.tryParse(parts[2]);
  if (timestamp == null) return false;
  return now - timestamp < 24 * 60 * 60 * 1000;
}).toList();


    validAttempts.add('$identifier|$type|$now');
    await prefs.setStringList(_storageKey, validAttempts);
  }




  /// identifier = phone or email
  static Future<int> getRemainingAttempts(String identifier, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getStringList(_storageKey) ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    

  final count = attempts.where((entry) {
  final parts = entry.split('|');
  if (parts.length < 3) return false;
  final timestamp = int.tryParse(parts[2]);
  if (timestamp == null) return false;
  return parts[0] == identifier &&
         parts[1] == type &&
         now - timestamp < 24 * 60 * 60 * 1000;
}).length;



    return _maxDailyAttempts - count;
  }
}
 
enum _VerifyChannel { phone, email }

class _RegisterState extends State<Register> {
  late TextEditingController phoneOTP;
  late TextEditingController emailController;
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  bool _attemptsLoaded = false;
  late FlCountryCodePicker countrycodePicker;
  CountryCode? _countryCode;
  bool _isLoading = false;
  final _form = GlobalKey<FormState>();
  String? authStatus = "";
  bool _submitted = false;
  Timer? _debounce;
  _VerifyChannel _channel = _VerifyChannel.phone;


  String get phoneNumberForBackend =>
      "${_countryCode?.dialCode ?? '+252'}${phoneOTP.text.trim()}";

  String get phoneNumberForOtp =>
      "${_countryCode?.dialCode ?? '+252'}${phoneOTP.text.trim()}";



  final somalia = CountryCode.fromMap({
  'name': 'Somalia',
  'code': 'SO',
  'dial_code': '+252',
});

  @override
  void initState() {
    super.initState();
    phoneOTP = TextEditingController();
    emailController = TextEditingController();

    countrycodePicker = const FlCountryCodePicker(
      showDialCode: true,
      showSearchBar: true, 
      favoritesIcon: Icon(Icons.star, color: primaryColor),
      favorites: ['SO', 'US'],
    );

    
    _countryCode = somalia;

    phoneOTP.addListener(_onPhoneNumberChanged);
    emailController.addListener(_onPhoneNumberChanged);
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
      'registration'
    );
    if (mounted) setState(() => _attemptsLoaded = true);
  }

  String get _fullPhoneNumber {
 
  final rawCode = _countryCode?.dialCode ?? '+252';
  final digitsOnly = rawCode.replaceAll('+', '');
  return '+$digitsOnly${phoneOTP.text.trim()}';   
}

   void appLog(String message) {
  debugPrint("🟢[MYAPP] $message");
}

  @override
  void dispose() {
    phoneOTP.removeListener(_onPhoneNumberChanged);
    emailController.removeListener(_onPhoneNumberChanged);
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    phoneOTP.dispose();
    emailController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String get _currentIdentifier =>
      _channel == _VerifyChannel.phone ? phoneNumberForBackend : emailController.text.trim();




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
            const url = 'https://play.google.com/store/apps/details?id=com.asal.asalpay'; 
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              print('Could not launch Play Store URL');
            }
          },
          child: const Text('Update Now'),
        ),
      ],
    ),
  );
}

Future<bool> checkAppVersion(BuildContext context, {String? phoneForVersion}) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}Wallet_login/login'),
      headers: {
        'Content-Type': 'application/json',
        'API-KEY': TokenClass().key,
        'Authorization': 'Bearer ${TokenClass().getToken()}',
      },
      body: jsonEncode({
        'phone': phoneForVersion ?? '+252000000000',
        'password': 'dummy',
        'version': currentVersion,
      }),
    );

    print(' Version Sent: $currentVersion');
    print(' Status: ${response.statusCode}');
    print(' Body: ${response.body}');

    final decoded = json.decode(response.body);
    final errorText = decoded['error']?.toString().toLowerCase() ?? '';

    if (errorText.contains('update your app')) {
      _showUpdateDialog(context);
      return false;
    }

    return true;
  } catch (e) {
    print('[VERSION CHECK] Error: $e');
    return true; 
  }
}



  Future<void> _OptVerification(BuildContext context) async {
    setState(() => _isLoading = true);

    print(" Checking OTP attempts for: ${phoneNumberForBackend}");

    final remainingAttempts = await OtpAttemptManager.getRemainingAttempts(
      // _fullPhoneNumber, 
      phoneNumberForBackend, 
      'registration'
    );

    print(" Remaining attempts: $remainingAttempts");


    if (remainingAttempts <= 0) {
      if (mounted) {
        setState(() => _isLoading = false);
        print("OTP attempts exhausted for: ${phoneNumberForBackend}");

        openSnackbar(context, "Maximum OTP requests reached. Try again tomorrow.", Colors.red);
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiUrls.BASE_URL}VerificationController/createCode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // 'phoneNumber': _fullPhoneNumber,

          'phoneNumber': phoneNumberForOtp,

          'type': 'registration',
        }),


        
      );

      

      print(" Response status: ${response.statusCode}");
      print(" Response body: ${response.body}");


      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('<') || (!body.startsWith('{') && !body.startsWith('['))) {
          if (mounted) openSnackbar(context, "Server temporarily unavailable. Please try again later.", secondryColor);
          return;
        }
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {

          // await OtpAttemptManager.recordOtpAttempt(_fullPhoneNumber, 'registration');

          print(" OTP created successfully for: ${phoneNumberForBackend}");

          OtpAttemptManager.recordOtpAttempt(phoneNumberForBackend, 'registration');


          if (mounted) {

            Navigator.push(context, MaterialPageRoute(
              builder: (context) => MyVerify(
                verifiedIdentifier: phoneNumberForOtp,
                channel: 'phone',
                type: 'registration',
              ),
            )).then((_) {
            
              if (mounted) setState(() => _isLoading = false);
            });
          }

        } else {

           print(" OTP creation failed: ${data['message']}");

          // openSnackbar(context, data['message'] ?? "Verification failed", const Color.fromARGB(255, 15, 37, 36));

          final errorMessage = (data['message']?.toString().isNotEmpty ?? false)
            ? data['message']
            : "Unknown backend error";

        print(" OTP creation failed: $errorMessage");
        openSnackbar(context, errorMessage, const Color.fromARGB(255, 15, 37, 36));

        }
      } else {
                print(" HTTP error: ${response.statusCode} - ${response.reasonPhrase}");

        openSnackbar(context, "Error: ${response.reasonPhrase}", secondryColor);
      }
    } on FormatException catch (_) {
      if (mounted) openSnackbar(context, "Server temporarily unavailable. Please try again later.", secondryColor);
    } catch (e) {
      openSnackbar(context, "Connection error. Please check your internet and try again.", secondryColor);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _OptVerificationEmail(BuildContext context) async {
    setState(() => _isLoading = true);
    final email = emailController.text.trim();

    final remainingAttempts = await OtpAttemptManager.getRemainingAttempts(email, 'registration');
    if (remainingAttempts <= 0) {
      if (mounted) {
        setState(() => _isLoading = false);
        openSnackbar(context, "Maximum OTP requests reached. Try again tomorrow.", Colors.red);
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiUrls.BASE_URL}VerificationController/createCodeEmail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'type': 'registration'}),
      );

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('<') || (!body.startsWith('{') && !body.startsWith('['))) {
          if (mounted) openSnackbar(context, "Server temporarily unavailable. Please try again later.", secondryColor);
          return;
        }
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          OtpAttemptManager.recordOtpAttempt(email, 'registration');
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => MyVerify(
                verifiedIdentifier: email,
                channel: 'email',
                type: 'registration',
              ),
            )).then((_) {
              if (mounted) setState(() => _isLoading = false);
            });
          }
        } else {
          openSnackbar(context, data['message']?.toString() ?? "Verification failed", Colors.red);
        }
      } else {
        openSnackbar(context, "Error: ${response.reasonPhrase}", secondryColor);
      }
    } on FormatException catch (_) {
      if (mounted) openSnackbar(context, "Server temporarily unavailable. Please try again later.", secondryColor);
    } catch (e) {
      openSnackbar(context, "Connection error. Please check your internet and try again.", secondryColor);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ChecKAndVerify() async {
  FocusScope.of(context).unfocus();
  _submitted = true;

  if (!(_form.currentState?.validate() ?? false)) {
    setState(() => _isLoading = false);
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Version check before anything
    final versionOk = await checkAppVersion(context,
        phoneForVersion: _channel == _VerifyChannel.phone ? phoneNumberForBackend : null);
    if (!versionOk) {
      setState(() => _isLoading = false);
      return; // stop if outdated
    }

    if (_channel == _VerifyChannel.phone) {
      debugPrint("Attempting backend check with: $phoneNumberForBackend");
      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .checkNumberRegistration(phoneNumberForBackend);
      await _OptVerification(context);
    } else {
      final email = emailController.text.trim();
      debugPrint("Attempting email check with: $email");
      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .checkEmailRegistration(email);
      await _OptVerificationEmail(context);
    }
  } on HttpException catch (error) {
    String errorMessage = error.toString();
    appLog("[Check] HttpException caught: $errorMessage");
    if (errorMessage.contains('User already registered')) {
      errorMessage = _channel == _VerifyChannel.phone
          ? 'This number is already registered'
          : 'This email is already registered';
    }
    openSnackbar(context, errorMessage, secondryColor);
  } catch (error) {
    appLog("[Check] Unexpected error: $error");
    openSnackbar(context, 'An unexpected error occurred', secondryColor);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


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
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 32, color: primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset("assets/otp2.png"),
                ),
                const Text(
                  'Registration',
                  style: TextStyle(
                    fontSize: 22,
                    color: secondryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _channel == _VerifyChannel.phone
                        ? "Enter your phone number. We will send a verification code via SMS."
                        : "Enter your email. We will send a verification code to your inbox.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<_VerifyChannel>(
                  segments: const [
                    ButtonSegment(value: _VerifyChannel.phone, label: Text('Phone'), icon: Icon(Icons.phone)),
                    ButtonSegment(value: _VerifyChannel.email, label: Text('Email'), icon: Icon(Icons.email)),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (Set<_VerifyChannel> selection) {
                    FocusScope.of(context).unfocus();
                    setState(() => _channel = selection.first);
                  },
                ),
                const SizedBox(height: 28),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Form(
                          key: _form,
                          child: _channel == _VerifyChannel.phone
                              ? TextFormField(
                                  key: const ValueKey('phone_input'),
                                  controller: phoneOTP,
                                  focusNode: _phoneFocusNode,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _phoneFocusNode.unfocus(),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (value) {
                                    if (_submitted && (value == null || value.isEmpty)) return 'Phone is required.';
                                    if (value != null && value.length < 7) return "Phone should be at least 7 digits";
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: primaryColor, width: 1.5),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: secondryColor, width: 1.5),
                                    ),
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              try {
                                                final code = await countrycodePicker.showPicker(context: context);
                                                if (code != null && mounted) setState(() => _countryCode = code);
                                              } catch (e) {
                                                openSnackbar(context, 'Failed to select country', Colors.red);
                                              }
                                            },
                                            child: Text(
                                              _countryCode?.dialCode ?? "+252",
                                              style: const TextStyle(color: secondryColor, fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    hintText: 'Enter Phone Number',
                                    hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
                                    contentPadding: const EdgeInsets.only(top: 16),
                                  ),
                                )
                              : TextFormField(
                                  key: const ValueKey('email_input'),
                                  controller: emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _emailFocusNode.unfocus(),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (value) {
                                    if (_submitted && (value == null || value.isEmpty)) return 'Email is required.';
                                    if (value != null && value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Enter a valid email.';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: primaryColor, width: 1.5),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: secondryColor, width: 1.5),
                                    ),
                                    prefixIcon: const Icon(Icons.email_outlined, color: secondryColor),
                                    hintText: 'Enter Email',
                                    hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
                                    contentPadding: const EdgeInsets.only(top: 16),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<int>(

                        // future: OtpAttemptManager.getRemainingAttempts(_fullPhoneNumber, 'registration'),

                         future: OtpAttemptManager.getRemainingAttempts(_currentIdentifier, 'registration'),

                          builder: (context, snapshot) {
                            final remaining = snapshot.data ?? 3;
                            final validInput = _channel == _VerifyChannel.phone
                                ? phoneOTP.text.trim().length >= 7
                                : RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim());
                            
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                validInput ? 'Remaining attempts: ${remaining.clamp(0, 3)}' : '',
                                style: TextStyle(
                                  color: validInput ? (remaining > 0 ? Colors.green : Colors.red) : Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const LogoandSpinner(
                                  imageAssets: 'assets/asalicon.png',
                                  reverse: true,
                                  arcColor: primaryColor,
                                  spinSpeed: Duration(milliseconds: 500),
                                )
                              : InkWell(
                                  onTap: () => _ChecKAndVerify(),
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