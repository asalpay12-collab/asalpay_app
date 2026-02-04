import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../services/252pay_api_service.dart';
import '../../utils/bnpl_utils.dart';
import '../../models/product_rules.dart';
import '../../models/location_risk.dart';
import '../../models/credit_limit.dart';
import 'bnpl_tracking_screen.dart';

class BnplApplicationScreen extends StatefulWidget {
  final String? walletAccountId;
  final double totalOrderAmount;
  final List<Map<String, dynamic>> orderItems;
  final int? initialStep; // Optional: start from a specific step

  const BnplApplicationScreen({
    super.key,
    required this.walletAccountId,
    required this.totalOrderAmount,
    required this.orderItems,
    this.initialStep,
  });

  @override
  State<BnplApplicationScreen> createState() => _BnplApplicationScreenState();
}

class _BnplApplicationScreenState extends State<BnplApplicationScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final api = ApiService();
  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();

  int _currentStep = 0;
  bool isLoading = false;
  bool isSubmitting = false;
  bool isLoadingDistricts = false;
  bool isSavingDraft = false;
  int? draftApplicationId;
  Timer? _autoSaveTimer;

  // Application Configuration (loaded from API)
  Map<String, dynamic>? appConfig;
  List<Map<String, dynamic>> eligibilityChecklistItems = [];
  List<Map<String, dynamic>> genderOptions = [];
  List<Map<String, dynamic>> maritalStatusOptions = [];
  List<Map<String, dynamic>> employmentStatusOptions = [];
  List<Map<String, dynamic>> documentTypes = [];
  Map<String, dynamic>? ageRequirements;

  // Step 1: Eligibility Checklist (dynamically initialized)
  Map<String, bool> eligibilityChecklist = {};

  // Step 2: Personal Information
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  String? selectedGender;
  String? selectedMaritalStatus;
  final TextEditingController residentialAddressController =
      TextEditingController();

  // Step 3: Location
  List<Map<String, dynamic>> regions = [];
  List<Map<String, dynamic>> districts = [];
  int? selectedRegionId;
  int? selectedDistrictId;
  LocationRisk? locationRisk;
  bool isLoadingLocationRisk = false;

  // Step 4: Employment & Financial
  String? selectedEmploymentStatus;
  final TextEditingController employerNameController = TextEditingController();
  final TextEditingController monthlyIncomeController = TextEditingController();
  String? incomeCategory;
  List<Map<String, dynamic>> banks = [];
  int? selectedBankId;
  String? selectedBankName;
  final TextEditingController bankAccountController = TextEditingController();

  // Customer data
  bool customerExists = false;
  Map<String, dynamic>? existingCustomerData;

  // Step 5: Product & Rules
  ProductRules? productRules;
  CreditLimit? creditLimit;
  bool isLoadingProductRules = false;

  // Step 6: Guarantor (if needed)
  final TextEditingController guarantorNameController = TextEditingController();
  final TextEditingController guarantorPhoneController =
      TextEditingController();
  final TextEditingController guarantorAddressController =
      TextEditingController();
  final TextEditingController guarantorIncomeController =
      TextEditingController();

  // Step 7: Documents (dynamically initialized)
  Map<String, File?> documents = {};
  Map<String, String?> documentExpirationDates =
      {}; // Document expiration dates
  Map<String, String?> documentNumbers = {}; // Document numbers
  Map<String, bool> existingDocuments = {}; // Track existing documents
  String? selectedDocumentType; // Selected document type from dropdown
  final TextEditingController expirationDateController =
      TextEditingController(); // Expiration date input
  final TextEditingController documentNumberController =
      TextEditingController(); // Document number input

  // Step 8: Review
  Map<String, dynamic>? applicationResult;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadApplicationConfiguration(),
        _loadRegions(),
        _loadBanks(),
        _loadCreditLimit(),
      ]);

      // Check for draft first, then previous application data, then existing customer
      // Make sure eligibility checklist is initialized before loading draft
      if (eligibilityChecklist.isEmpty &&
          eligibilityChecklistItems.isNotEmpty) {
        for (var item in eligibilityChecklistItems) {
          final key = item['checklist_key']?.toString();
          if (key != null) {
            eligibilityChecklist[key] = false;
          }
        }
      }

      await _checkForDraft();
      if (draftApplicationId == null) {
        await _checkPreviousApplication();
      }
      if (draftApplicationId == null) {
        await _checkExistingCustomer();
      }

      // If initialStep is provided, navigate to that step
      if (widget.initialStep != null &&
          widget.initialStep! >= 0 &&
          widget.initialStep! < 8) {
        _currentStep = widget.initialStep!;
        _pageController.jumpToPage(_currentStep);
      } else if (draftApplicationId != null) {
        // Resume at the step the user left (already set from draft in _loadDraftData)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final step = _currentStep.clamp(0, 7);
            setState(() {
              _currentStep = step;
            });
            _pageController.jumpToPage(step);
            api.appLog("✅ Resumed draft at Step ${step + 1}");

            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _showDraftContinuationMessage(step);
              }
            });
          }
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDraftContinuationMessage(int step) {
    final stepNames = [
      'Eligibility Checklist',
      'Personal Information',
      'Location',
      'Employment & Financial',
      'Product & Rules',
      'Guarantor',
      'Documents',
      'Review & Submit',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Continue Draft Application',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have a draft application. Please complete the following step:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_forward, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Step ${step + 1}: ${stepNames[step]}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can also edit previous steps if needed.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForDraft() async {
    if (widget.walletAccountId == null || widget.walletAccountId!.isEmpty) {
      return;
    }

    try {
      final draft = await api.getApplicationDraft(widget.walletAccountId!);
      if (draft != null && mounted) {
        setState(() {
          final appId = draft['application_id'];
          draftApplicationId =
              appId is int ? appId : int.tryParse(appId?.toString() ?? '');
        });
        await _loadDraftData(draft);
        api.appLog("✅ Draft data loaded completely");
      }
    } catch (e) {
      api.appLog("⚠️ Failed to check for draft: $e");
      // Continue without draft
    }
  }

  Future<void> _checkPreviousApplication() async {
    if (widget.walletAccountId == null || widget.walletAccountId!.isEmpty) {
      return;
    }

    try {
      final previousData =
          await api.getPreviousApplicationData(widget.walletAccountId!);
      if (previousData != null && mounted) {
        _loadPreviousApplicationData(previousData);
      }
    } catch (e) {
      api.appLog("⚠️ Failed to check for previous application: $e");
      // Continue without previous data
    }
  }

  Future<void> _loadDraftData(Map<String, dynamic> draft) async {
    // Pre-fill all form fields from draft
    if (draft['full_name'] != null) {
      fullNameController.text = draft['full_name'].toString().trim();
    }
    if (draft['phone_number'] != null) {
      phoneController.text = draft['phone_number'].toString().trim();
      api.appLog("✅ Loaded phone_number: ${draft['phone_number']}");
    }
    if (draft['email'] != null) {
      emailController.text = draft['email'].toString().trim();
      api.appLog("✅ Loaded email: ${draft['email']}");
    }
    if (draft['date_of_birth'] != null) {
      final dob = draft['date_of_birth'].toString().trim();
      if (dob.isNotEmpty) {
        dateOfBirthController.text = dob;
        api.appLog("✅ Loaded date_of_birth: $dob");
      }
    }
    if (draft['gender'] != null &&
        draft['gender'].toString().trim().isNotEmpty &&
        genderOptions.isNotEmpty) {
      final genderVal = draft['gender'].toString().trim().toLowerCase();
      try {
        final matchingGender = genderOptions.firstWhere(
          (g) => (g['gender_key']?.toString().toLowerCase() ?? '') == genderVal,
        );
        if (matchingGender['gender_key'] != null) {
          setState(() {
            selectedGender = matchingGender['gender_key'].toString();
          });
          api.appLog("✅ Loaded gender: $selectedGender");
        }
      } catch (e) {
        api.appLog("⚠️ Gender not found in options for: $genderVal");
      }
    }
    if (draft['marital_status'] != null &&
        draft['marital_status'].toString().trim().isNotEmpty &&
        maritalStatusOptions.isNotEmpty) {
      final maritalVal =
          draft['marital_status'].toString().trim().toLowerCase();
      try {
        final matchingMarital = maritalStatusOptions.firstWhere(
          (m) =>
              (m['marital_status_key']?.toString().toLowerCase() ?? '') ==
              maritalVal,
        );
        if (matchingMarital['marital_status_key'] != null) {
          setState(() {
            selectedMaritalStatus =
                matchingMarital['marital_status_key'].toString();
          });
          api.appLog("✅ Loaded marital_status: $selectedMaritalStatus");
        }
      } catch (e) {
        api.appLog("⚠️ Marital status not found in options for: $maritalVal");
      }
    }
    if (draft['residential_address'] != null) {
      final addr = draft['residential_address'].toString().trim();
      if (addr.isNotEmpty) {
        residentialAddressController.text = addr;
        api.appLog("✅ Loaded residential_address: $addr");
      }
    }

    // Pre-fill location (region_id and district_id from draft/customer)
    final regionIdRaw = draft['region_id'];
    final regionId = regionIdRaw is int
        ? regionIdRaw
        : int.tryParse(regionIdRaw?.toString() ?? '');
    if (regionId != null && regionId > 0) {
      setState(() {
        selectedRegionId = regionId;
      });
      await _loadDistricts(regionId);
      api.appLog("✅ Loaded region_id: $regionId");
    }
    final districtIdRaw = draft['district_id'];
    final districtId = districtIdRaw is int
        ? districtIdRaw
        : int.tryParse(districtIdRaw?.toString() ?? '');
    if (districtId != null && districtId > 0) {
      setState(() {
        selectedDistrictId = districtId;
      });
      api.appLog("✅ Loaded district_id: $districtId");
    }

    // Pre-fill employment
    if (draft['employment_status'] != null &&
        employmentStatusOptions.isNotEmpty) {
      try {
        final matchingEmployment = employmentStatusOptions.firstWhere(
          (e) =>
              e['employment_status_key']?.toString().toLowerCase() ==
              draft['employment_status'].toString().toLowerCase(),
        );
        if (matchingEmployment['employment_status_key'] != null) {
          setState(() {
            selectedEmploymentStatus =
                matchingEmployment['employment_status_key'].toString();
          });
        }
      } catch (e) {
        api.appLog("⚠️ Employment status not found in options");
      }
    }
    if (draft['employer_name'] != null &&
        draft['employer_name'].toString().isNotEmpty) {
      employerNameController.text = draft['employer_name'].toString();
      api.appLog("✅ Loaded employer_name: ${draft['employer_name']}");
    }
    if (draft['monthly_income'] != null) {
      final incomeStr = draft['monthly_income'].toString();
      if (incomeStr.isNotEmpty) {
        monthlyIncomeController.text = incomeStr;
        final income = double.tryParse(incomeStr);
        if (income != null) {
          incomeCategory = BnplUtils.getIncomeCategory(income);
          api.appLog(
              "✅ Loaded monthly_income: $income, category: $incomeCategory");
          await _loadProductRules();
        }
      }
    }
    if (draft['bank_id'] != null) {
      final bankId = int.tryParse(draft['bank_id'].toString());
      if (bankId != null) {
        setState(() {
          selectedBankId = bankId;
        });
        api.appLog("✅ Loaded bank_id: $bankId");
      }
    }
    if (draft['bank_account_number'] != null) {
      bankAccountController.text =
          draft['bank_account_number'].toString().trim();
      api.appLog(
          "✅ Loaded bank_account_number: ${draft['bank_account_number']}");
    }

    // Pre-fill eligibility checklist: first from database checklist_items, then fallback to legacy flags
    if (draft['checklist_items'] != null && draft['checklist_items'] is List) {
      final list = draft['checklist_items'] as List;
      for (var item in list) {
        if (item is! Map<String, dynamic>) continue;
        final key = item['checklist_key']?.toString();
        final isChecked = item['is_checked'] == 1 ||
            item['is_checked'] == true ||
            item['is_checked'] == '1';
        if (key != null && key.isNotEmpty) {
          eligibilityChecklist[key] = isChecked;
          api.appLog("📋 Checklist from DB: $key = $isChecked");
        }
      }
    }
    // Fallback: map draft legacy fields (age_verified, documentation_complete, guarantor_provided) to checklist keys
    for (var item in eligibilityChecklistItems) {
      final key = item['checklist_key']?.toString();
      if (key == null) continue;

      // Map draft fields to checklist keys
      if (key.toLowerCase().contains('age') ||
          key.toLowerCase().contains('18')) {
        // Age verification
        if (draft['age_verified'] == 1 || draft['age_verified'] == true) {
          eligibilityChecklist[key] = true;
        }
      } else if (key.toLowerCase().contains('id') ||
          key.toLowerCase().contains('valid')) {
        // Valid ID
        if (draft['documentation_complete'] == 1 ||
            draft['documentation_complete'] == true) {
          eligibilityChecklist[key] = true;
        }
      } else if (key.toLowerCase().contains('income') ||
          key.toLowerCase().contains('proof')) {
        // Income proof
        if (draft['documentation_complete'] == 1 ||
            draft['documentation_complete'] == true) {
          eligibilityChecklist[key] = true;
        }
      } else if (key.toLowerCase().contains('bank') ||
          key.toLowerCase().contains('statement')) {
        // Bank statement
        if (draft['documentation_complete'] == 1 ||
            draft['documentation_complete'] == true) {
          eligibilityChecklist[key] = true;
        }
      } else if (key.toLowerCase().contains('guarantor') ||
          key.toLowerCase().contains('willing')) {
        // Guarantor
        if (draft['guarantor_provided'] == 1 ||
            draft['guarantor_provided'] == true) {
          eligibilityChecklist[key] = true;
        }
      }
    }

    // Also try direct mapping with common key names
    if (draft['age_verified'] == 1 || draft['age_verified'] == true) {
      // Try common key names
      final ageKeys = ['age_18_plus', 'age_18', 'age_verified', 'age'];
      for (var ageKey in ageKeys) {
        if (eligibilityChecklist.containsKey(ageKey)) {
          eligibilityChecklist[ageKey] = true;
          break;
        }
      }
    }

    if (draft['documentation_complete'] == 1 ||
        draft['documentation_complete'] == true) {
      // Try common key names for documentation
      final docKeys = [
        'has_valid_id',
        'has_id',
        'valid_id',
        'has_income_proof',
        'income_proof',
        'has_bank_statement',
        'bank_statement'
      ];
      for (var docKey in docKeys) {
        if (eligibilityChecklist.containsKey(docKey)) {
          eligibilityChecklist[docKey] = true;
        }
      }
    }

    if (draft['guarantor_provided'] == 1 ||
        draft['guarantor_provided'] == true) {
      // Try common key names for guarantor
      final guarantorKeys = [
        'willing_to_provide_guarantor',
        'guarantor',
        'provide_guarantor'
      ];
      for (var guarantorKey in guarantorKeys) {
        if (eligibilityChecklist.containsKey(guarantorKey)) {
          eligibilityChecklist[guarantorKey] = true;
          break;
        }
      }
    }

    api.appLog("📋 Eligibility checklist loaded from draft:");
    api.appLog("   - Checklist items: ${eligibilityChecklist.toString()}");
    if (mounted) {
      setState(() {
        eligibilityChecklist = Map<String, bool>.from(eligibilityChecklist);
      });
    }

    // Pre-fill guarantor if available
    if (draft['guarantor_name'] != null) {
      guarantorNameController.text = draft['guarantor_name'].toString();
    }
    if (draft['guarantor_phone'] != null) {
      guarantorPhoneController.text = draft['guarantor_phone'].toString();
    }
    if (draft['guarantor_address'] != null) {
      guarantorAddressController.text = draft['guarantor_address'].toString();
    }
    if (draft['guarantor_income'] != null) {
      guarantorIncomeController.text = draft['guarantor_income'].toString();
    }

    // Load document expiration dates and numbers from draft; mark non-expired as existing
    if (draft['documents'] != null && draft['documents'] is List) {
      final documentsList = draft['documents'] as List;
      final today = DateTime.now();
      for (var doc in documentsList) {
        if (doc is Map<String, dynamic>) {
          final docType = doc['document_type']?.toString();
          final expDate = doc['expiration_date']?.toString();
          final docNumber = doc['document_number']?.toString();
          if (docType != null) {
            if (expDate != null && expDate.isNotEmpty) {
              documentExpirationDates[docType] = expDate;
              api.appLog("📄 Loaded expiration date for $docType: $expDate");
              final exp = DateTime.tryParse(expDate);
              if (exp == null || exp.isAfter(today)) {
                existingDocuments[docType] = true;
                api.appLog(
                    "📄 Marked existing document (not expired): $docType");
              }
            } else {
              existingDocuments[docType] = true;
              api.appLog("📄 Marked existing document (no expiry): $docType");
            }
            if (docNumber != null && docNumber.isNotEmpty) {
              documentNumbers[docType] = docNumber;
              api.appLog("📄 Loaded document number for $docType: $docNumber");
            }
          }
        }
      }
    }

    // Resume at the step the user left (backend current_step is 1-based)
    final stepFromDraft = draft['current_step'];
    final draftStep = stepFromDraft is int
        ? stepFromDraft
        : int.tryParse(stepFromDraft?.toString() ?? '1');
    if (draftStep != null && draftStep >= 1 && draftStep <= 8 && mounted) {
      setState(() {
        _currentStep = (draftStep - 1).clamp(0, 7);
      });
      api.appLog(
          "📍 Draft resume at step ${_currentStep + 1} (from draft current_step: $draftStep)");
    }
  }

  void _loadPreviousApplicationData(Map<String, dynamic> previousData) {
    // Load eligibility checklist
    if (previousData['eligibility_checklist'] != null) {
      final checklist =
          previousData['eligibility_checklist'] as Map<String, dynamic>;
      if (checklist['age_verified'] == 1) {
        eligibilityChecklist['age_18_plus'] = true;
      }
      if (checklist['documentation_complete'] == 1) {
        eligibilityChecklist['has_valid_id'] = true;
        eligibilityChecklist['has_income_proof'] = true;
        eligibilityChecklist['has_bank_statement'] = true;
      }
      if (checklist['guarantor_provided'] == 1) {
        eligibilityChecklist['willing_to_provide_guarantor'] = true;
      }
    }

    // Load personal information
    if (previousData['personal_information'] != null) {
      final personalInfo =
          previousData['personal_information'] as Map<String, dynamic>;
      _prefillCustomerData(personalInfo);
    }

    // Load document expiration dates from previous application (only for non-expired documents)
    if (previousData['documents'] != null &&
        previousData['documents'] is List) {
      final documentsList = previousData['documents'] as List;
      for (var doc in documentsList) {
        if (doc is Map<String, dynamic>) {
          final docType = doc['document_type']?.toString();
          final expDate = doc['expiration_date']?.toString();
          final isExpired = doc['is_expired'] == 1 || doc['is_expired'] == true;

          // Only load expiration dates for documents that are not expired
          if (docType != null &&
              expDate != null &&
              expDate.isNotEmpty &&
              !isExpired) {
            documentExpirationDates[docType] = expDate;
            api.appLog(
                "📄 Loaded expiration date from previous application for $docType: $expDate");
          } else if (docType != null && isExpired) {
            api.appLog(
                "⚠️ Document $docType is expired, not loading expiration date");
          }
        }
      }
    }
  }

  /// Builds the products payload for API: list of { product_id, quantity, price }.
  /// Backend expects this when multiple items (saves to tbl_bnpl_application_items).
  List<Map<String, dynamic>> _buildProductsPayload() {
    final list = <Map<String, dynamic>>[];
    for (final item in widget.orderItems) {
      final pid = item['product_id'];
      final productId = pid is int
          ? pid
          : int.tryParse(pid?.toString() ?? '');
      if (productId == null) continue;
      final qty = item['quantity'];
      final quantity = qty is int ? qty : int.tryParse(qty?.toString() ?? '1') ?? 1;
      final up = item['unit_price'];
      final price = (up is num) ? up.toDouble() : (double.tryParse(up?.toString() ?? '0') ?? 0.0);
      list.add({
        'product_id': productId,
        'quantity': quantity,
        'price': price,
      });
    }
    return list;
  }

  Future<void> _saveDraft() async {
    if (widget.walletAccountId == null || widget.walletAccountId!.isEmpty) {
      return;
    }

    if (isSavingDraft) return; // Prevent multiple simultaneous saves

    setState(() => isSavingDraft = true);

    try {
      // Convert wallet_account to int if possible
      dynamic walletAccount = widget.walletAccountId;
      final walletAccountInt = int.tryParse(walletAccount.toString());
      if (walletAccountInt != null) {
        walletAccount = walletAccountInt;
      }

      final hasMultipleProducts = widget.orderItems.length > 1;

      // Prepare draft data - all fields optional except wallet_account
      final draftData = <String, dynamic>{
        'wallet_account': walletAccount ?? '',
        if (fullNameController.text.isNotEmpty)
          'full_name': fullNameController.text.trim(),
        if (phoneController.text.isNotEmpty)
          'phone_number': phoneController.text.trim(),
        if (emailController.text.isNotEmpty)
          'email': emailController.text.trim(),
        if (dateOfBirthController.text.isNotEmpty)
          'date_of_birth': dateOfBirthController.text.trim(),
        if (selectedGender != null) 'gender': selectedGender,
        if (selectedMaritalStatus != null)
          'marital_status': selectedMaritalStatus,
        if (residentialAddressController.text.isNotEmpty)
          'residential_address': residentialAddressController.text.trim(),
        if (selectedRegionId != null) 'region_id': selectedRegionId,
        if (selectedDistrictId != null) 'district_id': selectedDistrictId,
        if (selectedEmploymentStatus != null)
          'employment_status': selectedEmploymentStatus,
        if (employerNameController.text.isNotEmpty)
          'employer_name': employerNameController.text.trim(),
        if (monthlyIncomeController.text.isNotEmpty)
          'monthly_income':
              double.tryParse(monthlyIncomeController.text) ?? 0.0,
        if (selectedBankId != null) 'bank_id': selectedBankId,
        if (bankAccountController.text.isNotEmpty)
          'bank_account_number': bankAccountController.text.trim(),
        // Multi-product: send products array (backend saves each to tbl_bnpl_application_items)
        if (hasMultipleProducts && widget.orderItems.isNotEmpty)
          'products': _buildProductsPayload(),
        // Single product: send product_id and product_price
        if (!hasMultipleProducts && widget.orderItems.isNotEmpty)
          'product_id': widget.orderItems.first['product_id'],
        if (!hasMultipleProducts && widget.totalOrderAmount > 0)
          'product_price': widget.totalOrderAmount,
        if (guarantorNameController.text.isNotEmpty)
          'guarantor_name': guarantorNameController.text.trim(),
        if (guarantorPhoneController.text.isNotEmpty)
          'guarantor_phone': guarantorPhoneController.text.trim(),
        if (guarantorAddressController.text.isNotEmpty)
          'guarantor_address': guarantorAddressController.text.trim(),
        if (guarantorIncomeController.text.isNotEmpty)
          'guarantor_income':
              double.tryParse(guarantorIncomeController.text) ?? 0.0,
        'current_step': _currentStep + 1,
        // Include document expiration dates and numbers in draft
        if (documentExpirationDates.isNotEmpty || documentNumbers.isNotEmpty)
          'documents': [
            ...documentExpirationDates.entries
                .where((e) => e.value != null && e.value!.isNotEmpty)
                .map((e) => {
                      'document_type': e.key,
                      'expiration_date': e.value,
                      'document_number': documentNumbers[e.key],
                    }),
            ...documentNumbers.entries
                .where((e) =>
                    e.value != null &&
                    e.value!.isNotEmpty &&
                    !documentExpirationDates.containsKey(e.key))
                .map((e) => {
                      'document_type': e.key,
                      'document_number': e.value,
                    }),
          ],
      };

      // Map eligibility checklist to draft fields using dynamic keys
      bool ageVerified = false;
      bool hasValidId = false;
      bool hasIncomeProof = false;
      bool hasBankStatement = false;
      bool guarantorProvided = false;

      for (var item in eligibilityChecklistItems) {
        final key = item['checklist_key']?.toString();
        if (key == null) continue;
        final isChecked = eligibilityChecklist[key] == true;

        if (key.toLowerCase().contains('age') ||
            key.toLowerCase().contains('18')) {
          ageVerified = isChecked;
        } else if (key.toLowerCase().contains('id') ||
            key.toLowerCase().contains('valid')) {
          hasValidId = isChecked;
        } else if (key.toLowerCase().contains('income') ||
            key.toLowerCase().contains('proof')) {
          hasIncomeProof = isChecked;
        } else if (key.toLowerCase().contains('bank') ||
            key.toLowerCase().contains('statement')) {
          hasBankStatement = isChecked;
        } else if (key.toLowerCase().contains('guarantor') ||
            key.toLowerCase().contains('willing')) {
          guarantorProvided = isChecked;
        }
      }

      // Also try direct key lookup as fallback
      if (!ageVerified) {
        final ageKeys = ['age_18_plus', 'age_18', 'age_verified', 'age'];
        for (var ageKey in ageKeys) {
          if (eligibilityChecklist[ageKey] == true) {
            ageVerified = true;
            break;
          }
        }
      }
      if (!hasValidId) {
        final idKeys = ['has_valid_id', 'has_id', 'valid_id'];
        for (var idKey in idKeys) {
          if (eligibilityChecklist[idKey] == true) {
            hasValidId = true;
            break;
          }
        }
      }
      if (!hasIncomeProof) {
        final incomeKeys = ['has_income_proof', 'income_proof'];
        for (var incomeKey in incomeKeys) {
          if (eligibilityChecklist[incomeKey] == true) {
            hasIncomeProof = true;
            break;
          }
        }
      }
      if (!hasBankStatement) {
        final bankKeys = ['has_bank_statement', 'bank_statement'];
        for (var bankKey in bankKeys) {
          if (eligibilityChecklist[bankKey] == true) {
            hasBankStatement = true;
            break;
          }
        }
      }
      if (!guarantorProvided) {
        final guarantorKeys = [
          'willing_to_provide_guarantor',
          'guarantor',
          'provide_guarantor'
        ];
        for (var guarantorKey in guarantorKeys) {
          if (eligibilityChecklist[guarantorKey] == true) {
            guarantorProvided = true;
            break;
          }
        }
      }

      // Add eligibility checklist fields to draft data
      draftData['age_verified'] = ageVerified ? 1 : 0;
      draftData['documentation_complete'] =
          (hasValidId && hasIncomeProof && hasBankStatement) ? 1 : 0;
      draftData['guarantor_provided'] = guarantorProvided ? 1 : 0;
      draftData['eligibility_checklist_complete'] =
          eligibilityChecklist.values.every((v) => v == true) ? 1 : 0;
      // Save per-item checklist to tbl_bnpl_application_checklist_items
      draftData['eligibility_checklist_items'] =
          Map<String, dynamic>.fromEntries(eligibilityChecklist.entries
              .map((e) => MapEntry(e.key, e.value == true ? 1 : 0)));

      final result = await api.saveApplicationDraft(draftData);
      if (mounted) {
        setState(() {
          final appId = result['application_id'];
          draftApplicationId = appId is int
              ? appId
              : int.tryParse(appId?.toString() ?? '');
        });
        api.appLog(
            "✅ Draft saved successfully: ${result['application_number']}");
      }
    } catch (e) {
      api.appLog("⚠️ Failed to save draft: $e");
      // Don't show error to user - draft save is silent
    } finally {
      if (mounted) {
        setState(() => isSavingDraft = false);
      }
    }
  }

  void _startAutoSave() {
    // Cancel existing timer
    _autoSaveTimer?.cancel();

    // Start new timer - auto-save after 3 seconds of inactivity
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      _saveDraft();
    });
  }

  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
  }

  Future<void> _loadApplicationConfiguration() async {
    try {
      final config = await api.getBnplApplicationConfiguration();
      if (mounted) {
        setState(() {
          appConfig = config;
          eligibilityChecklistItems = (config['eligibility_checklist'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          genderOptions = (config['gender_options'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          maritalStatusOptions = (config['marital_status_options'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          employmentStatusOptions =
              (config['employment_status_options'] as List?)
                      ?.map((e) => Map<String, dynamic>.from(e))
                      .toList() ??
                  [];
          documentTypes = (config['document_types'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          ageRequirements = config['age_requirements'] != null &&
                  (config['age_requirements'] as List).isNotEmpty
              ? Map<String, dynamic>.from(
                  (config['age_requirements'] as List).first)
              : null;

          // Initialize eligibility checklist dynamically
          eligibilityChecklist = {};
          for (var item in eligibilityChecklistItems) {
            final key = item['checklist_key']?.toString();
            if (key != null) {
              eligibilityChecklist[key] = false;
            }
          }

          // Initialize documents map dynamically
          documents = {};
          for (var docType in documentTypes) {
            final key = docType['document_type_key']?.toString();
            if (key != null) {
              documents[key] = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load application configuration: $e');
        // Set defaults if config fails to load
        _setDefaultConfiguration();
      }
    }
  }

  void _setDefaultConfiguration() {
    // Fallback to hardcoded values if API fails
    eligibilityChecklist = {
      'age_18_plus': false,
      'has_valid_id': false,
      'has_income_proof': false,
      'has_bank_statement': false,
      'willing_to_provide_guarantor': false,
    };
    documents = {
      'nira': null,
      'passport': null,
      'bank_statement': null,
      'employment_id': null,
      'loan_request_letter': null,
    };
  }

  // Helper function to map icon_name string to IconData
  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.info;
    switch (iconName.toLowerCase()) {
      case 'person':
        return Icons.person;
      case 'badge':
        return Icons.badge;
      case 'receipt':
        return Icons.receipt;
      case 'account_balance':
        return Icons.account_balance;
      case 'people':
        return Icons.people;
      case 'work':
        return Icons.work;
      case 'description':
        return Icons.description;
      case 'receipt_long':
        return Icons.receipt_long;
      default:
        return Icons.info;
    }
  }

  Future<void> _loadBanks() async {
    try {
      final data = await api.getBnplBanks();
      if (mounted) {
        setState(() {
          banks = data;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load banks: $e');
        setState(() {
          banks = [];
        });
      }
    }
  }

  Future<Map<String, dynamic>> _checkExistingDocuments() async {
    if (widget.walletAccountId == null || widget.walletAccountId!.isEmpty) {
      return {'documents': []};
    }

    try {
      final result = await api.checkDocumentsSkip(widget.walletAccountId!);
      return result;
    } catch (e) {
      api.appLog("⚠️ Could not check existing documents: $e");
      return {'documents': []};
    }
  }

  Future<void> _checkExistingCustomer() async {
    if (widget.walletAccountId == null || widget.walletAccountId!.isEmpty) {
      return;
    }

    try {
      // Convert wallet_account to int if possible
      dynamic walletAccount = widget.walletAccountId;
      final walletAccountInt = int.tryParse(walletAccount.toString());
      if (walletAccountInt != null) {
        walletAccount = walletAccountInt;
      }

      final customerData = await api.getOrCreateCustomer({
        'wallet_account': walletAccount,
      });

      if (mounted) {
        setState(() {
          existingCustomerData = customerData;
          customerExists = customerData['exists'] == true;
        });

        // If customer exists, pre-fill their information
        // Wait for configuration to be loaded first
        if (customerExists) {
          if (genderOptions.isEmpty || maritalStatusOptions.isEmpty) {
            // Wait a bit for configuration to load
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                _prefillCustomerData(customerData);
              }
            });
          } else {
            _prefillCustomerData(customerData);
          }
        }
      }
    } catch (e) {
      // If customer doesn't exist or error occurs, that's okay - user will fill the form
      if (mounted) {
        setState(() {
          customerExists = false;
          existingCustomerData = null;
        });
      }
    }
  }

  void _prefillCustomerData(Map<String, dynamic> customerData) {
    // Pre-fill personal information if available
    if (customerData['full_name'] != null) {
      fullNameController.text = customerData['full_name'].toString();
    }
    if (customerData['phone_number'] != null) {
      phoneController.text = customerData['phone_number'].toString();
    }
    if (customerData['email'] != null) {
      emailController.text = customerData['email'].toString();
    }
    if (customerData['date_of_birth'] != null) {
      final dobValue = customerData['date_of_birth'].toString();
      // Handle different date formats
      if (dobValue.isNotEmpty) {
        dateOfBirthController.text = dobValue;
      }
    }
    if (customerData['gender'] != null && genderOptions.isNotEmpty) {
      final genderValue = customerData['gender'].toString();
      // Find matching gender in options (case-insensitive)
      try {
        final matchingGender = genderOptions.firstWhere(
          (g) =>
              g['gender_key']?.toString().toLowerCase() ==
              genderValue.toLowerCase(),
        );
        if (matchingGender['gender_key'] != null) {
          setState(() {
            selectedGender = matchingGender['gender_key'].toString();
          });
        }
      } catch (e) {
        // Gender not found in options, skip pre-fill
        api.appLog("⚠️ Gender '$genderValue' not found in options");
      }
    }
    if (customerData['marital_status'] != null &&
        maritalStatusOptions.isNotEmpty) {
      final maritalValue = customerData['marital_status'].toString();
      // Find matching marital status in options (case-insensitive)
      try {
        final matchingMarital = maritalStatusOptions.firstWhere(
          (m) =>
              m['marital_status_key']?.toString().toLowerCase() ==
              maritalValue.toLowerCase(),
        );
        if (matchingMarital['marital_status_key'] != null) {
          setState(() {
            selectedMaritalStatus =
                matchingMarital['marital_status_key'].toString();
          });
        }
      } catch (e) {
        // Marital status not found in options, skip pre-fill
        api.appLog("⚠️ Marital status '$maritalValue' not found in options");
      }
    }
    if (customerData['residential_address'] != null) {
      residentialAddressController.text =
          customerData['residential_address'].toString();
    }

    // Pre-fill location if available
    if (customerData['region_id'] != null) {
      final regionId = int.tryParse(customerData['region_id'].toString());
      if (regionId != null) {
        selectedRegionId = regionId;
        _loadDistricts(regionId);
      }
    }
    if (customerData['district_id'] != null) {
      final districtId = int.tryParse(customerData['district_id'].toString());
      if (districtId != null) {
        selectedDistrictId = districtId;
      }
    }

    // Pre-fill employment & financial if available
    if (customerData['employment_status'] != null) {
      selectedEmploymentStatus = customerData['employment_status'].toString();
    }
    if (customerData['employer_name'] != null) {
      employerNameController.text = customerData['employer_name'].toString();
    }
    if (customerData['monthly_income'] != null) {
      monthlyIncomeController.text = customerData['monthly_income'].toString();
      final income = double.tryParse(customerData['monthly_income'].toString());
      if (income != null) {
        incomeCategory = BnplUtils.getIncomeCategory(income);
        _loadProductRules();
      }
    }
    // Handle bank selection - try to match by bank_id first, then by name
    if (customerData['bank_id'] != null) {
      final bankId = int.tryParse(customerData['bank_id'].toString());
      if (bankId != null && bankId != 0) {
        selectedBankId = bankId;
        // Find bank name from banks list if available
        if (banks.isNotEmpty) {
          try {
            final bank = banks.firstWhere(
              (b) {
                final bId = b['bank_id'] ?? b['id'];
                return bId != null && int.tryParse(bId.toString()) == bankId;
              },
            );
            if (bank['bank_name'] != null || bank['name'] != null) {
              selectedBankName = (bank['bank_name'] ?? bank['name']).toString();
            }
          } catch (e) {
            // Bank not found in list, but we have the ID
            selectedBankName = customerData['bank_name']?.toString();
          }
        } else {
          // Banks not loaded yet, use bank_name from customer data if available
          selectedBankName = customerData['bank_name']?.toString();
        }
      }
    } else if (customerData['bank_name'] != null && banks.isNotEmpty) {
      // Fallback to bank_name if bank_id is not available
      final bankName = customerData['bank_name'].toString();
      selectedBankName = bankName;
      // Try to find matching bank in the list
      try {
        final bank = banks.firstWhere(
          (b) {
            final bName =
                (b['bank_name'] ?? b['name']).toString().toLowerCase();
            return bName == bankName.toLowerCase();
          },
        );
        final bankId = bank['bank_id'] ?? bank['id'];
        if (bankId != null) {
          selectedBankId = int.tryParse(bankId.toString());
        }
      } catch (e) {
        // Bank not found in list, but we have the name
      }
    } else if (customerData['bank_name'] != null) {
      // Banks not loaded yet, just store the name
      selectedBankName = customerData['bank_name'].toString();
    }
    if (customerData['bank_account_number'] != null) {
      bankAccountController.text =
          customerData['bank_account_number'].toString();
    }
  }

  Future<void> _loadRegions() async {
    try {
      final data = await api.getBnplRegions();
      if (mounted) {
        setState(() {
          regions = data;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load regions: $e');
        setState(() {
          regions = [];
        });
      }
    }
  }

  Future<void> _loadDistricts(int regionId) async {
    setState(() {
      isLoadingDistricts = true;
      districts = [];
      selectedDistrictId = null;
    });
    try {
      final data = await api.getBnplDistricts(regionId: regionId);
      if (mounted) {
        setState(() {
          districts = data;
          isLoadingDistricts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load districts: $e');
        setState(() {
          districts = [];
          isLoadingDistricts = false;
        });
      }
    }
  }

  Future<void> _loadCreditLimit() async {
    try {
      final data = await api.getCreditLimit(widget.walletAccountId ?? '');
      setState(() => creditLimit = CreditLimit.fromJson(data));
    } catch (e) {
      // Credit limit might not exist yet, that's okay
    }
  }

  Future<void> _calculateLocationRisk() async {
    if (selectedDistrictId == null || selectedRegionId == null) return;

    setState(() => isLoadingLocationRisk = true);
    try {
      final data = await api.calculateLocationRisk(
          selectedDistrictId!, selectedRegionId!);
      final risk = LocationRisk.fromJson(data);
      setState(() {
        locationRisk = risk;
      });

      // Reload document types filtered by risk level
      if (risk.riskLevel != null) {
        await _loadDocumentTypesByRiskLevel(risk.riskLevel!.toLowerCase());
      }
    } catch (e) {
      _showError('Failed to calculate location risk: $e');
    } finally {
      setState(() => isLoadingLocationRisk = false);
    }
  }

  Future<void> _loadDocumentTypesByRiskLevel(String riskLevel) async {
    try {
      final config =
          await api.getBnplApplicationConfiguration(riskLevel: riskLevel);
      if (mounted && config['document_types'] != null) {
        setState(() {
          documentTypes = (config['document_types'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          // Update documents map to include new document types
          for (var docType in documentTypes) {
            final key = docType['document_type_key']?.toString();
            if (key != null && !documents.containsKey(key)) {
              documents[key] = null;
            }
          }
        });
      }
    } catch (e) {
      // If reload fails, keep existing document types
      api.appLog("⚠️ Failed to reload document types by risk level: $e");
    }
  }

  Future<void> _loadProductRules() async {
    if (incomeCategory == null || incomeCategory!.isEmpty) return;

    setState(() => isLoadingProductRules = true);
    try {
      final data =
          await api.getProductRules(incomeCategory!, widget.totalOrderAmount);
      if (data.isEmpty) {
        setState(() => productRules = null);
        if (mounted) {
          _showError(
              'No product rule found for this income category. Please check your monthly income or try again.');
        }
      } else {
        setState(() => productRules = ProductRules.fromJson(data));
      }
    } catch (e) {
      api.appLog("⚠️ Product rules error: $e");
      if (mounted) {
        _showError(
            'Failed to load product rules. Please check your monthly income and try again.');
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingProductRules = false);
      }
    }
  }

  void _onRegionChanged(dynamic value) {
    int? regionId;
    if (value is int) {
      regionId = value;
    } else if (value != null) {
      regionId = int.tryParse(value.toString());
    }
    setState(() {
      selectedRegionId = regionId;
      selectedDistrictId = null;
      districts = [];
      locationRisk = null;
    });
    if (regionId != null) {
      _loadDistricts(regionId);
      _startAutoSave();
    }
  }

  void _onDistrictChanged(dynamic value) {
    int? districtId;
    if (value is int) {
      districtId = value;
    } else if (value != null) {
      districtId = int.tryParse(value.toString());
    }
    setState(() => selectedDistrictId = districtId);
    if (districtId != null && selectedRegionId != null) {
      _calculateLocationRisk();
      _startAutoSave();
    }
  }

  void _onIncomeChanged(String value) {
    final income = double.tryParse(value);
    if (income != null) {
      final category = BnplUtils.getIncomeCategory(income);
      setState(() {
        incomeCategory = category;
        monthlyIncomeController.text = value;
      });
      _loadProductRules();
    }
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      // Show dialog to choose between image or PDF
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Select Document Type',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF005653)),
                title: const Text('Image (JPG/PNG)'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.picture_as_pdf, color: Color(0xFF005653)),
                title: const Text('PDF Document'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
            ],
          ),
        ),
      );

      if (choice == null) return; // User cancelled

      if (choice == 'pdf') {
        // Pick PDF file
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          final filePath = result.files.single.path!;

          // Check if document requires expiration date
          final docType = documentTypes.firstWhere(
            (d) => d['document_type_key']?.toString() == documentType,
            orElse: () => {},
          );
          final requiresExpiration = docType['requires_expiration_date'] == 1 ||
              docType['requires_expiration'] == 1;

          // If expiration is required, check if it's already set in the controller
          String? expirationDate;
          if (requiresExpiration) {
            if (expirationDateController.text.isNotEmpty) {
              expirationDate = expirationDateController.text;
            } else {
              // Ask for expiration date if not already set
              expirationDate = await _showExpirationDateDialog(documentType);
              if (expirationDate == null) {
                _showError(
                    'Expiration date is required for this document type');
                return;
              }
              expirationDateController.text = expirationDate;
            }
          }

          setState(() {
            documents[documentType] = File(filePath);
            // Only save expiration date if document type requires it
            if (requiresExpiration && expirationDate != null) {
              documentExpirationDates[documentType] = expirationDate;
              if (selectedDocumentType == documentType) {
                expirationDateController.text = expirationDate;
              }
            } else if (!requiresExpiration) {
              // Document doesn't require expiration - remove from map if exists
              documentExpirationDates.remove(documentType);
              if (selectedDocumentType == documentType) {
                expirationDateController.clear();
              }
            }
          });
          _showSuccess('PDF document selected: ${result.files.single.name}');
          _startAutoSave();
        }
        return;
      }

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        // Check if document requires expiration date
        final docType = documentTypes.firstWhere(
          (d) => d['document_type_key']?.toString() == documentType,
          orElse: () => {},
        );
        final requiresExpiration = docType['requires_expiration_date'] == 1 ||
            docType['requires_expiration'] == 1;

        // If expiration is required, check if it's already set in the controller
        String? expirationDate;
        if (requiresExpiration) {
          if (expirationDateController.text.isNotEmpty) {
            expirationDate = expirationDateController.text;
          } else {
            // Ask for expiration date if not already set
            expirationDate = await _showExpirationDateDialog(documentType);
            if (expirationDate == null) {
              _showError('Expiration date is required for this document type');
              return;
            }
            expirationDateController.text = expirationDate;
          }
        }

        setState(() {
          documents[documentType] = File(image.path);
          // Only save expiration date if document type requires it
          if (requiresExpiration && expirationDate != null) {
            documentExpirationDates[documentType] = expirationDate;
            if (selectedDocumentType == documentType) {
              expirationDateController.text = expirationDate;
            }
          } else if (!requiresExpiration) {
            // Document doesn't require expiration - remove from map if exists
            documentExpirationDates.remove(documentType);
            if (selectedDocumentType == documentType) {
              expirationDateController.clear();
            }
          }
        });
        _showSuccess('Image selected: ${image.name}');
        _startAutoSave();
      }
    } catch (e) {
      _showError('Failed to pick document: $e');
    }
  }

  Future<String?> _showExpirationDateDialog(String documentType) async {
    final docType = documentTypes.firstWhere(
      (d) => d['document_type_key']?.toString() == documentType,
      orElse: () => {},
    );
    final docLabel = docType['document_type_label']?.toString() ?? documentType;

    DateTime? selectedDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Document Expiration Date',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$docLabel requires an expiration date.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                  helpText: 'Select Expiration Date',
                );
                if (date != null) {
                  selectedDate = date;
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Select Expiration Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == true && selectedDate != null) {
      return DateFormat('yyyy-MM-dd').format(selectedDate!);
    }
    return null;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Check each requirement individually using dynamic checklist
        for (var item in eligibilityChecklistItems) {
          final key = item['checklist_key']?.toString();
          final isRequired = item['is_required'] == 1;
          if (key != null && isRequired) {
            final isChecked = eligibilityChecklist[key] ?? false;
            if (!isChecked) {
              final title = item['checklist_title']?.toString() ??
                  item['checklist_description']?.toString() ??
                  'Please confirm this requirement';
              _showError('Please confirm: $title');
              return false;
            }
          }
        }
        return true;
      case 1:
        final fullName = fullNameController.text.trim();
        final phone = phoneController.text.trim();
        final email = emailController.text.trim();
        final dob = dateOfBirthController.text.trim();
        final address = residentialAddressController.text.trim();

        if (fullName.isEmpty) {
          _showError('Please enter your full name');
          return false;
        }
        if (phone.isEmpty) {
          _showError('Please enter your phone number');
          return false;
        }
        if (email.isEmpty) {
          _showError('Please enter your email address');
          return false;
        }
        if (dob.isEmpty) {
          _showError('Please select your date of birth');
          return false;
        }
        if (selectedGender == null) {
          _showError('Please select your gender');
          return false;
        }
        if (selectedMaritalStatus == null) {
          _showError('Please select your marital status');
          return false;
        }
        if (address.isEmpty) {
          _showError('Please enter your residential address');
          return false;
        }
        return true;
      case 2:
        if (selectedRegionId == null) {
          _showError('Please select a region');
          return false;
        }
        if (selectedDistrictId == null) {
          _showError('Please select a district');
          return false;
        }
        return true;
      case 3:
        if (selectedEmploymentStatus == null) {
          _showError('Please select employment status');
          return false;
        }
        if (monthlyIncomeController.text.trim().isEmpty) {
          _showError('Please enter your monthly income');
          return false;
        }
        if (incomeCategory == null) {
          _showError('Please enter a valid monthly income');
          return false;
        }
        if (employerNameController.text.trim().isEmpty) {
          _showError('Please enter employer/business name');
          return false;
        }
        if (selectedBankId == null) {
          _showError('Please select a bank');
          return false;
        }
        if (bankAccountController.text.trim().isEmpty) {
          _showError('Please enter bank account number');
          return false;
        }
        return true;
      case 4:
        if (productRules == null) {
          _showError(
              'Product rules not loaded. Please wait or go back and enter income again.');
          return false;
        }
        return true;
      case 5:
        if (locationRisk?.isHighRisk == true) {
          if (guarantorNameController.text.trim().isEmpty) {
            _showError('Please enter guarantor name');
            return false;
          }
          if (guarantorPhoneController.text.trim().isEmpty) {
            _showError('Please enter guarantor phone number');
            return false;
          }
          if (guarantorAddressController.text.trim().isEmpty) {
            _showError('Please enter guarantor address');
            return false;
          }
          if (guarantorIncomeController.text.trim().isEmpty) {
            _showError('Please enter guarantor monthly income');
            return false;
          }
        }
        return true;
      case 6:
        // Require at least 1 income proof (e.g. income statement) + 1 ID (NIRA, Passport, etc.)
        // Consider "have" if existingDocuments[key] == true OR documents[key] != null
        const incomeDocKeys = [
          'has_income_proof',
          'income_proof',
          'income_statement',
          'salary_slip',
          'employment_id',
          'bank_statement',
        ];
        const idDocKeys = [
          'has_valid_id',
          'nira',
          'passport',
          'driving_license',
          'national_id',
        ];
        bool hasIncomeDoc = false;
        bool hasIdDoc = false;
        for (var docType in documentTypes) {
          final key = docType['document_type_key']?.toString();
          if (key == null) continue;
          final hasDoc =
              existingDocuments[key] == true || documents[key] != null;
          if (incomeDocKeys.contains(key) && hasDoc) hasIncomeDoc = true;
          if (idDocKeys.contains(key) && hasDoc) hasIdDoc = true;
        }
        if (!hasIncomeDoc) {
          _showError(
              'Please provide proof of income (e.g. salary slip or business document).');
          return false;
        }
        if (!hasIdDoc) {
          _showError(
              'Please provide a valid ID (NIRA, Passport, or Driving License).');
          return false;
        }
        return true;
      case 7:
        return true;
      default:
        return false;
    }
  }

  Future<void> _submitApplication() async {
    if (!_validateCurrentStep()) {
      // Error message already shown in _validateCurrentStep
      return;
    }

    // Validate order items
    if (widget.orderItems.isEmpty) {
      _showError('No order items found. Please add products to your order.');
      return;
    }

    // Validate required fields
    if (selectedDistrictId == null) {
      _showError('Please select a district');
      return;
    }
    if (selectedRegionId == null) {
      _showError('Please select a region');
      return;
    }

    final hasMultipleProducts = widget.orderItems.length > 1;
    int? productId;
    if (!hasMultipleProducts && widget.orderItems.isNotEmpty) {
      final firstItem = widget.orderItems.first;
      final productIdValue = firstItem['product_id'];
      if (productIdValue != null) {
        productId = productIdValue is int
            ? productIdValue
            : int.tryParse(productIdValue.toString());
      }
    }

    if (!hasMultipleProducts && productId == null) {
      _showError('Product ID not found in order items');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Convert wallet_account to int if possible, otherwise use as string
      dynamic walletAccount = widget.walletAccountId;
      if (walletAccount != null) {
        final walletAccountInt = int.tryParse(walletAccount.toString());
        if (walletAccountInt != null) {
          walletAccount = walletAccountInt;
        }
      }

      // Prepare application data - ensure all fields are non-null and properly typed
      final applicationData = <String, dynamic>{
        'wallet_account': walletAccount ?? '',
        'full_name': fullNameController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'email': emailController.text.trim().isEmpty
            ? 'noemail@example.com'
            : emailController.text.trim(),
        'date_of_birth': dateOfBirthController.text.trim(),
        'gender': selectedGender ?? 'male',
        'marital_status': selectedMaritalStatus ?? 'single',
        'residential_address': residentialAddressController.text.trim(),
        'district_id': selectedDistrictId!,
        'region_id': selectedRegionId!,
        'employment_status': selectedEmploymentStatus ?? 'employed',
        'employer_name': employerNameController.text.trim(),
        'monthly_income': double.tryParse(monthlyIncomeController.text) ?? 0.0,
        if (selectedBankId != null) 'bank_id': selectedBankId,
        if (selectedBankName != null) 'bank_name': selectedBankName,
        'bank_account_number': bankAccountController.text.trim(),
        // Multi-product: send products array (backend saves each row in tbl_bnpl_application_items)
        if (hasMultipleProducts) 'products': _buildProductsPayload(),
        // Single product: send product_id and product_price
        if (!hasMultipleProducts && productId != null) 'product_id': productId,
        if (!hasMultipleProducts) 'product_price': widget.totalOrderAmount,
        'requested_deposit': productRules?.calculatedDeposit != null
            ? (productRules!.calculatedDeposit is num
                ? productRules!.calculatedDeposit
                : (double.tryParse(
                        productRules!.calculatedDeposit.toString()) ??
                    0.0))
            : 0.0,
        'location_risk_category': locationRisk?.riskCategory ?? '1',
        'location_risk_score': locationRisk?.riskScore != null
            ? (locationRisk!.riskScore is num
                ? locationRisk!.riskScore
                : (double.tryParse(locationRisk!.riskScore.toString()) ?? 0.0))
            : 0.0,
      };

      // Add guarantor if required
      if (locationRisk?.isHighRisk == true) {
        applicationData['guarantor_name'] = guarantorNameController.text.trim();
        applicationData['guarantor_phone'] =
            guarantorPhoneController.text.trim();
        applicationData['guarantor_address'] =
            guarantorAddressController.text.trim();
        applicationData['guarantor_income'] =
            double.tryParse(guarantorIncomeController.text) ?? 0.0;
      }

      // Log the data being sent for debugging
      api.appLog(
          "📤 Submitting BNPL application with data: ${jsonEncode(applicationData)}");

      // Create application
      final result = await api.createBnplApplication(applicationData);
      final applicationIdRaw = result['application_id'];
      // Convert application_id to int (handle both String and int)
      final int applicationId = applicationIdRaw is int
          ? applicationIdRaw
          : (applicationIdRaw is String
              ? int.tryParse(applicationIdRaw) ?? 0
              : 0);

      if (applicationId == 0) {
        throw Exception('Invalid application ID received from server');
      }

      // Check for existing documents before uploading
      Map<String, dynamic>? existingDocsData;
      try {
        existingDocsData =
            await api.checkDocumentsSkip(widget.walletAccountId ?? '');
        if (existingDocsData['documents'] != null) {
          final List existingDocs = existingDocsData['documents'] as List;
          for (var doc in existingDocs) {
            final docType = doc['document_type']?.toString();
            if (docType != null) {
              existingDocuments[docType] = true;
            }
          }
        }
      } catch (e) {
        api.appLog("⚠️ Could not check existing documents: $e");
      }

      // Upload documents
      for (var entry in documents.entries) {
        if (entry.value != null) {
          // Check if document already exists
          if (existingDocuments[entry.key] == true) {
            api.appLog(
                "ℹ️ Document type ${entry.key} already exists. Skipping upload.");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Document ${entry.key.replaceAll('_', ' ')} already exists. You can skip this step.'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            continue; // Skip uploading this document
          }

          try {
            final file = entry.value!;
            final bytes = await file.readAsBytes();
            final base64 = base64Encode(bytes);

            // Get file extension
            final fileName = file.path.split('/').last;
            final fileExtension = fileName.split('.').last.toLowerCase();

            // Create descriptive document name matching API documentation format
            // Format: "Document Type Name - timestamp.extension"
            final documentTypeNames = {
              'nira': 'NIRA Document',
              'passport': 'Passport Document',
              'driving_license': 'Driving License',
              'bank_statement': 'Bank Statement',
              'wallet_statement': 'Wallet Statement',
              'employment_id': 'Employment ID',
              'loan_request_letter': 'Loan Request Letter',
              'guarantor_id': 'Guarantor ID',
              'other': 'Other Document',
            };

            final typeDisplayName = documentTypeNames[entry.key] ??
                entry.key
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((word) => word.isEmpty
                        ? ''
                        : word[0].toUpperCase() + word.substring(1))
                    .join(' ');

            // Create unique filename with timestamp and document number if provided
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final docNumber = documentNumbers[entry.key];
            final documentName = docNumber != null && docNumber.isNotEmpty
                ? '$typeDisplayName - $docNumber - $timestamp.$fileExtension'
                : '$typeDisplayName - $timestamp.$fileExtension';

            // Log upload attempt with full details
            api.appLog("📤 Uploading document:");
            api.appLog("   - Document Type: ${entry.key}");
            api.appLog("   - Document Name: $documentName");
            api.appLog(
                "   - File Size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(2)} KB)");
            api.appLog("   - File Extension: $fileExtension");
            api.appLog("   - Base64 Length: ${base64.length} characters");
            api.appLog("   - Application ID: $applicationId");

            // Log request body preview (without full base64 for readability)
            api.appLog("📤 Request Body (without base64): ${jsonEncode({
                  'application_id': applicationId,
                  'document_type': entry.key,
                  'document_name': documentName,
                  'document_base64':
                      '${base64.substring(0, base64.length > 50 ? 50 : base64.length)}... (${base64.length} chars)'
                })}");

            // Check if this document type requires expiration date
            final docType = documentTypes.firstWhere(
              (d) => d['document_type_key']?.toString() == entry.key,
              orElse: () => {},
            );
            final requiresExpiration =
                docType['requires_expiration_date'] == 1 ||
                    docType['requires_expiration'] == 1;

            // Only get expiration date if this document type requires it
            String? expirationDate;
            if (requiresExpiration) {
              expirationDate = documentExpirationDates[entry.key];
              if (expirationDate == null || expirationDate.isEmpty) {
                api.appLog(
                    "⚠️ WARNING: Document type ${entry.key} requires expiration date but it's not set!");
              }
            } else {
              // Document doesn't require expiration date, explicitly set to null
              expirationDate = null;
              // Also remove from map if it exists (shouldn't happen, but clean up just in case)
              if (documentExpirationDates.containsKey(entry.key)) {
                documentExpirationDates.remove(entry.key);
              }
            }

            // Log expiration date before upload
            api.appLog("📤 Uploading document:");
            api.appLog("   - Document Type: ${entry.key}");
            api.appLog("   - Requires Expiration: $requiresExpiration");
            api.appLog(
                "   - Expiration Date: ${expirationDate ?? 'NULL (not required)'}");
            api.appLog(
                "   - Expiration Date in map: ${documentExpirationDates.containsKey(entry.key) ? 'EXISTS' : 'NOT FOUND'}");

            // Get document number if provided
            final documentNumber = documentNumbers[entry.key];

            final uploadResult = await api.uploadDocument(
              applicationId: applicationId,
              documentType: entry.key,
              documentName: documentName,
              documentBase64: base64,
              expirationDate:
                  expirationDate, // Will be null if document doesn't require it
              documentNumber: documentNumber, // Document number if provided
            );

            api.appLog("✅ Document uploaded successfully:");
            api.appLog(
                "   - Document ID: ${uploadResult['document_id'] ?? 'N/A'}");
            api.appLog(
                "   - Expiration Date Sent: ${expirationDate ?? 'NULL'}");
            api.appLog("   - Response: ${jsonEncode(uploadResult)}");

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$typeDisplayName uploaded successfully'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            api.appLog("❌ Failed to upload ${entry.key}: $e");
            api.appLog("   - Error details: ${e.toString()}");
            final errorTypeNames = {
              'nira': 'NIRA Document',
              'passport': 'Passport Document',
              'driving_license': 'Driving License',
              'bank_statement': 'Bank Statement',
              'wallet_statement': 'Wallet Statement',
              'employment_id': 'Employment ID',
              'loan_request_letter': 'Loan Request Letter',
              'guarantor_id': 'Guarantor ID',
              'other': 'Other Document',
            };

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to upload ${errorTypeNames[entry.key] ?? entry.key.replaceAll('_', ' ')}: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }

      // NOTE: Order is NOT created here
      // Order is created only when application reaches 'operations_approved' status
      // This happens in backend: BNPLController::update_application_status()
      api.appLog(
          "✅ Application submitted successfully. Order will be created upon approval.");

      // Delete draft if it exists (application is now submitted)
      if (draftApplicationId != null) {
        try {
          // Draft will be automatically replaced by submitted application
          api.appLog("✅ Draft will be replaced by submitted application");
        } catch (e) {
          api.appLog("⚠️ Could not delete draft: $e");
        }
      }

      setState(() {
        applicationResult = result;
        _currentStep = 7;
        draftApplicationId = null; // Clear draft ID
      });

      // Stop auto-save
      _stopAutoSave();

      // Show success and navigate
      _showSuccess(
          'Application submitted successfully! Order will be created upon approval.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BnplTrackingScreen(
                walletAccountId: widget.walletAccountId ?? '',
              ),
            ),
          );
        }
      });
    } catch (e) {
      _showError('Failed to submit application: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    dateOfBirthController.dispose();
    residentialAddressController.dispose();
    employerNameController.dispose();
    monthlyIncomeController.dispose();
    bankAccountController.dispose();
    guarantorNameController.dispose();
    guarantorPhoneController.dispose();
    guarantorAddressController.dispose();
    guarantorIncomeController.dispose();
    expirationDateController.dispose();
    documentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BNPL Application',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            if (draftApplicationId != null)
              Text(
                'Draft Saved',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildProgressIndicator(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Eligibility(),
                _buildStep2PersonalInfo(),
                _buildStep3Location(),
                _buildStep4Employment(),
                _buildStep5ProductRules(),
                _buildStep6Guarantor(),
                _buildStep7Documents(),
                _buildStep8Review(),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildProgressIndicator() {
    final stepNum = _currentStep + 1;
    final percent = ((stepNum / 8) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          if (draftApplicationId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Draft progress',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$percent%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: stepNum / 8,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: List.generate(8, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 7 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            draftApplicationId != null
                ? 'Draft - Step $stepNum of 8 ($percent% complete)'
                : 'Step $stepNum of 8',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Eligibility() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eligibility Checklist',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please confirm that you meet the following requirements:',
            style:
                GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          if (eligibilityChecklistItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading eligibility requirements...',
                      style:
                          GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...eligibilityChecklistItems.map((item) {
              final key = item['checklist_key']?.toString() ?? '';
              final title = item['checklist_title']?.toString() ?? '';
              final iconName = item['icon_name']?.toString();
              return _buildChecklistItem(
                title,
                key,
                _getIconFromName(iconName),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, String key, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: eligibilityChecklist[key],
        onChanged: (value) {
          setState(() => eligibilityChecklist[key] = value ?? false);
          // Trigger auto-save when checklist changes
          _startAutoSave();
        },
        title: Text(title, style: GoogleFonts.poppins(fontSize: 14)),
        secondary: Icon(icon, color: primaryColor),
        activeColor: primaryColor,
      ),
    );
  }

  Widget _buildStep2PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: fullNameController,
            label: 'Full Name *',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: phoneController,
            label: 'Phone Number *',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: emailController,
            label: 'Email Address *',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: dateOfBirthController,
            label: 'Date of Birth *',
            icon: Icons.calendar_today,
            readOnly: true,
            onTap: () async {
              try {
                // Safely parse minimum_age - handle both int and string
                int minAge = 18;
                if (ageRequirements?['minimum_age'] != null) {
                  final minAgeValue = ageRequirements!['minimum_age'];
                  if (minAgeValue is int) {
                    minAge = minAgeValue;
                  } else if (minAgeValue is String) {
                    minAge = int.tryParse(minAgeValue) ?? 18;
                  } else {
                    minAge = int.tryParse(minAgeValue.toString()) ?? 18;
                  }
                }

                // Safely parse maximum_age - handle both int and string
                int? maxAge;
                if (ageRequirements?['maximum_age'] != null) {
                  final maxAgeValue = ageRequirements!['maximum_age'];
                  if (maxAgeValue is int) {
                    maxAge = maxAgeValue;
                  } else if (maxAgeValue is String) {
                    maxAge = int.tryParse(maxAgeValue);
                  } else {
                    maxAge = int.tryParse(maxAgeValue.toString());
                  }
                }

                // Calculate dates
                final now = DateTime.now();
                final lastDate = maxAge != null
                    ? now.subtract(Duration(days: 365 * maxAge))
                    : now.subtract(Duration(days: 365 * minAge));
                final firstDate = DateTime(1950);

                // Set initial date - try to parse existing date, or use calculated default
                DateTime initialDate;
                if (dateOfBirthController.text.isNotEmpty) {
                  try {
                    final existingDate = DateFormat('yyyy-MM-dd')
                        .parse(dateOfBirthController.text);
                    initialDate = existingDate;
                  } catch (e) {
                    // If parsing fails, use calculated default
                    initialDate = maxAge != null
                        ? now.subtract(
                            Duration(days: 365 * ((minAge + maxAge) ~/ 2)))
                        : now.subtract(Duration(days: 365 * (minAge + 5)));
                  }
                } else {
                  initialDate = maxAge != null
                      ? now.subtract(
                          Duration(days: 365 * ((minAge + maxAge) ~/ 2)))
                      : now.subtract(Duration(days: 365 * (minAge + 5)));
                }

                // Ensure initial date is within valid range
                if (initialDate.isAfter(lastDate)) {
                  initialDate = lastDate;
                }
                if (initialDate.isBefore(firstDate)) {
                  initialDate = firstDate;
                }

                final date = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  helpText: 'Select Date of Birth',
                  cancelText: 'Cancel',
                  confirmText: 'Select',
                );

                if (date != null && mounted) {
                  setState(() {
                    dateOfBirthController.text =
                        DateFormat('yyyy-MM-dd').format(date);
                  });
                }
              } catch (e) {
                if (mounted) {
                  _showError('Failed to select date: $e');
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Gender *',
            value: selectedGender,
            items: genderOptions
                .map((g) => g['gender_key']?.toString())
                .whereType<String>()
                .toList(),
            displayItems: genderOptions
                .map((g) => g['gender_label']?.toString() ?? '')
                .toList(),
            onChanged: (value) {
              setState(() => selectedGender = value);
              _startAutoSave();
            },
            icon: Icons.wc,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Marital Status *',
            value: selectedMaritalStatus,
            items: maritalStatusOptions
                .map((m) => m['marital_status_key']?.toString())
                .whereType<String>()
                .toList(),
            displayItems: maritalStatusOptions
                .map((m) => m['marital_status_label']?.toString() ?? '')
                .toList(),
            onChanged: (value) {
              setState(() => selectedMaritalStatus = value);
              _startAutoSave();
            },
            icon: Icons.family_restroom,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: residentialAddressController,
            label: 'Residential Address *',
            icon: Icons.home,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Information',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          if (isLoading && regions.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (regions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No regions available. Please check your connection.',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else
            Builder(
              builder: (context) {
                // Create valid region pairs (id, name) filtering out invalid IDs
                final validRegions = <MapEntry<int, String>>[];
                for (var r in regions) {
                  final id = r['region_id'];
                  int? parsedId;
                  if (id is int) {
                    parsedId = id;
                  } else {
                    parsedId = int.tryParse(id.toString());
                  }
                  if (parsedId != null) {
                    validRegions.add(
                        MapEntry(parsedId, r['region_name']?.toString() ?? ''));
                  }
                }

                return _buildDropdown(
                  label: 'Region *',
                  value: selectedRegionId,
                  items: validRegions.map((e) => e.key).toList(),
                  displayItems: validRegions.map((e) => e.value).toList(),
                  onChanged: _onRegionChanged,
                  icon: Icons.location_city,
                );
              },
            ),
          const SizedBox(height: 16),
          if (selectedRegionId != null)
            isLoadingDistricts
                ? const Center(child: CircularProgressIndicator())
                : districts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No districts available for this region.',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // Create valid district pairs (id, name) filtering out invalid IDs
                          final validDistricts = <MapEntry<int, String>>[];
                          for (var d in districts) {
                            // API returns 'district_id' not 'adress_id'
                            final id = d['district_id'] ?? d['adress_id'];
                            int? parsedId;
                            if (id is int) {
                              parsedId = id;
                            } else {
                              parsedId = int.tryParse(id.toString());
                            }
                            if (parsedId != null) {
                              validDistricts.add(MapEntry(parsedId,
                                  d['district_name']?.toString() ?? ''));
                            }
                          }

                          return _buildDropdown(
                            label: 'District *',
                            value: selectedDistrictId,
                            items: validDistricts.map((e) => e.key).toList(),
                            displayItems:
                                validDistricts.map((e) => e.value).toList(),
                            onChanged: _onDistrictChanged,
                            icon: Icons.place,
                          );
                        },
                      ),
          if (isLoadingLocationRisk)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (locationRisk != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: locationRisk!.isHighRisk
                    ? Colors.red.shade50
                    : locationRisk!.isMediumRisk
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon(
                      //   locationRisk!.isHighRisk
                      //       ? Icons.warning
                      //       : locationRisk!.isMediumRisk
                      //           ? Icons.info
                      //           : Icons.check_circle,
                      //   color: locationRisk!.isHighRisk
                      //       ? Colors.red
                      //       : locationRisk!.isMediumRisk
                      //           ? Colors.orange
                      //           : Colors.green,
                      // ),
                      const SizedBox(width: 8),
                      // Text(
                      //   'Location Risk: ${locationRisk!.riskLevel}',
                      //   style: GoogleFonts.poppins(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Text(
                  //   BnplUtils.getRiskCategoryDescription(
                  //       locationRisk!.riskCategory ?? ''),
                  //   style: GoogleFonts.poppins(fontSize: 14),
                  // ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4Employment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employment & Financial Information',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Employment Status *',
            value: selectedEmploymentStatus,
            items: employmentStatusOptions
                .map((e) => e['employment_status_key']?.toString())
                .whereType<String>()
                .toList(),
            displayItems: employmentStatusOptions
                .map((e) => e['employment_status_label']?.toString() ?? '')
                .toList(),
            onChanged: (value) {
              setState(() => selectedEmploymentStatus = value);
              _startAutoSave();
            },
            icon: Icons.work,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: employerNameController,
            label: 'Employer Name / Business Name *',
            icon: Icons.business,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: monthlyIncomeController,
            label: 'Monthly Income (USD) *',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            onChanged: _onIncomeChanged,
          ),
          if (incomeCategory != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Income Category: $incomeCategory',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildBankDropdown(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: bankAccountController,
            label: 'Bank Account Number *',
            icon: Icons.account_circle,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildStep5ProductRules() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product & Payment Terms',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          if (isLoadingProductRules)
            const Center(child: CircularProgressIndicator())
          else if (productRules != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Product Price',
                      BnplUtils.formatCurrency(widget.totalOrderAmount)),
                  const Divider(),
                  _buildInfoRow('Deposit Percentage',
                      '${productRules!.depositPercentage}%'),
                  _buildInfoRow(
                      'Deposit Amount',
                      BnplUtils.formatCurrency(
                          productRules!.calculatedDeposit)),
                  _buildInfoRow('Loan Amount',
                      BnplUtils.formatCurrency(productRules!.loanAmount)),
                  const Divider(),
                  _buildInfoRow('Repayment Duration',
                      '${productRules!.repaymentDurationMonths} months'),
                  _buildInfoRow(
                      'Monthly Installment',
                      BnplUtils.formatCurrency(
                          productRules!.monthlyInstallment)),
                ],
              ),
            ),
            if (creditLimit != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: creditLimit!.isFrozen == true
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          creditLimit!.isFrozen == true
                              ? Icons.lock
                              : Icons.credit_card,
                          color: creditLimit!.isFrozen == true
                              ? Colors.red
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Credit Limit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Available Credit',
                        BnplUtils.formatCurrency(creditLimit!.availableCredit)),
                    _buildInfoRow('Used Credit',
                        BnplUtils.formatCurrency(creditLimit!.usedCredit)),
                    if (creditLimit!.isFrozen == true)
                      Text(
                        'Your credit is frozen: ${creditLimit!.freezeReason ?? "Contact support"}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ] else
            Center(
              child: Text(
                'Please complete previous steps to see payment terms',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep6Guarantor() {
    if (locationRisk?.isHighRisk != true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Guarantor Not Required',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your location risk assessment, a guarantor is not required.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guarantor Required: Due to your location risk level, a guarantor is mandatory.',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Guarantor Information',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: guarantorNameController,
            label: 'Guarantor Full Name *',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: guarantorPhoneController,
            label: 'Guarantor Phone Number *',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: guarantorAddressController,
            label: 'Guarantor Address *',
            icon: Icons.home,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: guarantorIncomeController,
            label: 'Guarantor Monthly Income (USD) *',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildStep7Documents() {
    // Filter document types based on risk level
    final availableDocumentTypes = documentTypes.where((docType) {
      final requiredForRisk = docType['required_for_risk_level']?.toString();
      if (locationRisk != null) {
        final riskLevel = locationRisk!.riskLevel?.toLowerCase();
        return requiredForRisk == 'all' || requiredForRisk == riskLevel;
      }
      return requiredForRisk == 'all';
    }).toList();

    // Get selected document type details
    Map<String, dynamic>? selectedDocTypeDetails;
    if (selectedDocumentType != null) {
      try {
        selectedDocTypeDetails = availableDocumentTypes.firstWhere(
          (d) => d['document_type_key']?.toString() == selectedDocumentType,
        );
      } catch (e) {
        selectedDocTypeDetails = null;
      }
    }

    // Check if selected document type requires expiration date
    final requiresExpiration = selectedDocTypeDetails != null &&
        (selectedDocTypeDetails['requires_expiration_date'] == 1 ||
            selectedDocTypeDetails['requires_expiration'] == 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Documents',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a document type and upload the required file:',
            style:
                GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),

          // Check for existing documents
          FutureBuilder<Map<String, dynamic>>(
            future: _checkExistingDocuments(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final docsData = snapshot.data!;
                final existingDocs = docsData['documents'] as List? ?? [];
                if (existingDocs.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You already have the following documents uploaded. You can skip uploading them again:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...existingDocs.map((doc) {
                          final docType =
                              doc['document_type']?.toString() ?? '';
                          final docTypeLabel = documentTypes
                                  .firstWhere(
                                    (d) =>
                                        d['document_type_key']?.toString() ==
                                        docType,
                                    orElse: () =>
                                        {'document_type_label': docType},
                                  )['document_type_label']
                                  ?.toString() ??
                              docType;
                          existingDocuments[docType] = true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    docTypeLabel,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
          if (documentTypes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading document requirements...',
                      style:
                          GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Document Type Dropdown
            _buildDocumentTypeDropdown(availableDocumentTypes),
            const SizedBox(height: 24),

            // Upload Section (only shown when document type is selected)
            if (selectedDocumentType != null) ...[
              if (existingDocuments[selectedDocumentType!] == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You already have this document. You can skip uploading or upload a new file to replace it.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIconFromName(
                              selectedDocTypeDetails?['icon_name']?.toString()),
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedDocTypeDetails?['document_type_label']
                                    ?.toString() ??
                                selectedDocumentType ??
                                'Document',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedDocTypeDetails?['document_type_description'] !=
                        null) ...[
                      const SizedBox(height: 8),
                      Text(
                        selectedDocTypeDetails!['document_type_description']
                            .toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Expiration Date Field (always show when document type is selected)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: requiresExpiration
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: requiresExpiration
                              ? Colors.orange.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: requiresExpiration
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                requiresExpiration
                                    ? 'Expiration Date *'
                                    : 'Expiration Date (Optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: requiresExpiration
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectExpirationDate(),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      expirationDateController.text.isNotEmpty
                                          ? expirationDateController.text
                                          : 'Tap to select expiration date',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: expirationDateController
                                                .text.isNotEmpty
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down,
                                      color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          if (requiresExpiration &&
                              expirationDateController.text.isEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.warning,
                                    size: 16, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'This document type requires an expiration date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Document Number Field
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.badge,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Document Number (Optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: documentNumberController,
                            label: 'Enter document number if available',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.text,
                            onChanged: (value) {
                              if (selectedDocumentType != null) {
                                documentNumbers[selectedDocumentType!] =
                                    value.isEmpty ? null : value;
                                _startAutoSave();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Button
                    ElevatedButton.icon(
                      onPressed: () => _pickDocument(selectedDocumentType!),
                      icon: documents[selectedDocumentType] != null
                          ? const Icon(Icons.check_circle)
                          : const Icon(Icons.upload_file),
                      label: Text(
                        documents[selectedDocumentType] != null
                            ? 'Change Document'
                            : 'Upload Document',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),

                    // Show uploaded document info
                    if (documents[selectedDocumentType] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    documents[selectedDocumentType]!
                                        .path
                                        .split('/')
                                        .last,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (documentExpirationDates[
                                          selectedDocumentType] !=
                                      null)
                                    Text(
                                      'Expires: ${documentExpirationDates[selectedDocumentType]}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  if (documentNumbers[selectedDocumentType] !=
                                          null &&
                                      documentNumbers[selectedDocumentType]!
                                          .isNotEmpty)
                                    Text(
                                      'Number: ${documentNumbers[selectedDocumentType]}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // List of uploaded documents
            if (documents.entries.any((e) => e.value != null)) ...[
              const SizedBox(height: 24),
              Text(
                'Uploaded Documents',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ...documents.entries.where((e) => e.value != null).map((entry) {
                final docType = availableDocumentTypes.firstWhere(
                  (d) => d['document_type_key']?.toString() == entry.key,
                  orElse: () => {},
                );
                final label =
                    docType['document_type_label']?.toString() ?? entry.key;
                final iconName = docType['icon_name']?.toString();
                return _buildDocumentUploadCard(
                    label, entry.key, _getIconFromName(iconName));
              }).toList(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentTypeDropdown(
      List<Map<String, dynamic>> availableDocumentTypes) {
    // Create dropdown items
    final documentTypeKeys = availableDocumentTypes
        .map((d) => d['document_type_key']?.toString() ?? '')
        .where((k) => k.isNotEmpty)
        .toList();

    final documentTypeLabels = availableDocumentTypes
        .map((d) =>
            d['document_type_label']?.toString() ??
            d['document_type_key']?.toString() ??
            '')
        .where((l) => l.isNotEmpty)
        .toList();

    return _buildDropdown(
      label: 'Select Document Type *',
      value: selectedDocumentType != null &&
              documentTypeKeys.contains(selectedDocumentType)
          ? documentTypeKeys.indexOf(selectedDocumentType!)
          : null,
      items: List.generate(documentTypeKeys.length, (index) => index),
      displayItems: documentTypeLabels,
      onChanged: (value) {
        if (value != null) {
          final selectedKey = documentTypeKeys[value];

          // Check if new document type requires expiration date
          final newDocType = availableDocumentTypes.firstWhere(
            (d) => d['document_type_key']?.toString() == selectedKey,
            orElse: () => {},
          );
          final newRequiresExpiration =
              newDocType['requires_expiration_date'] == 1 ||
                  newDocType['requires_expiration'] == 1;

          setState(() {
            selectedDocumentType = selectedKey;

            // Clear expiration date controller
            expirationDateController.clear();

            // Only load expiration date if:
            // 1. Document type requires expiration date
            // 2. Expiration date exists in map for this document type
            if (newRequiresExpiration &&
                documentExpirationDates[selectedKey] != null) {
              expirationDateController.text =
                  documentExpirationDates[selectedKey]!;
            } else if (!newRequiresExpiration) {
              // Document doesn't require expiration - make sure it's cleared
              expirationDateController.clear();
              // Don't remove from map in case user switches back, but don't show it
            }

            // Load document number if exists
            documentNumberController.text = documentNumbers[selectedKey] ?? '';
          });
          _startAutoSave();
        }
      },
      icon: Icons.description,
    );
  }

  Widget _buildDocumentUploadCard(
      String label, String documentType, IconData icon) {
    final hasDocument = documents[documentType] != null;
    final expirationDate = documentExpirationDates[documentType];
    final documentNumber = documentNumbers[documentType];
    final hasExistingDocument = existingDocuments[documentType] == true;

    // Check if this document type requires expiration date
    final docType = documentTypes.firstWhere(
      (d) => d['document_type_key']?.toString() == documentType,
      orElse: () => {},
    );
    final requiresExpiration = docType['requires_expiration_date'] == 1 ||
        docType['requires_expiration'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        subtitle: hasDocument || hasExistingDocument
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (hasDocument)
                    Text(
                      documents[documentType]!.path.split('/').last,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.green),
                    )
                  else if (hasExistingDocument)
                    Text(
                      'Document already exists - You can skip',
                      style:
                          GoogleFonts.poppins(fontSize: 12, color: Colors.blue),
                    ),
                  if (expirationDate != null)
                    Text(
                      'Expires: $expirationDate',
                      style:
                          GoogleFonts.poppins(fontSize: 11, color: Colors.blue),
                    )
                  else if (requiresExpiration && !hasExistingDocument)
                    Text(
                      'Expiration date required',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.orange),
                    ),
                  if (documentNumber != null && documentNumber.isNotEmpty)
                    Text(
                      'Number: $documentNumber',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.green.shade700),
                    ),
                ],
              )
            : const Text('Not uploaded', style: TextStyle(color: Colors.red)),
        trailing: hasDocument || hasExistingDocument
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.upload_file, color: primaryColor),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDocument) ...[
                  // Expiration date field for uploaded documents that require it
                  if (requiresExpiration) ...[
                    Text(
                      'Expiration Date *',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: expirationDate != null
                              ? DateFormat('yyyy-MM-dd').parse(expirationDate)
                              : DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 20)),
                          helpText: 'Select Expiration Date',
                        );
                        if (date != null) {
                          final formattedDate =
                              DateFormat('yyyy-MM-dd').format(date);
                          setState(() {
                            documentExpirationDates[documentType] =
                                formattedDate;
                            if (selectedDocumentType == documentType) {
                              expirationDateController.text = formattedDate;
                            }
                          });
                          api.appLog("💾 Expiration date saved to map:");
                          api.appLog("   - Document Type: $documentType");
                          api.appLog("   - Expiration Date: $formattedDate");
                          api.appLog(
                              "   - Map contains key: ${documentExpirationDates.containsKey(documentType)}");
                          _showSuccess('Expiration date saved');
                          _startAutoSave();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: cardBg,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                expirationDate ?? 'Select Expiration Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: expirationDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedDocumentType = documentType;
                            if (documentExpirationDates[documentType] != null) {
                              expirationDateController.text =
                                  documentExpirationDates[documentType]!;
                            } else {
                              expirationDateController.clear();
                            }
                          });
                          // Scroll to upload section
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ] else ...[
                  // Upload button for not uploaded documents
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedDocumentType = documentType;
                        expirationDateController.clear();
                      });
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
      helpText: 'Select Expiration Date',
    );
    if (date != null && selectedDocumentType != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      setState(() {
        expirationDateController.text = formattedDate;
        documentExpirationDates[selectedDocumentType!] = formattedDate;
      });
      _startAutoSave();
    }
  }

  Widget _buildStep8Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewSection('Personal Information', [
            'Name: ${fullNameController.text}',
            'Phone: ${phoneController.text}',
            'Email: ${emailController.text}',
            'DOB: ${dateOfBirthController.text}',
            'Gender: ${selectedGender}',
            'Marital Status: ${selectedMaritalStatus}',
          ]),
          _buildReviewSection('Location', [
            'Region: ${regions.isNotEmpty && selectedRegionId != null ? regions.firstWhere((r) {
                final id = r['region_id'];
                final rId = id is int ? id : int.tryParse(id.toString());
                return rId == selectedRegionId;
              }, orElse: () => {'region_name': 'N/A'})['region_name'] : 'N/A'}',
            'District: ${districts.isNotEmpty && selectedDistrictId != null ? districts.firstWhere((d) {
                final id = d['district_id'] ?? d['adress_id'];
                final dId = id is int ? id : int.tryParse(id.toString());
                return dId == selectedDistrictId;
              }, orElse: () => {
                  'district_name': 'N/A'
                })['district_name'] : 'N/A'}',
            'Risk Level: ${locationRisk?.riskLevel ?? 'N/A'}',
          ]),
          _buildReviewSection('Employment', [
            'Status: ${selectedEmploymentStatus}',
            'Employer: ${employerNameController.text}',
            'Monthly Income: \$${monthlyIncomeController.text}',
            'Income Category: $incomeCategory',
          ]),
          _buildReviewSection('Payment Terms', [
            'Product Price: ${BnplUtils.formatCurrency(widget.totalOrderAmount)}',
            'Deposit: ${BnplUtils.formatCurrency(productRules?.calculatedDeposit)}',
            'Loan Amount: ${BnplUtils.formatCurrency(productRules?.loanAmount)}',
            'Monthly Installment: ${BnplUtils.formatCurrency(productRules?.monthlyInstallment)}',
            'Duration: ${productRules?.repaymentDurationMonths} months',
          ]),
          if (applicationResult != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Application Submitted!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Application Number: ${applicationResult!['application_number']}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged(value);
        }
        // Trigger auto-save after user stops typing
        _startAutoSave();
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: cardBg,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required List<dynamic> items,
    List<String>? displayItems,
    required Function(dynamic) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: cardBg,
      ),
      items: items.map((item) {
        final index = items.indexOf(item);
        final display = displayItems != null && index < displayItems.length
            ? displayItems[index]
            : item.toString();
        return DropdownMenuItem(
          value: item,
          child: Text(display),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBankDropdown() {
    // Filter out invalid banks and create unique items
    final validBanks = banks.where((bank) {
      final bankId = bank['bank_id'] ?? bank['id'];
      return bankId != null && bankId != 0 && bankId != '0';
    }).toList();

    final bankIds = validBanks
        .map((bank) {
          final bankId = bank['bank_id'] ?? bank['id'];
          return int.tryParse(bankId.toString()) ?? 0;
        })
        .where((id) => id != 0)
        .toList();

    final bankNames = validBanks.map((bank) {
      return (bank['bank_name'] ?? bank['name'] ?? 'Unknown').toString();
    }).toList();

    return DropdownButtonFormField<int>(
      value: selectedBankId,
      decoration: InputDecoration(
        labelText: 'Bank Name *',
        prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF005653)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: cardBg,
      ),
      hint: Text(
        'Select Bank',
        style: GoogleFonts.poppins(fontSize: 16),
      ),
      items: bankIds.asMap().entries.map((entry) {
        final index = entry.key;
        final bankId = entry.value;
        final bankName =
            index < bankNames.length ? bankNames[index] : 'Unknown';
        return DropdownMenuItem<int>(
          value: bankId,
          child: Text(
            bankName,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: (int? value) {
        if (value != null) {
          final index = bankIds.indexOf(value);
          setState(() {
            selectedBankId = value;
            selectedBankName = index >= 0 && index < bankNames.length
                ? bankNames[index]
                : null;
          });
          _startAutoSave();
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep--);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: primaryColor),
                  ),
                  child: Text(
                    'Previous',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        if (_currentStep < 7) {
                          if (_validateCurrentStep()) {
                            setState(() => _currentStep++);
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            // Load product rules when reaching step 5
                            if (_currentStep == 4) {
                              _loadProductRules();
                            }
                          } else {
                            // Error message already shown in _validateCurrentStep
                          }
                        } else {
                          _submitApplication();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentStep == 7 ? 'Submit Application' : 'Next',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
