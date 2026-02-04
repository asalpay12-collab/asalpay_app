import 'dart:convert';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

import '../login/ForGetPPassword.dart';
import '../widgets/commonBtn.dart';
import 'PasswordOPT.dart';

class MyPassVerify extends StatefulWidget {
  final String phoneNumber;
  final String type; // 'registration', 'forget_password', 'forget_pin'
  
  const MyPassVerify({
    super.key,
    required this.phoneNumber,
    required this.type,
  });

  @override
  State<MyPassVerify> createState() => _MyPassVerifyState();
}

class _MyPassVerifyState extends State<MyPassVerify> {
  final pinController = TextEditingController();
  String authStatus = '';



  void appLog(String message) {
  debugPrint("🟢[MYAPP] $message");
}

  Future<void> _verifyOtp() async {
    final otpCode = pinController.text.trim();


    appLog("🔐 [Verify OTP] Phone Number: ${widget.phoneNumber}");
    appLog("🔐 [Verify OTP] Type: ${widget.type}");
    appLog("🔐 [Verify OTP] Entered Code: $otpCode");

    appLog("🔐 [FINAL VERIFICATION] Phone: ${widget.phoneNumber}, OTP: $otpCode");

    try {
      final response = await http.post(
        Uri.parse('${ApiUrls.BASE_URL}/VerificationController/validateCode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': widget.phoneNumber,
          'otpCode': otpCode,
          'type': widget.type,
        }
        
           
        ),
        
      );


      appLog("Response status: ${response.statusCode}");
      appLog("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (widget.type == 'forget_password') {


            Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => ForgetPassWord(phoneNumber: widget.phoneNumber),
  ),
);



          }
        } else {
          openSnackbar(context, data['message'] ?? "Invalid OTP Code", Colors.red);
        }
      } else {
        openSnackbar(context, "Error: ${response.reasonPhrase}", Colors.red);
      }
    } catch (e) {
      openSnackbar(context, "Network error: $e", Colors.red);
      print("Verification error: ${e.toString()}");
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
    border: Border.all(color: primaryColor),
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
              Text(
                "Verify Your Phone",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter the 6-digit code sent to your phone number.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 36),

              Pinput(
                controller: pinController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                showCursor: true,
                onCompleted: (pin) {
                  setState(() {
                    
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: InkWell(
                  onTap: () {
                    final code = pinController.text.trim();
                    if (code.length == 6) {
                      _verifyOtp(); 
                    } else {
                      openSnackbar(context, "Please enter a valid 6-digit OTP.", Colors.red);
                    }
                  },
                  child: const CommonBtn(txt: "Verify Phone Number"),
                ),
              ),

              const SizedBox(height: 20),

              if (authStatus.isNotEmpty)
                Text(
                  authStatus,
                  style: const TextStyle(color: Colors.green),
                ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                },
                child: const Text(
                  "Didn't receive a code? Resend",
                  style: TextStyle(color: Colors.black87),
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

