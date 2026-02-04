import 'package:flutter/material.dart';
import '../constants/Constant.dart';
import '../services/bnpl_api_service.dart';
import '../services/qows_kaab_api_service.dart';
import 'bnpl/bnpl_status_screen.dart';
import 'bnpl/bnpl_payment_screen.dart';
import 'qows_kaab/qows_kaab_status_screen.dart';
import 'qows_kaab/qows_kaab_payment_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  final String? walletAccountId;

  const MyApplicationsScreen({
    super.key,
    required this.walletAccountId,
  });

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final BnplApiService _bnplApiService = BnplApiService();
  final QowsKaabApiService _qowsKaabApiService = QowsKaabApiService();

  late TabController _tabController;
  List<Map<String, dynamic>> _bnplApplications = [];
  List<Map<String, dynamic>> _qowsKaabApplications = [];
  bool _isLoadingBnpl = true;
  bool _isLoadingQowsKaab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    await Future.wait([
      _loadBnplApplications(),
      _loadQowsKaabApplications(),
    ]);
  }

  Future<void> _loadBnplApplications() async {
    setState(() => _isLoadingBnpl = true);
    try {
      final applications = await _bnplApiService.getMyApplications(
        walletAccount: widget.walletAccountId ?? '',
      );
      setState(() {
        _bnplApplications = applications;
        _isLoadingBnpl = false;
      });
    } catch (e) {
      setState(() => _isLoadingBnpl = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading BNPL applications: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadQowsKaabApplications() async {
    setState(() => _isLoadingQowsKaab = true);
    try {
      final applications = await _qowsKaabApiService.getMyApplications(
        walletAccount: widget.walletAccountId ?? '',
      );
      setState(() {
        _qowsKaabApplications = applications;
        _isLoadingQowsKaab = false;
      });
    } catch (e) {
      setState(() => _isLoadingQowsKaab = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading QOWS KAAB applications: ${e.toString()}')),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'operations approved':
      case 'credit approved':
      case 'branch approved':
        return Colors.blue;
      case 'pending':
      case 'pending review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'operations approved':
        return 'Operations Approved';
      case 'credit approved':
        return 'Credit Approved';
      case 'branch approved':
        return 'Branch Approved';
      case 'pending review':
        return 'Pending Review';
      default:
        return status?.toUpperCase() ?? 'PENDING';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        // Try to parse and format
        final parts = date.split(' ');
        if (parts.isNotEmpty) {
          final datePart = parts[0];
          final dateParts = datePart.split('-');
          if (dateParts.length == 3) {
            return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
          }
        }
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondryColor,
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: primaryColor,
        foregroundColor: pureWhite,
        bottom: TabBar(
          controller: _tabController,
          labelColor: pureWhite,
          unselectedLabelColor: pureWhite.withOpacity(0.7),
          indicatorColor: pureWhite,
          tabs: const [
            Tab(text: 'BNPL (252Pay)', icon: Icon(Icons.credit_card)),
            Tab(text: 'QOWS KAAB', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBnplApplicationsList(),
          _buildQowsKaabApplicationsList(),
        ],
      ),
    );
  }

  Widget _buildBnplApplicationsList() {
    if (_isLoadingBnpl) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bnplApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No BNPL Applications',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by applying for BNPL',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBnplApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bnplApplications.length,
        itemBuilder: (context, index) {
          final app = _bnplApplications[index];
          final status = app['status']?.toString() ?? 'pending';
          final statusColor = _getStatusColor(status);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BnplStatusScreen(
                      walletAccountId: widget.walletAccountId,
                      applicationId: app['application_id'] ?? app['id'],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                                app['application_number'] ?? 'Application #${app['application_id'] ?? app['id']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (app['product_name'] != null)
                                Text(
                                  app['product_name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor, width: 1),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Application Details
                    if (app['created_at'] != null || app['application_date'] != null) ...[
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date:',
                        _formatDate(app['created_at'] ?? app['application_date']),
                      ),
                    ],
                    if (app['product_price'] != null) ...[
                      _buildDetailRow(
                        Icons.attach_money,
                        'Product Price:',
                        '\$${(app['product_price'] as num).toStringAsFixed(2)}',
                      ),
                    ],
                    if (app['deposit_amount'] != null) ...[
                      _buildDetailRow(
                        Icons.credit_card,
                        'Deposit:',
                        '\$${(app['deposit_amount'] as num).toStringAsFixed(2)}',
                      ),
                    ],
                    if (app['loan_amount'] != null) ...[
                      _buildDetailRow(
                        Icons.account_balance_wallet,
                        'Loan Amount:',
                        '\$${(app['loan_amount'] as num).toStringAsFixed(2)}',
                      ),
                    ],
                    if (app['monthly_installment'] != null) ...[
                      _buildDetailRow(
                        Icons.access_time,
                        'Monthly Installment:',
                        '\$${(app['monthly_installment'] as num).toStringAsFixed(2)}',
                      ),
                    ],
                    if (app['duration_months'] != null) ...[
                      _buildDetailRow(
                        Icons.timer,
                        'Duration:',
                        '${app['duration_months']} months',
                      ),
                    ],
                    if (app['branch_name'] != null) ...[
                      _buildDetailRow(
                        Icons.business,
                        'Branch:',
                        app['branch_name'],
                      ),
                    ],
                    // Action Buttons
                    if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'operations approved') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BnplPaymentScreen(
                                  walletAccountId: widget.walletAccountId,
                                  applicationId: app['application_id'] ?? app['id'],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('View Repayment Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: pureWhite,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQowsKaabApplicationsList() {
    if (_isLoadingQowsKaab) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_qowsKaabApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No QOWS KAAB Applications',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by applying for QOWS KAAB',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQowsKaabApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _qowsKaabApplications.length,
        itemBuilder: (context, index) {
          final app = _qowsKaabApplications[index];
          final status = app['status']?.toString() ?? 'pending';
          final statusColor = _getStatusColor(status);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QowsKaabStatusScreen(
                      walletAccountId: widget.walletAccountId,
                      qowsKaabId: app['id'],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                                'Application #${app['application_number'] ?? app['id']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: secondryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Credit Limit: \$${(app['credit_limit'] ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (app['created_at'] != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Applied: ${app['created_at']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (status.toLowerCase() == 'approved') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QowsKaabPaymentScreen(
                                  walletAccountId: widget.walletAccountId,
                                  qowsKaabId: app['id'],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text('Make Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
