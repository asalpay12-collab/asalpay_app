import 'dart:io';
import 'package:asalpay/home/homescreen.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../constants/Constant.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';
import '../snack_bar/open_snack_bar.dart';

class ForgetPin extends StatefulWidget {
// final String ? phonNumber;

  final String phoneNumber;

  const ForgetPin({
    super.key,required this.phoneNumber
  });
  @override
  State<ForgetPin> createState() => _ForgetPinState(); 
}

class _ForgetPinState extends State<ForgetPin> {
  bool obsecureold = true;
  bool obsecurenew = true;
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
  _submitted = true;
  if (!_formkey.currentState!.validate()) return;

  _formkey.currentState!.save();
  setState(() => isloading = true);

  var errorMessage = 'Successfully changed';
  try {
    var defaultCode = "+252";
    var phoneNumber = phoneController.text.trim();
    var countryCode = _countryCode?.dialCode ?? defaultCode;

    appLog(" [ForgetPIN] Phone to reset: ${widget.phoneNumber}");
    appLog(" [ForgetPIN] New PIN: ${PasswordControllerNew.text}");

    await Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .ForgetPIN(widget.phoneNumber, PasswordControllerNew.text);

    appLog(" [ForgetPIN] Password change successful");

    // Clear loading before navigating
    setState(() => isloading = false);

    openSnackbar(context, errorMessage, Colors.green);

    phoneController.clear();
    PasswordControllerConfirm.clear();
    PasswordControllerNew.clear();

    openSnackbar(context, errorMessage, Colors.green);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          name: Provider.of<Auth>(context, listen: false).Name,
          wallet_accounts_id: Provider.of<Auth>(context, listen: false).wallet_accounts_id.toString(),
          fromLogin: false,
        ),
      ),
    );


    // Provider.of<Auth>(context, listen: false).logout();
    // Navigator.of(context).pushReplacementNamed('/');


  } on HttpException catch (error) {
    appLog(" [ForgetPIN] HttpException: $error");

    if (error.toString().contains('Invalid Phone Number')) {
      errorMessage = 'Could not find a user with that phone.';
    } else if (error.toString().contains('OP')) {
      errorMessage = 'Operation failed.';
    }

    openSnackbar(context, errorMessage, secondryColor);
    setState(() => isloading = false);
    return;
  } catch (error) {
    appLog(" [ForgetPIN] Unknown error: $error");
    openSnackbar(context, 'An unexpected error occurred.', Colors.red);
    setState(() => isloading = false);
    return;
  }

  _submitted = false;
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
                height: 180,
              ),
              const SizedBox(height: 20),
              Text(
                "Change Your PIN",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please enter and confirm your new PIN.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Form(
                key: _formkey,
                child: Column(
                  children: [
                    // New PIN Field
                    TextFormField(
                      controller: PasswordControllerNew,
                      obscureText: obsecureold,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Enter New PIN",
                        prefixIcon: Icon(Icons.lock, color: primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obsecureold ? Icons.visibility_off : Icons.visibility,
                            color: secondryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              obsecureold = !obsecureold;
                            });
                          },
                        ),
                        counterText: "", 
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        final pin = value?.trim() ?? '';
                        if (_submitted && pin.isEmpty) return "PIN is required";
                        if (pin.length != 4) return "PIN must be 4 digits";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Confirm PIN Field
                    TextFormField(
                      controller: PasswordControllerConfirm,
                      obscureText: obsecurenew,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Confirm New PIN",
                        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obsecurenew ? Icons.visibility_off : Icons.visibility,
                            color: secondryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              obsecurenew = !obsecurenew;
                            });
                          },
                        ),
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        final confirm = value?.trim() ?? '';
                        final original = PasswordControllerNew.text.trim();
                        if (_submitted && confirm.isEmpty) return "Please confirm your PIN";
                        if (confirm != original) return "PINs do not match";
                        if (confirm.length != 4) return "PIN must be 4 digits";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    InkWell(
                      onTap: () {
                        setState(() {
                          _submitted = true;
                        });
                        _submit();
                        print(PasswordControllerNew.text);
                        print(PasswordControllerConfirm.text);
                      },
                      child: const CommonBtn(txt: "Change PIN"),
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
