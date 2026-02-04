import 'dart:io';

import 'package:asalpay/services/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login/ForGetPPIN.dart';
import '../widgets/commonBtn.dart';
import 'PINOPT.dart';
import 'sms_retriever_impl.dart';

class MyPINVerify extends StatefulWidget {

  final String phoneNumber;
  final String type;

const MyPINVerify({
    super.key,
    required this.phoneNumber,
    required this.type,
  });


  @override
  State<MyPINVerify> createState() => _MyPINVerifyState();
}

class _MyPINVerifyState extends State<MyPINVerify> {
   final pinController = TextEditingController();
  String authStatus = '';


  // late final SmsRetrieverImpl smsRetriever;

  late final SmsRetrieverImpl? smsRetriever;



@override
void initState() {
  super.initState();
  if (Platform.isAndroid) {
    smsRetriever = SmsRetrieverImpl(
      useUserConsentApi: true,
      listenForMultipleSms: true,
    );
  }
}


  @override
void dispose() {
  smsRetriever?.dispose();
  pinController.dispose();
  super.dispose();
}



   void appLog(String message) {
  debugPrint("🟢[MYAPP] $message");
}



Future<void> _verifyOtp(BuildContext context, String code) async {
  final otpCode = pinController.text.trim();

  appLog(" [OTP VERIFY] Phone: ${widget.phoneNumber}");
  appLog("[OTP VERIFY] Code entered: $otpCode");
  appLog("[OTP VERIFY] Type: ${widget.type}");

  try {
    final response = await http.post(
      Uri.parse('${ApiUrls.BASE_URL}/VerificationController/validateCode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': widget.phoneNumber,
        'otpCode': otpCode,
        'type': widget.type,
      }),
    );

    appLog("[OTP VERIFY] Status Code: ${response.statusCode}");
    appLog("[OTP VERIFY] Raw Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      appLog("[OTP VERIFY] Decoded Response: $data");

      if (data['status'] == 'success') {
        appLog("[OTP VERIFY] OTP Verified. Navigating to ForgetPin screen...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ForgetPin(phoneNumber: widget.phoneNumber),
          ),
        );
      } else {
        appLog(" [OTP VERIFY] Server rejected OTP: ${data['message']}");
        openSnackbar(context, data['message'] ?? "Invalid OTP Code", Colors.red);
      }
    } else {
      appLog("[OTP VERIFY] Non-200 response: ${response.statusCode} - ${response.reasonPhrase}");
      openSnackbar(context, "Error: ${response.reasonPhrase}", Colors.red);
    }
  } catch (e) {
    appLog(" [OTP VERIFY] Exception during OTP validation: $e");
    openSnackbar(context, "Network error: $e", Colors.red);
  }
}
 
  void openSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

 
 
 @override
Widget build(BuildContext context) {
  final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: const TextStyle(
      fontSize: 20,
      color: Color.fromRGBO(30, 60, 87, 1),
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
      borderRadius: BorderRadius.circular(14),
    ),
  );

  final focusedPinTheme = defaultPinTheme.copyDecorationWith(
    border: Border.all(color: Color.fromRGBO(114, 178, 238, 1)),
    borderRadius: BorderRadius.circular(14),
  );

  final submittedPinTheme = defaultPinTheme.copyWith(
    decoration: defaultPinTheme.decoration?.copyWith(
      color: Colors.grey.shade200,
    ),
  );

  return Scaffold(
    backgroundColor: Colors.white,
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
      ),
      elevation: 0,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Image.asset(
                'assets/otp2.png',
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 20),
              const Text(
                "Phone Verification",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "We need to verify your phone to reset your PIN.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 36),


              Pinput(
               controller: pinController,
               smsRetriever: Platform.isAndroid ? smsRetriever : null,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                  border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
                ),
                submittedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    color: Colors.grey.shade200,
                  ),
                ),
                showCursor: true,
              ),
             
             
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: InkWell(
                  onTap: () {
                    final code = pinController.text.trim();
                    if (code.length == 6) {
                      _verifyOtp(context, code);
                    } else {
                      openSnackbar(context, "Please enter a valid 6-digit OTP.", Colors.red);
                    }
                  },
                  child: const CommonBtn(txt: "Verify Phone Number"),
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
