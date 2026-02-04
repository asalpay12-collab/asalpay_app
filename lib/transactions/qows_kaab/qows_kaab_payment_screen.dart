import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/Constant.dart';
import '../../services/qows_kaab_api_service.dart';

class QowsKaabPaymentScreen extends StatefulWidget {
  final String? walletAccountId;
  final int? qowsKaabId;

  const QowsKaabPaymentScreen({
    super.key,
    required this.walletAccountId,
    required this.qowsKaabId,
  });

  @override
  State<QowsKaabPaymentScreen> createState() => _QowsKaabPaymentScreenState();
}

class _QowsKaabPaymentScreenState extends State<QowsKaabPaymentScreen> {
  final QowsKaabApiService _apiService = QowsKaabApiService();
  Map<String, dynamic>? _paymentDue;
  bool _isLoading = true;
  bool _isProcessing = false;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentDue();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentDue() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getPaymentDue(
        walletAccount: widget.walletAccountId ?? '',
        qowsKaabId: widget.qowsKaabId,
      );
      setState(() {
        _paymentDue = result['data'];
        if (_paymentDue != null && _paymentDue!['amount_due'] != null) {
          _amountController.text = _paymentDue!['amount_due'].toString();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _makePayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Are you sure you want to pay \$${amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Confirm', style: TextStyle(color: pureWhite)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _apiService.makePayment(
        walletAccount: widget.walletAccountId ?? '',
        qowsKaabId: widget.qowsKaabId!,
        amount: amount,
      );

      if (result['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPaymentDue();
          _amountController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Payment failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondryColor,
      appBar: AppBar(
        title: const Text('QOWS KAAB Payment'),
        backgroundColor: primaryColor,
        foregroundColor: pureWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentDue == null
              ? const Center(child: Text('No payment information available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: secondryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                'Credit Limit',
                                '\$${(_paymentDue!['credit_limit'] ?? 0.0).toStringAsFixed(2)}',
                                Icons.account_balance_wallet,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Used Amount',
                                '\$${(_paymentDue!['used_amount'] ?? 0.0).toStringAsFixed(2)}',
                                Icons.shopping_cart,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Amount Due',
                                '\$${(_paymentDue!['amount_due'] ?? 0.0).toStringAsFixed(2)}',
                                Icons.payment,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Available Credit',
                                '\$${(_paymentDue!['available_credit'] ?? 0.0).toStringAsFixed(2)}',
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Make Payment',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: secondryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  labelText: 'Payment Amount',
                                  hintText: 'Enter amount to pay',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing ? null : _makePayment,
                                  icon: _isProcessing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: pureWhite,
                                          ),
                                        )
                                      : const Icon(Icons.payment),
                                  label: Text(
                                    _isProcessing ? 'Processing...' : 'Pay Now',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: pureWhite,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color ?? primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color ?? secondryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
