import 'package:asalpay/FundMoving/FundMoving.dart';
import 'package:asalpay/PayBills/PayBills.dart';
import 'package:asalpay/constants/Constant.dart' as C;
import 'package:asalpay/home/home_design_showcase.dart';
import 'package:asalpay/sendMoney/searchpage.dart';
import 'package:asalpay/topup/TopUp.dart';
import 'package:asalpay/transfer/MerchantAccount.dart';
import 'package:asalpay/transfer/Transfer1.dart' as T1;
import 'package:asalpay/transactions/ProductPurchaseScreen.dart';
import 'package:asalpay/transactions/SeeAllTransactions.dart';
import 'package:asalpay/transactions/qows_kaab/qows_kaab_products_screen.dart';
import 'package:flutter/material.dart';

class AllServices extends StatefulWidget {
  final String? wallet_accounts_id;
  const AllServices({super.key, this.wallet_accounts_id});
  @override
  _AllServicesState createState() => _AllServicesState();
}

class _AllServicesState extends State<AllServices> {
  static const List<Color> _iconColors = [
    Color(0xFF02DF7E),
    Color(0xFF4DD0E1),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFFE57373),
    Color(0xFF9575CD),
    Color(0xFF4FC3F7),
    Color(0xFFFF8A65),
  ];

  void _showComingSoon() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.secondryColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Most Used', 'Quick access'),
                    const SizedBox(height: 10),
                    _buildMostUsedSection(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('All Services', 'Browse all'),
                    const SizedBox(height: 10),
                    _buildAllServicesGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Material(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Services',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostUsedSection() {
    final items = [
      (
        Icons.home_rounded,
        'Home Design',
        () => HomeDesignShowcaseScreen(
            wallet_accounts_id: widget.wallet_accounts_id!)
      ),
      (Icons.receipt_rounded, 'Top Up', () => const TopUpScreen()),
      (
        Icons.transform_rounded,
        'Transfer',
        () => T1.Transfer(wallet_accounts_id: widget.wallet_accounts_id!)
      ),
      (
        Icons.send_rounded,
        'Send Money',
        () => Searchpage1(wallet_accounts_id: widget.wallet_accounts_id!)
      ),
      (
        Icons.qr_code_scanner_rounded,
        'Pay Merchant',
        () => Merchant(wallet_accounts_id: widget.wallet_accounts_id!)
      ),
      (
        Icons.swap_horiz_rounded,
        'Funds Transfer',
        () => FundMoving(wallet_accounts_id: widget.wallet_accounts_id)
      ),
    ];
    const sectionBg = 0.12;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(sectionBg),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _serviceCard(
            item.$1,
            item.$2,
            _iconColors[index % _iconColors.length],
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => item.$3())),
          );
        },
      ),
    );
  }

  Widget _buildAllServicesGrid() {
    final items = [
      (
        Icons.devices_other_rounded,
        C.kEasyShopServiceName,
        () =>
            ProductPurchaseScreen(wallet_accounts_id: widget.wallet_accounts_id)
      ),
      (
        Icons.shopping_basket_rounded,
        'Qoys Kaab',
        () => QowsKaabProductsScreen(
            walletAccountId: widget.wallet_accounts_id ?? '')
      ),
      (
        Icons.payments_rounded,
        'Pay Bill',
        () => ServicePaymentScreen(walletAccountsId: widget.wallet_accounts_id!)
      ),
      (
        Icons.receipt_long_rounded,
        'Funds Transfer',
        () => FundMoving(wallet_accounts_id: widget.wallet_accounts_id)
      ),
      (Icons.history_rounded, 'All Transactions', () => const Transfer()),
      (
        Icons.currency_bitcoin,
        'E-Wareeji',
        () => const SizedBox.shrink()
        // () => EwareejiMainScreen(
        //       wallet_accounts_id: widget.wallet_accounts_id,
        //     )
      ),
    ];
    const sectionBg = 0.12;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(sectionBg),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _serviceCard(
            item.$1,
            item.$2,
            _iconColors[index % _iconColors.length],
            () {
              if (item.$2 == 'E-Wareeji') {
                _showComingSoon();
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => EwareejiMainScreen(
                //       wallet_accounts_id: widget.wallet_accounts_id,
                //     ),
                //   ),
                // );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.$3()),
              );
            },
          );
        },
      ),
    );
  }

  Widget _serviceCard(
      IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.08),
        child: Container(
          decoration: const BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: iconColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: -0.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
