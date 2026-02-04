import 'dart:io';
import 'package:asalpay/splash/SplashScrn1.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/Constant.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';
import '../snack_bar/open_snack_bar.dart';

class ChangePassWord extends StatefulWidget {
// final String ? phonNumber;
  const ChangePassWord({super.key, });
  @override
  State<ChangePassWord> createState() => _ChangePassWordState();
}

class _ChangePassWordState extends State<ChangePassWord> {
  bool obsecurenew = true;
  bool obsecureold = true;
  bool obsecurecn = true;

  RegExp pass_valid = RegExp(r"(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W)");
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
  }

  late FlCountryCodePicker countrycodePicker;
  CountryCode? _countryCode;
  final phoneController = TextEditingController();
  final PasswordControllerOld = TextEditingController();
  final PasswordControllerNew = TextEditingController();
  final PasswordControllerConfirm = TextEditingController();

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
  Future<void> _submit() async {
    _submitted = true;
    setState(() {
      isloading = true;
    });
    var errorMessage = 'successfully changed';
    try {

      var defaultCode = "+252"; 
      var phoneNumber = phoneController.text.trim();
      var countryCode = _countryCode?.dialCode ?? defaultCode;
      final auth = Provider.of<Auth>(context, listen: false);

      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .ChangePassWord(
          auth.phone!,
              PasswordControllerOld.text,
              PasswordControllerNew.text);
      print('hello welcome');
      print(auth.phone);
      print(PasswordControllerOld.text);
      print(PasswordControllerNew.text);
    } on HttpException catch (error) {

      if (error.toString().contains('Invalid Phone Number')) {
        errorMessage = 'Could not find a user with that phone .';
      } else if (error.toString().contains('Your Old Password is Invalid')) {
        errorMessage = 'Your Old Password is Invalid.';
      } else if (error.toString().contains('OP')) {
        errorMessage = 'operation failed .';
      }

      print(error.toString());
      print('hello welcome');
      // _showErrorDialog(errorMessage);
      openSnackbar(context, errorMessage, secondryColor);
      return ;

    }
    setState(() {
      isloading = false;
    });
    _submitted = false;
    phoneController.text = "";
    PasswordControllerOld.text = "";
    PasswordControllerNew.text = "";
    openSnackbar(context, errorMessage, secondryColor);
    Provider.of<Auth>(context, listen: false).logout();
    Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen1()),
          (route) => false,
        );
  }


Widget _buildPasswordField({
  required BuildContext context,
  required TextEditingController controller,
  required String hintText,
  required bool isObscured,
  required VoidCallback toggleObscure,
  FormFieldValidator<String>? validator,
}) {
  return TextFormField(
    controller: controller,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    obscureText: isObscured,
    validator: validator,
    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black45),
      prefixIcon: const Icon(Icons.lock, color: primaryColor),
      suffixIcon: InkWell(
        onTap: toggleObscure,
        child: Icon(
          isObscured ? Icons.visibility_off : Icons.visibility,
          color: secondryColor,
        ),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: secondryColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    ),
  );
}



  @override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;

  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Image
            Image.asset(
              "assets/otp2.png",
              height: size.height * 0.25,
            ),
            const SizedBox(height: 16),

            // Form Fields
            Form(
              key: _formkey,
              child: Column(
                children: [
                  // Old Password
                  _buildPasswordField(
                    context: context,
                    controller: PasswordControllerOld,
                    hintText: "Enter Current Password",
                    isObscured: obsecureold,
                    toggleObscure: () {
                      setState(() => obsecureold = !obsecureold);
                    },
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  _buildPasswordField(
                    context: context,
                    controller: PasswordControllerNew,
                    hintText: "Enter New Password",
                    isObscured: obsecurenew,
                    toggleObscure: () {
                      setState(() => obsecurenew = !obsecurenew);
                    },
                    validator: (value) {
                      if (_submitted && value!.isEmpty) {
                        return "Password field is required";
                      }
                      bool result = validatePassword(value!);
                      if (value.length < 8) {
                        return "Password must be at least 8 characters long";
                      } else if (!result) {
                        return "Password should contain Upper, Lower, Number & Special";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  _buildPasswordField(
                    context: context,
                    controller: PasswordControllerConfirm,
                    hintText: "Confirm Password",
                    isObscured: obsecurecn,
                    toggleObscure: () {
                      setState(() => obsecurecn = !obsecurecn);
                    },
                    validator: (value) {
                      if (_submitted && value!.isEmpty) {
                        return "Confirm Password is required";
                      } else if (value != PasswordControllerNew.text.trim()) {
                        return "Passwords must match";
                      } else if (value!.length < 8) {
                        return "Password must be at least 8 characters long";
                      } else if (!validatePassword(value)) {
                        return "Password should contain Upper, Lower, Number & Special";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  //  Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: InkWell(
                      onTap: () {
                        _submit();
                        print(phoneController.text);
                        print(PasswordControllerOld.text);
                        print(PasswordControllerNew.text);
                      },
                      child: const CommonBtn(txt: "Change Password"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
