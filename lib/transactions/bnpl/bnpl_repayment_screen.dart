import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:provider/provider.dart';
import '../../services/252pay_api_service.dart';
import '../../utils/bnpl_utils.dart';
import '../../models/repayment_schedule.dart';
import '../../providers/HomeSliderandTransaction.dart';
import '../../providers/auth.dart';
import '../../models/http_exception.dart';

class BnplRepaymentScreen extends StatefulWidget {
  final String walletAccountId;
  final int? applicationId;

  const BnplRepaymentScreen({
    super.key,
    required this.walletAccountId,
    this.applicationId,
  });

  @override
  State<BnplRepaymentScreen> createState() => _BnplRepaymentScreenState();
}

class _BnplRepaymentScreenState extends State<BnplRepaymentScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final api = ApiService();

  bool isLoading = true;
  bool isProcessingPayment = false;
  bool isVerifyingPin = false;
  List<RepaymentSchedule> schedules = [];
  String? selectedPaymentStatus;
  String pinNumber = "";

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules({String? paymentStatus}) async {
    if (!mounted) {
      api.appLog("⚠️ Widget not mounted, cannot load schedules");
      return;
    }

    // Set loading state (but don't clear schedules - keep them visible while loading)
    if (mounted) {
    setState(() {
      isLoading = true;
      selectedPaymentStatus = paymentStatus;
        // DON'T clear schedules - keep them visible while refreshing
    });
      api.appLog("🔄 isLoading set to true, starting load...");
      api.appLog("   - Current schedules count: ${schedules.length}");
    }

    try {
      api.appLog("📥 Loading repayment schedules...");
      final data = await api
          .getRepaymentSchedules(
        widget.walletAccountId,
        applicationId: widget.applicationId,
        paymentStatus: paymentStatus,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      api.appLog("✅ Received ${data.length} repayment schedules");

      if (!mounted) {
        api.appLog("⚠️ Widget not mounted, skipping state update");
        return;
      }

      // Parse schedules
      final parsedSchedules = data
          .map((e) {
            try {
              final schedule = RepaymentSchedule.fromJson(e);
              // Log if amount is null or zero for debugging
              if (schedule.amount == null || schedule.amount == 0) {
                api.appLog("⚠️ Repayment Schedule has null/zero amount");
                api.appLog("   - Raw data: $e");
                api.appLog("   - Parsed amount: ${schedule.amount}");
              }
              return schedule;
            } catch (parseError) {
              api.appLog("⚠️ Error parsing repayment schedule: $parseError");
              api.appLog("   - Data: $e");
              return null;
            }
          })
          .whereType<RepaymentSchedule>()
          .toList();

      // Update state only if still mounted
      if (mounted) {
      setState(() {
          schedules = parsedSchedules;
        isLoading = false;
      });
        api.appLog("✅ State updated with ${schedules.length} schedules");
      } else {
        api.appLog("⚠️ Widget unmounted before state update");
      }

      api.appLog("✅ Schedules loaded successfully: ${schedules.length} items");
    } catch (e) {
      api.appLog("❌ Error loading schedules: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError('Failed to load repayment schedules: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _makePayment(RepaymentSchedule schedule) async {
    if (schedule.paymentStatus == 'paid') {
      _showError('This installment is already paid');
      return;
    }

    final paymentAmount = schedule.installmentAmount ?? schedule.amount ?? 0.0;
    final installmentNumber = schedule.installmentNumber ?? schedule.id ?? 0;

    if (paymentAmount <= 0) {
      api.appLog("⚠️ Invalid payment amount: $paymentAmount");
      api.appLog(
          "   - schedule.installmentAmount: ${schedule.installmentAmount}");
      api.appLog("   - schedule.amount: ${schedule.amount}");
      _showError('Invalid payment amount. Please contact support.');
      return;
    }

    if (installmentNumber == 0) {
      api.appLog("⚠️ Invalid installment number");
      _showError('Invalid installment information. Please contact support.');
      return;
    }

    // Step 1: Show initial confirmation dialog
    final initialConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Pay ${BnplUtils.formatCurrency(paymentAmount)} for installment #$installmentNumber?',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Pay',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (initialConfirmed != true) return;

    // Step 2: Verify PIN
    bool pinVerified = await _showPinConfirmationDialog();
    if (!pinVerified) {
      return; // User cancelled or PIN verification failed
    }

    // Step 2: Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Step 3: Get wallet account info and merchant account
      final accountInfoResponse =
          await api.getAcountInfo(widget.walletAccountId);
      final merchantAccountResponse = await api.fetchmerchantAccount();

      if (accountInfoResponse.isEmpty || merchantAccountResponse.isEmpty) {
        Navigator.of(context).pop(); // Close loading
        _showError('Failed to load account information');
        return;
      }

      final accountInfo = accountInfoResponse.first;
      final merchantAccount = merchantAccountResponse.first;
      final merchantAccountNo = merchantAccount['merchant_account'];

      // Step 4: Get merchant info
      final merchantInfoResponse = await api.getMerchantInfo(merchantAccountNo);
      if (merchantInfoResponse.isEmpty) {
        Navigator.of(context).pop(); // Close loading
        _showError('Failed to load merchant information');
        return;
      }

      final merchantInfo = merchantInfoResponse.first;

      // Step 5: Extract currency information
      final double balance =
          double.tryParse(accountInfo['balance'].toString()) ?? 0.0;
      final String walletCurrency = accountInfo['currency_name'] ?? 'USD';
      final String merchantCurrency = merchantInfo['currency_name'] ?? 'USD';
      final String walletCurrencyId =
          accountInfo['currency_id']?.toString() ?? '';
      final String merchantCurrencyId =
          merchantInfo['currency_id']?.toString() ?? '';

      // Step 6: Balance check - must be done before exchange calculation
      if (balance <= 0.0) {
        Navigator.of(context).pop(); // Close loading
        _showError('Your wallet balance is zero. Insufficient balance.');
        return;
      }

      // Step 7: Close loading dialog before showing confirmation (will show again for exchange if needed)
      Navigator.of(context).pop();

      // Step 8: Handle currency exchange if needed
      if (walletCurrency.toUpperCase() != merchantCurrency.toUpperCase()) {
        // Currencies differ - need exchange
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          // Exchange: Convert paymentAmount (in merchant currency) to wallet currency
          // API: getExchangeInfo(currencyFromId, currencyToId, amountFrom)
          // We want: Convert paymentAmount USD to ZAR, so we pass (merchantCurrencyId, walletCurrencyId, paymentAmount)
          final exchangeData = await api.getExchangeInfo(
            merchantCurrencyId, // From: merchant currency (USD)
            walletCurrencyId, // To: wallet currency (ZAR)
            paymentAmount, // Amount in merchant currency
          );

          Navigator.of(context).pop(); // Close loading

          // amount_to is the converted amount in wallet currency (ZAR)
          final double amountFrom =
              double.tryParse(exchangeData['amount_to']?.toString() ?? '') ??
                  double.tryParse(
                      exchangeData['amount_to_usds']?.toString() ?? '') ??
                  0.0;
          final double amountTo =
              paymentAmount; // Amount in merchant currency (USD)

          // Validate exchange result
          if (amountFrom <= 0) {
            _showError(
                'Exchange calculation failed: Invalid exchange rate or amount.');
            return;
          }

          // Check balance
          if (balance <= 0) {
            Navigator.of(context).pop(); // Close loading if still open
            _showError('Your wallet balance is zero. Insufficient balance.');
            return;
          }

          if (balance < amountFrom) {
            _showError(
                'Your balance (${BnplUtils.formatCurrency(balance)}) is less than the amount to be paid (${BnplUtils.formatCurrency(amountFrom)}). Insufficient balance.');
            return;
          }

          // Show payment confirmation with exchange
          await _showPaymentConfirmationDialog(
            schedule: schedule,
            installmentNumber: installmentNumber,
            amountFrom: amountFrom,
            amountTo: amountTo,
            currencyFrom: walletCurrency,
            currencyTo: merchantCurrency,
            currencyFromId: walletCurrencyId,
            currencyToId: merchantCurrencyId,
            merchantAccount: merchantAccountNo,
          );
        } catch (e) {
          Navigator.of(context).pop(); // Close loading if still open
          api.appLog("❌ Exchange error: $e");
          _showError(
              'Exchange calculation failed: ${e.toString()}. Please try again or contact support.');
        }
      } else {
        // Same currency - no exchange needed
        // Still check balance before showing confirmation
        if (balance < paymentAmount) {
          _showError(
              'Your balance (${BnplUtils.formatCurrency(balance)}) is less than the amount to be paid (${BnplUtils.formatCurrency(paymentAmount)}). Insufficient balance.');
          return;
        }

        await _showPaymentConfirmationDialog(
          schedule: schedule,
          installmentNumber: installmentNumber,
          amountFrom: paymentAmount,
          amountTo: paymentAmount,
          currencyFrom: walletCurrency,
          currencyTo: merchantCurrency,
          currencyFromId: walletCurrencyId,
          currencyToId: merchantCurrencyId,
          merchantAccount: merchantAccountNo,
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Ensure loading dialog is closed
      _showError('Payment process failed: $e');
    }
  }

  Future<bool> _showPinConfirmationDialog() async {
    bool result = false;
    String currentPin = "";

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setModalState) {
            Future<void> verifyPin(String code) async {
              if (code.length != 4 || isVerifyingPin) return;

              setModalState(() {
                isVerifyingPin = true;
              });

              pinNumber = code;
              bool isValid = await _checkPinNumber();

              setModalState(() {
                isVerifyingPin = false;
              });

              if (isValid && mounted) {
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
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  OtpTextField(
                    numberOfFields: 4,
                    borderColor: primaryColor,
                    obscureText: true,
                    onCodeChanged: (String code) {
                      currentPin = code;
                      if (code.length == 4 && !isVerifyingPin) {
                        // Auto-verify when 4 digits are entered
                        verifyPin(code);
                      }
                    },
                    onSubmit: (String code) async {
                      currentPin = code;
                      if (code.length == 4 && !isVerifyingPin) {
                        await verifyPin(code);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (isVerifyingPin)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: <Widget>[
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isVerifyingPin
                          ? null
                          : () async {
                              if (currentPin.length != 4) {
                                _showError('Please enter a 4-digit PIN.');
                                return;
                              }
                              await verifyPin(currentPin);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Pin',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
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

  Future<bool> _checkPinNumber() async {
    try {
      final auth = Provider.of<Auth>(context, listen: false);
      final phone = auth.phone;

      if (phone == null || phone.isEmpty) {
        _showError('Phone number is not available. Please log in again.');
        return false;
      }

      if (pinNumber.isEmpty || pinNumber.length != 4) {
        _showError('Please enter a valid 4-digit PIN.');
        return false;
      }

      await Provider.of<HomeSliderAndTransaction>(context, listen: false)
          .LoginPIN(
        phone,
        pinNumber,
      );
      return true;
    } on HttpException catch (error) {
      if (error.toString().contains('INVALID_PHONE')) {
        _showError('Could not find a user with that phone.');
      } else if (error.toString().contains('INVALID_PIN')) {
        _showError('Invalid PIN.');
      } else if (error.toString().contains('INACTIVE_ACCOUNT')) {
        _showError('Your Account is not Active.');
      } else if (error.toString().contains('OP')) {
        _showError('Operation failed.');
      } else {
        _showError(error.toString());
      }
      return false;
    } catch (error) {
      api.appLog("❌ PIN verification error: $error");
      _showError('PIN verification failed: ${error.toString()}');
      return false;
    }
  }

  Future<void> _showPaymentConfirmationDialog({
    required RepaymentSchedule schedule,
    required int installmentNumber,
    required double amountFrom,
    required double amountTo,
    required String currencyFrom,
    required String currencyTo,
    required String currencyFromId,
    required String currencyToId,
    required String merchantAccount,
  }) async {
    // Capture screen context so loading dialog is shown/closed on correct navigator stack
    final screenContext = context;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.credit_card,
                          color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm Payment',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            'Installment #$installmentNumber',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Installment Payment Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Installment Payment',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              'Installment #$installmentNumber',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Currency Fields
                _buildCurrencyField(
                  icon: Icons.account_balance_wallet,
                  label: 'From Currency',
                  value: currencyFrom,
                ),
                const SizedBox(height: 12),
                _buildCurrencyField(
                  icon: Icons.money,
                  label: 'From Amount',
                  value: '${amountFrom.toStringAsFixed(2)} $currencyFrom',
                ),
                const SizedBox(height: 12),
                _buildCurrencyField(
                  icon: Icons.currency_exchange,
                  label: 'To Currency',
                  value: currencyTo,
                ),
                const SizedBox(height: 12),
                _buildCurrencyField(
                  icon: Icons.attach_money,
                  label: 'To Amount',
                  value: '${amountTo.toStringAsFixed(2)} $currencyTo',
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: amountFrom > 0 && amountTo > 0
                            ? () async {
                                // Close confirmation dialog first
                                Navigator.pop(context);

                                // Wait a bit to ensure dialog is closed
                                await Future.delayed(
                                    const Duration(milliseconds: 100));

                                // Check if still mounted
                                if (!mounted) return;

                                // Show loading on screen's navigator (so we can close it later)
                                showDialog(
                                  context: screenContext,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                      child: CircularProgressIndicator()),
                                );

                                try {
                                  api.appLog("💳 Starting payment process...");
                                  api.appLog("   - Amount From: $amountFrom");
                                  api.appLog("   - Amount To: $amountTo");
                                  api.appLog(
                                      "   - Schedule ID: ${schedule.scheduleId ?? schedule.id}");

                                  // Step 1: Purchase order (deduct from wallet, credit merchant)
                                  api.appLog(
                                      "📤 Step 1: Calling purchaseOrder...");
                                  try {
                                    await api
                                        .purchaseOrder(
                                      walletAccount: widget.walletAccountId,
                                      merchantAccount: merchantAccount,
                                      currencyFromId: currencyFromId,
                                      currencyToId: currencyToId,
                                      amountFrom: amountFrom,
                                      amountTo: amountTo,
                                    )
                                        .timeout(
                                      const Duration(seconds: 30),
                                      onTimeout: () {
                                        throw Exception(
                                            'Purchase order request timed out. Please try again.');
                                      },
                                    );
                                    api.appLog(
                                        "✅ Step 1: purchaseOrder completed");
                                  } catch (e) {
                                    api.appLog(
                                        "❌ Step 1: purchaseOrder failed: $e");
                                    rethrow;
                                  }

                                  // Step 2: Record BNPL payment
                                  final scheduleId =
                                      schedule.scheduleId ?? schedule.id;
                                  if (scheduleId == null) {
                                    throw Exception('Schedule ID is missing');
                                  }

                                  api.appLog(
                                      "📤 Step 2: Calling makeBnplPayment...");
                                  try {
                                    await api
                                        .makeBnplPayment(
                                      scheduleId: scheduleId,
                                      walletAccount: widget.walletAccountId,
                                      amount: amountTo,
                                      paymentMethod: 'wallet',
                                    )
                                        .timeout(
                                      const Duration(seconds: 30),
                                      onTimeout: () {
                                        throw Exception(
                                            'Payment recording request timed out. Please check if payment was processed.');
                                      },
                                    );
                                    api.appLog(
                                        "✅ Step 2: makeBnplPayment completed");
                                  } catch (e) {
                                    api.appLog(
                                        "❌ Step 2: makeBnplPayment failed: $e");
                                    rethrow;
                                  }

                                  // Close loading dialog (use screen context so it actually closes)
                                  if (mounted) {
                                    try {
                                      Navigator.of(screenContext).pop();
                                    } catch (e) {
                                      api.appLog(
                                          "⚠️ Error closing loading dialog: $e");
                                    }
                                  }

                                  // Show success message
                                  if (mounted) {
                                    api.appLog(
                                        "✅ Payment process completed successfully");
                                    _showSuccess('Payment successful!');
                                    // Reload schedules after a short delay to ensure message is visible
                                    await Future.delayed(
                                        const Duration(milliseconds: 1000));
                                    if (mounted) {
                                      api.appLog(
                                          "🔄 Refreshing schedules after payment...");
                                      await _loadSchedules(
                                          paymentStatus: selectedPaymentStatus);
                                      api.appLog(
                                          "✅ Schedule refresh completed");
                                    }
                                  }
                                } catch (e) {
                                  api.appLog("❌ Payment error caught: $e");
                                  api.appLog(
                                      "   - Error type: ${e.runtimeType}");

                                  // Close loading dialog (use screen context so it actually closes)
                                  if (mounted) {
                                    try {
                                      Navigator.of(screenContext).pop();
                                    } catch (navError) {
                                      api.appLog(
                                          "⚠️ Error closing loading dialog: $navError");
                                    }
                                  }

                                  // Show error message
                                  if (mounted) {
                                    final errorMessage = e
                                        .toString()
                                        .replaceAll('Exception: ', '');
                                    _showError('Payment failed: $errorMessage');
                                  }
                                }
                              }
                            : null, // Disable button if amounts are invalid
                        icon: const Icon(Icons.check,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Confirm & Pay',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    try {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      api.appLog("⚠️ Error showing error message: $e");
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    try {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(
      SnackBar(
            content: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
        backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
      ),
    );
      }
    } catch (e) {
      api.appLog("⚠️ Error showing success message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingSchedules =
        schedules.where((s) => s.paymentStatus == 'pending').toList();
    final paidSchedules =
        schedules.where((s) => s.paymentStatus == 'paid').toList();
    final overdueSchedules = schedules.where((s) => s.isOverdue).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Repayment Schedule',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'all') {
                _loadSchedules();
              } else {
                _loadSchedules(paymentStatus: value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'paid', child: Text('Paid')),
              const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSchedules(paymentStatus: selectedPaymentStatus),
        child: isLoading && schedules.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : schedules.isEmpty
                ? _buildEmptyState()
                : Stack(
                    children: [
                      // Show schedules even while loading (for refresh scenario)
                      SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (overdueSchedules.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                    Icon(Icons.warning,
                                        color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You have ${overdueSchedules.length} overdue payment(s)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (pendingSchedules.isNotEmpty) ...[
                          Text(
                            'Pending Payments',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                              ...pendingSchedules.map(
                                  (schedule) => _buildScheduleCard(schedule)),
                          const SizedBox(height: 24),
                        ],
                        if (paidSchedules.isNotEmpty) ...[
                          Text(
                            'Paid Installments',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                              ...paidSchedules.map(
                                  (schedule) => _buildScheduleCard(schedule)),
                        ],
                      ],
                    ),
                      ),
                      // Show loading overlay on top if loading and schedules exist
                      if (isLoading && schedules.isNotEmpty)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No repayment schedules found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(RepaymentSchedule schedule) {
    final isPaid = schedule.paymentStatus == 'paid';
    final isOverdue = schedule.isOverdue;
    final statusColor = isPaid
        ? Colors.green
        : isOverdue
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Installment #${schedule.installmentNumber ?? schedule.id ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    schedule.paymentStatus?.toUpperCase() ?? 'PENDING',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Due Date',
              BnplUtils.formatDate(schedule.dueDate),
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Amount',
              BnplUtils.formatCurrency(schedule.installmentAmount),
            ),
            if (isPaid && schedule.paymentDate != null) ...[
              _buildInfoRow(
                Icons.check_circle,
                'Paid Date',
                BnplUtils.formatDate(schedule.paymentDate),
              ),
              if (schedule.paymentMethod != null)
                _buildInfoRow(
                  Icons.payment,
                  'Payment Method',
                  schedule.paymentMethod ?? 'N/A',
                ),
            ],
            if (!isPaid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _makePayment(schedule),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOverdue ? Colors.red : primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isOverdue ? 'Pay Now (Overdue)' : 'Pay Installment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
