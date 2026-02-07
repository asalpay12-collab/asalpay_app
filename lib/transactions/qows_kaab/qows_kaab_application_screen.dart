import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/qows_kaab_api_service.dart';
import '../../services/252pay_api_service.dart';
import '../../models/qows_kaab_product.dart';
import 'qows_kaab_document_upload_screen.dart';

class QowsKaabApplicationScreen extends StatefulWidget {
  final String? walletAccountId;
  final String serviceModel; // "monthly_pack" or "daily_credit"
  final Map<String, dynamic>? eligibilityData;
  final double? monthlyIncome;

  const QowsKaabApplicationScreen({
    super.key,
    required this.walletAccountId,
    required this.serviceModel,
    this.eligibilityData,
    this.monthlyIncome,
  });

  @override
  State<QowsKaabApplicationScreen> createState() =>
      _QowsKaabApplicationScreenState();
}

class _QowsKaabApplicationScreenState extends State<QowsKaabApplicationScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final BorderRadius br12 = BorderRadius.circular(12);
  final QowsKaabApiService qowsKaabApi = QowsKaabApiService();

  // Region & District
  List<Map<String, dynamic>> regions = [];
  List<Map<String, dynamic>> districts = [];
  int? selectedRegionId;
  int? selectedDistrictId;
  bool isLoadingRegions = false;
  bool isLoadingDistricts = false;

  // Products & basket (same for both modes)
  List<QowsKaabProduct> availableProducts = [];
  List<Map<String, dynamic>> selectedProducts =
      []; // product_id, product_name, quantity, unit_price
  double totalAmount = 0.0;
  bool isLoadingProducts = false;

  // Common fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController familySizeController = TextEditingController();
  final TextEditingController monthlyIncomeController = TextEditingController();
  String? usageType;
  bool isSubmitting = false;

  /// Min/max amount from tbl_qows_kaab_usage_type_limits for current usage_type + service_model
  double? _limitMin;
  double? _limitMax;

  /// Step 0 = products only; Step 1 = other input fields; then Next → documents screen
  int _currentStep = 0;

  bool get isMonthlyPack => widget.serviceModel == 'monthly_pack';
  bool get isDailyCredit => widget.serviceModel == 'daily_credit';

  @override
  void initState() {
    super.initState();
    if (widget.monthlyIncome != null) {
      monthlyIncomeController.text = widget.monthlyIncome.toString();
    }
    if (widget.eligibilityData != null) {
      final analysis = widget.eligibilityData!['analysis'];
      if (analysis != null) {
        familySizeController.text = analysis['family_size']?.toString() ?? '';
        usageType = analysis['usage_type'];
      }
    }
    _loadRegions();
    if (usageType != null && widget.serviceModel.isNotEmpty) {
      _loadUsageTypeLimits();
    }
    _loadProducts();
    if (widget.walletAccountId != null && widget.walletAccountId!.isNotEmpty) {
      _loadCustomerForPrefill();
    }
  }

  /// If customer exists in tbl_bnpl_customers, pre-fill form (monthly_income, region, district).
  Future<void> _loadCustomerForPrefill() async {
    if (widget.walletAccountId == null) return;
    try {
      final res = await qowsKaabApi.getCustomerByWallet(
          walletAccount: widget.walletAccountId!);
      final dataFound = res['data_found'] == true;
      final customer = res['customer'];
      if (!mounted) return;
      if (!dataFound || customer == null) return;
      final Map<String, dynamic> c = Map<String, dynamic>.from(customer);
      if (c['full_name'] != null &&
          c['full_name'].toString().trim().isNotEmpty) {
        if (mounted) {
          setState(
              () => fullNameController.text = c['full_name'].toString().trim());
        }
      }
      if (c['phone_number'] != null &&
          c['phone_number'].toString().trim().isNotEmpty) {
        if (mounted) {
          setState(() =>
              phoneNumberController.text = c['phone_number'].toString().trim());
        }
      }
      if (c['monthly_income'] != null) {
        final v = c['monthly_income'];
        if (mounted) {
          setState(() {
            monthlyIncomeController.text =
                (v is num) ? v.toString() : v.toString();
          });
        }
      }
      final regionId = c['region_id'];
      final districtId = c['district_id'];
      if (regionId != null && mounted) {
        final rId =
            regionId is int ? regionId : int.tryParse(regionId.toString());
        if (rId != null) {
          await _loadDistricts(rId);
          if (!mounted) return;
          final dId = districtId != null
              ? (districtId is int
                  ? districtId
                  : int.tryParse(districtId.toString()))
              : null;
          setState(() {
            selectedRegionId = rId;
            selectedDistrictId = dId;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneNumberController.dispose();
    familySizeController.dispose();
    monthlyIncomeController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() => isLoadingRegions = true);
    try {
      final res = await qowsKaabApi.getRegions();
      final data = res['data'];
      setState(() {
        regions = data != null ? List<Map<String, dynamic>>.from(data) : [];
        isLoadingRegions = false;
      });
    } catch (e) {
      setState(() => isLoadingRegions = false);
      _showError(e.toString());
    }
  }

  Future<void> _loadDistricts(int? regionId) async {
    if (regionId == null) {
      setState(() {
        districts = [];
        selectedDistrictId = null;
      });
      return;
    }
    setState(() => isLoadingDistricts = true);
    try {
      final res = await qowsKaabApi.getDistricts(regionId: regionId);
      final data = res['data'];
      setState(() {
        districts = data != null ? List<Map<String, dynamic>>.from(data) : [];
        selectedDistrictId = null;
        isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() => isLoadingDistricts = false);
      _showError(e.toString());
    }
  }

  Future<void> _loadProducts() async {
    setState(() => isLoadingProducts = true);
    try {
      final data = await qowsKaabApi.getProducts();
      setState(() {
        availableProducts =
            data.map((e) => QowsKaabProduct.fromJson(e)).toList();
        isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => isLoadingProducts = false);
      _showError(e.toString());
    }
  }

  void _showAddToBasketDialog(QowsKaabProduct product,
      {VoidCallback? onAdded}) {
    final quantityController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name ?? 'Product', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price: ${(product.price ?? 0).toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(borderRadius: br12),
                  filled: true,
                  fillColor: cardBg,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(quantityController.text) ?? 1;
              if (qty < 1) {
                _showError('Quantity must be at least 1');
                return;
              }
              Navigator.pop(ctx);
              _addToBasket(product, qty);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('Add to basket',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addToBasket(QowsKaabProduct product, int quantity) {
    final unitPrice = product.price ?? 0.0;
    final unitLabel = product.unitSymbol ?? product.unitName ?? '';
    final productId = product.productId ?? product.id;
    setState(() {
      final existingIndex =
          selectedProducts.indexWhere((p) => (p['product_id']) == productId);
      if (existingIndex >= 0) {
        selectedProducts[existingIndex]['quantity'] =
            (selectedProducts[existingIndex]['quantity'] as int) + quantity;
      } else {
        selectedProducts.add({
          'product_id': productId,
          'product_name': product.name ?? 'Product',
          'quantity': quantity,
          'unit_price': unitPrice,
          'unit': unitLabel,
        });
      }
      _calculateTotal();
    });
  }

  void _updateBasketQuantity(int index, int delta) {
    setState(() {
      final qty = (selectedProducts[index]['quantity'] as int) + delta;
      if (qty < 1) {
        selectedProducts.removeAt(index);
      } else {
        selectedProducts[index]['quantity'] = qty;
      }
      _calculateTotal();
    });
  }

  bool _basketSheetShowAddMore = false;

  void _showBasketSheet() {
    _basketSheetShowAddMore = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 20 + MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Basket',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primaryColor)),
                      if (selectedProducts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: br12),
                          child: Text(
                              '${selectedProducts.length} item${selectedProducts.length == 1 ? '' : 's'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 48),
                      children: [
                        if (selectedProducts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No items in basket',
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey.shade600)),
                                const SizedBox(height: 6),
                                Text(
                                    'Tap "Add more products" below to add items',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        else ...[
                          ...selectedProducts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final unit = item['unit'] as String? ?? '';
                            final qty = item['quantity'] as int;
                            final unitPrice =
                                (item['unit_price'] as num).toDouble();
                            final subtotal = qty * unitPrice;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: br12,
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.15)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            item['product_name'] as String? ??
                                                '',
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(
                                            '\$${unitPrice.toStringAsFixed(2)} each${unit.isNotEmpty ? ' / $unit' : ''}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey.shade600)),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                              color:
                                                  primaryColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: primaryColor
                                                      .withOpacity(0.3))),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                  icon: const Icon(Icons.remove,
                                                      size: 18),
                                                  onPressed: () {
                                                    _updateBasketQuantity(
                                                        index, -1);
                                                    setModalState(() {});
                                                  },
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 28,
                                                          minHeight: 28),
                                                  style: IconButton.styleFrom(
                                                      foregroundColor:
                                                          primaryColor)),
                                              SizedBox(
                                                  width: 28,
                                                  child: Text('$qty',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              primaryColor))),
                                              IconButton(
                                                  icon: const Icon(Icons.add,
                                                      size: 18),
                                                  onPressed: () {
                                                    _updateBasketQuantity(
                                                        index, 1);
                                                    setModalState(() {});
                                                  },
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 28,
                                                          minHeight: 28),
                                                  style: IconButton.styleFrom(
                                                      foregroundColor:
                                                          primaryColor)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('\$${subtotal.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: primaryColor)),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () {
                                          _removeFromBasket(index);
                                          setModalState(() {});
                                        },
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  size: 16,
                                                  color: Colors.red.shade400),
                                              const SizedBox(width: 4),
                                              Text('Remove',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.red.shade400))
                                            ]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: br12,
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.2))),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total:',
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                                  Text('\$${totalAmount.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor)),
                                ]),
                          ),
                        ],
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => setModalState(() =>
                              _basketSheetShowAddMore =
                                  !_basketSheetShowAddMore),
                          borderRadius: br12,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: br12,
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.2))),
                            child: Row(
                              children: [
                                Icon(Icons.add_shopping_cart,
                                    color: primaryColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text('Add more products',
                                          style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor)),
                                      Text('Browse and add without leaving',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey.shade600))
                                    ])),
                                Icon(
                                    _basketSheetShowAddMore
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: primaryColor),
                              ],
                            ),
                          ),
                        ),
                        if (_basketSheetShowAddMore) ...[
                          const SizedBox(height: 12),
                          Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Select a product to add',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700))),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: availableProducts.length,
                            itemBuilder: (context, idx) {
                              final product = availableProducts[idx];
                              final pid = product.productId ?? product.id;
                              final isInBasket = selectedProducts
                                  .any((p) => p['product_id'] == pid);
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isInBasket
                                      ? null
                                      : () {
                                          _showAddToBasketDialog(product,
                                              onAdded: () =>
                                                  setModalState(() {}));
                                        },
                                  borderRadius: br12,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: br12,
                                        border: Border.all(
                                            color: primaryColor
                                                .withOpacity(0.12))),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: (product.imagePath != null &&
                                                  product.imagePath!.isNotEmpty)
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                      '${ApiService.baseUrl}${product.imagePath}',
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      errorBuilder:
                                                          (_, __, ___) => Icon(
                                                              Icons
                                                                  .shopping_basket,
                                                              size: 32,
                                                              color:
                                                                  primaryColor)))
                                              : Icon(Icons.shopping_basket,
                                                  size: 32,
                                                  color: primaryColor),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(product.name ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            '\$${(product.price ?? 0).toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: primaryColor)),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 28,
                                          child: ElevatedButton(
                                            onPressed: isInBasket
                                                ? null
                                                : () {
                                                    _showAddToBasketDialog(
                                                        product,
                                                        onAdded: () =>
                                                            setModalState(
                                                                () {}));
                                                  },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6))),
                                            child: Text(
                                                isInBasket
                                                    ? 'In basket'
                                                    : 'Add',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 11)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _removeFromBasket(int index) {
    setState(() {
      selectedProducts.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    totalAmount = selectedProducts.fold<double>(
      0.0,
      (sum, item) =>
          sum + ((item['quantity'] as int) * (item['unit_price'] as double)),
    );
  }

  /// Load min/max from tbl_qows_kaab_usage_type_limits for current usage_type + service_model
  Future<void> _loadUsageTypeLimits() async {
    if (usageType == null || widget.serviceModel.isEmpty) return;
    try {
      final data = await qowsKaabApi.getUsageTypeLimits(
        usageType: usageType!,
        serviceModel: widget.serviceModel,
      );
      if (!mounted) return;
      setState(() {
        _limitMin = (data['min_amount'] as num?)?.toDouble();
        _limitMax = (data['max_amount'] as num?)?.toDouble();
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _limitMin = null;
          _limitMax = null;
        });
    }
  }

  /// Next: go to document screen with form data; database is written only when user taps "Submit Application" there.
  /// Validates total amount against tbl_qows_kaab_usage_type_limits (min/max by usage_type + service_model).
  Future<void> _goToNextStep() async {
    final fullName = fullNameController.text.trim();
    if (fullName.isEmpty) {
      _showError('Customer Name is required');
      return;
    }
    if (selectedRegionId == null) {
      _showError('Please select a region');
      return;
    }
    if (selectedDistrictId == null) {
      _showError('Please select a district');
      return;
    }
    if (isMonthlyPack && selectedProducts.isEmpty) {
      _showError('Please add at least one product to your monthly pack');
      return;
    }
    if (isDailyCredit && selectedProducts.isEmpty) {
      _showError('Please add at least one product for daily credit');
      return;
    }

    // Usage type is required to validate amount against tbl_qows_kaab_usage_type_limits
    if (usageType == null || usageType!.isEmpty) {
      _showError(
          'Please select Usage Type (household or business) to validate your amount.');
      return;
    }

    // Validate total amount against min/max from tbl_qows_kaab_usage_type_limits
    double minAllowed = _limitMin ?? 0;
    double maxAllowed = _limitMax ?? double.infinity;
    if (_limitMin == null || _limitMax == null) {
      try {
        final data = await qowsKaabApi.getUsageTypeLimits(
          usageType: usageType!,
          serviceModel: widget.serviceModel,
        );
        minAllowed = (data['min_amount'] as num?)?.toDouble() ?? 0;
        maxAllowed =
            (data['max_amount'] as num?)?.toDouble() ?? double.infinity;
        if (mounted)
          setState(() {
            _limitMin = minAllowed;
            _limitMax = maxAllowed;
          });
      } catch (e) {
        _showError('Could not load amount limits. Please try again.');
        return;
      }
    }
    if (totalAmount < minAllowed) {
      _showError(
          'Total amount is too low. Minimum for ${usageType} ${widget.serviceModel == 'monthly_pack' ? 'Monthly Pack' : 'Daily Credit'}: \$${minAllowed.toStringAsFixed(2)}. Your total: \$${totalAmount.toStringAsFixed(2)}');
      return;
    }
    if (totalAmount > maxAllowed) {
      _showError(
          'Total amount is too high. Maximum for ${usageType} ${widget.serviceModel == 'monthly_pack' ? 'Monthly Pack' : 'Daily Credit'}: \$${maxAllowed.toStringAsFixed(2)}. Your total: \$${totalAmount.toStringAsFixed(2)}');
      return;
    }

    final monthlyPackItems = selectedProducts
        .map((e) => {
              'product_id': e['product_id'],
              'quantity': e['quantity'],
              'unit_price': e['unit_price'],
            })
        .toList();

    final applicationFormData = {
      'wallet_account': widget.walletAccountId,
      'full_name': fullName,
      'phone_number': phoneNumberController.text.trim().isEmpty
          ? null
          : phoneNumberController.text.trim(),
      'service_model': widget.serviceModel,
      'region_id': selectedRegionId,
      'district_id': selectedDistrictId,
      if (familySizeController.text.isNotEmpty)
        'family_size': int.tryParse(familySizeController.text),
      if (monthlyIncomeController.text.isNotEmpty)
        'monthly_income': double.tryParse(monthlyIncomeController.text),
      'usage_type': usageType,
      'monthly_pack_items': monthlyPackItems,
      if (isMonthlyPack) 'pack_total_amount': totalAmount,
    };

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QowsKaabDocumentUploadScreen(
          walletAccountId: widget.walletAccountId ?? '',
          applicationFormData: applicationFormData,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Step 0: user tapped Next after selecting products → go to step 1 (form fields)
  void _onNextFromProducts() {
    if (isMonthlyPack && selectedProducts.isEmpty) {
      _showError('Please add at least one product to your monthly pack');
      return;
    }
    if (isDailyCredit && selectedProducts.isEmpty) {
      _showError('Please add at least one product for daily credit');
      return;
    }
    setState(() => _currentStep = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMonthlyPack ? 'Monthly Pack' : 'Daily Credit',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Text(
              _currentStep == 0
                  ? 'Step 1: Select products'
                  : 'Step 2: Your details',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _showBasketSheet,
              ),
              if (selectedProducts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${selectedProducts.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _currentStep == 0
                ? _buildProductsStepContent()
                : _buildFormFieldsStepContent(),
          ),
        ),
      ),
    );
  }

  /// Step 0: ONLY products + basket + Next (no other fields)
  List<Widget> _buildProductsStepContent() {
    return [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: br12,
            ),
            child: Text(
              'Step 1 of 2',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        isMonthlyPack
            ? 'Select Products for Monthly Pack'
            : 'Select Products for Daily Credit',
        style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor),
      ),
      const SizedBox(height: 6),
      Text(
        'Add products to your basket, then tap Next. Your details will be on the next step.',
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
      ),
      const SizedBox(height: 16),
      if (isLoadingProducts)
        const Center(child: CircularProgressIndicator())
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: availableProducts.length,
          itemBuilder: (context, index) {
            final product = availableProducts[index];
            return Card(
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: br12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showAddToBasketDialog(product),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: product.imagePath != null &&
                              product.imagePath!.isNotEmpty
                          ? Image.network(
                              '${ApiService.baseUrl}${product.imagePath}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: cardBg,
                                child: Icon(Icons.shopping_basket,
                                    size: 48, color: primaryColor),
                              ),
                            )
                          : Container(
                              color: cardBg,
                              child: Icon(Icons.shopping_basket,
                                  size: 48, color: primaryColor),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Text(
                        product.name ?? 'Product',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '\$${(product.price ?? 0).toStringAsFixed(2)}${(product.unitSymbol ?? product.unitName ?? '').isNotEmpty ? ' / ${product.unitSymbol ?? product.unitName}' : ''}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _onNextFromProducts,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: br12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Next',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  bool _formStepShowAddMore = false;

  /// Step 2: Basic Info + other input fields + Back + Next (→ documents screen)
  List<Widget> _buildFormFieldsStepContent() {
    return [
      Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 22),
            onPressed: () => setState(() => _currentStep = 0),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: br12,
            ),
            child: Text(
              'Step 2 of 2',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Basic Information',
        style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor),
      ),
      const SizedBox(height: 6),
      Text(
        'Wallet account is linked to your session. New customers must enter name and phone.',
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
      ),
      const SizedBox(height: 12),
      Text('Customer Name *',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
      const SizedBox(height: 8),
      TextField(
        controller: fullNameController,
        decoration: InputDecoration(
          hintText: 'Enter your full name',
          prefixIcon: const Icon(Icons.person_outline),
          border: OutlineInputBorder(borderRadius: br12),
          filled: true,
          fillColor: cardBg,
        ),
      ),
      const SizedBox(height: 16),
      Text('Phone Number (Optional if no mobile)',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
      const SizedBox(height: 8),
      TextField(
        controller: phoneNumberController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: 'Enter phone number',
          prefixIcon: const Icon(Icons.phone_outlined),
          border: OutlineInputBorder(borderRadius: br12),
          filled: true,
          fillColor: cardBg,
        ),
      ),
      const SizedBox(height: 24),
      Text('Monthly Income (USD) *',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
      const SizedBox(height: 8),
      TextField(
        controller: monthlyIncomeController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Enter your monthly income',
          prefixText: '\$ ',
          border: OutlineInputBorder(borderRadius: br12),
          filled: true,
          fillColor: cardBg,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'This will be stored with your application',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
      ),
      const SizedBox(height: 24),
      Text('Region (Required)',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
      const SizedBox(height: 8),
      isLoadingRegions
          ? const Center(child: CircularProgressIndicator())
          : DropdownButtonFormField<int>(
              isExpanded: true,
              value: selectedRegionId,
              decoration: InputDecoration(
                hintText: 'Select region',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(borderRadius: br12),
                filled: true,
                fillColor: cardBg,
              ),
              items: regions
                  .map((r) {
                    final id = r['region_id'] ?? r['id'];
                    final name = r['region_name'] ?? r['name'] ?? '${id ?? ""}';
                    return DropdownMenuItem<int>(
                      value: id != null ? int.tryParse(id.toString()) : null,
                      child: Text(name.toString(),
                          overflow: TextOverflow.ellipsis),
                    );
                  })
                  .where((e) => e.value != null)
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedRegionId = v;
                  _loadDistricts(v);
                });
              },
            ),
      const SizedBox(height: 16),
      Text('District (Required)',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
      const SizedBox(height: 8),
      isLoadingDistricts
          ? const Center(child: CircularProgressIndicator())
          : DropdownButtonFormField<int>(
              isExpanded: true,
              value: selectedDistrictId,
              decoration: InputDecoration(
                hintText: 'Select district',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: br12),
                filled: true,
                fillColor: cardBg,
              ),
              items: districts
                  .map((d) {
                    final id = d['district_id'] ?? d['address_id'] ?? d['id'];
                    final name =
                        d['district_name'] ?? d['name'] ?? '${id ?? ""}';
                    return DropdownMenuItem<int>(
                      value: id != null ? int.tryParse(id.toString()) : null,
                      child: Text(name.toString(),
                          overflow: TextOverflow.ellipsis),
                    );
                  })
                  .where((e) => e.value != null)
                  .toList(),
              onChanged: selectedRegionId == null
                  ? null
                  : (v) => setState(() => selectedDistrictId = v),
            ),
      const SizedBox(height: 16),
      Text('Family Size (Optional)',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
      const SizedBox(height: 8),
      TextField(
        controller: familySizeController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Number of family members',
          prefixIcon: const Icon(Icons.people),
          border: OutlineInputBorder(borderRadius: br12),
          filled: true,
          fillColor: cardBg,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        selectedProducts.isNotEmpty
            ? 'Usage Type (Required – for amount limits)'
            : 'Usage Type (Optional)',
        style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        isExpanded: true,
        value: usageType,
        decoration: InputDecoration(
          hintText: 'Select usage type (household or business)',
          prefixIcon: const Icon(Icons.home),
          border: OutlineInputBorder(borderRadius: br12),
          filled: true,
          fillColor: cardBg,
        ),
        items: ['household', 'business']
            .map((type) => DropdownMenuItem(
                value: type,
                child:
                    Text(type.toUpperCase(), overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (v) {
          setState(() {
            usageType = v;
            _limitMin = null;
            _limitMax = null;
          });
          if (v != null && widget.serviceModel.isNotEmpty)
            _loadUsageTypeLimits();
        },
      ),
      if (_limitMin != null && _limitMax != null) ...[
        const SizedBox(height: 8),
        Text(
          'Allowed amount: \$${_limitMin!.toStringAsFixed(2)} - \$${_limitMax!.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
      const SizedBox(height: 24),
      Text('Selected Products',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)),
      const SizedBox(height: 6),
      Text('Products below your form. Adjust quantity or add more.',
          style:
              GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
      const SizedBox(height: 12),
      if (selectedProducts.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: br12,
              border: Border.all(color: Colors.amber.shade200)),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'No products yet. Tap "Add more products" below to add items.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.amber.shade900))),
            ],
          ),
        )
      else ...[
        ...selectedProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final unit = item['unit'] as String? ?? '';
          final qty = item['quantity'] as int;
          final unitPrice = (item['unit_price'] as num).toDouble();
          final subtotal = qty * unitPrice;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cardBg,
                borderRadius: br12,
                border: Border.all(color: primaryColor.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['product_name'] as String? ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          '\$${unitPrice.toStringAsFixed(2)} each${unit.isNotEmpty ? ' / $unit' : ''}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.3))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () =>
                                    _updateBasketQuantity(index, -1),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                style: IconButton.styleFrom(
                                    foregroundColor: primaryColor)),
                            SizedBox(
                                width: 28,
                                child: Text('$qty',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor))),
                            IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () =>
                                    _updateBasketQuantity(index, 1),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                style: IconButton.styleFrom(
                                    foregroundColor: primaryColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${subtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: primaryColor)),
                    const SizedBox(height: 6),
                    InkWell(
                        onTap: () => _removeFromBasket(index),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Text('Remove',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.red.shade400))
                        ])),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: br12,
              border: Border.all(color: primaryColor.withOpacity(0.2))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total:',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            Text('\$${totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      InkWell(
        onTap: () =>
            setState(() => _formStepShowAddMore = !_formStepShowAddMore),
        borderRadius: br12,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: br12,
              border: Border.all(color: primaryColor.withOpacity(0.2))),
          child: Row(
            children: [
              Icon(Icons.add_shopping_cart, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Add more products',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryColor)),
                    Text('Browse and add without going back',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade600))
                  ])),
              Icon(_formStepShowAddMore ? Icons.expand_less : Icons.expand_more,
                  color: primaryColor),
            ],
          ),
        ),
      ),
      if (_formStepShowAddMore) ...[
        const SizedBox(height: 12),
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Select a product to add',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700))),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78),
          itemCount: availableProducts.length,
          itemBuilder: (context, idx) {
            final product = availableProducts[idx];
            final pid = product.productId ?? product.id;
            final isInBasket =
                selectedProducts.any((p) => p['product_id'] == pid);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    isInBasket ? null : () => _showAddToBasketDialog(product),
                borderRadius: br12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: br12,
                      border:
                          Border.all(color: primaryColor.withOpacity(0.12))),
                  child: Column(
                    children: [
                      Expanded(
                        child: (product.imagePath != null &&
                                product.imagePath!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    '${ApiService.baseUrl}${product.imagePath}',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.shopping_basket,
                                        size: 32,
                                        color: primaryColor)))
                            : Icon(Icons.shopping_basket,
                                size: 32, color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(product.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      Text('\$${(product.price ?? 0).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: primaryColor)),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: isInBasket
                              ? null
                              : () => _showAddToBasketDialog(product),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6))),
                          child: Text(isInBasket ? 'In basket' : 'Add',
                              style: GoogleFonts.poppins(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
      const SizedBox(height: 32),
      Text(
        'After Next you will upload your documents.',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _goToNextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: br12),
          ),
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Next → Upload documents',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ];
  }
}
