import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/ewareeji/ewareeji_buy_screen.dart';
import 'package:asalpay/ewareeji/ewareeji_sell_screen.dart';
import 'package:asalpay/ewareeji/ewareeji_setup_screen.dart';
import 'package:asalpay/ewareeji/ewareeji_transactions_screen.dart';
import 'package:flutter/material.dart';

/// E-Wareeji (Buy & Sell) main screen – modern, professional entry point.
/// Top: Sell, Buy, Setup, Transactions. Middle: Last 3 transactions. Bottom: Market list.
class EwareejiMainScreen extends StatefulWidget {
  final String? wallet_accounts_id;

  const EwareejiMainScreen({super.key, this.wallet_accounts_id});

  @override
  State<EwareejiMainScreen> createState() => _EwareejiMainScreenState();
}

class _EwareejiMainScreenState extends State<EwareejiMainScreen> {
  final List<Map<String, String>> _lastTransactions = [
    {'type': 'Buy', 'amount': '100 USDT', 'rate': '1.00', 'date': 'Today', 'status': 'Completed'},
    {'type': 'Sell', 'amount': '50 USDT', 'rate': '0.99', 'date': 'Yesterday', 'status': 'Completed'},
    {'type': 'Buy', 'amount': '200 USDT', 'rate': '1.01', 'date': '2 days ago', 'status': 'Pending'},
  ];

  // Currencies: hadda sample (USDT, USDC). Marka API diyaar noqdo, u beddel: _currencies = apiResponse;
  List<String> _currencies = ['USDT', 'USDC'];
  int _selectedCurrencyIndex = 0;

  final Map<String, List<Map<String, dynamic>>> _currencyNetworks = {
    'USDT': [
      {
        'network': 'TRC20',
        'buyRate': '1.00',
        'sellRate': '0.99',
        'buyRates': [
          {'min': '10', 'max': '1,000', 'rate': '1.00'},
          {'min': '1,000', 'max': '10,000', 'rate': '0.99'},
        ],
        'sellRates': [
          {'min': '10', 'max': '5,000', 'rate': '0.99'},
          {'min': '5,000', 'max': '20,000', 'rate': '0.98'},
        ],
      },
      {
        'network': 'ERC20',
        'buyRate': '1.01',
        'sellRate': '1.00',
        'buyRates': [
          {'min': '20', 'max': '2,000', 'rate': '1.01'},
          {'min': '2,000', 'max': '15,000', 'rate': '1.00'},
        ],
        'sellRates': [
          {'min': '20', 'max': '10,000', 'rate': '1.00'},
        ],
      },
      {
        'network': 'BEP20',
        'buyRate': '0.99',
        'sellRate': '0.98',
        'buyRates': [
          {'min': '10', 'max': '5,000', 'rate': '0.99'},
        ],
        'sellRates': [
          {'min': '10', 'max': '8,000', 'rate': '0.98'},
        ],
      },
    ],
    'USDC': [
      {
        'network': 'ERC20',
        'buyRate': '1.00',
        'sellRate': '0.99',
        'buyRates': [
          {'min': '50', 'max': '10,000', 'rate': '1.00'},
        ],
        'sellRates': [
          {'min': '50', 'max': '10,000', 'rate': '0.99'},
        ],
      },
      {
        'network': 'BEP20',
        'buyRate': '1.00',
        'sellRate': '0.99',
        'buyRates': [
          {'min': '50', 'max': '5,000', 'rate': '1.00'},
        ],
        'sellRates': [
          {'min': '50', 'max': '5,000', 'rate': '0.99'},
        ],
      },
    ],
  };

  void _showRatesSheet(bool isBuy, String currency, String network, List<dynamic> rates) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isBuy ? 'Buy rates' : 'Sell rates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: secondryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$currency · $network',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...(rates as List<Map<String, String>>).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${r['min']} - ${r['max']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Rate ${r['rate']}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: secondryColor),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => isBuy ? const EwareejiBuyScreen() : const EwareejiSellScreen(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isBuy ? 'Continue to Buy' : 'Continue to Sell'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              secondryColor,
              secondryColor.withOpacity(0.82),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopIcons(),
                      const SizedBox(height: 20),
                      _buildLastTransactions(),
                      const SizedBox(height: 24),
                      _buildMarketSection(),
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
            'E-Wareeji',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcons() {
    final items = [
      {'icon': Icons.sell_rounded, 'label': 'Sell'},
      {'icon': Icons.shopping_cart_rounded, 'label': 'Buy'},
      {'icon': Icons.settings_rounded, 'label': 'Setup'},
      {'icon': Icons.history_rounded, 'label': 'Transactions'},
    ];
    return Row(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
            child: Material(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  final label = item['label'] as String;
                  Widget? screen;
                  if (label == 'Sell') screen = const EwareejiSellScreen();
                  else if (label == 'Buy') screen = const EwareejiBuyScreen();
                  else if (label == 'Setup') screen = const EwareejiSetupScreen();
                  else if (label == 'Transactions') screen = const EwareejiTransactionsScreen();
                  if (screen != null) Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(item['icon'] as IconData, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLastTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last transactions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_lastTransactions.length.clamp(0, 3), (i) {
          final t = _lastTransactions[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (t['type'] == 'Buy' ? primaryColor : Colors.orange).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t['type']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['amount']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rate ${t['rate']} · ${t['date']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  t['status']!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMarketSection() {
    if (_currencies.isEmpty) {
      return const SizedBox.shrink();
    }
    final currency = _currencies[_selectedCurrencyIndex.clamp(0, _currencies.length - 1)];
    final networks = _currencyNetworks[currency];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Market',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        // Tabs: laba = labo qaybood buuxiyaan; seddex = seddex qaybood; ilaa inta badan = width siman
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Row(
            children: List.generate(_currencies.length, (i) {
              final isSelected = i == _selectedCurrencyIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _currencies.length - 1 ? 6 : 0),
                  child: Material(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCurrencyIndex = i),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _currencies[i],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? secondryColor : Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        // Networks under selected currency (empty haddii API soo celiyo currency cusub oo aan la keyin _currencyNetworks)
        if (networks != null && networks.isNotEmpty) ...[
          Text(
            'Networks',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...networks.map((n) {
            final network = n['network'] as String;
            final buyRate = n['buyRate'] as String;
            final sellRate = n['sellRate'] as String;
            final buyRates = n['buyRates'] as List<Map<String, String>>;
            final sellRates = n['sellRates'] as List<Map<String, String>>;
            return _buildNetworkCard(currency, network, buyRate, sellRate, buyRates, sellRates);
          }),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No networks for $currency',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkCard(
    String currency,
    String network,
    String buyRate,
    String sellRate,
    List<Map<String, String>> buyRates,
    List<Map<String, String>> sellRates,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [secondryColor.withOpacity(0.2), secondryColor.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lan_rounded, color: secondryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    network,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _rateChip(Icons.trending_up_rounded, buyRate, true),
                      const SizedBox(width: 6),
                      _rateChip(Icons.trending_down_rounded, sellRate, false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _actionIconButton(
              icon: Icons.shopping_cart_rounded,
              isBuy: true,
              onTap: () => _showRatesSheet(true, currency, network, buyRates),
            ),
            const SizedBox(width: 6),
            _actionIconButton(
              icon: Icons.sell_rounded,
              isBuy: false,
              onTap: () => _showRatesSheet(false, currency, network, sellRates),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateChip(IconData icon, String rate, bool isBuy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: (isBuy ? primaryColor : Colors.orange).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isBuy ? primaryColor : Colors.orange.shade700),
          const SizedBox(width: 3),
          Text(
            rate,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isBuy ? primaryColor : Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton({
    required IconData icon,
    required bool isBuy,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isBuy ? secondryColor.withOpacity(0.12) : secondryColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isBuy ? secondryColor : Colors.white,
          ),
        ),
      ),
    );
  }
}
