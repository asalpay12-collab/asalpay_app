import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/services/ewareeji_api_service.dart';
import 'package:flutter/material.dart';

/// E-Wareeji Transactions screen – real data from API.
/// Default: today's transactions. Date filter to load by range. Wallet details on card tap.
class EwareejiTransactionsScreen extends StatefulWidget {
  final String? wallet_accounts_id;

  const EwareejiTransactionsScreen({super.key, this.wallet_accounts_id});

  @override
  State<EwareejiTransactionsScreen> createState() =>
      _EwareejiTransactionsScreenState();
}

class _EwareejiTransactionsScreenState
    extends State<EwareejiTransactionsScreen> {
  List<EwareejiCryptoTransaction> _transactions = [];
  bool _loading = false;
  String? _error;
  String? _selectedId;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final walletId = int.tryParse(widget.wallet_accounts_id?.trim() ?? '');
    final list = await EwareejiApiService.instance.getTransactions(
      startDate: _startDate,
      endDate: _endDate,
      walletAccountId: (walletId != null && walletId > 0) ? walletId : null,
    );
    if (!mounted) return;
    setState(() {
      _transactions = list;
      _loading = false;
      _error = EwareejiApiService.instance.lastError;
      if (_selectedId != null &&
          !_transactions.any((t) => t.id == _selectedId)) {
        _selectedId = null;
      }
    });
  }

  void _setTodayAndLoad() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day);
    });
    _loadTransactions();
  }

  static String _formatDateDisplay(String isoDate) {
    if (isoDate.isEmpty) return '—';
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dDate = DateTime(d.year, d.month, d.day);
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (dDate == today) return 'Today $time';
    if (dDate == yesterday) return 'Yesterday $time';
    const months = 'JanFebMarAprMayJunJulAugSepOctNovDec';
    final m = d.month - 1;
    final mon = months.substring(m * 3, m * 3 + 3);
    return '${d.day} $mon ${d.year} $time';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [secondryColor, secondryColor.withOpacity(0.82)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateFilter(),
                      const SizedBox(height: 16),
                      const Text(
                        'Transaction history',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      else if (_error != null && _error!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        )
                      else if (_transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No transactions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._transactions.expand((t) {
                          final widgets = <Widget>[
                            _buildTransactionCard(t),
                          ];
                          if (_selectedId == t.id) {
                            widgets.add(const SizedBox(height: 12));
                            widgets.add(_buildWalletDetails());
                          }
                          return widgets;
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Transactions',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateChip('From', _startDate, (DateTime d) {
                  setState(() => _startDate = d);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateChip('To', _endDate, (DateTime d) {
                  setState(() => _endDate = d);
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: _loading ? null : _setTodayAndLoad,
                icon: const Icon(Icons.today, color: Colors.white, size: 18),
                label:
                    const Text('Today', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _loadTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Filter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateChip(
      String label, DateTime value, ValueChanged<DateTime> onPick) {
    final str =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
            Text(str,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(EwareejiCryptoTransaction t) {
    final isSelected = _selectedId == t.id;
    final isBuy = t.type == 'BUY';
    final amountStr =
        '${t.cryptoAmount.toStringAsFixed(t.cryptoAmount.truncateToDouble() == t.cryptoAmount ? 0 : 4)} ${t.customerWalletName ?? 'Crypto'}';
    final network = t.customerNetworkName ?? t.customerNetworkCode ?? '—';
    final dateStr = _formatDateDisplay(t.createdAt);
    final statusStr = _capitalize(t.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withOpacity(isSelected ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () =>
              setState(() => _selectedId = _selectedId == t.id ? null : t.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isBuy
                      ? primaryColor.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                  child: Icon(
                    isBuy ? Icons.shopping_cart_rounded : Icons.sell_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isBuy ? 'Buy' : 'Sell'} $amountStr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$network · $dateStr',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                      Text(
                        statusStr,
                        style: TextStyle(
                          color: statusStr.toLowerCase() == 'pending'
                              ? Colors.amber
                              : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rate ${t.rate.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    Icon(
                      isSelected
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
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

  Widget _buildWalletDetails() {
    final idx = _transactions.indexWhere((e) => e.id == _selectedId);
    if (idx < 0) return const SizedBox.shrink();
    final t = _transactions[idx];
    final network = t.customerNetworkName ?? t.customerNetworkCode ?? '—';
    final walletLabel = '${t.customerWalletName ?? 'Wallet'} ($network)';
    final amountStr =
        '${t.cryptoAmount.toStringAsFixed(4)} ${t.customerWalletName ?? 'Crypto'}';
    final statusStr = _capitalize(t.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _detailRow('Wallet', walletLabel),
          _detailRow('Network', network),
          _detailRow('Amount', amountStr),
          _detailRow('Fiat', '\$${t.fiatAmount.toStringAsFixed(2)}'),
          _detailRow('Rate', t.rate.toStringAsFixed(4)),
          _detailRow('Date', _formatDateDisplay(t.createdAt)),
          _detailRow('Status', statusStr),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
