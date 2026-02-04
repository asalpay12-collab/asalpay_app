import 'package:asalpay/FundMoving/FundMoving.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:asalpay/topup/TopUp.dart';
import 'package:asalpay/sendMoney/searchpage.dart';
import 'package:asalpay/transfer/MerchantAccount.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../login/login.dart';
import '../providers/auth.dart';
import '../transfer/Transfer1.dart';
import '../PayBills/PayBills.dart';

import '../home/home_design_showcase.dart';

//filterScreen original
//filterScreen copy

class MostUsedServices extends StatefulWidget {
  final String? wallet_accounts_id;

  final String? fullName;
  

  const MostUsedServices({super.key, this.wallet_accounts_id,  this.fullName,});

  @override
  State<MostUsedServices> createState() => _MostUsedServicesState();
}

class _MostUsedServicesState extends State<MostUsedServices> {


   BalanceDisplayModel? currentBalance; 
   HomeTransactionModel? currentTransactions;


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return SizedBox(
        height: constraints.maxWidth * 0.01 * 28,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,  
              children: [
                
// serviceCard(
//   Icons.receipt,
//   "Pay Bill",#
//   ServicePaymentScreen( 
//     walletAccountsId: widget.wallet_accounts_id!,
  
//   ),
// ),

                serviceCard(
                  Icons.home,
                  "Home Design",
                  HomeDesignShowcaseScreen(wallet_accounts_id: widget.wallet_accounts_id!),
                ),

                serviceCard(Icons.receipt, "Top Up", const TopUpScreen()),
                serviceCard(Icons.transform, "Transfer", Transfer(wallet_accounts_id: widget.wallet_accounts_id!)),
                serviceCard(Icons.send_rounded, "Send Money", Searchpage1(wallet_accounts_id: widget.wallet_accounts_id!)),
                serviceCard(Icons.qr_code_scanner_sharp, "Pay Merchant", Merchant(wallet_accounts_id: widget.wallet_accounts_id!)),
                serviceCard(Icons.move_up, "Funds Transfer", FundMoving(wallet_accounts_id: widget.wallet_accounts_id!)),
               // serviceCard(Icons.filter_list, "Filter", FilterScreen(wallet_accounts_id: widget.wallet_accounts_id!)), 

                //tijaabo
              //  serviceCard(Icons.chat, "Chat", AsalChatsScreen(
              //   wallet_accounts_id: widget.wallet_accounts_id!,
              //   fullName: widget.fullName,
                
              //   )), 
              
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget serviceCard(IconData icon, String title, Widget destination) {
    return InkWell(
      onTap: () {
        final auth = Provider.of<Auth>(context, listen: false);
        if (auth.isAuth) {
          auth.autoLogout(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
        }
      },
      child: card(icon, title),
    );
  }

  Widget card(IconData icn, String txt) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.2;
    final double cardHeight = MediaQuery.of(context).size.height * 0.07;
    return Padding(
      padding: const EdgeInsets.all(5.5),
      child: Container(
        width: cardWidth,
        height: cardHeight + 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: secondryColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icn, size: cardHeight * 0.4, color: Colors.white),
            SizedBox(height: cardHeight * 0.1),
            Text(
              txt,
              style: TextStyle(fontSize: cardHeight * 0.2, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}