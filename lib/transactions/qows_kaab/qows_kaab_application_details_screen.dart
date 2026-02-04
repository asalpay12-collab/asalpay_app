import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../../services/252pay_api_service.dart';
import '../../providers/auth.dart';
import '../../providers/HomeSliderandTransaction.dart';
import '../../models/http_exception.dart';
import 'qows_kaab_payments_history_screen.dart';

class QowsKaabApplicationDetailsScreen extends StatefulWidget {
  final int qowsKaabId;
  final String walletAccountId;

  const QowsKaabApplicationDetailsScreen({
    super.key,
    required this.qowsKaabId,
    required this.walletAccountId,
  });

  @override
  State<QowsKaabApplicationDetailsScreen> createState() =>
      _QowsKaabApplicationDetailsScreenState();
}

class _QowsKaabApplicationDetailsScreenState
    extends State<QowsKaabApplicationDetailsScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();

  Map<String, dynamic>? applicationData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await api.getQowsKaabApplicationDetails(widget.qowsKaabId);
      setState(() {
        applicationData = data['application'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  bool get isDailyCredit =>
      _str(applicationData?['service_model']) == 'daily_credit';

  /// True when at least one payment has been made (so View Payment History is shown).
  bool _hasPaymentStarted() {
    if (applicationData == null) return false;
    final v = applicationData!['total_paid_amount'];
    if (v == null) return false;
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    return n != null && n > 0;
  }

  String _str(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  String _formatAmount(dynamic v) {
    if (v == null) return '\$0.00';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return '\$0.00';
    return '\$${n.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic v) {
    if (v == null) return 'N/A';
    final s = v.toString();
    if (s.isEmpty) return 'N/A';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Color _getStatusColor(String status) {
    if (status.isEmpty) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Application Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : applicationData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Application Information (sawirka 1) ---
                          Text(
                            'Application Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: br12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(
                                    'Application Number',
                                    _str(applicationData!['application_number'])
                                            .isEmpty
                                        ? 'N/A'
                                        : _str(applicationData![
                                            'application_number']),
                                  ),
                                  _buildDetailRow(
                                    'Service Model',
                                    _str(applicationData!['service_model'])
                                            .isEmpty
                                        ? 'N/A'
                                        : _str(
                                            applicationData!['service_model']),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Status',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(_str(
                                                        applicationData![
                                                            'status']))
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getStatusColor(_str(
                                                      applicationData![
                                                          'status'])),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _str(applicationData![
                                                                    'status'])
                                                                .toLowerCase() ==
                                                            'active'
                                                        ? Icons.check_circle
                                                        : Icons.info_outline,
                                                    size: 18,
                                                    color: _getStatusColor(_str(
                                                        applicationData![
                                                            'status'])),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    (_str(applicationData![
                                                                    'status'])
                                                                .isEmpty
                                                            ? 'N/A'
                                                            : _str(
                                                                applicationData![
                                                                    'status']))
                                                        .toUpperCase(),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _getStatusColor(
                                                          _str(applicationData![
                                                              'status'])),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(Icons.info_outline,
                                                size: 18,
                                                color: Colors.grey.shade500),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (applicationData!['pack_total_amount'] !=
                                      null)
                                    _buildDetailRow(
                                        'Pack Amount',
                                        _formatAmount(applicationData![
                                            'pack_total_amount'])),
                                  if (applicationData!['daily_credit_limit'] !=
                                      null)
                                    _buildDetailRow(
                                        'Daily Credit Limit',
                                        _formatAmount(applicationData![
                                            'daily_credit_limit'])),
                                  if (applicationData![
                                          'payment_due_next_month'] !=
                                      null)
                                    _buildDetailRow(
                                        'Payment Due',
                                        _formatDate(applicationData![
                                            'payment_due_next_month'])),
                                  if (applicationData!['monthly_payment_due'] !=
                                      null)
                                    _buildDetailRow(
                                        'Payment Due',
                                        _formatDate(applicationData![
                                            'monthly_payment_due'])),
                                  if (applicationData!['family_size'] != null)
                                    _buildDetailRow('Family Size',
                                        _str(applicationData!['family_size'])),
                                  if (applicationData!['usage_type'] != null &&
                                      _str(applicationData!['usage_type'])
                                          .isNotEmpty)
                                    _buildDetailRow('Usage Type',
                                        _str(applicationData!['usage_type'])),
                                ],
                              ),
                            ),
                          ),
                          // --- Payment Progress (sawirka 1 & 2) ---
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.credit_card,
                                  color: primaryColor, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: br12,
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.more_horiz,
                                        color: Colors.orange.shade700,
                                        size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Payment progress is pending',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Application Total',
                                  _formatAmount(
                                      applicationData!['pack_total_amount'] ??
                                          0),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Outstanding',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        _formatAmount(applicationData![
                                                'total_outstanding'] ??
                                            applicationData![
                                                'pack_total_amount'] ??
                                            0),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: _showPaymentAmountModal,
                                    icon:
                                        const Icon(Icons.credit_card, size: 22),
                                    label: Text(
                                      'Pay Now',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: br12),
                                    ),
                                  ),
                                ),
                                if (_hasPaymentStarted()) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                QowsKaabPaymentsHistoryScreen(
                                              walletAccountId:
                                                  widget.walletAccountId,
                                              qowsKaabId: widget.qowsKaabId,
                                            ),
                                          ),
                                        ).then((_) => _loadDetails());
                                      },
                                      icon: const Icon(
                                          Icons.history, size: 22),
                                      label: Text(
                                        'View Payment History',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: BorderSide(
                                            color: primaryColor, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: br12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isDailyCredit) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.credit_card_outlined,
                                    size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Daily Credit: Daily payments based on monthly total',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  static const double _minDailyPayment = 1.0;

  Future<void> _showPaymentAmountModal() async {
    try {
      final response = await api.getQowsKaabPaymentDue(
        walletAccount: widget.walletAccountId,
        qowsKaabId: widget.qowsKaabId,
      );
      final paymentData = response['data'];
      if (paymentData == null || paymentData is! Map) {
        if (mounted) _showSnack('No payment due found.', isError: true);
        return;
      }
      final paymentId = paymentData['payment_id'];
      if (paymentId == null) {
        if (mounted) _showSnack('Payment information incomplete.', isError: true);
        return;
      }
      final amountDue = (paymentData['amount_due'] is num)
          ? (paymentData['amount_due'] as num).toDouble()
          : double.tryParse(paymentData['amount_due']?.toString() ?? '') ?? 0.0;
      final maxAllowed = (applicationData!['total_outstanding'] is num)
          ? (applicationData!['total_outstanding'] as num).toDouble()
          : double.tryParse(applicationData!['total_outstanding']?.toString() ?? '') ?? amountDue;
      final isDaily = _str(applicationData!['service_model']) == 'daily_credit';
      final showMinWarning = isDaily && amountDue < _minDailyPayment;

      // Payment currency: from backend (252pay) or from dev2 (Wallet_merchant_transfer/fill_merchant_info) when ID empty
      String paymentCurrencyNameDisplay = (paymentData['payment_currency_name'] ?? 'USD').toString();
      String paymentCurrencyId = paymentData['payment_currency_id']?.toString() ?? '';
      if (paymentCurrencyId.isEmpty) {
        try {
          final merchants = await api.fetchmerchantAccount();
          if (merchants.isNotEmpty && merchants.first['merchant_account'] != null) {
            final merchantInfo = await api.getMerchantInfo(merchants.first['merchant_account'].toString());
            if (merchantInfo.isNotEmpty) {
              paymentCurrencyNameDisplay = (merchantInfo.first['currency_name'] ?? 'USD').toString();
              paymentCurrencyId = merchantInfo.first['currency_id']?.toString() ?? '';
            }
          }
        } catch (_) {}
      }
      final paymentCurrencyName = paymentCurrencyNameDisplay.toUpperCase();

      // Wallet currency from dev2 (same API as My Profile: Wallet_dashboard/fill_Account_balances)
      List<Map<String, dynamic>> walletInfoList = [];
      try {
        walletInfoList = await api.getAccountBalancesFromDashboard(widget.walletAccountId);
      } catch (_) {}
      final walletCurrencyName = (walletInfoList.isNotEmpty ? (walletInfoList.first['currency_name'] ?? 'USD') : 'USD').toString().toUpperCase();
      final walletCurrencyId = (walletInfoList.isNotEmpty ? walletInfoList.first['currency_id']?.toString() : '') ?? '';
      final currenciesDiffer = walletCurrencyId.isNotEmpty &&
          paymentCurrencyId.isNotEmpty &&
          walletCurrencyName != paymentCurrencyName;

      // Always show short "Payment Amount" dialog first (140823); only after Continue go to next step
      final amountController = TextEditingController(
        text: amountDue > 0 ? amountDue.toStringAsFixed(2) : '0',
      );

      if (!mounted) return;
      final double? proceedAmount = await showDialog<double>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final amountText = amountController.text;
              final amount = double.tryParse(amountText) ?? 0;
              final needMin = isDaily && amount > 0 && amount < _minDailyPayment;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: br12),
                title: Row(
                  children: [
                    Icon(Icons.edit, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Amount',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
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
                        'Enter the payment amount:',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: br12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Daily Due Amount:', style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue.shade800)),
                            Text(
                              '\$${amountDue.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: br12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Maximum Allowed:', style: GoogleFonts.poppins(fontSize: 14, color: Colors.green.shade800)),
                            Text(
                              '\$${maxAllowed.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: br12),
                          errorBorder: OutlineInputBorder(
                            borderRadius: br12,
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              amountController.text = amountDue.toStringAsFixed(2);
                              setDialogState(() {});
                            },
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      if (showMinWarning || needMin) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Only amount allowed is \$${_minDailyPayment.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Exchange rate will be calculated after confirmation',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: primaryColor)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final a = double.tryParse(amountController.text) ?? 0;
                      if (a <= 0 || a > maxAllowed) {
                        _showSnack('Enter a valid amount between \$${_minDailyPayment.toStringAsFixed(0)} and \$${maxAllowed.toStringAsFixed(2)}.', isError: true);
                        return;
                      }
                      if (isDaily && a < _minDailyPayment) {
                        _showSnack('Minimum payment is \$${_minDailyPayment.toStringAsFixed(0)}. Amounts less than \$${_minDailyPayment.toStringAsFixed(0)} are not allowed.', isError: true);
                        return;
                      }
                      Navigator.pop(context, a);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: Text('Continue', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        amountController.dispose();
      });
      if (proceedAmount != null && proceedAmount > 0) {
        if (currenciesDiffer && mounted) {
          final double? confirmedAmount = await _showCurrencyConversionModal(
            paymentId: (paymentId is int) ? paymentId : int.tryParse(paymentId.toString()) ?? 0,
            amountDue: amountDue,
            maxAllowed: maxAllowed,
            initialPaymentAmount: proceedAmount,
            walletCurrencyName: walletInfoList.isNotEmpty ? (walletInfoList.first['currency_name'] ?? 'USD').toString() : 'USD',
            walletCurrencyId: walletCurrencyId,
            paymentCurrencyName: paymentCurrencyNameDisplay,
            paymentCurrencyId: paymentCurrencyId,
            period: _formatDate(applicationData!['payment_period'] ?? applicationData!['created_at']),
          );
          if (confirmedAmount != null && confirmedAmount > 0) {
            await _showPinModalAndPay(
              amount: confirmedAmount,
              paymentId: (paymentId is int) ? paymentId : int.tryParse(paymentId.toString()) ?? 0,
              walletCurrencyId: walletCurrencyId,
              paymentCurrencyId: paymentCurrencyId,
            );
          }
        } else {
          await _showPinModalAndPay(
            amount: proceedAmount,
            paymentId: (paymentId is int) ? paymentId : int.tryParse(paymentId.toString()) ?? 0,
            walletCurrencyId: walletCurrencyId,
            paymentCurrencyId: paymentCurrencyId,
          );
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Error: ${e.toString()}', isError: true);
    }
  }

  Future<double?> _showCurrencyConversionModal({
    required int paymentId,
    required double amountDue,
    required double maxAllowed,
    double? initialPaymentAmount,
    required String walletCurrencyName,
    required String walletCurrencyId,
    required String paymentCurrencyName,
    required String paymentCurrencyId,
    required String period,
  }) async {
    if (!mounted) return null;
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyConversionDialogContent(
        api: api,
        primaryColor: primaryColor,
        br12: br12,
        minDailyPayment: _minDailyPayment,
        paymentId: paymentId,
        amountDue: amountDue,
        maxAllowed: maxAllowed,
        initialPaymentAmount: initialPaymentAmount ?? amountDue,
        walletCurrencyName: walletCurrencyName,
        walletCurrencyId: walletCurrencyId,
        paymentCurrencyName: paymentCurrencyName,
        paymentCurrencyId: paymentCurrencyId,
        period: period,
        showSnack: _showSnack,
      ),
    );
  }

  Future<void> _showPinModalAndPay({
    required double amount,
    required int paymentId,
    String? walletCurrencyId,
    String? paymentCurrencyId,
    double? amountInWalletCurrency,
  }) async {
    String pinNumber = '';
    bool isVerifyingPin = false;

    // 1. Balance check before PIN (same API as My Profile: Wallet_dashboard/fill_Account_balances)
    List<Map<String, dynamic>> accountInfoList = [];
    try {
      accountInfoList = await api.getAccountBalancesFromDashboard(widget.walletAccountId);
    } catch (e) {
      if (mounted) {
        _showSnack(e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Could not load wallet balance.', isError: true);
      }
      return;
    }
    if (accountInfoList.isEmpty && mounted) {
      _showSnack('Could not load wallet balance. Please try again.', isError: true);
      return;
    }
    final double balance =
        double.tryParse(accountInfoList.first['balance']?.toString() ?? '') ?? 0.0;
    final String resolvedWalletCurrencyId =
        walletCurrencyId ?? accountInfoList.first['currency_id']?.toString() ?? '';
    final String resolvedPaymentCurrencyId = paymentCurrencyId ?? '';

    double amountToCompare = amount;
    if (resolvedWalletCurrencyId.isNotEmpty &&
        resolvedPaymentCurrencyId.isNotEmpty &&
        resolvedWalletCurrencyId != resolvedPaymentCurrencyId) {
      try {
        final exchangeResult = await api.getExchangeInfo(
          resolvedPaymentCurrencyId,
          resolvedWalletCurrencyId,
          amount,
        );
        amountToCompare = double.tryParse(exchangeResult['amount_to']?.toString() ?? '') ??
            double.tryParse(exchangeResult['amount_to_usds']?.toString() ?? '') ??
            amount;
      } catch (_) {
        amountToCompare = amount;
      }
    } else if (amountInWalletCurrency != null) {
      amountToCompare = amountInWalletCurrency;
    }

    if (balance <= 0) {
      if (mounted) _showSnack('Your wallet balance is zero. Insufficient balance.', isError: true);
      return;
    }
    if (balance < amountToCompare) {
      if (mounted) {
        _showSnack(
          'Insufficient balance. Your balance is \$${balance.toStringAsFixed(2)}.',
          isError: true,
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> verifyAndClose(bool success) async {
              if (success) Navigator.pop(context, true);
            }

            Future<void> verifyPin(String code) async {
              if (code.length != 4 || isVerifyingPin) return;
              setDialogState(() => isVerifyingPin = true);
              try {
                final auth = Provider.of<Auth>(context, listen: false);
                final phone = auth.phone;
                if (phone == null || phone.isEmpty) {
                  if (mounted) _showSnack('Phone number not available. Please log in again.', isError: true);
                  setDialogState(() => isVerifyingPin = false);
                  return;
                }
                await Provider.of<HomeSliderAndTransaction>(context, listen: false)
                    .LoginPIN(phone, code);
                await verifyAndClose(true);
              } on HttpException catch (e) {
                if (mounted) {
                  final msg = e.toString().contains('INVALID_PIN') ? 'Invalid PIN.' : e.toString();
                  _showSnack(msg, isError: true);
                }
                setDialogState(() => isVerifyingPin = false);
              } catch (e) {
                if (mounted) _showSnack('PIN verification failed.', isError: true);
                setDialogState(() => isVerifyingPin = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: br12),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Confirmation Pin',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          child: Icon(Icons.close, color: primaryColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter 4-digit Pin To Send Money and Subtract from Your Wallet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  OtpTextField(
                    numberOfFields: 4,
                    borderColor: primaryColor,
                    obscureText: true,
                    onCodeChanged: (String code) {
                      pinNumber = code;
                      if (code.length == 4 && !isVerifyingPin) verifyPin(code);
                    },
                    onSubmit: (String code) async {
                      pinNumber = code;
                      if (code.length == 4 && !isVerifyingPin) await verifyPin(code);
                    },
                  ),
                  if (isVerifyingPin)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isVerifyingPin
                          ? null
                          : () async {
                              if (pinNumber.length != 4) {
                                _showSnack('Please enter a 4-digit PIN.', isError: true);
                                return;
                              }
                              await verifyPin(pinNumber);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: br12),
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

    if (confirmed != true) return;

    // 2. Debit wallet via purchaseOrder, then record via makeQowsKaabPayment (plan)
    try {
      final merchants = await api.fetchmerchantAccount();
      if (merchants.isEmpty || merchants.first['merchant_account'] == null) {
        if (mounted) _showSnack('Merchant account not available. Please try again.', isError: true);
        return;
      }
      final merchantAccountNo = merchants.first['merchant_account'].toString();
      final merchantInfoList = await api.getMerchantInfo(merchantAccountNo);
      if (merchantInfoList.isEmpty) {
        if (mounted) _showSnack('Merchant information not available. Please try again.', isError: true);
        return;
      }

      final String currencyFromId = resolvedWalletCurrencyId.isNotEmpty
          ? resolvedWalletCurrencyId
          : (accountInfoList.first['currency_id']?.toString() ?? '');
      final String currencyToId = resolvedPaymentCurrencyId.isNotEmpty
          ? resolvedPaymentCurrencyId
          : (merchantInfoList.first['currency_id']?.toString() ?? currencyFromId);
      final double amountFrom = (currencyFromId != currencyToId) ? amountToCompare : amount;
      final double amountTo = amount;

      await api.purchaseOrder(
        walletAccount: widget.walletAccountId,
        merchantAccount: merchantAccountNo,
        currencyFromId: currencyFromId,
        currencyToId: currencyToId,
        amountFrom: amountFrom,
        amountTo: amountTo,
      );

      await api.makeQowsKaabPayment(
        paymentId: paymentId,
        amount: amount,
        paymentMethod: 'wallet',
      );
      if (mounted) {
        _showSnack('Payment successful!', isError: false);
        _loadDetails();
      }
    } catch (e) {
      if (mounted) _showSnack('Payment failed: ${e.toString()}', isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyConversionDialogContent extends StatefulWidget {
  final ApiService api;
  final Color primaryColor;
  final BorderRadius br12;
  final double minDailyPayment;
  final int paymentId;
  final double amountDue;
  final double maxAllowed;
  final double initialPaymentAmount;
  final String walletCurrencyName;
  final String walletCurrencyId;
  final String paymentCurrencyName;
  final String paymentCurrencyId;
  final String period;
  final void Function(String message, {required bool isError}) showSnack;

  const _CurrencyConversionDialogContent({
    required this.api,
    required this.primaryColor,
    required this.br12,
    required this.minDailyPayment,
    required this.paymentId,
    required this.amountDue,
    required this.maxAllowed,
    required this.initialPaymentAmount,
    required this.walletCurrencyName,
    required this.walletCurrencyId,
    required this.paymentCurrencyName,
    required this.paymentCurrencyId,
    required this.period,
    required this.showSnack,
  });

  @override
  State<_CurrencyConversionDialogContent> createState() => _CurrencyConversionDialogContentState();
}

class _CurrencyConversionDialogContentState extends State<_CurrencyConversionDialogContent> {
  late TextEditingController _amountController;
  double? _fromAmount;
  bool _loadingExchange = false;
  bool _exchangeError = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialPaymentAmount > 0 ? widget.initialPaymentAmount.toStringAsFixed(2) : (widget.amountDue > 0 ? widget.amountDue.toStringAsFixed(2) : '1.00'),
    );
    _amountController.addListener(_onAmountChanged);
    _fetchExchange(double.tryParse(_amountController.text) ?? widget.initialPaymentAmount);
  }

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text);
    if (amount != null && amount > 0) _fetchExchange(amount);
  }

  Future<void> _fetchExchange(double amountInPaymentCurrency) async {
    if (widget.paymentCurrencyId.isEmpty || widget.walletCurrencyId.isEmpty) return;
    setState(() {
      _loadingExchange = true;
      _exchangeError = false;
    });
    try {
      final result = await widget.api.getExchangeInfo(
        widget.paymentCurrencyId,
        widget.walletCurrencyId,
        amountInPaymentCurrency,
      );
      final fromAmt = double.tryParse(result['amount_to']?.toString() ?? '') ??
          double.tryParse(result['amount_to_usds']?.toString() ?? '') ?? 0.0;
      if (mounted) {
        setState(() {
          _fromAmount = fromAmt;
          _loadingExchange = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fromAmount = null;
          _loadingExchange = false;
          _exchangeError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final paymentSymbol = widget.paymentCurrencyName.toUpperCase() == 'USD' ? '\$' : '${widget.paymentCurrencyName} ';
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: widget.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confirm Payment',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Icon(Icons.close, color: widget.primaryColor, size: 24),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.08),
                        borderRadius: widget.br12,
                        border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qows Kaab Payment',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: widget.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Period: ${widget.period}',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.account_balance_wallet, 'From Currency', widget.walletCurrencyName),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.money,
                      'From Amount',
                      _loadingExchange
                          ? '...'
                          : _exchangeError
                              ? '—'
                              : '${(_fromAmount ?? 0).toStringAsFixed(2)} ${widget.walletCurrencyName}',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.currency_exchange, 'To Currency', widget.paymentCurrencyName),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: widget.br12,
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Due Amount:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$paymentSymbol${widget.amountDue.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: widget.br12,
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Amount',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Minimum Payment:',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.blue.shade800),
                              ),
                              Text(
                                '$paymentSymbol${widget.minDailyPayment.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Maximum Allowed:',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                                ),
                                Text(
                                  '$paymentSymbol${widget.maxAllowed.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Enter Payment Amount',
                              prefixText: '$paymentSymbol ',
                              border: OutlineInputBorder(borderRadius: widget.br12),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  _amountController.text = widget.amountDue.toStringAsFixed(2);
                                  _fetchExchange(widget.amountDue);
                                },
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.attach_money,
                      'To Amount',
                      '$paymentSymbol${amount.toStringAsFixed(2)} ${widget.paymentCurrencyName}',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: Text('Cancel', style: GoogleFonts.poppins(color: widget.primaryColor, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final a = double.tryParse(_amountController.text) ?? 0;
                              if (a < widget.minDailyPayment) {
                                widget.showSnack(
                                  'Minimum payment is $paymentSymbol${widget.minDailyPayment.toStringAsFixed(0)}. Amounts less than that are not allowed.',
                                  isError: true,
                                );
                                return;
                              }
                              if (a <= 0 || a > widget.maxAllowed) {
                                widget.showSnack(
                                  'Enter a valid amount between $paymentSymbol${widget.minDailyPayment.toStringAsFixed(0)} and $paymentSymbol${widget.maxAllowed.toStringAsFixed(2)}.',
                                  isError: true,
                                );
                                return;
                              }
                              Navigator.pop(context, a);
                            },
                            icon: const Icon(Icons.check, color: Colors.white, size: 20),
                            label: Text('Confirm & Pay', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: bottomPadding + 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: widget.br12,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: widget.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
