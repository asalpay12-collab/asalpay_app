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
  final String verifiedIdentifier; // phone (e.g. +252...) or email
  final String channel; // 'phone' | 'email'
  final String type; // 'registration', 'forget_password', 'forget_pin'

  const MyVerify({
    super.key,
    required this.verifiedIdentifier,
    required this.channel,
    required this.type,
  });

  String get phoneNumber => verifiedIdentifier;

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
      final url = widget.channel == 'email'
          ? '${ApiUrls.BASE_URL}VerificationController/validateCodeEmail'
          : '${ApiUrls.BASE_URL}VerificationController/validateCode';
      final body = widget.channel == 'email'
          ? {'email': widget.verifiedIdentifier, 'otpCode': otpCode, 'type': widget.type}
          : {'phoneNumber': widget.verifiedIdentifier, 'otpCode': otpCode, 'type': widget.type};

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final respBody = response.body.trim();
        if (respBody.startsWith('<') || (!respBody.startsWith('{') && !respBody.startsWith('['))) {
          openSnackbar(context, "Server temporarily unavailable. Please try again later.", Colors.red);
          return;
        }
        final data = jsonDecode(respBody);
        if (data['status'] == 'success') {
          if (widget.type == 'registration') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => InitiateRegistrationScreen(
                  verifiedIdentifier: widget.verifiedIdentifier,
                  channel: widget.channel,
                ),
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
    } on FormatException catch (_) {
      openSnackbar(context, "Server temporarily unavailable. Please try again later.", Colors.red);
    } catch (e) {
      openSnackbar(context, "Connection error. Please check your internet and try again.", Colors.red);
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
              Text(
                widget.channel == 'email' ? "Email Verification" : "Phone Verification",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                widget.channel == 'email'
                    ? "Enter the 6-digit code sent to your email."
                    : "We need to register your phone for getting started!",
                style: const TextStyle(fontSize: 16),
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
                  child: CommonBtn(
                    txt: widget.channel == 'email' ? "Verify Email" : "Verify Phone Number",
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