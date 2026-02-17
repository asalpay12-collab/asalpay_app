import 'dart:convert';
import 'package:asalpay/constants/Constant.dart'; // <- contains secondryColor
import 'package:asalpay/providers/FillDropdownbyRegistreration.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllinOneDropdownSearch.dart'; // <- for Country selector
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:fl_country_code_picker/fl_country_code_picker.dart';

import 'package:asalpay/services/tokens.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:asalpay/home/homescreen.dart';


class InitiateRegistrationScreen extends StatefulWidget {
  final String verifiedIdentifier; // phone (e.g. +252...) or email
  final String channel; // 'phone' | 'email'

  const InitiateRegistrationScreen({
    super.key,
    required this.verifiedIdentifier,
    required this.channel,
  });

  @override
  State<InitiateRegistrationScreen> createState() => _InitiateRegistrationScreenState();
}

class _InitiateRegistrationScreenState extends State<InitiateRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TokenClass tokenClass = TokenClass();

  final _fname = TextEditingController();
  final _mname = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(); // used when channel is email
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _referralCode = TextEditingController();
  final _preferredContact = TextEditingController();

  // Search controller for the Country searchable dropdown
  final _countrySearchCtr = TextEditingController();

  late FlCountryCodePicker _countryCodePicker;
  CountryCode? _phoneCountryCode;

  String? selectedCountryId;
  String? selectedWalletTypeId;
  String? selectedCurrencyId;

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final provider = Provider.of<FillRegisterationDropdown>(context, listen: false);
      provider.fetchAndSetCountry();
      provider.fetchAndSetCurrency();
      provider.fetchAndSetWalletType();
      _isInit = false;
    }
  }

  static final CountryCode _somalia = CountryCode.fromMap({
    'name': 'Somalia',
    'code': 'SO',
    'dial_code': '+252',
  });

  @override
  void initState() {
    super.initState();
    _countryCodePicker = const FlCountryCodePicker(
      showDialCode: true,
      showSearchBar: true,
    );
    _phoneCountryCode = _somalia;
    if (widget.channel == 'email') {
      _email.text = widget.verifiedIdentifier;
    }
  }

  @override
  void dispose() {
    _fname.dispose();
    _mname.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _pin.dispose();
    _referralCode.dispose();
    _preferredContact.dispose();
    _countrySearchCtr.dispose();
    super.dispose();
  }

  String get _phoneForApi {
    if (widget.channel == 'phone') return widget.verifiedIdentifier;
    final dialCode = _phoneCountryCode?.dialCode ?? '+252';
    final digits = dialCode.replaceAll(RegExp(r'[^\d]'), '');
    String phoneDigits = _phone.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.startsWith(digits)) phoneDigits = phoneDigits.substring(digits.length);
    return '$dialCode$phoneDigits';
  }
  String get _emailForApi =>
      widget.channel == 'phone' ? _email.text.trim() : widget.verifiedIdentifier;

  Map<String, dynamic> _maskedBodyForLog(Map<String, dynamic> src) {
    final copy = Map<String, dynamic>.from(src);
    if (copy['password'] != null) copy['password'] = _mask(copy['password'].toString());
    if (copy['pin'] != null)      copy['pin']      = _mask(copy['pin'].toString());
    if (copy['phone'] != null)    copy['phone']    = _maskRight(copy['phone'].toString(), visible: 4);
    return copy;
  }

  Map<String, String> _redactSensitiveHeaders(Map<String, String> headers) {
    final h = Map<String, String>.from(headers);
    for (final k in h.keys.toList()) {
      final kl = k.toLowerCase();
      if (kl.contains('auth') || kl.contains('key') || kl.contains('token')) {
        h[k] = '***redacted***';
      }
    }
    return h;
  }

  String _mask(String s) => s.isEmpty ? s : '*' * (s.length.clamp(4, 12));
  String _maskRight(String s, {int visible = 4}) {
    if (s.isEmpty) return s;
    if (s.length <= visible) return '*' * s.length;
    final maskedLen = s.length - visible;
    return ('*' * maskedLen) + s.substring(maskedLen);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCountryId == null || selectedCurrencyId == null || selectedWalletTypeId == null) {
      openSnackbar(context, 'Please select country, wallet type, and currency', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final String token  = tokenClass.getToken();
    final String apiKey = tokenClass.key;

    final body = {
      "f_name": _fname.text.trim(),
      "m_name": _mname.text.trim(),
      "country_id": int.parse(selectedCountryId!),
      "phone": _phoneForApi,
      "password": _password.text.trim(),
      "pin": _pin.text.trim(),
      "preferred_cn": _preferredContact.text.trim(),
      "referral_code": _referralCode.text.trim(),
      "wallet_type_id": selectedWalletTypeId!,
      "email": _emailForApi,
      "currency_id": selectedCurrencyId!,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      // 'Access-Control-Allow-Origin': '*', // response header; not needed in request
      "API-KEY": apiKey,
      "Authorization": "Bearer $token",
    };

    try {
      final url = Uri.parse("${ApiUrls.BASE_URL}/Wallet_registration/initiateRegistration");

      debugPrint('➡️  POST $url');
      debugPrint('➡️  Headers: ${_redactSensitiveHeaders(headers)}');
      debugPrint('➡️  Body: ${jsonEncode(_maskedBodyForLog(body))}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('⬅️  Status: ${response.statusCode}');
      debugPrint('⬅️  Resp Headers: ${response.headers}');
      debugPrint('⬅️  Resp Body: ${response.body}');

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'status': false, 'message': 'Non-JSON response', 'raw': response.body};
      }


if (response.statusCode == 200 && data is Map && (data['status'] == true)) {
  // Snack (optional)
  openSnackbar(context, 'Registration Initiated. Please complete your profile.', Colors.green);

  final walletId = _phoneForApi.replaceAll(RegExp(r'[^\d]'), '');

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet_accounts_id', walletId);

  await prefs.setString('init_country_id', selectedCountryId!);
  await prefs.setString('init_wallet_type_id', selectedWalletTypeId!);
  await prefs.setString('init_preferred_cn', _preferredContact.text.trim());
  await prefs.setString('init_referral_code', _referralCode.text.trim());
  await prefs.setString('init_currency_id', selectedCurrencyId!);

  } catch (_) {}

  if (!mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => HomeScreen(
        wallet_accounts_id: walletId,
        fromLogin: true,

      ),
    ),


    

    (route) => false,
  );
  return;
} else {
  final msg = (data is Map && data['message'] != null)
      ? data['message'].toString()
      : 'Failed to register. Status ${response.statusCode}';
  openSnackbar(context, msg, Colors.red);
}



    } catch (e) {
      debugPrint(' REQUEST ERROR: $e');
      openSnackbar(context, 'Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _input(String label, {IconData? icon, bool isPassword = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: secondryColor) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: secondryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dropdownProvider = Provider.of<FillRegisterationDropdown>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: secondryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Registration'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(

              padding: const EdgeInsets.fromLTRB(16, 20, 16, 50),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: secondryColor.withOpacity(.12),
                            child: Icon(Icons.person_add_alt_1, color: secondryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Start with a few quick details to create your wallet.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF334155),
                                    height: 1.3,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _fname,
                                decoration: _input('First Name', icon: Icons.badge_outlined),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _mname,
                                decoration: _input('Middle Name', icon: Icons.person_outline),
                              ),
                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Country', style: Theme.of(context).textTheme.labelLarge),
                              ),
                              const SizedBox(height: 6),
                              AllinOneDropdownSearch(
                                SearchCtr: _countrySearchCtr,
                                hintxt: "Select your Country",
                                maintext: "Search Country",
                                items: dropdownProvider.country,
                                dropdownValue: selectedCountryId,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() => selectedCountryId = value);
                                },
                              ),

                              const SizedBox(height: 12),
                              widget.channel == 'phone'
                                  ? TextFormField(
                                      initialValue: widget.verifiedIdentifier,
                                      enabled: false,
                                      decoration: _input('Phone', icon: Icons.phone_iphone),
                                    )
                                  : TextFormField(
                                      controller: _phone,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required for wallet' : null,
                                      decoration: InputDecoration(
                                        labelText: 'Phone (country code added automatically)',
                                        prefixIcon: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  try {
                                                    final code = await _countryCodePicker.showPicker(context: context);
                                                    if (code != null && mounted) setState(() => _phoneCountryCode = code);
                                                  } catch (e) {
                                                    if (mounted) openSnackbar(context, 'Failed to select country', Colors.red);
                                                  }
                                                },
                                                child: Text(
                                                  _phoneCountryCode?.dialCode ?? '+252',
                                                  style: const TextStyle(color: secondryColor, fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: secondryColor, width: 1.5),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.red, width: 1),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 12),
                              widget.channel == 'phone'
                                  ? TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: _input('Email', icon: Icons.email_outlined),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                    )
                                  : TextFormField(
                                      initialValue: widget.verifiedIdentifier,
                                      enabled: false,
                                      decoration: _input('Email', icon: Icons.email_outlined),
                                    ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                decoration: _input('Password', icon: Icons.lock_outline),
                                validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _pin,
                                keyboardType: TextInputType.number,
                                decoration: _input('PIN (4 digits)', icon: Icons.pin_outlined),
                                validator: (v) => (v == null || v.length != 4) ? 'Must be 4 digits' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _preferredContact,
                                keyboardType: TextInputType.phone,
                                decoration: _input('Preferred Contact Number (Optional)', icon: Icons.call),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _referralCode,
                                decoration: _input('Referral Code (Optional)', icon: Icons.card_giftcard_outlined),
                              ),
                              const SizedBox(height: 12),

                              // Wallet Type
                              DropdownButtonFormField(
                                value: selectedWalletTypeId,
                                decoration: _input('Wallet Type', icon: Icons.account_balance_wallet_outlined),
                                items: dropdownProvider.walletType.map((item) {
                                  return DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => selectedWalletTypeId = value),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),

                              // Currency
                              DropdownButtonFormField(
                                value: selectedCurrencyId,
                                decoration: _input('Currency', icon: Icons.currency_exchange),
                                items: dropdownProvider.currency.map((item) {
                                  return DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => selectedCurrencyId = value),
                                validator: (v) => v == null ? 'Required' : null,
                              ),

                              const SizedBox(height: 20),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          'Submit',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
