import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/ewareeji/ewareeji_buy_screen.dart';
import 'package:asalpay/ewareeji/ewareeji_sell_screen.dart';
import 'package:asalpay/ewareeji/ewareeji_setup_screen.dart';
import 'package:asalpay/ewareeji/ewareeji_transactions_screen.dart';
import 'package:asalpay/services/ewareeji_api_service.dart';
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
  List<EwareejiCryptoTransaction> _lastTransactions = [];
  bool _loadingLastTransactions = false;

  List<String> _currencies = [];
  int _selectedCurrencyIndex = 0;
  bool _loadingMarket = false;
  String? _marketError;
  Map<String, List<Map<String, dynamic>>> _currencyNetworks = {};

  @override
  void initState() {
    super.initState();
    _loadMarketFromApi();
    _loadLastTransactions();
  }

  Future<void> _loadLastTransactions() async {
    if (!mounted) return;
    setState(() => _loadingLastTransactions = true);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final walletId = int.tryParse(widget.wallet_accounts_id?.trim() ?? '');
    final list = await EwareejiApiService.instance.getTransactions(
      startDate: start,
      endDate: now,
      walletAccountId: (walletId != null && walletId > 0) ? walletId : null,
    );
    if (!mounted) return;
    setState(() {
      _lastTransactions = list.take(3).toList();
      _loadingLastTransactions = false;
    });
  }

  static String _shortDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dDate = DateTime(d.year, d.month, d.day);
    if (dDate == today) return 'Today';
    if (dDate == yesterday) return 'Yesterday';
    const months = 'JanFebMarAprMayJunJulAugSepOctNovDec';
    final m = d.month - 1;
    final mon = months.substring(m * 3, m * 3 + 3);
    return '${d.day} $mon';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Called on pull-to-refresh; reloads last transactions and market data.
  Future<void> _onRefresh() async {
    await Future.wait([
      _loadLastTransactions(),
      _loadMarketFromApi(),
    ]);
  }

  Future<void> _loadMarketFromApi() async {
    final svc = EwareejiApiService.instance;
    setState(() {
      _loadingMarket = true;
      _marketError = null;
    });
    try {
      final wallets = await svc.getWallets(activeOnly: true);
      if (!mounted) {
        setState(() => _loadingMarket = false);
        return;
      }
      if (svc.lastError != null && wallets.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingMarket = false;
            _marketError = 'Server error';
          });
        }
        return;
      }
      final networks = await svc.getNetworks(activeOnly: true);
      if (!mounted) {
        setState(() => _loadingMarket = false);
        return;
      }
      if (svc.lastError != null && networks.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingMarket = false;
            _marketError = 'Server error';
          });
        }
        return;
      }
      final netById = {for (var n in networks) n.id: n.code};
      final currencySet = <String>{};
      final Map<String, List<Map<String, dynamic>>> built = {};
      for (final w in wallets) {
        final parts = w.name.trim().split(RegExp(r'\s+'));
        final currency = parts.isNotEmpty ? parts.first.toUpperCase() : w.name;
        currencySet.add(currency);
        final networkCode =
            w.networkCode ?? netById[w.networkId] ?? '${w.networkId}';
        final rates = await svc.getRates(walletId: w.id, activeOnly: true);
        if (!mounted) break;
        String buyRate = 'No rate';
        String sellRate = 'No rate';
        final buyRates = <Map<String, String>>[];
        final sellRates = <Map<String, String>>[];
        for (final r in rates) {
          if (r.buyRate > 0) {
            if (buyRate == 'No rate') buyRate = r.buyRate.toStringAsFixed(4);
            buyRates.add({
              'min': (r.minAmount ?? 0).toStringAsFixed(0),
              'max':
                  r.maxAmount != null ? r.maxAmount!.toStringAsFixed(0) : '—',
              'rate': r.buyRate.toStringAsFixed(4),
            });
          }
          if (r.sellRate > 0) {
            if (sellRate == 'No rate') sellRate = r.sellRate.toStringAsFixed(4);
            sellRates.add({
              'min': (r.minAmount ?? 0).toStringAsFixed(0),
              'max':
                  r.maxAmount != null ? r.maxAmount!.toStringAsFixed(0) : '—',
              'rate': r.sellRate.toStringAsFixed(4),
            });
          }
        }
        if (buyRates.isEmpty)
          buyRates.add({'min': '0', 'max': '—', 'rate': 'No rate'});
        if (sellRates.isEmpty)
          sellRates.add({'min': '0', 'max': '—', 'rate': 'No rate'});
        built.putIfAbsent(currency, () => []).add({
          'network': networkCode,
          'buyRate': buyRate,
          'sellRate': sellRate,
          'buyRates': buyRates,
          'sellRates': sellRates,
        });
      }
      if (mounted) {
        setState(() {
          _currencies = currencySet.toList()..sort();
          _selectedCurrencyIndex = 0;
          _currencyNetworks = built;
          _loadingMarket = false;
          _marketError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMarket = false;
          _marketError = 'Server error';
        });
      }
    }
  }

  void _showRatesSheet(
      bool isBuy, String currency, String network, List<dynamic> rates) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
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
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Rate ${r['rate']}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: secondryColor),
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isBuy
                            ? EwareejiBuyScreen(wallet_accounts_id: widget.wallet_accounts_id)
                            : EwareejiSellScreen(wallet_accounts_id: widget.wallet_accounts_id),
                      ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: secondryColor,
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                  if (label == 'Sell')
                    screen = EwareejiSellScreen(wallet_accounts_id: widget.wallet_accounts_id);
                  else if (label == 'Buy')
                    screen = EwareejiBuyScreen(wallet_accounts_id: widget.wallet_accounts_id);
                  else if (label == 'Setup')
                    screen = EwareejiSetupScreen(
                        wallet_accounts_id: widget.wallet_accounts_id);
                  else if (label == 'Transactions')
                    screen = EwareejiTransactionsScreen(wallet_accounts_id: widget.wallet_accounts_id);
                  if (screen != null)
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => screen!));
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(item['icon'] as IconData,
                          color: Colors.white, size: 28),
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
        if (_loadingLastTransactions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          )
        else if (_lastTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No recent transactions',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          )
        else
          ..._lastTransactions.map((t) {
            final isBuy = t.type == 'BUY';
            final amountStr =
                '${t.cryptoAmount.toStringAsFixed(t.cryptoAmount.truncateToDouble() == t.cryptoAmount ? 0 : 2)} ${t.customerWalletName ?? 'Crypto'}';
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isBuy ? primaryColor : Colors.orange)
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBuy ? 'Buy' : 'Sell',
                      style: const TextStyle(
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
                          amountStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rate ${t.rate.toStringAsFixed(2)} · ${_shortDate(t.createdAt)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _capitalize(t.status),
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
    if (_loadingMarket) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_marketError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Market',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_off_rounded,
                    color: Colors.white.withOpacity(0.8), size: 40),
                const SizedBox(height: 12),
                Text(
                  _marketError!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.95), fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loadMarketFromApi,
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                  label: const Text('Retry',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_currencies.isEmpty) {
      return const SizedBox.shrink();
    }
    final currency =
        _currencies[_selectedCurrencyIndex.clamp(0, _currencies.length - 1)];
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
                  padding: EdgeInsets.only(
                      right: i < _currencies.length - 1 ? 6 : 0),
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
                            color: isSelected
                                ? secondryColor
                                : Colors.white.withOpacity(0.95),
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
            return _buildNetworkCard(
                currency, network, buyRate, sellRate, buyRates, sellRates);
          }),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No networks for $currency',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 14),
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
                  colors: [
                    secondryColor.withOpacity(0.2),
                    secondryColor.withOpacity(0.08)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.lan_rounded, color: secondryColor, size: 20),
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
          Icon(icon,
              size: 12, color: isBuy ? primaryColor : Colors.orange.shade700),
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
