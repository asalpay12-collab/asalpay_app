import 'dart:io';

import 'package:asalpay/OTP/initiate_registration.dart';
import 'package:asalpay/OTP/register.dart';
import 'package:asalpay/OTP/sms_retriever_impl.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../Registration2.dart';
import '../widgets/commonBtn.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class MyVerify extends StatefulWidget {
  final String phoneNumber;
  final String type; // 'registration', 'forget_password', 'forget_pin'
  
   const MyVerify({
    super.key,
    required this.phoneNumber,
    required this.type,
  });

  @override
  State<MyVerify> createState() => _MyVerifyState();
}

class _MyVerifyState extends State<MyVerify> {


  final pinController = TextEditingController();
  String? otpCode;
  String authStatus = '';

  // late final SmsRetrieverImpl smsRetriever;

  late final SmsRetrieverImpl? smsRetriever;


  @override
  void initState() {
    super.initState();

    // 2. create it once
    // smsRetriever = SmsRetrieverImpl(
    //   useUserConsentApi: true,
    //   listenForMultipleSms: true,
    // );


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


  //commented, added on 26/04/25

  Future<void> _verifyOtp(BuildContext context, String s) async {
    final otpCode = pinController.text.trim();

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (widget.type == 'registration') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(

                // builder: (_) => SignUp(phoneNumber: widget.phoneNumber),

               builder: (_) => InitiateRegistrationScreen(phoneNumber: widget.phoneNumber),

              ),
            );
          } else if (widget.type == 'forget_password') {
            // Navigate to password reset screen
          }
        } else {
          openSnackbar(context, "Invalid OTP Code", Colors.red);
        }
      } else {
        openSnackbar(context, "Error: ${response.reasonPhrase}", Colors.red);
      }
    } catch (e) {
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
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    var code = "";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 25, right: 25),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/otp2.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(
                height: 25,
              ),
              const Text(
                "Phone Verification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                "We need to register your phone for getting started!",
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 30,
              ),

          Pinput(
          controller: pinController,
          length: 6,
          showCursor: true,
          smsRetriever: Platform.isAndroid ? smsRetriever : null, 
          onCompleted: (pin) => setState(() => otpCode = pin),
          onChanged: (value) => setState(() => otpCode = value),
        ),


              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: InkWell(
                  onTap: () {
                    if (otpCode != null && otpCode!.length == 6) {
                      _verifyOtp(context, otpCode!); 
                    } else {
                      openSnackbar(context, "Please enter a valid OTP.", Colors.red);
                    }
                  },
                  child: const CommonBtn(
                    txt: "Verify Phone Number",
                  ),
                ),
              ),
              if (authStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    authStatus,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}