// lib/settings/complete_profile_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/providers/FillDropdownbyRegistreration.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/snack_bar/open_snack_bar.dart';
import 'package:asalpay/widgets/AllinOneDropdownSearch.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String phone;             // must include '+' (e.g. +2526...)
  final String? walletTypeIdHint; // optional prefill

  const CompleteProfileScreen({
    super.key,
    required this.phone,
    this.walletTypeIdHint,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Loading flags
  bool _isLoadingDropData = false; // country / docType / walletType lists
  bool _loadingProvince   = false; // only province spinner
  bool _loadingCity       = false; // only city spinner
  bool _submitting        = false;

  // controllers for fields still needed here
  final _documentNo   = TextEditingController();
  final _streetName   = TextEditingController();
  final _streetNumber = TextEditingController();
  final _suburb       = TextEditingController();

  // optional controllers for dropdown search fields
  final _countrySearch    = TextEditingController();
  final _provinceSearch   = TextEditingController();
  final _citySearch       = TextEditingController();
  final _docTypeSearch    = TextEditingController();
  final _walletTypeSearch = TextEditingController();

  // selected IDs (STRING IDs)
  String? _countryId;
  String? _provinceId;
  String? _cityId;
  String? _docTypeId;
  String? _walletTypeId;

  // prefilled (from InitiateRegistration)
  String? _initPreferredCn;
  String? _initReferralCode;

  // picked files
  File? _selfieImage;   // imageUrl -> base64
  File? _documentFile;  // documentUrl -> base64 (pdf/jpg/png)

  // auth
  final tokenClass = TokenClass();
  late final String _apiKey;
  late final String _bearer;

  @override
  void initState() {
    super.initState();
    _apiKey  = tokenClass.key;
    _bearer  = tokenClass.getToken();
    _walletTypeId = widget.walletTypeIdHint; // optional hint
    _prefillFromInitiate().then((_) => _primeDropdowns()); // prefill first, then load lists
  }

  Future<void> _prefillFromInitiate() async {
    final prefs = await SharedPreferences.getInstance();
    _countryId        = prefs.getString('init_country_id') ?? _countryId;
    _walletTypeId     = prefs.getString('init_wallet_type_id') ?? _walletTypeId;
    _initPreferredCn  = prefs.getString('init_preferred_cn');
    _initReferralCode = prefs.getString('init_referral_code');
    if (mounted) setState(() {});
  }

  Future<void> _primeDropdowns() async {
    setState(() => _isLoadingDropData = true);
    final dd = Provider.of<FillRegisterationDropdown>(context, listen: false);
    try {
      if (dd.country.isEmpty)      { await dd.fetchAndSetCountry(); }
      if (dd.documentType.isEmpty) { await dd.fetchAndSetDocumentType(); }
      if (dd.walletType.isEmpty)   { await dd.fetchAndSetWalletType(); }

      // if country prefilled, only fetch provinces initially
      if (_countryId != null && _countryId!.isNotEmpty) {
        setState(() => _loadingProvince = true);
        await dd.fetchAndSetProvince(_countryId!);
        if (mounted) setState(() => _loadingProvince = false);
      }
    } finally {
      if (mounted) setState(() => _isLoadingDropData = false);
    }
  }

  @override
  void dispose() {
    _documentNo.dispose();
    _streetName.dispose();
    _streetNumber.dispose();
    _suburb.dispose();

    _countrySearch.dispose();
    _provinceSearch.dispose();
    _citySearch.dispose();
    _docTypeSearch.dispose();
    _walletTypeSearch.dispose();
    super.dispose();
  }

  // ---------- pickers ----------
  Future<void> _pickSelfie() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked != null) {
      setState(() => _selfieImage = File(picked.path));
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _documentFile = File(result.files.single.path!));
    }
  }

  // ---------- utils ----------
  String _toBase64(File? f) {
    if (f == null) return '';
    final bytes = f.readAsBytesSync();
    return base64Encode(bytes);
  }

  Map<String, String> _safeHeaders(Map<String, String> src) {
    final h = Map<String, String>.from(src);
    for (final k in h.keys.toList()) {
      final kl = k.toLowerCase();
      if (kl.contains('auth') || kl.contains('key') || kl.contains('token')) {
        h[k] = '***redacted***';
      }
    }
    return h;
  }

  String _nameById<T>(List<T> list, String? id) {
    if (id == null) return '';
    for (final item in list) {
      final m = item as dynamic;
      if ((m.id?.toString() ?? '') == id.toString()) return (m.name?.toString() ?? '');
    }
    return '';
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required VoidCallback onChange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onChange,
            icon: const Icon(Icons.edit, color: secondryColor),
          ),
        ],
      ),
    );
  }

  // ---------- submit ----------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_countryId == null || _docTypeId == null || _walletTypeId == null ||
        _provinceId == null || _cityId == null) {
      openSnackbar(context, 'Please complete all required selections.', Colors.red);
      return;
    }

    setState(() => _submitting = true);

    // ensure lists exist for selected ids
    final dd = Provider.of<FillRegisterationDropdown>(context, listen: false);
    if (dd.province.isEmpty && _countryId != null) {
      await dd.fetchAndSetProvince(_countryId!);
    }
    if (dd.city.isEmpty && _provinceId != null) {
      await dd.fetchAndSetCity(_provinceId!);
    }

    final body = {
      "country_id": int.parse(_countryId!),               // int
      "phone": widget.phone,                              // +252...
      "preferred_cn": _initPreferredCn ?? '',             // DRY from initiate
      "referral_code": _initReferralCode ?? '',           // DRY from initiate
      "document_type_id": _docTypeId!,                    // string id
      "document_no": _documentNo.text.trim(),
      "street_name": _streetName.text.trim(),
      "street_number": _streetNumber.text.trim(),
      "province_id": _provinceId!,                        // string id
      "city_id": _cityId!,                                // string id
      "suburb": _suburb.text.trim(),
      "wallet_type_id": _walletTypeId!,                   // string id (prefilled ok)
      "imageUrl": _toBase64(_selfieImage),                // base64
      "documentUrl": _toBase64(_documentFile),            // base64
    };

    final url = Uri.parse("${ApiUrls.BASE_URL}/Wallet_registration/completeProfile");
    final headers = {
      'Content-Type': 'application/json',
      'API-KEY': _apiKey,
      'Authorization': 'Bearer $_bearer',
    };

    // DEBUG (masked)
    debugPrint('➡️  POST $url');
    debugPrint('➡️  Headers: ${_safeHeaders(headers)}');
    final maskedBody = Map<String, dynamic>.from(body);
    if (maskedBody['phone'] != null) {
      final ph = maskedBody['phone'].toString();
      maskedBody['phone'] = ph.length > 4
          ? ('*' * (ph.length - 4)) + ph.substring(ph.length - 4)
          : '****';
    }
    maskedBody['imageUrl'] = _selfieImage == null ? '' : '<base64:${_selfieImage!.lengthSync()} bytes>';
    maskedBody['documentUrl'] = _documentFile == null ? '' : '<base64:${_documentFile!.lengthSync()} bytes>';
    debugPrint('➡️  Body: ${jsonEncode(maskedBody)}');

    try {
      final resp = await http.post(url, headers: headers, body: jsonEncode(body));
      debugPrint('⬅️  Status: ${resp.statusCode}');
      debugPrint('⬅️  Resp Body: ${resp.body}');
      dynamic data;
      try { data = jsonDecode(resp.body); } catch (_) { data = null; }

      final ok = resp.statusCode == 200 &&
                 data is Map &&
                 (data['status'] == true);

      if (ok) {
        openSnackbar(context, data['message']?.toString() ?? 'Profile completed and account activated.', Colors.green);
        if (!mounted) return;
        Navigator.of(context).pop(true); // back to settings
      } else {
        final msg = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Complete profile failed. Status ${resp.statusCode}';
        openSnackbar(context, msg, Colors.red);
      }
    } catch (e) {
      debugPrint('❌ CompleteProfile error: $e');
      if (mounted) openSnackbar(context, 'Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: secondryColor,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(icon, color: secondryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: secondryColor, width: 1.5),
              ),
              hintText: "Enter $label",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool hasFile,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: hasFile ? Colors.green : secondryColor,
          side: BorderSide(
            color: hasFile ? Colors.green : secondryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              hasFile ? '$label Selected' : label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasFile ? Colors.green : secondryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _smallSpinner() {
  return const SizedBox(
    width: 30,
    height: 30,
    child: LogoandSpinner(
      imageAssets: 'assets/asalicon.png',
      reverse: true,
      arcColor: primaryColor,
      spinSpeed: Duration(milliseconds: 500),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final dd = Provider.of<FillRegisterationDropdown>(context);

    // friendly names for prefilled summary tiles
    final countryName   = _nameById(dd.country, _countryId);
    final walletTypeStr = _nameById(dd.walletType, _walletTypeId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondryColor,
        title: const Text('Complete Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoadingDropData
            ? const Center(
                child: LogoandSpinner(
                  imageAssets: 'assets/asalicon.png',
                  reverse: true,
                  arcColor: primaryColor,
                  spinSpeed: Duration(milliseconds: 500),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const Text(
                      //   'Complete Your Profile',
                      //   style: TextStyle(
                      //     fontSize: 24,
                      //     fontWeight: FontWeight.bold,
                      //     color: secondryColor,
                      //   ),
                      // ),
                      const SizedBox(height: 8),
                      // const Text(
                      //   'Please fill in the remaining details to activate your account',
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Color(0xFF64748B),
                      //   ),
                      // ),
                      const SizedBox(height: 24),

                      if (_countryId != null || 
                          _walletTypeId != null || 
                          (_initPreferredCn ?? '').isNotEmpty || 
                          (_initReferralCode ?? '').isNotEmpty)
                        // _buildSectionTitle('Prefilled Information'),

                      if (_countryId != null && _countryId!.isNotEmpty)
                        _summaryTile(
                          label: 'Country',
                          value: countryName,
                          onChange: () {
                            setState(() {
                              _countryId  = null;
                              _provinceId = null;
                              _cityId     = null;
                            });
                          },
                        ),

                      if (_walletTypeId != null && _walletTypeId!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _summaryTile(
                          label: 'Wallet Type',
                          value: walletTypeStr,
                          onChange: () => setState(() => _walletTypeId = null),
                        ),
                      ],

                      if ((_initPreferredCn ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _summaryTile(
                          label: 'Preferred Contact',
                          value: _initPreferredCn!,
                          onChange: () async {
                            final v = await showDialog<String>(
                              context: context,
                              builder: (_) {
                                final c = TextEditingController(text: _initPreferredCn);
                                return AlertDialog(
                                  title: const Text('Edit Preferred Contact'),
                                  content: TextField(controller: c),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context), 
                                      child: const Text('Cancel')
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, c.text.trim()), 
                                      child: const Text('Save')
                                    ),
                                  ],
                                );
                              },
                            );
                            if (v != null) setState(() => _initPreferredCn = v);
                          },
                        ),
                      ],

                      if ((_initReferralCode ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _summaryTile(
                          label: 'Referral Code',
                          value: _initReferralCode!,
                          onChange: () async {
                            final v = await showDialog<String>(
                              context: context,
                              builder: (_) {
                                final c = TextEditingController(text: _initReferralCode);
                                return AlertDialog(
                                  title: const Text('Edit Referral Code'),
                                  content: TextField(controller: c),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context), 
                                      child: const Text('Cancel')
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, c.text.trim()), 
                                      child: const Text('Save')
                                    ),
                                  ],
                                );
                              },
                            );
                            if (v != null) setState(() => _initReferralCode = v);
                          },
                        ),
                      ],

                      // ====== Ask only what we still need ======
                      _buildSectionTitle('Required Information'),

                      // Country (only if not prefilled)
                      if (_countryId == null || _countryId!.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Country',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AllinOneDropdownSearch(
                                SearchCtr: _countrySearch,
                                hintxt: "Select Your Country",
                                maintext: "search Country",
                                items: dd.country,
                                dropdownValue: _countryId,
                                onChanged: (value) async {
                                  setState(() {
                                    _countryId    = value;
                                    _provinceId   = null;
                                    _cityId       = null;
                                    _loadingProvince = true; // only province loads
                                    _loadingCity     = false;
                                  });
                                  await dd.fetchAndSetProvince(_countryId!);
                                  if (mounted) setState(() => _loadingProvince = false);
                                },
                                validator: (v) => (v == null || v.isEmpty) ? 'Country Field is Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Province
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Province',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                        _loadingProvince
                        ? Center(child: _smallSpinner())
                        : AllinOneDropdownSearch(
                            SearchCtr: _provinceSearch,
                            hintxt: "Select Your Province",
                            maintext: "search Province",
                            items: dd.province,
                            dropdownValue: _provinceId,
                            onChanged: (value) async {
                              setState(() {
                                _provinceId = value;
                                _cityId = null;
                                _loadingCity = true; // only city shows a spinner now
                              });
                              await dd.fetchAndSetCity(_provinceId!);
                              if (mounted) setState(() => _loadingCity = false);
                            },
                            validator: (v) => (v == null || v.isEmpty) ? 'Province Field is Required' : null,
                          ),
                          ],
                        ),
                      ),

                      // City
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'City',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_provinceId == null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Select a province first',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                            ] else ...[
                            _loadingCity
                              ? const Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: LogoandSpinner(
                                      imageAssets: 'assets/asalicon.png',
                                      reverse: true,
                                      arcColor: primaryColor,
                                      spinSpeed: Duration(milliseconds: 500),
                                    ),
                                  ),
                                )
                                  : AllinOneDropdownSearch(
                                      SearchCtr: _citySearch,
                                      hintxt: "Select Your City",
                                      maintext: "search City",
                                      items: dd.city,
                                      dropdownValue: _cityId,
                                      onChanged: (value) => setState(() => _cityId = value),
                                      validator: (v) => (v == null || v.isEmpty) ? 'City Field is Required' : null,
                                    ),
                            ],
                          ],
                        ),
                      ),

                      // Wallet type (only if not prefilled)
                      if (_walletTypeId == null || _walletTypeId!.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Wallet Type',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AllinOneDropdownSearch(
                                SearchCtr: _walletTypeSearch,
                                hintxt: "Select any Wallet type",
                                maintext: "Search Wallet type",
                                items: dd.walletType,
                                dropdownValue: _walletTypeId,
                                onChanged: (value) => setState(() => _walletTypeId = value),
                                validator: (v) => (v == null || v.isEmpty) ? 'Wallet Type is Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Document type
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Document Type',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AllinOneDropdownSearch(
                              SearchCtr: _docTypeSearch,
                              hintxt: "Select Your Identification Type!",
                              maintext: "Search Identification",
                              items: dd.documentType,
                              dropdownValue: _docTypeId,
                              onChanged: (value) => setState(() => _docTypeId = value),
                              validator: (v) => (v == null || v.isEmpty) ? 'Identification Type is Required' : null,
                            ),
                          ],
                        ),
                      ),

                      // Document number
                      _buildFormField(
                        controller: _documentNo,
                        label: 'Document Number',
                        icon: Icons.description,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      _buildSectionTitle('Address Information'),

                      // Street name
                      _buildFormField(
                        controller: _streetName,
                        label: 'Street Name',
                        icon: Icons.location_on,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      // Street number
                      _buildFormField(
                        controller: _streetNumber,
                        label: 'Street Number',
                        icon: Icons.numbers,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      // District/Suburb
                      _buildFormField(
                        controller: _suburb,
                        label: 'District / Suburb',
                        icon: Icons.location_city,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      _buildSectionTitle('Upload Documents'),

                      // Document upload
                      _buildFilePickerButton(
                        label: 'Upload Document (pdf/jpg/png)',
                        icon: Icons.upload_file,
                        onPressed: _pickDocument,
                        hasFile: _documentFile != null,
                      ),
                      const SizedBox(height: 12),

                      // Selfie upload
                      _buildFilePickerButton(
                        label: 'Capture Selfie',
                        icon: Icons.camera_alt,
                        onPressed: _pickSelfie,
                        hasFile: _selfieImage != null,
                      ),
                      const SizedBox(height: 24),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 24, 
                                  height: 24, 
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Complete Profile', 
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600, 
                                    fontSize: 16
                                  ),
                                ),
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