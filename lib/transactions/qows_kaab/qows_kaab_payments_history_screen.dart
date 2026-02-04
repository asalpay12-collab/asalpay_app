import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/Constant.dart';
import '../../services/252pay_api_service.dart';

/// QOWS KAAB Payment History screen (no Due Payments tab).
/// Opened from Application Details "View Payment History".
class QowsKaabPaymentsHistoryScreen extends StatefulWidget {
  final String walletAccountId;
  final int qowsKaabId;

  const QowsKaabPaymentsHistoryScreen({
    super.key,
    required this.walletAccountId,
    required this.qowsKaabId,
  });

  @override
  State<QowsKaabPaymentsHistoryScreen> createState() =>
      _QowsKaabPaymentsHistoryScreenState();
}

class _QowsKaabPaymentsHistoryScreenState
    extends State<QowsKaabPaymentsHistoryScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = true;
  String? _historyError;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final list = await _api.getQowsKaabPaymentHistory(
        widget.walletAccountId,
        qowsKaabId: widget.qowsKaabId,
      );
      if (mounted) {
        setState(() {
          _history = list;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString().replaceFirst('Exception: ', '');
          _historyLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.isEmpty) return '—';
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(dynamic v) {
    if (v == null) return '\$0.00';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return '\$0.00';
    return '\$${n.toStringAsFixed(2)}';
  }

  DateTime? _parseItemDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_fromDate == null && _toDate == null) return _history;
    return _history.where((p) {
      final dateRaw = p['paid_date'] ?? p['payment_period'] ?? p['due_date'];
      final d = _parseItemDate(dateRaw);
      if (d == null) return true;
      final day = DateTime(d.year, d.month, d.day);
      if (_fromDate != null) {
        final from =
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (day.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
        if (day.isAfter(to)) return false;
      }
      return true;
    }).toList();
  }

  bool get _hasDateFilter => _fromDate != null || _toDate != null;

  Future<void> _showDateFilterSheet() async {
    DateTime? from = _fromDate;
    DateTime? to = _toDate;
    final br12 = BorderRadius.circular(12);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter by date',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: secondryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('From date',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey.shade700)),
                    subtitle: Text(
                      from == null
                          ? 'Any'
                          : _formatDate(from!.toIso8601String()),
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    trailing: Icon(Icons.calendar_today, color: primaryColor),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: from ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => from = picked);
                    },
                    shape: RoundedRectangleBorder(borderRadius: br12),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('To date',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey.shade700)),
                    subtitle: Text(
                      to == null ? 'Any' : _formatDate(to!.toIso8601String()),
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    trailing: Icon(Icons.calendar_today, color: primaryColor),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: to ?? from ?? DateTime.now(),
                        firstDate: from ?? DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => to = picked);
                    },
                    shape: RoundedRectangleBorder(borderRadius: br12),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      if (from != null || to != null)
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              from = null;
                              to = null;
                            });
                          },
                          icon: Icon(Icons.clear, size: 20),
                          label: Text('Clear'),
                        ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _fromDate = from;
                              _toDate = to;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: br12),
                          ),
                          child: Text('Apply',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final br12 = BorderRadius.circular(12);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'QOWS KAAB Payment History',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pureWhite,
          ),
        ),
        backgroundColor: secondryColor,
        foregroundColor: pureWhite,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasDateFilter,
              smallSize: 8,
              child: Icon(Icons.filter_list, color: pureWhite),
            ),
            onPressed: _showDateFilterSheet,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: _buildHistoryContent(br12),
    );
  }

  Widget _buildHistoryContent(BorderRadius br12) {
    if (_historyLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              SizedBox(height: 12),
              Text(
                _historyError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey.shade700),
              ),
              SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadHistory,
                icon: Icon(Icons.refresh, size: 20),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_history.isEmpty) {
      return Center(
        child: Text(
          'No payment history yet',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
      );
    }
    final list = _filteredHistory;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_list_off,
                  size: 48, color: Colors.grey.shade400),
              SizedBox(height: 12),
              Text(
                'No payments in selected date range',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade600, fontSize: 16),
              ),
              SizedBox(height: 16),
              TextButton.icon(
                onPressed: _showDateFilterSheet,
                icon: Icon(Icons.edit, size: 20),
                label: Text('Change filter'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        final amount = (p['amount_paid'] is num)
            ? (p['amount_paid'] as num).toDouble()
            : double.tryParse(p['amount_paid']?.toString() ?? '') ?? 0.0;
        final period =
            p['paid_date'] ?? p['payment_period'] ?? p['due_date'] ?? '';
        final method = (p['payment_method'] ?? 'wallet').toString();
        final type = (p['payment_type'] ?? 'Daily Payment').toString();
        final status = (p['payment_status'] ?? 'paid').toString().toLowerCase();
        final isPaid = status == 'paid';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: br12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPaid
                        ? primaryColor.withValues(alpha: 0.15)
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle : Icons.schedule,
                    color: isPaid ? primaryColor : Colors.orange.shade700,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Period: ${_formatDate(period)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Method: $method',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (!isPaid) ...[
                        SizedBox(height: 8),
                        // Text(
                        //   'Payment received for this period. Full application payment still in progress.',
                        //   style: GoogleFonts.poppins(
                        //     fontSize: 12,
                        //     color: Colors.grey.shade600,
                        //     height: 1.3,
                        //   ),
                        // ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(amount),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                    
                    SizedBox(height: 6),
                    // Period payment status: always Paid (this period's payment was received)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Period: Paid',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    // Application payment status: Paid or Processing from payment_status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? primaryColor.withValues(alpha: 0.2)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPaid
                            ? 'Application: Paid'
                            : 'Application: Processing',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isPaid ? primaryColor : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
