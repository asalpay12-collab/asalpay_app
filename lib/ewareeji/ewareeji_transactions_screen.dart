import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

/// E-Wareeji Transactions screen – sample data for design.
/// History, network, last transactions; wallet details when a Buy is selected.
class EwareejiTransactionsScreen extends StatefulWidget {
  const EwareejiTransactionsScreen({super.key});

  @override
  State<EwareejiTransactionsScreen> createState() => _EwareejiTransactionsScreenState();
}

class _EwareejiTransactionsScreenState extends State<EwareejiTransactionsScreen> {
  static final List<Map<String, String>> _transactions = [
    {'id': '1', 'type': 'Buy', 'amount': '100 USDT', 'rate': '1.00', 'network': 'TRC20', 'date': 'Today 10:30', 'status': 'Completed', 'wallet': 'Main Wallet'},
    {'id': '2', 'type': 'Sell', 'amount': '50 USDT', 'rate': '0.99', 'network': 'ERC20', 'date': 'Yesterday 14:00', 'status': 'Completed', 'wallet': 'Trading Wallet'},
    {'id': '3', 'type': 'Buy', 'amount': '200 USDT', 'rate': '1.01', 'network': 'TRC20', 'date': '2 days ago', 'status': 'Pending', 'wallet': 'Main Wallet'},
    {'id': '4', 'type': 'Sell', 'amount': '75 USDT', 'rate': '1.00', 'network': 'BEP20', 'date': '3 days ago', 'status': 'Completed', 'wallet': 'Main Wallet'},
  ];
  String? _selectedId;

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
                      const Text('Transaction history', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._transactions.map((t) => _buildTransactionCard(t)),
                      if (_selectedId != null) ...[
                        const SizedBox(height: 20),
                        _buildWalletDetails(),
                      ],
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Transactions',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, String> t) {
    final isSelected = _selectedId == t['id'];
    final isBuy = t['type'] == 'Buy';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withOpacity(isSelected ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _selectedId = _selectedId == t['id'] ? null : t['id']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isBuy ? primaryColor.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                  child: Icon(isBuy ? Icons.shopping_cart_rounded : Icons.sell_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t['type']} ${t['amount']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${t['network']} · ${t['date']}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      Text(t['status']!, style: TextStyle(color: t['status'] == 'Pending' ? Colors.amber : Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rate ${t['rate']}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                    Icon(isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
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
    final t = _transactions.firstWhere((e) => e['id'] == _selectedId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _detailRow('Wallet', t['wallet']!),
          _detailRow('Network', t['network']!),
          _detailRow('Amount', t['amount']!),
          _detailRow('Rate', t['rate']!),
          _detailRow('Date', t['date']!),
          _detailRow('Status', t['status']!),
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
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
