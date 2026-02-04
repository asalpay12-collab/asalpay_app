
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../providers/auth.dart';
import '../services/252pay_api_service.dart';
import '../widgets/commonBtn.dart';
import 'DiscountProductsDrawer.dart';
import 'my_orders_screen.dart';

class DiscountProductPurchaseScreen extends StatefulWidget {
  const DiscountProductPurchaseScreen({super.key, required this.wallet_accounts_id});
  final String? wallet_accounts_id;

  @override
  State<DiscountProductPurchaseScreen> createState() => _ProductPurchaseScreenState();
}

class _ProductPurchaseScreenState extends State<DiscountProductPurchaseScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final Color bodyBg = Colors.white;
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();

  List<Category> categories = [];
  List<Product> products = [];
  List<Map<String, dynamic>> accountInfo = [];
  List<Map<String, dynamic>> PaymentPolicy = [];
  List<Map<String, dynamic>> merchantInfo = [];
  List<Map<String, dynamic>> orderItems = [];
  List<Map<String, dynamic>> merchnataccountInfo = [];
  static const String baseUrl = ApiService.imgURL;
  bool isLoading = true;
  String ModelErrorMessage = "";
  String pinNumber = "";

  @override
  void initState() {
    super.initState();
    _loadDiscountProducts();
  }

  Future<void> _loadDiscountProducts() async {
    setState(() {
      isLoading = true;
      products.clear();
    });

    try {
      final fetchedProducts = await api.fetchDiscuntProducts();
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(' $message '),
      backgroundColor: Colors.green,
    ));
  }

  void _showOrderDialog(Product product, double unitPrice,String remainingQuantity) {
    final quantityController = TextEditingController(text: '1');
    final totalController =
    TextEditingController(text: unitPrice.toStringAsFixed(2));

    void updateTotal() {
      final qty = int.tryParse(quantityController.text) ?? 1;
      final total = qty * unitPrice;
      totalController.text = total.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Order ${product.name}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity (Max: $remainingQuantity)',
                    errorText: int.tryParse(quantityController.text) != null &&
                        int.parse(quantityController.text) >  int.parse(remainingQuantity)
                        ? 'Exceeds available quantity'
                        : null,
                  ),
                  onChanged: (value) {
                    final enteredQty = int.tryParse(value) ?? 1;
                    if (enteredQty > int.parse(remainingQuantity)) {
                      quantityController.text = remainingQuantity.toString();
                      quantityController.selection = TextSelection.fromPosition(
                        TextPosition(offset: quantityController.text.length),
                      );
                    }
                    updateTotal();
                  },
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: totalController,
                  decoration: const InputDecoration(labelText: 'Total Price'),
                  enabled: false,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(quantityController.text) ?? 1;
                setState(() {
                  orderItems.add({
                    "product_id": product.id,
                    "quantity": qty,
                    "unit_price": unitPrice,
                    "name": product.name,
                  });

                });
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
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
          addressId:addressId,
          description: description,
          phone: phone,
          merchantAccount: merchantAccount,
          currencyFromId: currencyFromId,
          currencyToId: currencyToId,
          amountFrom: amountFrom,
          amountTo: amountTo
      );
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
                      maxHeight: constraints.maxHeight * 0.95, // Responsive limit
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
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                hint: const Text("Choose address"),
                                value: selectedAddressId,
                                items: customerAddresses.map((address) {
                                  return DropdownMenuItem<int>(
                                    value: int.tryParse(address['adress_id'].toString()),
                                    child: Text(address['district_name'] ?? 'Unknown District'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => selectedAddressId = value);
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
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (selectedAddressId == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('🚫 Please select a delivery address.'),
                                          ),
                                        );
                                        return;
                                      }

                                      if (descriptionController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('📝 Please enter a delivery description.'),
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
                                        walletAccount: widget.wallet_accounts_id,
                                      );

                                      _submitOrder(
                                          totalAmount: totalAmount,
                                          status: 'Paid',
                                          items: items,
                                          addressId: selectedAddressId!,
                                          description: descriptionController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          merchantAccount: merchantaccount,
                                          currencyFromId: currencyFromId,
                                          currencyToId: currencyToId,
                                          amountFrom: amountFrom,
                                          amountTo: amountTo
                                      );
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
      await Provider.of<HomeSliderAndTransaction>(context, listen: false).LoginPIN(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Confirmation Pin",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20) ??
                            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, color: primaryColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Enter 4-digit Pin To Send Money",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 16),
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
                      await verifyPin(code); // Also trigger check on keyboard done
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


  Future<void> submitPayNowOrder(double totalAmount, List<Map<String, dynamic>> items) async {
    try {
      // Step 1: Ask for pin and verify it
      bool pinVerified = await _showMyDialogConfirmPin();
      if (!pinVerified) return; // Cancel the process if verification fails

      // Step 2: Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await api.getAcountInfo(widget.wallet_accounts_id);
      final merchantAccount = await api.fetchmerchantAccount();

      accountInfo = List<Map<String, dynamic>>.from(response);
      merchnataccountInfo = List<Map<String, dynamic>>.from(merchantAccount);
      final account = merchnataccountInfo.first;
      final responseMerchant = await api.getMerchantInfo(account['merchant_account']);

      merchantInfo = List<Map<String, dynamic>>.from(responseMerchant);

      final user = accountInfo.first;
      final merchant = merchantInfo.first;

      final double balance = double.tryParse(user['balance'].toString()) ?? 0.0;
      final double paymentAmount = double.tryParse(totalAmount.toString()) ?? 0.0;

      final String walletCurrency = user['currency_name'];
      final String merchantCurrency = merchant['currency_name'];
      final String merchantcurrency_id = merchant['currency_id'];
      final String walletcurrency_id = user['currency_id'];

      // Balance checks
      if (balance == 0.0) {
        Navigator.of(context).pop(); // Close loading
        _showError("Your wallet balance is zero. Insufficient balance.");
        return;
      } else if (balance < paymentAmount) {
        Navigator.of(context).pop(); // Close loading
        _showError("Your balance is less than the amount to be paid.");
        return;
      }

      // Dismiss loading before showing bottom sheet
      Navigator.of(context).pop();

      if (walletCurrency == merchantCurrency) {
        await showPaymentConfirmationBottomSheet(
          amountFrom: paymentAmount,
          amountTo: paymentAmount,
          currencyFromId: walletcurrency_id,
          currencyToId: merchantcurrency_id,
          merchantCurrency: merchantCurrency,
          merchantaccount: account['merchant_account'],
          walletCurrency: walletCurrency,
          totalAmount: totalAmount,
          items: items,
        );
      } else {
        // Show loading again for exchange API
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final exchangeData = await api.getExchangeInfo(
          merchantcurrency_id,
          walletcurrency_id,
          paymentAmount,
        );

        Navigator.of(context).pop(); // Close loading dialog

        final double amountchanges = double.tryParse(exchangeData['amount_to'].toString()) ?? 0.0;

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
          merchantaccount: account['merchant_account'],
          walletCurrency: walletCurrency,
          totalAmount: totalAmount,
          items: items,
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Ensure dialog is closed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
    return SafeArea(   // <-- Wrap the whole Scaffold in SafeArea
      child: Scaffold(
        backgroundColor: bodyBg,
        appBar: AppBar(
          elevation: 2,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: Text(
            '252pay',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyOrdersScreen(
                      walletAccountId: widget.wallet_accounts_id!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
              label: Text(
                'View Orders',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildProductGrid(),
        ),
      ),
    );
  }




  Widget _buildProductGrid() {
    int crossAxisCount = MediaQuery.of(context).size.width < 600 ? 2 : 3;

    if (products.isEmpty) {
      return Center(
        child: Text(
          'No discounted products available.',
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
                    'Select Discounted Products',
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
                    childAspectRatio: 0.75, // Adjusted for enough vertical space
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, idx) {
                    final product = products[idx];
                    final originalPrice = double.tryParse(product.originalPrice) ?? 0.0;
                    final currentPrice = product.currentPrice;
                    final discountValue = product.discountValue;
                    final remainingQuantity = product.remainingQuantity;
                    final discountType = product.discountType.toLowerCase();
                    final endDate = product.edate;
                    final startDate = product.sdate;

                    String discountLabel = '';
                    if (discountType == 'percentage') {
                      discountLabel = '-${discountValue.toStringAsFixed(0)}%';
                    } else if (discountType == 'fixed') {
                      discountLabel = '-\$${discountValue.toStringAsFixed(2)}';
                    }

                    return InkWell(
                      borderRadius: br12,
                      child: ClipRRect(
                        borderRadius: br12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Prevents forcing full height
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.network(
                                  '$baseUrl/${product.imagePath}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Product Name
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

                              // Discount Label (if any)
                              if (discountLabel.isNotEmpty)
                                Text(
                                  discountLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                              const SizedBox(height: 2),

                              // Prices
                              Column(
                                children: [
                                  Text(
                                    '\$${originalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    '\$${currentPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 2),

                              // Available Quantity
                              Text(
                                'Available: $remainingQuantity',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Start-End Date
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$startDate - $endDate',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Order Button
                              SizedBox(
                                height: 32,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showOrderDialog(product, currentPrice, remainingQuantity);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: br12),
                                  ),
                                  child: const Text('Order', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(height: 4),

                              /// 🔹 "See Details" text button
                              GestureDetector(
                                onTap: () {
                                  _showPaymentPolicySheet(product);
                                },
                                child: Text(
                                  "See Details",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
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
            ),
          ),
        ),
        _buildBottomOrderPanel(),
      ],
    );
  }



  Widget _buildBottomOrderPanel() {
    if (orderItems.isEmpty) return const SizedBox.shrink();

    final total = orderItems.fold<double>(0.0, (sum, item) {
      return sum + ((item['quantity'] as int) * (item['unit_price'] as double));
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: br12,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Items',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3, // 30% of screen
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: orderItems.length,
                    itemBuilder: (_, i) {
                      final item = orderItems[i];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['name']} x${item['quantity']}',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                          Text(
                            '\$${(item['unit_price'] * item['quantity']).toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => orderItems.removeAt(i));
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    /// Pay Now
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            submitPayNowOrder(total, orderItems);
                          },
                          icon: const Icon(Icons.payment, size: 18),
                          label: Text(
                            'Pay Now',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "or",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    /// Pay Later
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _submitOrder(
                                totalAmount: total,
                                status: 'pending',
                                items: orderItems,
                                addressId: 0,
                                description: '',
                                phone: ''
                            );
                          },
                          icon: const Icon(Icons.send, size: 18),
                          label: Text(
                            'Pay later',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                    final months =
                        int.tryParse(policy['months_interval'].toString()) ?? 1;
                    final price =
                        double.tryParse(product.unitPrice.toString()) ?? 0.0;
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


}

