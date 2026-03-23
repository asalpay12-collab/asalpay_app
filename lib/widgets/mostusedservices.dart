import 'package:asalpay/FundMoving/FundMoving.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:asalpay/topup/TopUp.dart';
import 'package:asalpay/sendMoney/searchpage.dart';
import 'package:asalpay/transfer/MerchantAccount.dart';
import 'package:flutter/material.dart';
import '../transfer/Transfer1.dart';
import '../home/home_design_showcase.dart';

//filterScreen original
//filterScreen copy

class MostUsedServices extends StatefulWidget {
  final String? wallet_accounts_id;
  final String? fullName;
  /// When true, shows smaller cards (e.g. on All Services screen).
  final bool compact;

  const MostUsedServices({super.key, this.wallet_accounts_id, this.fullName, this.compact = false});

  @override
  State<MostUsedServices> createState() => _MostUsedServicesState();
}

class _MostUsedServicesState extends State<MostUsedServices> {


   BalanceDisplayModel? currentBalance; 
   HomeTransactionModel? currentTransactions;


  @override
  Widget build(BuildContext context) {
    final bool compact = widget.compact;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: compact ? 8 : 10,
      crossAxisSpacing: compact ? 8 : 10,
      childAspectRatio: compact ? 0.92 : 0.85,
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 2),
      children: [
        serviceCard(
          Icons.home_rounded,
          "Home Design",
          HomeDesignShowcaseScreen(wallet_accounts_id: widget.wallet_accounts_id!),
        ),
        serviceCard(Icons.receipt_rounded, "Top Up", const TopUpScreen()),
        serviceCard(Icons.transform_rounded, "Transfer", Transfer(wallet_accounts_id: widget.wallet_accounts_id!)),
        serviceCard(Icons.send_rounded, "Send Money", Searchpage1(wallet_accounts_id: widget.wallet_accounts_id!)),
        serviceCard(Icons.qr_code_scanner_rounded, "Pay Merchant", Merchant(wallet_accounts_id: widget.wallet_accounts_id!)),
        serviceCard(Icons.swap_horiz_rounded, "Funds Transfer", FundMoving(wallet_accounts_id: widget.wallet_accounts_id!)),
      ],
    );
  }

  Widget serviceCard(IconData icon, String title, Widget destination) {
    return InkWell(
      onTap: () {
        // Do not logout here: user is still in app. Session expiry is handled by API 401 in each screen.
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      borderRadius: BorderRadius.circular(20),
      child: _buildCard(icon, title),
    );
  }

  Widget _buildCard(IconData icon, String title) {
    final bool compact = widget.compact;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 2),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          boxShadow: [
            BoxShadow(
              color: secondryColor.withOpacity(0.06),
              blurRadius: compact ? 10 : 14,
              offset: Offset(0, compact ? 3 : 5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 12,
            horizontal: compact ? 6 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      secondryColor.withOpacity(0.22),
                      secondryColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(icon, size: compact ? 18 : 22, color: secondryColor),
              ),
              SizedBox(height: compact ? 5 : 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
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
    );
  }
}