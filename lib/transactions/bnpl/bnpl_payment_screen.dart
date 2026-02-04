import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/Constant.dart';
import '../../services/bnpl_api_service.dart';

class BnplPaymentScreen extends StatefulWidget {
  final String? walletAccountId;
  final int? applicationId;

  const BnplPaymentScreen({
    super.key,
    required this.walletAccountId,
    required this.applicationId,
  });

  @override
  State<BnplPaymentScreen> createState() => _BnplPaymentScreenState();
}

class _BnplPaymentScreenState extends State<BnplPaymentScreen> {
  final BnplApiService _apiService = BnplApiService();
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await _apiService.getRepaymentSchedules(
        walletAccount: widget.walletAccountId ?? '',
        applicationId: widget.applicationId,
        paymentStatus: 'pending',
      );
      setState(() {
        _schedules = schedules;
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

  Future<void> _makePayment(Map<String, dynamic> schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Are you sure you want to pay \$${(schedule['amount'] ?? 0.0).toStringAsFixed(2)}?',
        ),
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

    setState(() {
      _isProcessing = true;
      _selectedSchedule = schedule;
    });

    try {
      final result = await _apiService.makePayment(
        scheduleId: schedule['schedule_id'] ?? schedule['id'],
        walletAccount: widget.walletAccountId ?? '',
        amount: (schedule['amount'] ?? 0.0) is double
            ? schedule['amount'] as double
            : double.tryParse(schedule['amount'].toString()) ?? 0.0,
      );

      if (result['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSchedules();
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
      setState(() {
        _isProcessing = false;
        _selectedSchedule = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondryColor,
      appBar: AppBar(
        title: const Text('BNPL Payments'),
        backgroundColor: primaryColor,
        foregroundColor: pureWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No Pending Payments',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All payments are up to date',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSchedules,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = _schedules[index];
                      final amount = (schedule['amount'] ?? 0.0) is double
                          ? schedule['amount'] as double
                          : double.tryParse(schedule['amount'].toString()) ?? 0.0;
                      final dueDate = schedule['due_date'] != null
                          ? DateTime.tryParse(schedule['due_date'].toString())
                          : null;
                      final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isOverdue
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Payment #${schedule['schedule_id'] ?? schedule['id']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: secondryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Amount: \$${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isOverdue)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'OVERDUE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (dueDate != null) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Due Date: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isOverdue ? Colors.red : Colors.grey.shade700,
                                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing &&
                                          _selectedSchedule?['id'] == schedule['id']
                                      ? null
                                      : () => _makePayment(schedule),
                                  icon: _isProcessing &&
                                          _selectedSchedule?['id'] == schedule['id']
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
                                    _isProcessing &&
                                            _selectedSchedule?['id'] == schedule['id']
                                        ? 'Processing...'
                                        : 'Pay Now',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOverdue ? Colors.red : primaryColor,
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
                      );
                    },
                  ),
                ),
    );
  }
}
