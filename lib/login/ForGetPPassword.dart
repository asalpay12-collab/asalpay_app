import 'dart:io';
import 'package:asalpay/login/login.dart';
import 'package:asalpay/splash/SplashScrn1.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../OTP/PasswordOPT.dart';
import '../constants/Constant.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';
import '../snack_bar/open_snack_bar.dart';

class ForgetPassWord extends StatefulWidget {
// final String ? phonNumber;

  final String phoneNumber;

  const ForgetPassWord({ 
    super.key, required this.phoneNumber
  });
  @override
  State<ForgetPassWord> createState() => _ForgetPassWordState();
}

class _ForgetPassWordState extends State<ForgetPassWord> {
  bool obsecureold = true;
  bool obsecurenew = true;


  @override
  void initState() {
    final favoriteCountries = ['SO', 'KE', 'UG', 'US', 'CN'];
    // final favoriteCountries = widget.favoriteCountries ?? [];
    countrycodePicker = FlCountryCodePicker(
      favorites: favoriteCountries,
      favoritesIcon: const Icon(
        Icons.star,
        color: primaryColor,
      ),
    );
    _countryCode?.dialCode == "+252";
    super.initState();
  }

  late FlCountryCodePicker countrycodePicker;
  CountryCode? _countryCode;
  final phoneController = TextEditingController();
  final PasswordControllerConfirm = TextEditingController();
  final PasswordControllerNew = TextEditingController();

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred!'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  bool isloading = false;
  bool _submitted = false;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();



   void appLog(String message) {
  debugPrint("🟢[MYAPP] $message");
}


Future<void> _submit() async {
  final newPassword = PasswordControllerNew.text.trim();
  final confirmPassword = PasswordControllerConfirm.text.trim();

  // Set latest values
  PasswordControllerNew.text = newPassword;
  PasswordControllerConfirm.text = confirmPassword;

  if (!_formkey.currentState!.validate()) {
    return;
  }

  _formkey.currentState!.save();
  setState(() => isloading = true);

  try {
    await Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .ForgetPassWord(widget.phoneNumber, newPassword);

     _formkey.currentState!.reset();

    openSnackbar(context, "Password successfully changed", Colors.green);

      // Navigate to Login screen
  Future.delayed(const Duration(milliseconds: 500), () {
    // Navigator.of(context).pushReplacementNamed(Login.routeName);

     Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen1()),
          (route) => false,
        );
  });


  } on HttpException catch (error) {
    final message = error.toString().contains('Invalid Phone Number')
        ? 'Could not find a user with that phone number.'
        : error.toString();
    openSnackbar(context, message, secondryColor);
  } catch (_) {
    openSnackbar(context, "Unexpected error occurred.", Colors.red);
  } finally {
    setState(() => isloading = false);
  }
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/otp2.png",
                height: 240,
              ),
              const SizedBox(height: 20),
              Text(
                "Reset Your Password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please enter your new password below.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Form(
                key: _formkey,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "New Password",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                        textInputAction: TextInputAction.next,
                      controller: PasswordControllerNew,
                      obscureText: obsecureold,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Enter new password",
                        prefixIcon: Icon(Icons.lock, color: primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obsecureold ? Icons.visibility_off : Icons.visibility,
                            color: secondryColor,
                          ),
                          onPressed: () => setState(() {
                            obsecureold = !obsecureold;
                          }),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),

             validator: (value) {
              debugPrint("Validating new password: $value");
            final password = value?.trim() ?? '';
            if (password.isEmpty) return "New password is required";
            if (password.length < 6) return "Password must be at least 6 characters";
            if (password.length > 50) return "Password cannot exceed 50 characters";
            return null;
          }



                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Confirm Password",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),

                      controller: PasswordControllerConfirm,
                      obscureText: obsecurenew,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Re-enter new password",
                        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obsecurenew ? Icons.visibility_off : Icons.visibility,
                            color: secondryColor,
                          ),

                          
                          onPressed: () => setState(() {
                            obsecurenew = !obsecurenew;
                          }),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                        validator: (value) {

  debugPrint("Validating confirm: $value");
  debugPrint("New password value: ${PasswordControllerNew.text}");

                        final confirmPassword = value?.trim() ?? '';
                        final newPassword = PasswordControllerNew.text.trim();

                        if (confirmPassword.isEmpty) return "Please confirm your password";
                        if (confirmPassword != newPassword) return "Passwords do not match";
                        return null;
                      }


                    ),
                    const SizedBox(height: 30),
                    InkWell(
                      onTap: () {
                        _submit();
                        print(phoneController.text);
                        print(PasswordControllerConfirm.text);
                        print(PasswordControllerNew.text);
                      },
                      child: CommonBtn(txt: "Change Password"),
                    ),
                  ],
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