import 'dart:io';
import 'package:asalpay/login/login.dart';
import 'package:asalpay/splash/SplashScrn1.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/Constant.dart';
import '../home/homescreen.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';
import '../snack_bar/open_snack_bar.dart';

class ChangePIN extends StatefulWidget {
  const ChangePIN({super.key, });
  @override
  State<ChangePIN> createState() => _ChangePINState();
}

class _ChangePINState extends State<ChangePIN> {
  bool obsecureold = true;
  bool obsecurenew = true;
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
  final PINControllerOld = TextEditingController();
  final PINControllerNew = TextEditingController();
  final PINControllercn = TextEditingController();

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
    if (!_formkey.currentState!.validate()) {
      //Invalid!
      return;
    }
    _formkey.currentState!.save();
    setState(() {
      isloading = true;
    });
    var errorMessage = 'successfully changed';
    try {

      var defaultCode = "+252";
      var phoneNumber = phoneController.text.trim();
      var countryCode = _countryCode?.dialCode ?? defaultCode;

      final auth = Provider.of<Auth>(context, listen: false);

      String rawPhone = auth.phone ?? '';
      String formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';

      appLog(" [ChangePIN] Using phone: $formattedPhone");
      appLog("[ChangePIN] Old PIN: ${PINControllerOld.text}, New PIN: ${PINControllerNew.text}");

      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .ChangePIN(formattedPhone, PINControllerOld.text, PINControllerNew.text);




      print('hello welcome');
      print(auth.phone!);
      print(PINControllerOld.text);
      print(PINControllerNew.text);
    } on HttpException catch (error) {

      if (error.toString().contains('Invalid Phone Number')) {
        errorMessage = 'Could not find a user with that phone .';
      } else if (error.toString().contains('Your Old Pin is Invalid')) {
        errorMessage = 'Your Old Pin is Invalid.';
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
    PINControllerOld.text = "";
    PINControllerNew.text = "";
    PINControllercn.text = "";
    openSnackbar(context, errorMessage, secondryColor);
    

    openSnackbar(context, errorMessage, secondryColor);

   Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen1()),
          (route) => false,
        );

  }


  Widget _buildPinField({
  required BuildContext context,
  required TextEditingController controller,
  required String hintText,
  required bool isObscured,
  required VoidCallback toggleObscure,
  FormFieldValidator<String>? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    obscureText: isObscured,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: validator,
    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black45),
      filled: true,
      fillColor: Colors.grey.shade100,
      prefixIcon: const Icon(Icons.lock, color: primaryColor),
      suffixIcon: InkWell(
        onTap: toggleObscure,
        child: Icon(
          isObscured ? Icons.visibility_off : Icons.visibility,
          color: secondryColor,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: secondryColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
            //  Image
            Image.asset(
              "assets/otp2.png",
              height: size.height * 0.25,
            ),
            const SizedBox(height: 20),

            //  PIN Change Form
            Form(
              key: _formkey,
              child: Column(
                children: [
                  _buildPinField(
                    context: context,
                    controller: PINControllerOld,
                    hintText: "Enter Current PIN",
                    isObscured: obsecureold,
                    toggleObscure: () {
                      setState(() => obsecureold = !obsecureold);
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildPinField(
                    context: context,
                    controller: PINControllerNew,
                    hintText: "Enter New PIN",
                    isObscured: obsecurenew,
                    toggleObscure: () {
                      setState(() => obsecurenew = !obsecurenew);
                    },
                    validator: (value) {
                      if (_submitted && value!.isEmpty) {
                        return "PIN field is required";
                      } else if (value!.length != 4) {
                        return "PIN must be exactly 4 digits";
                      } else if (!RegExp(r"^\d{4}$").hasMatch(value)) {
                        return "Only numbers allowed";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildPinField(
                    context: context,
                    controller: PINControllercn,
                    hintText: "Confirm PIN",
                    isObscured: obsecurecn,
                    toggleObscure: () {
                      setState(() => obsecurecn = !obsecurecn);
                    },
                    validator: (value) {
                      if (_submitted && value!.isEmpty) {
                        return "Confirm PIN is required";
                      } else if (value != PINControllerNew.text.trim()) {
                        return "PINs must match";
                      } else if (value!.length != 4) {
                        return "PIN must be exactly 4 digits";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: InkWell(
                      onTap: () {
                        _submit();
                        print(phoneController.text);
                        print(PINControllerOld.text);
                        print(PINControllerNew.text);
                      },
                      child: const CommonBtn(txt: "Change PIN"),
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
