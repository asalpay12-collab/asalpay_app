import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../models/category.dart';
import '../models/product.dart';
import '../services/252pay_api_service.dart';
import '../services/bnpl_api_service.dart';
import '../services/api_urls.dart';
import 'DiscountProductsDrawer.dart';
import 'my_orders_screen.dart';
import 'basket_screen.dart';
import 'bnpl/bnpl_tracking_screen.dart';
import 'bnpl/bnpl_application_screen.dart';
import 'package:asalpay/widgets/commonBtn.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:provider/provider.dart';
import '../models/http_exception.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';

class ProductPurchaseScreen extends StatefulWidget {
  const ProductPurchaseScreen({super.key, required this.wallet_accounts_id});
  final String? wallet_accounts_id;
  @override
  State<ProductPurchaseScreen> createState() => _ProductPurchaseScreenState();
}

class _ProductPurchaseScreenState extends State<ProductPurchaseScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final Color bodyBg = Colors.white;
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();
  final bnplApi = BnplApiService();

  List<Product> products = [];
  List<Category> subCategories = [];
  List<Category> categories = [];
  List<Map<String, dynamic>> accountInfo = [];
  List<Map<String, dynamic>> PaymentPolicy = [];
  List<Map<String, dynamic>> merchnataccountInfo = [];
  List<Map<String, dynamic>> merchantInfo = [];
  List<Map<String, dynamic>> orderItems = [];
  static const String baseUrl = ApiService.imgURL;
  bool isLoading = true;
  Category? selectedCategory;
  Category? selectedSubCategory;
  Product? selectedProduct;
  String ModelErrorMessage = "";
  String pinNumber = "";

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoading = true;
    });
    try {
      print(
          "🔄 Loading categories from: ${ApiUrls.BASE_URL}wallet25Pay/mainCategories");
      final fetchedCategories = await api.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        isLoading = false;
      });
      print("✅ Loaded ${fetchedCategories.length} categories");
    } catch (e) {
      print("❌ Error loading categories: $e");
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        _showError('Failed to load categories: ${e.toString()}');
      }
    }
  }

  Future<void> _loadPaymentPolicy() async {
    try {
      final fetchedPolicy = await api.fetchPaymentPolicy();
      setState(() {
        PaymentPolicy = fetchedPolicy;
        isLoading = false;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadSubCategories(int categoryId) async {
    try {
      final fetchedSubCategories = await api.fetchSubCategories(categoryId);
      setState(() {
        subCategories = fetchedSubCategories;
        isLoading = false;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadProducts(int categoryId) async {
    setState(() {
      isLoading = true;
      products.clear();
    });
    try {
      final fetchedProducts = await api.fetchProducts(categoryId);
      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(' $message '),
      backgroundColor: Colors.green,
    ));
  }

  void _showOrderDialog(
      Product product, double unitPrice, String remainingQuantity) {
    final quantityController = TextEditingController(text: '1');
    final totalController =
        TextEditingController(text: unitPrice.toStringAsFixed(2));
    double currentPrice = unitPrice;
    bool isNegotiating = false;

    void updateTotal() {
      final qty = int.tryParse(quantityController.text) ?? 1;
      final total = qty * currentPrice;
      totalController.text = total.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Order ${product.name}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price per unit with Negotiate button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Price per unit'),
                              const SizedBox(height: 4),
                              Text(
                                '\$${currentPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (product.costPrice != null && product.costPrice! > 0)
                          ElevatedButton.icon(
                            onPressed: isNegotiating
                                ? null
                                : () async {
                                    await _showNegotiatePriceDialog(
                                      context,
                                      product,
                                      currentPrice,
                                      (newPrice) {
                                        setDialogState(() {
                                          currentPrice = newPrice;
                                          updateTotal();
                                        });
                                      },
                                    );
                                  },
                            icon: const Icon(Icons.attach_money, size: 16),
                            label: const Text('Negotiate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quantity – no availability limit; user can order any quantity
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      onChanged: (value) {
                        final qty = int.tryParse(value) ?? 1;
                        if (qty < 1) {
                          quantityController.text = '1';
                          quantityController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: quantityController.text.length),
                          );
                        }
                        updateTotal();
                      },
                    ),
                    const SizedBox(height: 12),
                    // Total
                    TextField(
                      controller: totalController,
                      decoration: const InputDecoration(labelText: 'Total:'),
                      enabled: false,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: primaryColor)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(quantityController.text) ?? 1;
                    setState(() {
                      orderItems.add({
                        "product_id": product.id,
                        "quantity": qty,
                        "unit_price": currentPrice,
                        "name": product.name,
                      });
                      selectedProduct = null;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to basket'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Basket'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMessageDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red : primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: GoogleFonts.poppins(fontSize: 15, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNegotiatePriceDialog(
    BuildContext context,
    Product product,
    double originalPrice,
    Function(double) onPriceUpdated,
  ) async {
    final requestedPriceController = TextEditingController();
    final messageController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.attach_money, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Negotiate Price',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original Price Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Original Price',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Requested Price
                    TextField(
                      controller: requestedPriceController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Your Requested Price *',
                        prefixIcon:
                            Icon(Icons.currency_exchange, color: primaryColor),
                        hintText: 'Enter amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Message (Optional)
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message (Optional)',
                        prefixIcon: Icon(Icons.message, color: primaryColor),
                        hintText: "e.g., 'This price is too high for me'",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: primaryColor)),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final requestedPrice =
                              double.tryParse(requestedPriceController.text);
                          if (requestedPrice == null || requestedPrice <= 0) {
                            await _showMessageDialog(
                              context,
                              title: 'Invalid Price',
                              message: 'Please enter a valid price.',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final result = await bnplApi.negotiatePrice(
                              productId: product.id,
                              originalPrice: originalPrice,
                              requestedPrice: requestedPrice,
                              customerMessage:
                                  messageController.text.trim().isEmpty
                                      ? null
                                      : messageController.text.trim(),
                            );

                            setDialogState(() => isSubmitting = false);
                            if (!context.mounted) return;
                            Navigator.pop(context); // Close negotiate dialog

                            final msg =
                                result['data']?['message']?.toString() ??
                                    result['message']?.toString() ??
                                    '';

                            if (result['data']?['can_negotiate'] == true) {
                              final counterOffer = result['data']
                                  ?['counter_offer_price'] as double?;
                              if (counterOffer != null) {
                                onPriceUpdated(counterOffer);
                              }
                              final successMsg = msg.isNotEmpty
                                  ? msg
                                  : (counterOffer != null
                                      ? 'Price negotiation successful. New price: \$${counterOffer.toStringAsFixed(2)}'
                                      : 'Price negotiation successful.');
                              await _showMessageDialog(
                                context,
                                title: 'Negotiation Result',
                                message: successMsg,
                                isError: false,
                              );
                            } else {
                              await _showMessageDialog(
                                context,
                                title: 'Negotiation Result',
                                message: msg.isNotEmpty
                                    ? msg
                                    : 'Price negotiation could not be completed.',
                                isError: false,
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (!context.mounted) return;
                            Navigator.pop(context); // Close negotiate dialog
                            await _showMessageDialog(
                              context,
                              title: 'Error',
                              message:
                                  e.toString().replaceFirst('Exception: ', ''),
                              isError: true,
                            );
                          }
                        },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitOrder({
    required double totalAmount,
    required String status,
    required List<Map<String, dynamic>> items,
    required int addressId,
    required String description,
    required String phone,
    String merchantAccount = '',
    String currencyFromId = '',
    String currencyToId = '',
    double? amountFrom,
    double? amountTo,
  }) async {
    try {
      await api.submitOrder(
          walletAccount: widget.wallet_accounts_id,
          totalAmount: totalAmount,
          status: status,
          items: items,
          addressId: addressId,
          description: description,
          phone: phone,
          merchantAccount: merchantAccount,
          currencyFromId: currencyFromId,
          currencyToId: currencyToId,
          amountFrom: amountFrom,
          amountTo: amountTo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order submitted successfully')),
      );
      setState(() {
        orderItems.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> showPaymentConfirmationBottomSheet({
    required double amountFrom,
    required double amountTo,
    required String currencyFromId,
    required String currencyToId,
    required String merchantCurrency,
    required String merchantaccount,
    required String walletCurrency,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    List<Map<String, dynamic>> customerAddresses = [];
    int? selectedAddressId;
    TextEditingController descriptionController = TextEditingController();
    TextEditingController phoneController = TextEditingController();

    try {
      customerAddresses = await api.fetchCustomerAddress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to load addresses')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          constraints.maxHeight * 0.95, // Responsive limit
                    ),
                    child: Padding(
                      padding: MediaQuery.of(context).viewInsets,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Row(
                                children: const [
                                  Icon(Icons.payment, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Confirm Payment',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Address Dropdown
                              const Text("Select Delivery Address"),
                              const SizedBox(height: 5),
                              Builder(
                                builder: (context) {
                                  final addressItems = <int, String>{};
                                  for (final address in customerAddresses) {
                                    final rawId = address['adress_id'] ??
                                        address['address_id'] ??
                                        address['district_id'] ??
                                        address['id'];
                                    final id = rawId is int
                                        ? rawId
                                        : int.tryParse(rawId?.toString() ?? '');
                                    if (id != null) {
                                      final name = address['district_name'] ??
                                          address['name'] ??
                                          'Unknown District';
                                      addressItems[id] =
                                          name.toString().trim().isEmpty
                                              ? 'Address #$id'
                                              : name.toString();
                                    }
                                  }
                                  final validIds = addressItems.keys.toList();
                                  final dropdownValue = selectedAddressId !=
                                              null &&
                                          validIds.contains(selectedAddressId)
                                      ? selectedAddressId
                                      : null;
                                  return DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    hint: const Text("Choose address"),
                                    value: dropdownValue,
                                    items: validIds
                                        .map((id) => DropdownMenuItem<int>(
                                              value: id,
                                              child:
                                                  Text(addressItems[id] ?? ''),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedAddressId = value;
                                      });
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              // Description
                              const Text("Delivery Description"),
                              const SizedBox(height: 5),
                              TextField(
                                controller: descriptionController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Enter delivery address notes...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Phone
                              const Text("Phone Number"),
                              const SizedBox(height: 5),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Enter phone number...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Currency Fields
                              _buildDisabledField(
                                icon: Icons.account_balance_wallet,
                                label: 'Currency From',
                                value: walletCurrency,
                              ),
                              _buildDisabledField(
                                icon: Icons.money,
                                label: 'Amount From',
                                value: amountFrom.toStringAsFixed(2),
                              ),
                              _buildDisabledField(
                                icon: Icons.currency_exchange,
                                label: 'Currency To',
                                value: merchantCurrency,
                              ),
                              _buildDisabledField(
                                icon: Icons.attach_money,
                                label: 'Amount To',
                                value: amountTo.toStringAsFixed(2),
                              ),
                              const SizedBox(height: 16),

                              // Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (selectedAddressId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '🚫 Please select a delivery address.'),
                                          ),
                                        );
                                        return;
                                      }

                                      if (descriptionController.text
                                          .trim()
                                          .isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '📝 Please enter a delivery description.'),
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.of(context).pop();

                                      await api.purchaseOrder(
                                        amountFrom: amountFrom,
                                        currencyFromId: currencyFromId,
                                        currencyToId: currencyToId,
                                        amountTo: amountTo,
                                        merchantAccount: merchantaccount,
                                        walletAccount:
                                            widget.wallet_accounts_id,
                                      );

                                      _submitOrder(
                                          totalAmount: totalAmount,
                                          status: 'Paid',
                                          items: items,
                                          addressId: selectedAddressId!,
                                          description:
                                              descriptionController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          merchantAccount: merchantaccount,
                                          currencyFromId: currencyFromId,
                                          currencyToId: currencyToId,
                                          amountFrom: amountFrom,
                                          amountTo: amountTo);
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text('Pay'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  bool isloading1 = false;
  bool _submitted1 = false;
  Future<bool> _CheckPinNumber() async {
    _submitted1 = true;
    setState(() {
      isloading1 = true;
      ModelErrorMessage = "";
    });

    var errorMessage = 'Successfully Sent!';
    try {
      final auth = Provider.of<Auth>(context, listen: false);
      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .LoginPIN(
        auth.phone!,
        pinNumber,
      );
    } on HttpException catch (error) {
      setState(() {
        isloading1 = false;
      });

      if (error.toString().contains('INVALID_PHONE')) {
        _showErrorDialog('Could not find a user with that phone.');
        return false;
      } else if (error.toString().contains('INVALID_PIN')) {
        _showErrorDialog('Invalid password.');
        return false;
      } else if (error.toString().contains('INACTIVE_ACCOUNT')) {
        _showErrorDialog('Your Account is not Active.');
        return false;
      } else if (error.toString().contains('OP')) {
        _showErrorDialog('Operation failed.');
        return false;
      }

      _showErrorDialog(error.toString());
      return false;
    } catch (error) {
      setState(() {
        isloading1 = false;
      });
      _showErrorDialog(error.toString());
      return false;
    }

    setState(() {
      isloading1 = false;
    });
    _submitted1 = false;
    ModelErrorMessage = "";
    return true;
  }

  Future<bool> _showMyDialogConfirmPin() async {
    bool result = false;
    String currentPin = "";

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setModalState) {
            Future<void> verifyPin(String code) async {
              if (code.length != 4 || isloading1) return;

              setModalState(() {
                isloading1 = true;
              });

              pinNumber = code;
              bool isValid = await _CheckPinNumber();

              setModalState(() {
                isloading1 = false;
              });

              if (isValid) {
                result = true;
                Navigator.pop(context);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Confirmation Pin",
                        style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontSize: 20) ??
                            const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.all(4),
                          child:
                              Icon(Icons.close, color: primaryColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Enter 4-digit Pin To Send Money and Subtract from Your Wallet",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  OtpTextField(
                    numberOfFields: 4,
                    borderColor: primaryColor,
                    obscureText: true,
                    onCodeChanged: (String code) {
                      currentPin = code;
                      if (code.length == 4) {
                        verifyPin(code); // 🔄 Auto-check when filled
                      }
                    },
                    onSubmit: (String code) async {
                      currentPin = code;
                      await verifyPin(
                          code); // Also trigger check on keyboard done
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              actions: <Widget>[
                Center(
                  child: isloading1
                      ? const CircularProgressIndicator()
                      : InkWell(
                          onTap: () async {
                            FocusScope.of(context).unfocus();

                            if (currentPin.length != 4) {
                              _showErrorDialog("Please enter a 4-digit PIN.");
                              return;
                            }

                            await verifyPin(currentPin);
                          },
                          child: const CommonBtn(txt: "Confirm Pin"),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  void _dismissLoadingIfOpen() {
    if (!mounted) return;
    try {
      Navigator.of(context).pop();
    } catch (_) {}
  }

  Future<void> submitPayNowOrder(
      double totalAmount, List<Map<String, dynamic>> items) async {
    if (!mounted) return;
    try {
      // Step 1: PIN dialog – verify before continuing (shows on top of basket)
      bool pinVerified = await _showMyDialogConfirmPin();
      if (!pinVerified || !mounted) return;

      // Close basket so loading and rest of flow show on ProductPurchaseScreen
      if (mounted) Navigator.of(context).pop();

      // Step 2: Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await api.getAcountInfo(widget.wallet_accounts_id);
      final merchantAccount = await api.fetchmerchantAccount();

      if (!mounted) return;
      accountInfo = List<Map<String, dynamic>>.from(response);
      merchnataccountInfo = List<Map<String, dynamic>>.from(merchantAccount);

      if (accountInfo.isEmpty) {
        _dismissLoadingIfOpen();
        _showError("Could not load wallet account.");
        return;
      }
      if (merchnataccountInfo.isEmpty) {
        _dismissLoadingIfOpen();
        _showError("Could not load merchant account.");
        return;
      }

      final account = merchnataccountInfo.first;
      final merchantAccountId = account['merchant_account']?.toString();
      if (merchantAccountId == null || merchantAccountId.isEmpty) {
        _dismissLoadingIfOpen();
        _showError("Invalid merchant account.");
        return;
      }

      final responseMerchant = await api.getMerchantInfo(merchantAccountId);
      if (!mounted) return;
      merchantInfo = List<Map<String, dynamic>>.from(responseMerchant);
      if (merchantInfo.isEmpty) {
        _dismissLoadingIfOpen();
        _showError("Could not load merchant info.");
        return;
      }

      final user = accountInfo.first;
      final merchant = merchantInfo.first;

      final double balance = double.tryParse(user['balance'].toString()) ?? 0.0;
      final double paymentAmount =
          double.tryParse(totalAmount.toString()) ?? 0.0;

      final String walletCurrency = user['currency_name']?.toString() ?? '';
      final String merchantCurrency =
          merchant['currency_name']?.toString() ?? '';
      final String merchantcurrency_id =
          merchant['currency_id']?.toString() ?? '';
      final String walletcurrency_id = user['currency_id']?.toString() ?? '';

      if (balance == 0.0) {
        _dismissLoadingIfOpen();
        _showError("Your wallet balance is zero. Insufficient balance.");
        return;
      }
      if (balance < paymentAmount) {
        _dismissLoadingIfOpen();
        _showError("Your balance is less than the amount to be paid.");
        return;
      }

      _dismissLoadingIfOpen();

      if (walletCurrency == merchantCurrency) {
        await showPaymentConfirmationBottomSheet(
          amountFrom: paymentAmount,
          amountTo: paymentAmount,
          currencyFromId: walletcurrency_id,
          currencyToId: merchantcurrency_id,
          merchantCurrency: merchantCurrency,
          merchantaccount: merchantAccountId,
          walletCurrency: walletCurrency,
          totalAmount: totalAmount,
          items: items,
        );
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final exchangeData = await api.getExchangeInfo(
          merchantcurrency_id,
          walletcurrency_id,
          paymentAmount,
        );

        if (!mounted) return;
        _dismissLoadingIfOpen();

        final double amountchanges =
            double.tryParse(exchangeData['amount_to']?.toString() ?? '') ?? 0.0;

        if (balance < amountchanges) {
          _showError("Your balance is less than the amount to be paid.");
          return;
        }

        await showPaymentConfirmationBottomSheet(
          amountFrom: amountchanges,
          amountTo: paymentAmount,
          currencyFromId: walletcurrency_id,
          currencyToId: merchantcurrency_id,
          merchantCurrency: merchantCurrency,
          merchantaccount: merchantAccountId,
          walletCurrency: walletCurrency,
          totalAmount: totalAmount,
          items: items,
        );
      }
    } catch (e) {
      _dismissLoadingIfOpen();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message, textAlign: TextAlign.center),
        content: const Text(
          "Enter a valid pin",
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Okay', style: TextStyle(color: primaryColor)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bodyBg,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: PopupMenuButton<String>(
          child: Text(
            '252pay',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          offset: const Offset(0, 50),
          onSelected: (value) {
            if (value == 'my_bnpl_applications') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BnplTrackingScreen(
                    walletAccountId: widget.wallet_accounts_id ?? '',
                  ),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'my_bnpl_applications',
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'My BNPL Applications',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              if (selectedProduct != null) {
                selectedProduct = null;
              } else if (selectedSubCategory != null) {
                selectedSubCategory = null;
              } else if (selectedCategory != null) {
                selectedCategory = null;
              } else {
                Navigator.pop(context);
              }
            });
          },
        ),
        actions: [
          // Basket Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag, color: Colors.white),
                onPressed: () {
                  if (orderItems.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BasketScreen(
                          walletAccountId: widget.wallet_accounts_id,
                          basketItems: orderItems,
                          onBasketUpdated: (updatedItems) {
                            setState(() {
                              orderItems = updatedItems;
                            });
                          },
                          onPayNow: (totalAmount, items) {
                            submitPayNowOrder(totalAmount, items);
                          },
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Your basket is empty')),
                    );
                  }
                },
              ),
              if (orderItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${orderItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Menu Icon (Three Dots)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'my_orders') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyOrdersScreen(
                      walletAccountId: widget.wallet_accounts_id!,
                    ),
                  ),
                );
              } else if (value == 'draft_applications') {
                _handleDraftApplications();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'my_orders',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'My Orders',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'draft_applications',
                child: Row(
                  children: [
                    Icon(Icons.drafts, color: primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Draft Applications',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : selectedCategory == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBnplApplicationsCard(),
                      const SizedBox(height: 20),
                      Expanded(child: _buildCategoryGrid()),
                    ],
                  )
                : selectedSubCategory == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainCategoriesBar(),
                          Expanded(
                            child: _buildSubCategoryGrid(),
                          ),
                        ],
                      )
                    : selectedProduct == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSubCategoriesBar(),
                              Expanded(child: _buildProductGrid()),
                            ],
                          )
                        : _buildPaymentPlaceholder(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiscountProductPurchaseScreen(
                      wallet_accounts_id: widget.wallet_accounts_id),
                ),
              );
            },
            icon: const Icon(Icons.local_offer),
            label: Text(
              'Discount Products',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: br12),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cloth')) return Icons.checkroom;
    if (lower.contains('electronic')) return Icons.electrical_services;
    return Icons.category;
  }

  Widget _buildMainCategoriesBar() {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Main Categories',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected =
                    selectedCategory?.categoryId == cat.categoryId;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () async {
                      await _loadSubCategories(cat.categoryId);
                      setState(() {
                        selectedCategory = cat;
                        selectedSubCategory = null;
                        selectedProduct = null;
                      });
                    },
                    borderRadius: br12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : cardBg,
                        borderRadius: br12,
                        border: Border.all(
                          color:
                              isSelected ? primaryColor : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat.productImage.isNotEmpty)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '$baseUrl/${cat.productImage}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _getIconForCategory(cat.categoryName),
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
                                  ),
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                          ? child
                                          : SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        isSelected
                                                            ? Colors.white
                                                            : primaryColor),
                                              ),
                                            ),
                                ),
                              ),
                            ),
                          if (cat.productImage.isNotEmpty)
                            const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              cat.categoryName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? Colors.white : primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesBar() {
    if (subCategories.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sub Categories',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                final subcat = subCategories[index];
                final isSelected =
                    selectedSubCategory?.subCategoryId == subcat.subCategoryId;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () async {
                      await _loadProducts(subcat.subCategoryId);
                      setState(() {
                        selectedSubCategory = subcat;
                        selectedProduct = null;
                      });
                    },
                    borderRadius: br12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : cardBg,
                        borderRadius: br12,
                        border: Border.all(
                          color:
                              isSelected ? primaryColor : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (subcat.imagePath.isNotEmpty)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '$baseUrl/${subcat.imagePath}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.category,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
                                  ),
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                          ? child
                                          : SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        isSelected
                                                            ? Colors.white
                                                            : primaryColor),
                                              ),
                                            ),
                                ),
                              ),
                            ),
                          if (subcat.imagePath.isNotEmpty)
                            const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              subcat.subCategoryName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? Colors.white : primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : 3;
    if (subCategories.isEmpty) {
      return Center(
        child: Text(
          'No  sub category available.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: subCategories.length,
      itemBuilder: (_, idx) {
        final subcat = subCategories[idx];
        return InkWell(
          borderRadius: br12,
          onTap: () async {
            print(subcat.subCategoryId);
            await _loadProducts(subcat.subCategoryId);
            setState(() {
              selectedSubCategory = subcat;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br12,
              color: cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    '$baseUrl/${subcat.imagePath}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                        size: 40, color: Colors.grey),
                    loadingBuilder: (context, child, progress) => progress ==
                            null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subcat.subCategoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBnplApplicationsCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BnplTrackingScreen(
              walletAccountId: widget.wallet_accounts_id ?? '',
            ),
          ),
        );
      },
      borderRadius: br12,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: br12,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My BNPL Applications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View and manage your applications',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : 3;
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No Category available.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: categories.length,
      itemBuilder: (_, idx) {
        final cat = categories[idx];
        return InkWell(
          borderRadius: br12,
          onTap: () async {
            await _loadSubCategories(cat.categoryId);
            setState(() {
              selectedCategory = cat;
              selectedSubCategory = null; // reset subcategory
              selectedProduct = null; // reset product
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br12,
              color: cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    '$baseUrl/${cat.productImage}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                        size: 40, color: Colors.grey),
                    loadingBuilder: (context, child, progress) => progress ==
                            null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.categoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    int crossAxisCount = MediaQuery.of(context).size.width < 600 ? 2 : 3;
    if (products.isEmpty) {
      return Center(
        child: Text(
          'No  product available.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Select Product – ${selectedSubCategory?.subCategoryName ?? ""}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
                GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, idx) {
                    final product = products[idx];
                    final unitPrice = double.tryParse(product.unitPrice) ?? 0.0;
                    final remainingQuantity = product.remainingQuantity;

                    return InkWell(
                      borderRadius: br12,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: br12,
                          color: cardBg,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.network(
                                '$baseUrl/${product.imagePath}',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2));
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${unitPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showOrderDialog(
                                      product, unitPrice, remainingQuantity);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: br12),
                                ),
                                child: const Text('Order',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // See Details – commented out for now; uncomment when needed
                            // GestureDetector(
                            //   onTap: () {
                            //     _showPaymentPolicySheet(product);
                            //   },
                            //   child: Text(
                            //     "See Details",
                            //     style: GoogleFonts.poppins(
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.w500,
                            //       color: Colors.blue,
                            //       decoration: TextDecoration.underline,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Basket Button at Bottom
        if (orderItems.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BasketScreen(
                          walletAccountId: widget.wallet_accounts_id,
                          basketItems: orderItems,
                          onBasketUpdated: (updatedItems) {
                            setState(() {
                              orderItems = updatedItems;
                            });
                          },
                          onPayNow: (totalAmount, items) {
                            submitPayNowOrder(totalAmount, items);
                          },
                        ),
                      ),
                    );
                  },
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_bag, size: 24),
                      if (orderItems.isNotEmpty)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${orderItems.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: Text(
                    'View Basket (${orderItems.length} items)',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentPlaceholder() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: br12,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, size: 80, color: primaryColor),
            const SizedBox(height: 24),
            Text(
              'Proceed to Payment for',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Text(
              selectedProduct!.name,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: br12),
                textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: const Text('Pay Now'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => setState(() => selectedProduct = null),
              child: Text('← Back to Products',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextField(
          readOnly: true,
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          controller: TextEditingController(text: value),
        ),
      ),
    );
  }

  void _showPaymentPolicySheet(dynamic product) async {
    // Load policies if not loaded
    if (PaymentPolicy.isEmpty) {
      await _loadPaymentPolicy();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8, // Max height: 80% of screen
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Drag Handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              /// Title
              Text(
                "Payment Plans for ${product.name}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth < 400 ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              /// Table Header
              Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Policy",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Months",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Price",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Per Month",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              /// Table Data
              Expanded(
                child: PaymentPolicy.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: PaymentPolicy.length,
                        itemBuilder: (context, index) {
                          final policy = PaymentPolicy[index];
                          final months = int.tryParse(
                                  policy['months_interval'].toString()) ??
                              1;
                          final price =
                              double.tryParse(product.unitPrice.toString()) ??
                                  0.0;
                          final perMonth = price / months;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      policy['policy_name'] ?? '',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      months.toString(),
                                      style: GoogleFonts.poppins(fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "\$${price.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "\$${perMonth.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDraftApplications() async {
    if (widget.wallet_accounts_id == null ||
        widget.wallet_accounts_id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet account ID is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Check for draft application
      final draft = await api.getApplicationDraft(widget.wallet_accounts_id!);

      if (draft != null && draft['application_id'] != null) {
        // Draft exists, navigate to application screen
        // The application screen will automatically load the draft data and determine the step
        // Extract order items from draft if available, otherwise use empty list
        List<Map<String, dynamic>> draftOrderItems = [];
        double draftTotalAmount = 0.0;

        if (draft['product_price'] != null) {
          draftTotalAmount = (draft['product_price'] is num)
              ? draft['product_price'].toDouble()
              : double.tryParse(draft['product_price'].toString()) ?? 0.0;
        }

        // Try to get order items from draft
        if (draft['order_items'] != null && draft['order_items'] is List) {
          draftOrderItems =
              List<Map<String, dynamic>>.from(draft['order_items']);
        } else if (draft['product_id'] != null) {
          // If single product, create order item
          draftOrderItems = [
            {
              'product_id': draft['product_id'],
              'quantity': 1,
              'subtotal': draftTotalAmount,
            }
          ];
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BnplApplicationScreen(
              walletAccountId: widget.wallet_accounts_id!,
              totalOrderAmount: draftTotalAmount,
              orderItems: draftOrderItems,
              initialStep:
                  null, // Will be determined by draft progress automatically
            ),
          ),
        );
      } else {
        // No draft found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No draft applications found. Start a new application to create a draft.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading draft: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
