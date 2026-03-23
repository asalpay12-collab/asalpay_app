import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/Constant.dart';
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
  int? _cancellingId;

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
        applications = data
            .map((e) => QowsKaabApplication.fromJson(e))
            .where((a) => (a.status ?? '').toLowerCase() != 'cancelled')
            .toList();
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
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCancelConfirmation(
      BuildContext context, QowsKaabApplication app) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel application',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this application (${app.applicationNumber ?? 'N/A'})? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('No', style: GoogleFonts.poppins(color: primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelApplication(app);
            },
            child: Text(
              'Yes, cancel',
              style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelApplication(QowsKaabApplication app) async {
    final id = app.qowsKaabId ?? app.id;
    if (id == null) return;
    setState(() => _cancellingId = id);
    try {
      await api.cancelQowsKaabApplication(id, widget.walletAccountId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Application cancelled successfully.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadApplications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightContentColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: secondryColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: pureWhite,
        title: Text(
          'My QOYS KAAB Applications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: pureWhite,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(color: secondryColor),
              )
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadApplications,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondryColor,
                            foregroundColor: pureWhite,
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
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
                              'No QOYS KAAB applications found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                      color: secondryColor,
                      backgroundColor: pureWhite,
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final app = applications[index];
                          final isCancelling =
                              _cancellingId == (app.qowsKaabId ?? app.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: pureWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE0E8E6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                              children: [
                                InkWell(
                                  onTap: isCancelling
                                      ? null
                                      : () {
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
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryColor,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                app.isMonthlyPack
                                                    ? 'Monthly Pack'
                                                    : 'Daily Credit',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF455A54),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
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
                                            if (app.canCancel) ...[
                                              const SizedBox(width: 4),
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: primaryColor,
                                                  size: 22,
                                                ),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: br12),
                                                onSelected: (value) {
                                                  if (value == 'cancel') {
                                                    _showCancelConfirmation(
                                                        context, app);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem<String>(
                                                    value: 'cancel',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.cancel_outlined,
                                                            color: Colors.red,
                                                            size: 20),
                                                        SizedBox(width: 8),
                                                        Text('Cancel application'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
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
                                if (isCancelling)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                          strokeWidth: 2.5,
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5A6B66),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
