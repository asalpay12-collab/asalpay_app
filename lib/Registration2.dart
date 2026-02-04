import 'dart:io';
import 'package:animations/animations.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/diaglogs/policyDialog.dart';
import 'package:asalpay/firebase/device_registration_service.dart';
import 'package:asalpay/firebase/fcm_token_manager.dart';
import 'package:asalpay/providers/FillDropdownbyRegistreration.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:asalpay/providers/auth.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllFormFields.dart';
import 'package:asalpay/widgets/AllinOneDropdownSearch.dart';
import 'package:asalpay/widgets/circleelevatedbutton.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:asalpay/widgets/countryCodeBTN.dart';
import 'package:asalpay/widgets/leadingnames.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/CustomerRegistration.dart';
import 'package:asalpay/home/homescreen.dart';


class KeyboardDismissOnTap extends StatelessWidget {
  final Widget child;
  const KeyboardDismissOnTap({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}


class SignUp extends StatefulWidget {
  // final bool hasNetwork;
  final String? phoneNumber;
  const SignUp({
    super.key,
    this.phoneNumber,
  });
  static const routeName = '/Registration2';
  @override
  State<SignUp> createState() => _SignUpState();
}

enum AppState { clear, picking, picked, cropped }

class _SignUpState extends State<SignUp> {

 static const routeName = '/auth';
  final Map<String, String> _authData = {
    'phone': '',
    'password': '',
    "version":''
  };

  bool _isLoadingDrop_data = false;
  bool _isLoadingproDrop = false;
  // var _isLoading = false;
  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Future<void> didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    setState(() {
      _isLoadingDrop_data = true;
    });
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetCountry()
        .then((_) {});
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetCurrency();
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetDocumentType();
    await Provider.of<FillRegisterationDropdown>(context, listen: false)
        .fetchAndSetWalletType();

    final fillDD =
        Provider.of<FillRegisterationDropdown>(context, listen: false);
    setState(() {
      _isLoadingDrop_data = false;
      print('identificationTye: $fillDD');
      identificationTye = _getDefaultSelectedidenficiationtype(fillDD);
      // RemitChannel = _getDefaultSelectedBeneficiaryBank(RemitChannelTypes);
    });
    setState(() {
      _isLoadingDrop_data = false;
    });
    // await Provider.of<FillRegisterationDropdown>(context, listen: false)
    //     .fetchAndSetCurrency();
  }

  // RegExp pass_valid = RegExp(r"(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W)");
  //A function that validate user entered password
  bool validatePassword(String pass) {
    String password = pass.trim();
    // if (pass_valid.hasMatch(_password)) {
    if (password.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  bool obsecure = true;
  bool obsecure1 = true;
  bool isLoading = false;
  AppState state = AppState.clear;
  File? mainImageFile;
  File? _pickDocuments;
  File? mainImageFileDocument;

  String? uploadedFileNameDocument;
  String? uploadedFileNameImageName;
  File? _pickImages;
  // File _pickImages = File('');
  final ImagePicker imagePicker = ImagePicker();

  // late String idropdownValue;
  // late String pdropdownValue;
  // late String cdropdownValue;

  bool rememberMe = false;
  // this bool will check rememberMe is checked
  bool showErrorMessage = false;
  final List<GlobalKey<FormState>> _form = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];
  final _nameFocusNode = FocusNode();
  final _name = TextEditingController();
  final _surnameFocusNode = FocusNode();
  final _surname = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _email = TextEditingController();
  final _nationalFocusNode = FocusNode();
  final _national = TextEditingController();
  final _telphoneFocusNode = FocusNode();
  final _telphone = TextEditingController();
  final _passwdFocusNode = FocusNode();
  final _passwd = TextEditingController();
  final _cpasswdFocusNode = FocusNode();
  final _cpasswd = TextEditingController();
  final _preferredcontactnumberFocusNode = FocusNode();
  final _preferredcontactnumber = TextEditingController();
  final _referralcodeFocusNode = FocusNode();
  final _referralcode = TextEditingController();
  final _identificationtypeFocusNode = FocusNode();
  final _identificationtype = TextEditingController();
  final _identificationnumberFocusNode = FocusNode();
  final _identificationnumber = TextEditingController();
  final _streetnameFocusNode = FocusNode();
  final _pinFocusNode = FocusNode();
  final _streetname = TextEditingController();
  final _streetnumberFocusNode = FocusNode();
  final _streetnumber = TextEditingController();
  final _provinceFocusNode = FocusNode();
  final _province = TextEditingController();
  final _cityFocusNode = FocusNode();
  final _pin = TextEditingController();
  final _suburbsFocusNode = FocusNode();
  final _suburbs = TextEditingController();

  //dropdowns textField searching values;
  TextEditingController CountryTextEditingController = TextEditingController();
  TextEditingController identificationTyeTextEditingController =
      TextEditingController();
  TextEditingController currencyTextEditingController = TextEditingController();
  TextEditingController walletTypeTextEditingController =
      TextEditingController();
  TextEditingController provinceTextEditingController = TextEditingController();
  TextEditingController cityTextEditingController = TextEditingController();
  //dropdowns selecting values;

  String? country;
  String? identificationTye;
  String? currency;
  String? walletType;
  String? province;
  String? city;

  int currenStep = 0;
  // bool ischeck = false;
  bool iscompleted = false;

  var _addcust = CustomerRegistration(
    city: '',
    country: '',
    // documentUrl: '' as File,
    documentUrl: null,
    currency: '',
    email: '',
    identificationnumber: '',
    referralcode: '',
    // imageUrl: '' as File,
    imageUrl: null,
    province: '',
    telphone: '',
    surname: '',
    streetname: '',
    streetnumber: '',
    suburbs: '',
    password: '',
    identificationtype: '',
    name: '',
    national: '',
    preferredcontactnumber: '',
    walletType: '',
    PIN: '',
  );
  String? selectedCountryName;

  void handleCountrySelected(String countryName) {
    setState(() {
      selectedCountryName = countryName;
      print("Selected Country111: $selectedCountryName");
    });
  }

  String? _getDefaultSelectedidenficiationtype(
      FillRegisterationDropdown fillDD) {
    if (fillDD.documentType.isNotEmpty) {
      return fillDD.documentType[0].id;
    }
    return null;
  }

  // @override
  // Widget build(BuildContext context) {
  //   final fillDD =
  //       Provider.of<FillRegisterationDropdown>(context, listen: false);
  //   return MaterialApp(
  //     debugShowCheckedModeBanner: false,

  //     home: Scaffold(
  //       appBar: AppBar(
  //         backgroundColor: secondryColor,
  //         centerTitle: true,
  //         title: const Text("Create your account"),
  //       ),

  //       // body: _isLoadingDrop_data

  //       body: SafeArea(
  //       child: _isLoadingDrop_data
  //           ? const Center(
  //               child:
  //                   // CircularProgressIndicator(
  //                   //   color: primaryColor,
  //                   // ),
  //                   LogoandSpinner(
  //                 imageAssets: 'assets/asalicon.png',
  //                 reverse: true,
  //                 arcColor: primaryColor,
  //                 spinSpeed: Duration(milliseconds: 500),
  //               ),
  //             )
  //           : Theme(
  //               data: ThemeData(
  //                 colorScheme: const ColorScheme.light(
  //                   primary: primaryColor, // Will work
  //                 ),
  //               ),
  //               child: Form(
  //                 key: _formKey,

  //             child: SingleChildScrollView(

  //                 child: Stepper(

  //                   type: StepperType.horizontal,
  //                   steps: getSteps(fillDD),
  //                   currentStep: currenStep,
  //                   //it goes up next to each other;
  //                   onStepContinue: () {
  //                     // _saveForm();
  //                     final isLastStep =
  //                         currenStep == getSteps(fillDD).length - 1;
  //                     setState(() {
  //                       if (_form[currenStep].currentState!.validate()) {
  //                         if (currenStep < getSteps(fillDD).length - 1) {
  //                           currenStep = currenStep + 1;
  //                         } else {
  //                           currenStep = 0;
  //                         }
  //                       }
  //                     });
  //                   },
                   
  //                   onStepCancel: () {
                      
  //                     if (currenStep == 0) {
  //                       return;
  //                     } else {
  //                       setState(() => currenStep -= 1);
  //                     }
  //                   },
  //                   //todo:onstepTapped;
  //                   onStepTapped: (step) {
  //                     setState(() {
  //                       currenStep = step;
  //                     });
  //                   },
  //                   controlsBuilder:
  //                       (BuildContext context, ControlsDetails dtl) {
  //                     final isLastStep =
  //                         currenStep == getSteps(fillDD).length - 1;
  //                     return Row(
  //                       children: [
  //                         if (currenStep != 0 && !isLastStep)
  //                           Expanded(
  //                             child: GestureDetector(
  //                               onTap: dtl.onStepCancel,
  //                               child: const CommonBtn(
  //                                 txt: 'BACK',
  //                               ),
  //                             ),
  //                           ),
  //                         const SizedBox(width: 12),
  //                         if (currenStep == 0 ||
  //                             (!isLastStep && currenStep != 0))
  //                           Expanded(
  //                             child: GestureDetector(
  //                               onTap: () {
  //                                 if (!rememberMe && currenStep == 2) {
  //                                   openSnackbar(
  //                                       context,
  //                                       'Please Accept the terms and conditions',
  //                                       primaryColor);
  //                                   return;
  //                                 }
  //                                 dtl.onStepContinue!(); // Proceed to the next step
  //                               },
  //                               child: const CommonBtn(
  //                                 txt: 'Next',
  //                               ),
  //                             ),
  //                           ),
  //                         if (isLastStep)
  //                           Expanded(
  //                             child: _isLoading
  //                                 ? const Center(
  //                                     child: LogoandSpinner(
  //                                     imageAssets: 'assets/asalicon.png',
  //                                     reverse: true,
  //                                     arcColor: primaryColor,
  //                                     spinSpeed: Duration(milliseconds: 500),
  //                                   )
  //                                     // CircularProgressIndicator(),
  //                                     )
  //                                 : GestureDetector(
  //                                     onTap: () {
  //                                       _saveForm();
  //                                     },
  //                                     child: const CommonBtn(
  //                                       txt: 'CONFIRM',
  //                                     ),
  //                                   ),
  //                           ),
  //                       ],
  //                     );
  //                   },
  //                 ),
  //               ),
  //             ),
  //     ),
  //     ),
  //     ),
  //   );
  // }





  @override
Widget build(BuildContext context) {
  final fillDD = Provider.of<FillRegisterationDropdown>(context, listen: false);
  
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(
        backgroundColor: secondryColor,
        centerTitle: true,
        title: const Text("Create your account"),
      ),


      body: SafeArea(


        child: _isLoadingDrop_data
            ? const Center(
                child: LogoandSpinner(
                  imageAssets: 'assets/asalicon.png',
                  reverse: true,
                  arcColor: primaryColor,
                  spinSpeed: Duration(milliseconds: 500),
                ),
              )
            : Theme(
                data: ThemeData(
                  colorScheme: const ColorScheme.light(
                    primary: primaryColor,
                  ),
                ),


                child: KeyboardDismissOnTap(
                child: Form(
                  key: _formKey,


                  child: Stepper(
                    type: StepperType.horizontal,
                    steps: getSteps(fillDD),
                    currentStep: currenStep,
                    onStepContinue: () {
                      final isLastStep = currenStep == getSteps(fillDD).length - 1;
                      setState(() {
                        if (_form[currenStep].currentState!.validate()) {
                          if (currenStep < getSteps(fillDD).length - 1) {
                            currenStep++;
                          } else {
                            currenStep = 0;
                          }
                        }
                      });
                    },
                    onStepCancel: () {
                      if (currenStep > 0) {
                        setState(() => currenStep--);
                      }
                    },
                    onStepTapped: (step) {
                      setState(() {
                        currenStep = step;
                      });
                    },
                    controlsBuilder: (BuildContext context, ControlsDetails dtl) {
                      final isLastStep = currenStep == getSteps(fillDD).length - 1;
                      return Row(
                        children: [
                          if (currenStep != 0 && !isLastStep)
                            Expanded(
                              child: GestureDetector(
                                onTap: dtl.onStepCancel,
                                child: const CommonBtn(txt: 'BACK'),
                              ),
                            ),
                          const SizedBox(width: 12),
                          if (currenStep == 0 || (!isLastStep && currenStep != 0))
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!rememberMe && currenStep == 2) {
                                    openSnackbar(
                                      context,
                                      'Please Accept the terms and conditions',
                                      primaryColor,
                                    );
                                    return;
                                  }
                                  dtl.onStepContinue!();
                                },
                                child: const CommonBtn(txt: 'Next'),
                              ),
                            ),
                          if (isLastStep)
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: LogoandSpinner(
                                        imageAssets: 'assets/asalicon.png',
                                        reverse: true,
                                        arcColor: primaryColor,
                                        spinSpeed: Duration(milliseconds: 500),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        _saveForm();
                                      },
                                      child: const CommonBtn(txt: 'CONFIRM'),
                                    ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
      ),
    ),
    ),
  );
}


  ///todo:imagesource

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      isLoading = true;
    });
    try {
      final picked = await imagePicker.pickImage(
          source: source, preferredCameraDevice: CameraDevice.front);
      // final picked = await imagePicker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          mainImageFile = File(picked.path);
          isLoading = false;
          uploadedFileNameImageName = path.basename(picked.path);
        });
      }
      final appDir = await syspaths.getApplicationDocumentsDirectory();
      final fileName = path.basename(picked!.path);
      final saveImage = await mainImageFile!.copy('${appDir.path}/$fileName');
      _pickImages = saveImage;
      // widget.onSelectImage(saveImage);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  ///todo:Documentsource
  Future<void> _pickDocument(ImageSource source) async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final pickedFile = result.files.single;
        final String filePath = pickedFile.path!;

        setState(() {
          mainImageFileDocument = File(filePath);
          isLoading = false;
          uploadedFileNameDocument = path.basename(filePath);
        });
        // final appDir = await getApplicationDocumentsDirectory();
        final appDir = await syspaths.getApplicationDocumentsDirectory();
        final fileName = path.basename(filePath);
        final saveDocument =
            await mainImageFileDocument!.copy('${appDir.path}/$fileName');
        _pickDocuments = saveDocument;
        // Display the file name
        // print('Picked file name: ${pickedFile.name}');
        // widget.onSelectImage(saveImage);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  //list of steps;




  List<Step> getSteps(FillRegisterationDropdown fillDD) => [

  // Profile Step

  Step(

    
      title: const Text('Profile'),
    isActive: currenStep >= 0,
    state: currenStep > 0 ? StepState.complete : StepState.indexed,
    content: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
      child: Form(

        key: _form[0],
        child: Column(
        children: [
          const LeadingNames(leadingName: "Name"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _name,
            hintxt: "Your Name",
            icn: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty || value.isEmpty) {
                return 'Name is Required';
              }
              return null;
            }, 
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              print(value);
              print("phone");
              print(widget.phoneNumber);
              _addcust = CustomerRegistration(
                name: value,
                surname: _addcust.surname,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                identificationnumber: _addcust.identificationnumber,
                referralcode: _addcust.referralcode,
                province: _addcust.province,
                telphone: widget.phoneNumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                identificationtype: _addcust.identificationtype,
                national: _addcust.national,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 10),
          const LeadingNames(leadingName: "Surname"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _surname,
            hintxt: "Your Surname",
            icn: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Surname is Required';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            focusNode: _surnameFocusNode,
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: value,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                identificationnumber: _addcust.identificationnumber,
                referralcode: _addcust.referralcode,
                province: _addcust.province,
                telphone: _addcust.telphone,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                identificationtype: _addcust.identificationtype,
                national: _addcust.national,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 10),
          const LeadingNames(leadingName: "Nationality"),
          const SizedBox(height: 5),
          DropdownCountryCode(
            onCountrySelected: handleCountrySelected,
            onChanged: (value) {
              selectedCountryName = value;
              print("Selected Nationality: $selectedCountryName");
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: selectedCountryName,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                identificationnumber: _addcust.identificationnumber,
                referralcode: _addcust.referralcode,
                province: _addcust.province,
                telphone: _addcust.telphone,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                identificationtype: _addcust.identificationtype,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 5),
          const LeadingNames(leadingName: "Preferred Contact Number (Optional)"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _preferredcontactnumber,
            hintxt: "Enter Your Preferred Contact Number",
            icn: Icons.call,
            textInputAction: TextInputAction.next,
            focusNode: _preferredcontactnumberFocusNode,
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: value,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                identificationnumber: _addcust.identificationnumber,
                referralcode: _addcust.referralcode,
                province: _addcust.province,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                identificationtype: _addcust.identificationtype,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "Referral Code (Optional)"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _referralcode,
            hintxt: "Enter Your Referral Code",
            icn: Icons.data_array_outlined,
            textInputAction: TextInputAction.next,
            focusNode: _referralcodeFocusNode,
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: value,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                identificationnumber: _addcust.identificationnumber,
                province: _addcust.province,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                identificationtype: _addcust.identificationtype,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    ),
  ),
  ),

  // ID Step

  Step(

  state: currenStep > 1 ? StepState.complete : StepState.indexed,
  isActive: currenStep >= 1,
  title: const Text("ID"),
  content: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
    child: Form(
      key: _form[1],
      child: Column(
        children: [
          const LeadingNames(leadingName: "Select an identification type"),
          const SizedBox(height: 5),
          AllinOneDropdownSearch(
            SearchCtr: identificationTyeTextEditingController,
            hintxt: "Select Your Identification Type!",
            maintext: "Search Identification",
            onChanged: (value) {
              setState(() {
                print(value.toString());
                identificationTye = value;
                _addcust = CustomerRegistration(
                  name: _addcust.name,
                  surname: _addcust.surname,
                  national: _addcust.national,
                  telphone: _addcust.telphone,
                  preferredcontactnumber: _addcust.preferredcontactnumber,
                  referralcode: _addcust.referralcode,
                  identificationtype: value,
                  city: _addcust.city,
                  country: _addcust.country,
                  currency: _addcust.currency,
                  email: _addcust.email,
                  identificationnumber: _addcust.identificationnumber,
                  province: _addcust.province,
                  streetname: _addcust.streetname,
                  streetnumber: _addcust.streetnumber,
                  suburbs: _addcust.suburbs,
                  password: _addcust.password,
                  walletType: _addcust.walletType,
                  PIN: _addcust.PIN,
                );
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Identification Type is Required';
              }
              return null;
            },
            items: fillDD.documentType,
            dropdownValue: identificationTye,
          ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "Enter your identification number here"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _identificationnumber,
            hintxt: "Enter your identification number",
            icn: Icons.perm_identity_outlined,
            textInputAction: TextInputAction.next,
            focusNode: _identificationnumberFocusNode,
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: value,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                province: _addcust.province,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Identification number is Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "Upload Your Identification Type"),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),

            padding: const EdgeInsets.all(15),



            alignment: Alignment.center,
            child: CircleElevatedButton(
              txt: uploadedFileNameDocument != null
                  ? uploadedFileNameDocument!
                  : "Upload Document",
              icn: const AssetImage("assets/upload2.png"),
              onPressed: () async {
                _pickDocument(ImageSource.gallery);
              },
            ),
          ),
          const SizedBox(height: 5),
          const LeadingNames(leadingName: "Take a Selfie"),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),

            padding: const EdgeInsets.all(15),


            alignment: Alignment.center,
            child: CircleElevatedButton(
              txt: uploadedFileNameImageName != null
                  ? uploadedFileNameImageName!
                  : "Selfie Capture",
              icn: const AssetImage("assets/frontcamera2.png"),
              onPressed: () async {
                _pickImage(ImageSource.camera);
              },
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    ),
  ),
  ),

  // Address Step
  Step(

     state: currenStep > 2 ? StepState.complete : StepState.indexed,
  isActive: currenStep >= 2,
  title: const Text("Address"), // ✅ title should not scroll
  content: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
    child: Form(
      key: _form[2],
      child: Column(
        children: [
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "Street Name"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _streetname,
            hintxt: 'Enter Street Name',
            icn: FontAwesomeIcons.route,
            textInputAction: TextInputAction.next,
            focusNode: _streetnameFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Street Name is Required';
              }
              return null;
            },
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: value,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                province: _addcust.province,
                streetnumber: _addcust.streetnumber,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "Street Number"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _streetnumber,
            hintxt: 'Enter Street Number',
            icn: FontAwesomeIcons.landmark,
            textInputAction: TextInputAction.next,
            focusNode: _streetnumberFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Street Number is Required';
              }
              return null;
            },
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: value,
                city: _addcust.city,
                country: _addcust.country,
                currency: _addcust.currency,
                email: _addcust.email,
                province: _addcust.province,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "Country"),
          const SizedBox(height: 5),
          AllinOneDropdownSearch(
            onChanged: (value) async {
              print(value);
              setState(() {
                country = value;
                _isLoadingproDrop = true;
              });
              await Provider.of<FillRegisterationDropdown>(context, listen: false)
                  .fetchAndSetProvince(country!);
              setState(() {
                _isLoadingproDrop = false;
              });
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                country: value,
                city: _addcust.city,
                currency: _addcust.currency,
                email: _addcust.email,
                province: _addcust.province,
                suburbs: _addcust.suburbs,
                password: _addcust.password,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Country Field is Required';
              }
              return null;
            },
            SearchCtr: CountryTextEditingController,
            hintxt: "Select Your Country",
            maintext: "search Country",
            items: fillDD.country,
            dropdownValue: country,
          ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "Province"),
          const SizedBox(height: 5),
          Container(
            child: _isLoadingDrop_data
                ? const LogoandSpinner(
                    imageAssets: 'assets/asalicon.png',
                    reverse: true,
                    arcColor: primaryColor,
                    spinSpeed: Duration(milliseconds: 500),
                  )
                : AllinOneDropdownSearch(
                    SearchCtr: provinceTextEditingController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Province Field is Required';
                      }
                      return null;
                    },
                    onChanged: (value) async {
                      print(value);
                      setState(() {
                        province = value;
                        _isLoadingproDrop = true;
                      });
                      await Provider.of<FillRegisterationDropdown>(context, listen: false)
                          .fetchAndSetCity(province!);
                      setState(() {
                        _isLoadingproDrop = false;
                      });
                      _addcust = CustomerRegistration(
                        name: _addcust.name,
                        surname: _addcust.surname,
                        national: _addcust.national,
                        telphone: _addcust.telphone,
                        preferredcontactnumber: _addcust.preferredcontactnumber,
                        referralcode: _addcust.referralcode,
                        identificationtype: _addcust.identificationtype,
                        identificationnumber: _addcust.identificationnumber,
                        streetname: _addcust.streetname,
                        streetnumber: _addcust.streetnumber,
                        country: _addcust.country,
                        province: value,
                        city: _addcust.city,
                        currency: _addcust.currency,
                        email: _addcust.email,
                        suburbs: _addcust.suburbs,
                        password: _addcust.password,
                        walletType: _addcust.walletType,
                        PIN: _addcust.PIN,
                      );
                    },
                    hintxt: "Select Your Province",
                    maintext: "search Province",
                    items: fillDD.province,
                    dropdownValue: province,
                  ),
          ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "City"),
          const SizedBox(height: 5),
          _isLoadingproDrop
              ? const LogoandSpinner(
                  imageAssets: 'assets/asalicon.png',
                  reverse: true,
                  arcColor: primaryColor,
                  spinSpeed: Duration(milliseconds: 500),
                )
              : AllinOneDropdownSearch(
                  SearchCtr: cityTextEditingController,
                  onChanged: (value) {
                    print(value);
                    setState(() {
                      city = value;
                    });
                    _addcust = CustomerRegistration(
                      name: _addcust.name,
                      surname: _addcust.surname,
                      national: _addcust.national,
                      telphone: _addcust.telphone,
                      preferredcontactnumber: _addcust.preferredcontactnumber,
                      referralcode: _addcust.referralcode,
                      identificationtype: _addcust.identificationtype,
                      identificationnumber: _addcust.identificationnumber,
                      streetname: _addcust.streetname,
                      streetnumber: _addcust.streetnumber,
                      country: _addcust.country,
                      province: _addcust.province,
                      city: value,
                      currency: _addcust.currency,
                      email: _addcust.email,
                      suburbs: _addcust.suburbs,
                      password: _addcust.password,
                      walletType: _addcust.walletType,
                      PIN: _addcust.PIN,
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City Field is Required';
                    }
                    return null;
                  },
                  hintxt: "Select Your City",
                  maintext: "search City",
                  items: fillDD.city,
                  dropdownValue: city,
                ),
          const SizedBox(height: 15),
          const LeadingNames(leadingName: "District"),
          const SizedBox(height: 5),
          AllformFields(
            ctr: _suburbs,
            hintxt: "Enter Your District",
            icn: Icons.location_on,
            textInputAction: TextInputAction.next,
            focusNode: _suburbsFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'District Field is Required';
              }
              return null;
            },
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                country: _addcust.country,
                province: _addcust.province,
                city: _addcust.city,
                suburbs: value,
                currency: _addcust.currency,
                email: _addcust.email,
                password: _addcust.password,
                walletType: _addcust.walletType,
                PIN: _addcust.PIN,
              );
            },
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  checkColor: Colors.white,
                  activeColor: primaryColor,
                  title: RichText(
                    text: TextSpan(
                      text: "I Agree to the Asal's ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: secondryColor,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms and conditions ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              showModal(
                                context: context,
                                configuration: const FadeScaleTransitionConfiguration(),
                                builder: (context) {
                                  return PolicyDialog(
                                    mdFileName: 'terms_and_conditions.md',
                                    key: key,
                                    btnName: "I AGREE",
                                  );
                                },
                              );
                            },
                        ),
                        const TextSpan(
                          text: 'and ',
                          style: TextStyle(
                            color: secondryColor,
                          ),
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return PolicyDialog(
                                    mdFileName: 'privacy_policy.md',
                                    key: key,
                                    btnName: "Cancel",
                                  );
                                },
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(left: 5),
                  value: rememberMe,
                  onChanged: (newValue) {
                    setState(() {
                      rememberMe = newValue!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
  ),

  // Credentials Step

  Step(

     state: currenStep > 3 ? StepState.complete : StepState.indexed,
  isActive: currenStep >= 3,
  title: const Text("Type"), // ✅ title fixed
  content: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
    child: Form(
      key: _form[3],
      child: Column(
        children: [
          const LeadingNames(leadingName: "Wallet type"),
          const SizedBox(height: 5),
          AllinOneDropdownSearch(
            SearchCtr: walletTypeTextEditingController,
            onChanged: (value) {
              print(value);
              setState(() {
                walletType = value;
              });
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                country: _addcust.country,
                province: _addcust.province,
                city: _addcust.city,
                suburbs: _addcust.suburbs,
                walletType: value,
                currency: _addcust.currency,
                email: _addcust.email,
                password: _addcust.password,
                PIN: _addcust.PIN,
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wallet Type is Required';
              }
              return null;
            },
            hintxt: "Select any Wallet type",
            maintext: "Search Wallet type",
            items: fillDD.walletType,
            dropdownValue: walletType,
          ),
          const SizedBox(height: 10),
          const LeadingNames(leadingName: "Pick Currency"),
          const SizedBox(height: 5),
          AllinOneDropdownSearch(
            onChanged: (value) {
              print(value);
              setState(() {
                currency = value;
              });
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                country: _addcust.country,
                province: _addcust.province,
                city: _addcust.city,
                suburbs: _addcust.suburbs,
                walletType: _addcust.walletType,
                currency: value,
                email: _addcust.email,
                password: _addcust.password,
                PIN: _addcust.PIN,
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Currency Type is Required';
              }
              return null;
            },
            hintxt: "Select any currency",
            maintext: "Search currency",
            SearchCtr: currencyTextEditingController,
            items: fillDD.currency,
            dropdownValue: currency,
          ),
          const SizedBox(height: 10),
          const LeadingNames(leadingName: "Email"),
          const SizedBox(height: 5),
          AllformFields(
            keyboardType: TextInputType.emailAddress,
            ctr: _email,
            hintxt: "Enter Email",
            icn: Icons.email_outlined,
            textInputAction: TextInputAction.next,
            focusNode: _emailFocusNode,
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                country: _addcust.country,
                province: _addcust.province,
                city: _addcust.city,
                suburbs: _addcust.suburbs,
                walletType: _addcust.walletType,
                currency: _addcust.currency,
                email: value,
                password: _addcust.password,
                PIN: _addcust.PIN,
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          const LeadingNames(leadingName: "Password"),
          const SizedBox(height: 5),
          TextFormField(
            onChanged: (value) {
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                country: _addcust.country,
                province: _addcust.province,
                city: _addcust.city,
                suburbs: _addcust.suburbs,
                walletType: _addcust.walletType,
                currency: _addcust.currency,
                email: _addcust.email,
                password: value,
                PIN: _addcust.PIN,
              );
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            controller: _passwd,
            focusNode: _passwdFocusNode,
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
            obscureText: obsecure,
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: secondryColor,
                  width: 1.5,
                ),
              ),
              prefixIcon: const Icon(
                Icons.lock,
                color: primaryColor,
              ),
              suffixIcon: InkWell(
                onTap: () {
                  setState(() {
                    obsecure = !obsecure;
                  });
                },
                child: obsecure
                    ? const Icon(
                        FontAwesomeIcons.eyeSlash,
                        color: secondryColor,
                        size: 18,
                      )
                    : const Icon(
                        Icons.remove_red_eye,
                        color: primaryColor,
                      ),
              ),
              contentPadding: const EdgeInsets.only(top: 18),
              hintText: "Enter Password",
              hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
            ),
            validator: (value) {
              if (_submitted && value!.isEmpty) {
                return "Password field is required";
              } else {
                bool result = validatePassword(value!);
                if (result) {
                  return null;
                } else if (value.length < 6) {
                  return "Password must be at least 6 characters long";
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          const LeadingNames(leadingName: "Confirm Password"),
          const SizedBox(height: 5),
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            controller: _cpasswd,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
            obscureText: obsecure1,
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: secondryColor,
                  width: 1.5,
                ),
              ),
              prefixIcon: const Icon(
                Icons.lock,
                color: primaryColor,
              ),
              suffixIcon: InkWell(
                onTap: () {
                  setState(() {
                    obsecure1 = !obsecure1;
                  });
                },
                child: obsecure1
                    ? const Icon(
                        FontAwesomeIcons.eyeSlash,
                        color: secondryColor,
                        size: 18,
                      )
                    : const Icon(
                        Icons.remove_red_eye,
                        color: primaryColor,
                      ),
              ),
              contentPadding: const EdgeInsets.only(top: 18),
              hintText: "Re Enter Password",
              hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45),
            ),
            validator: (value) {
              if (_submitted && (value == null || value.isEmpty)) {
                return "Confirm Password field is required";
              } else if (value != _passwd.text.trim()) {
                return 'Password must be the same as above';
              } else if (value == null || value.length < 6) {
                return "Password must be at least 6 characters long";
              } else {
                bool result = validatePassword(value);
                if (result) {
                  return null;
                } else {
                  return "Password should contain Uppercase, Lowercase, Number & Special characters";
                }
              }
            },

          ),
          const SizedBox(height: 10),
          const LeadingNames(leadingName: "PIN"),
          const SizedBox(height: 5),
          AllformFields(
            keyboardType: TextInputType.number,
            ctr: _pin,
            hintxt: "Enter PIN",
            icn: Icons.pin,
            textInputAction: TextInputAction.done,
            focusNode: _pinFocusNode,
            onChanged: (value) {
              print(value);
              _addcust = CustomerRegistration(
                name: _addcust.name,
                surname: _addcust.surname,
                national: _addcust.national,
                telphone: _addcust.telphone,
                preferredcontactnumber: _addcust.preferredcontactnumber,
                referralcode: _addcust.referralcode,
                identificationtype: _addcust.identificationtype,
                identificationnumber: _addcust.identificationnumber,
                streetname: _addcust.streetname,
                streetnumber: _addcust.streetnumber,
                country: _addcust.country,
                province: _addcust.province,
                city: _addcust.city,
                suburbs: _addcust.suburbs,
                walletType: _addcust.walletType,
                currency: _addcust.currency,
                email: _addcust.email,
                password: _addcust.password,
                PIN: value,
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'PIN is required';
              } else if (value.length != 4) {
                return 'PIN must be 4 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  ),
  ),
];


//saving function;
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Okay',
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final bool _submitted = false;

  //Maanta 25/05/24


  
  Future<void> prefetchImages(List<HomeSliderModel> sliderModels, BuildContext context) async {
  for (var model in sliderModels) {
    try {
      String fullImageUrl = '${ApiUrls.BASE_URL}${model.imageUrl}'; 
      final cacheManager = CachedNetworkImageProvider(fullImageUrl);
      await precacheImage(cacheManager, context);
    } catch (e) {
      print("Failed to cache image: ${model.imageUrl}, Error: $e");
    }
  }
}

Future<void> _saveForm() async {
  final isValid = _formKey.currentState?.validate();
  if (!isValid!) {
    return;
  }
  _formKey.currentState?.save();
  setState(() {
    _isLoading = true;
  });

  var errorMessage = 'Successfully Registered';


  try {
    await Provider.of<CustomerRegistration>(context, listen: false)
        .addCustomer(_addcust, _pickImages, _pickDocuments);

    // Log user in
    await Provider.of<Auth>(context, listen: false).login(
      _addcust.telphone,
      _addcust.password,
      _authData['version'],
      context,
    );


    final walletAccountId = (_addcust.telphone ?? '').replaceAll('+', '');

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet_accounts_id', walletAccountId);

    // Sync to your device-registry API if token changed
    try {
      final currentToken = await FcmTokenManager.getCurrentToken();
      final savedToken   = await FcmTokenManager.getSavedToken();

      if (currentToken != null &&
          currentToken.isNotEmpty &&
          currentToken != savedToken) {
        await DeviceRegistrationService.registerDevice(
          walletAccountsId: walletAccountId,
          fcmToken: currentToken,
        );
        await FcmTokenManager.saveToken(currentToken);
      }
    } catch (e) {
      debugPrint('FCM/device registration failed: $e');
    }

    // Fetch and cache slider images
    final homeSliderAndTransactionProvider = Provider.of<HomeSliderAndTransaction>(context, listen: false);
    final List<HomeSliderModel> sliderImages = await homeSliderAndTransactionProvider.fetchAndSetSliderImages();
    await prefetchImages(sliderImages, context);

    // Fetch and display balance
    homeSliderAndTransactionProvider.fetchAndDisplayBalance(_addcust.telphone!);

    // Remove the '+' character from the phone number
    String walletId = _addcust.telphone!.replaceAll('+', '');

    // Debug log
    print('Navigating to HomeScreen with wallet_accounts_id: $walletId');

    // Show success dialog
    showDialog(
      context: context,
      builder: (ctx) => SuccessDialog(
        message: 'Your account is successfully registered and you are now logged in.',
        onConfirm: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                wallet_accounts_id: walletId, // Provide a default value if null
                fromLogin: true,  // Flag set to true when navigating from registration
              ),
            ),
          );
        },
      ),
    );

  } on HttpException catch (error) {
    if (error.toString().contains('this phone number already registered please use another number')) {
      errorMessage = 'This phone number is already registered. Please use another number.';
    } else if (error.toString().contains('Email is already exit use another Email')) {
      errorMessage = 'Email is already in use. Please use another Email.';
    } else if (error.toString().contains('INACTIVE_ACCOUNT')) {
      errorMessage = 'Your Account is not Active.';
    } else if (error.toString().contains('OP')) {
      errorMessage = 'Operation failed.';
    }
    _showErrorDialog(errorMessage);
  } catch (error) {
    _showErrorDialog(error.toString());
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _email.dispose();
    _passwd.dispose();
    _cpasswd.dispose();
    super.dispose();
  }


}

class SuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;

  const SuccessDialog({super.key, required this.message, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(

        padding: const EdgeInsets.all(20.0), 


        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              'Success',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
