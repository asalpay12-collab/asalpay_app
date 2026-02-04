import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/252pay_api_service.dart';
import '../../utils/bnpl_utils.dart';
import '../../models/bnpl_application.dart';
import 'bnpl_repayment_screen.dart';

class BnplTrackingScreen extends StatefulWidget {
  final String walletAccountId;

  const BnplTrackingScreen({
    super.key,
    required this.walletAccountId,
  });

  @override
  State<BnplTrackingScreen> createState() => _BnplTrackingScreenState();
}

class _BnplTrackingScreenState extends State<BnplTrackingScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final api = ApiService();

  bool isLoading = true;
  List<BnplApplication> applications = [];
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications({String? status}) async {
    setState(() {
      isLoading = true;
      selectedStatus = status;
    });

    try {
      final data = await api.getMyBnplApplications(
        widget.walletAccountId,
        status: status,
      );
      setState(() {
        applications = data
            .map((e) {
              try {
                return BnplApplication.fromJson(e);
              } catch (parseError) {
                api.appLog("⚠️ Error parsing application: $parseError");
                api.appLog("   - Data: $e");
                return null;
              }
            })
            .whereType<BnplApplication>()
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load applications: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'My BNPL Applications',
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
                _loadApplications();
              } else {
                _loadApplications(status: value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'all', child: Text('All Applications')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(
                  value: 'branch_approved', child: Text('Branch Approved')),
              const PopupMenuItem(
                  value: 'credit_approved', child: Text('Credit Approved')),
              const PopupMenuItem(
                  value: 'operations_approved',
                  child: Text('Operations Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadApplications(status: selectedStatus),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : applications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      return _buildApplicationCard(applications[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No applications found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(BnplApplication application) {
    final statusColor = _getStatusColor(application.approvalStatus ?? '');
    final statusText =
        BnplUtils.getApprovalStatusDescription(application.approvalStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showApplicationDetails(application),
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
                          application.applicationNumber ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   application.productName ?? 'Product',
                        //   style: GoogleFonts.poppins(
                        //     fontSize: 14,
                        //     color: Colors.grey.shade700,
                        //   ),
                        // ),
                      ],
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
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.calendar_today,
                'Date',
                BnplUtils.formatDate(application.applicationDate),
              ),
              _buildInfoRow(
                Icons.attach_money,
                'Product Price',
                BnplUtils.formatCurrency(application.productPrice),
              ),
              _buildInfoRow(
                Icons.payment,
                'Deposit',
                BnplUtils.formatCurrency(application.calculatedDeposit),
              ),
              _buildInfoRow(
                Icons.account_balance_wallet,
                'Loan Amount',
                BnplUtils.formatCurrency(application.loanAmount),
              ),
              if (application.monthlyInstallment != null) ...[
                _buildInfoRow(
                  Icons.schedule,
                  'Monthly Installment',
                  BnplUtils.formatCurrency(application.monthlyInstallment),
                ),
                _buildInfoRow(
                  Icons.timer,
                  'Duration',
                  '${application.repaymentDurationMonths} months',
                ),
              ],
              if (application.orderId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BnplRepaymentScreen(
                            walletAccountId: widget.walletAccountId,
                            applicationId: application.applicationId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('View Repayment Schedule'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'branch_approved':
      case 'credit_approved':
      case 'operations_approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showApplicationDetails(BnplApplication application) async {
    final applicationId = application.id ?? application.applicationId;
    if (applicationId == null) return;

    // Show loading then fetch full details (branches for district, items for multi-product)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    Map<String, dynamic>? details;
    try {
      details = await api.getApplicationDetails(applicationId);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Failed to load details: $e');
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);

    final data = details['data'] is Map
        ? Map<String, dynamic>.from(details['data'] as Map)
        : <String, dynamic>{};
    final branches = details['branches'] is List
        ? details['branches'] as List<dynamic>
        : <dynamic>[];
    final items = details['items'] is List
        ? details['items'] as List<dynamic>
        : <dynamic>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            'Application Number',
                            data['application_number']?.toString() ??
                                application.applicationNumber ??
                                'N/A'),
                        _buildDetailRow(
                            'Status',
                            BnplUtils.getApprovalStatusDescription(
                                application.approvalStatus)),
                        _buildDetailRow('Date',
                            BnplUtils.formatDate(application.applicationDate)),
                        // Branch(es) for this district
                        if (branches.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Branch(es)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...(branches.map<Widget>((b) {
                            final map = b is Map
                                ? Map<String, dynamic>.from(b)
                                : <String, dynamic>{};
                            final name =
                                map['branch_name']?.toString() ?? 'Branch';
                            final isPrimary = map['is_primary'] == 1 ||
                                map['is_primary'] == true;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.store,
                                      size: 18, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Primary',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          })),
                          const SizedBox(height: 12),
                        ],
                        // Product(s) – single or list from items
                        if (items.isNotEmpty && items.length > 1) ...[
                          Text(
                            'Products',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...(items.map<Widget>((i) {
                            final map = i is Map<String, dynamic>
                                ? i
                                : (i is Map
                                    ? Map<String, dynamic>.from(i)
                                    : <String, dynamic>{});
                            final name =
                                map['product_name']?.toString() ?? 'Product';
                            final qty = (map['quantity'] is num)
                                ? (map['quantity'] as num).toInt()
                                : int.tryParse(
                                        map['quantity']?.toString() ?? '') ??
                                    1;
                            final subtotal = (map['subtotal'] is num)
                                ? (map['subtotal'] as num).toDouble()
                                : double.tryParse(
                                        map['subtotal']?.toString() ?? '') ??
                                    0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      size: 18, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$name × $qty',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    BnplUtils.formatCurrency(subtotal),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          })),
                          const SizedBox(height: 12),
                        ] else if (items.length == 1) ...[
                          _buildDetailRow(
                              'Product',
                              (items[0] is Map
                                      ? (items[0] as Map)['product_name']
                                          ?.toString()
                                      : null) ??
                                  application.productName ??
                                  'N/A'),
                          _buildDetailRow(
                              'Product Price',
                              BnplUtils.formatCurrency(
                                  application.productPrice)),
                        ] else ...[
                          _buildDetailRow(
                              'Product',
                              application.productName ??
                                  data['product_name']?.toString() ??
                                  'N/A'),
                          _buildDetailRow(
                              'Product Price',
                              BnplUtils.formatCurrency(
                                  application.productPrice)),
                        ],
                        if (items.length > 1)
                          _buildDetailRow(
                              'Total',
                              BnplUtils.formatCurrency(
                                  application.productPrice)),
                        _buildDetailRow(
                            'Deposit',
                            BnplUtils.formatCurrency(
                                application.calculatedDeposit)),
                        _buildDetailRow('Loan Amount',
                            BnplUtils.formatCurrency(application.loanAmount)),
                        _buildDetailRow(
                            'Monthly Installment',
                            BnplUtils.formatCurrency(
                                application.monthlyInstallment)),
                        _buildDetailRow('Duration',
                            '${application.repaymentDurationMonths} months'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
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
}
