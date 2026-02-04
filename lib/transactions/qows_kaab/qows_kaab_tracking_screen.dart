import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/252pay_api_service.dart';
import '../../models/qows_kaab_application.dart';
import 'qows_kaab_application_details_screen.dart';

class QowsKaabTrackingScreen extends StatefulWidget {
  final String walletAccountId;

  const QowsKaabTrackingScreen({
    super.key,
    required this.walletAccountId,
  });

  @override
  State<QowsKaabTrackingScreen> createState() => _QowsKaabTrackingScreenState();
}

class _QowsKaabTrackingScreenState extends State<QowsKaabTrackingScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();

  List<QowsKaabApplication> applications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await api.getMyQowsKaabApplications(widget.walletAccountId);
      setState(() {
        applications =
            data.map((e) => QowsKaabApplication.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
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
          'My QOWS KAAB Applications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
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
                        onPressed: _loadApplications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_basket_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No QOWS KAAB applications found',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final app = applications[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: br12),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        QowsKaabApplicationDetailsScreen(
                                      qowsKaabId: app.qowsKaabId ?? app.id ?? 0,
                                      walletAccountId: widget.walletAccountId,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: br12,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                app.applicationNumber ?? 'N/A',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                app.isMonthlyPack
                                                    ? 'Monthly Pack'
                                                    : 'Daily Credit',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                    app.status ?? 'pending')
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                  app.status ?? 'pending'),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            (app.status ?? 'pending')
                                                .toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusColor(
                                                  app.status ?? 'pending'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (app.isMonthlyPack &&
                                        app.packTotalAmount != null)
                                      _buildInfoRow(
                                        'Pack Amount',
                                        '\$${app.packTotalAmount!.toStringAsFixed(2)}',
                                      ),
                                    if (app.isDailyCredit &&
                                        app.dailyCreditLimit != null)
                                      _buildInfoRow(
                                        'Credit Limit',
                                        '\$${app.dailyCreditLimit!.toStringAsFixed(2)}',
                                      ),
                                    if (app.paymentDueNextMonth != null)
                                      _buildInfoRow(
                                        'Payment Due',
                                        '\$${app.paymentDueNextMonth!.toStringAsFixed(2)}',
                                      ),
                                    if (app.monthlyPaymentDue != null)
                                      _buildInfoRow(
                                        'Payment Due',
                                        '\$${app.monthlyPaymentDue!.toStringAsFixed(2)}',
                                      ),
                                    if (app.familySize != null)
                                      _buildInfoRow(
                                        'Family Size',
                                        app.familySize.toString(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
