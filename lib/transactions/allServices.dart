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
import 'package:asalpay/ewareeji/ewareeji_main_screen.dart';
import 'package:flutter/material.dart';

class AllServices extends StatefulWidget {
  final String? wallet_accounts_id;
  const AllServices({super.key, this.wallet_accounts_id});
  @override
  _AllServicesState createState() => _AllServicesState();
}

class _AllServicesState extends State<AllServices> {
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
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMostUsedSection() {
    final items = [
      (Icons.home_rounded, 'Home Design', () => HomeDesignShowcaseScreen(wallet_accounts_id: widget.wallet_accounts_id!)),
      (Icons.receipt_rounded, 'Top Up', () => const TopUpScreen()),
      (Icons.transform_rounded, 'Transfer', () => T1.Transfer(wallet_accounts_id: widget.wallet_accounts_id!)),
      (Icons.send_rounded, 'Send Money', () => Searchpage1(wallet_accounts_id: widget.wallet_accounts_id!)),
      (Icons.qr_code_scanner_rounded, 'Pay Merchant', () => Merchant(wallet_accounts_id: widget.wallet_accounts_id!)),
      (Icons.swap_horiz_rounded, 'Funds Transfer', () => FundMoving(wallet_accounts_id: widget.wallet_accounts_id)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.88,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _serviceCard(
            item.$1,
            item.$2,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.$3())),
          );
        },
      ),
    );
  }

  Widget _buildAllServicesGrid() {
    final items = [
      (Icons.devices_other_rounded, '252Pay', () => ProductPurchaseScreen(wallet_accounts_id: widget.wallet_accounts_id)),
      (Icons.shopping_basket_rounded, 'Qoys Kaab', () => QowsKaabProductsScreen(walletAccountId: widget.wallet_accounts_id ?? '')),
      (Icons.payments_rounded, 'Pay Bill', () => ServicePaymentScreen(walletAccountsId: widget.wallet_accounts_id!)),
      (Icons.receipt_long_rounded, 'Funds Transfer', () => FundMoving(wallet_accounts_id: widget.wallet_accounts_id)),
      (Icons.history_rounded, 'All Transactions', () => const Transfer()),
      (Icons.currency_exchange_rounded, 'E-Wareeji', () => EwareejiMainScreen(wallet_accounts_id: widget.wallet_accounts_id)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _serviceCard(
          item.$1,
          item.$2,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.$3())),
        );
      },
    );
  }

  Widget _serviceCard(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF8FAFC),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: C.secondryColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        C.secondryColor.withOpacity(0.18),
                        C.secondryColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 21, color: C.secondryColor),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
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
