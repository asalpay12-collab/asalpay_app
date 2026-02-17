import 'package:asalpay/FundMoving/FundMoving.dart';
import 'package:asalpay/PayBills/PayBills.dart';
import 'package:asalpay/constants/Constant.dart' as ConstantColors;
import 'package:asalpay/transactions/ProductPurchaseScreen.dart';
import 'package:asalpay/transactions/SeeAllTransactions.dart';
import 'package:asalpay/transactions/qows_kaab/qows_kaab_products_screen.dart';
import 'package:asalpay/widgets/mostusedservices.dart';
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
        body: Padding(
      padding: EdgeInsets.only(
        top: AppBar().preferredSize.height,
        left: 15,
        right: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_ios_new,
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              const Text(
                "Services",
                style: TextStyle(
                  fontSize: 20,
                  // color:primaryColor,
                  color: ConstantColors.secondryColor,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 40,
          ),
          const Text(
            "Most Used",
            style: TextStyle(
                fontSize: 18,
                // color:primaryColor,
                color: ConstantColors.secondryColor),
          ),

          ///todo:mostused ones;
          MostUsedServices(wallet_accounts_id: widget.wallet_accounts_id),
          const Text(
            "All Services",
            style: TextStyle(
              color: ConstantColors.secondryColor,
              fontSize: 18,
            ),
          ),
          Expanded(
            child: GridView.count(
              primary: false,
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductPurchaseScreen(
                              wallet_accounts_id: widget.wallet_accounts_id)),
                    );
                  },
                  // child: card2(Icons.devices_other, ConstantColors.primaryColor, "252PAY"),

                  child: card2(
                      Icons.devices_other, ConstantColors.pureWhite, "252PAY"),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QowsKaabProductsScreen(
                          walletAccountId: widget.wallet_accounts_id ?? '',
                        ),
                      ),
                    );
                  },
                  child: card2(Icons.shopping_basket, ConstantColors.pureWhite,
                      "QOWS KAAB"),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServicePaymentScreen(
                          walletAccountsId: widget.wallet_accounts_id!,
                        ),
                      ),
                    );
                  },
                  child: card2(Icons.payments_outlined,
                      ConstantColors.pureWhite, "PayBill"),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FundMoving(
                          wallet_accounts_id: widget.wallet_accounts_id,
                        ),
                      ),
                    );
                  },
                  child: card2(Icons.receipt_long_outlined,
                      ConstantColors.pureWhite, "Funds transfer"),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Transfer()));

                    // MaterialPageRoute(builder: (context) => Transfer(walletAccountsId: widget.wallet_accounts_id!,)));
                  },
                  child: card2(Icons.move_to_inbox_outlined,
                      ConstantColors.pureWhite, "Transactions"),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget card2(IconData icn, Color clr, String txt) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.2;
    final double cardHeight = MediaQuery.of(context).size.height * 0.07;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Card(
        elevation: 4,
        color: ConstantColors.secondryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          // width: 90,
          // height: 90,
          width: cardWidth,
          height: cardHeight + 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ConstantColors.primaryColor.withOpacity(0.01),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icn,
                // size: 32,
                size: cardHeight * 0.5,
                color: clr,
              ),
              SizedBox(
                height: cardHeight * 0.2,
                // height: 10,
              ),
              Text(
                txt,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: cardHeight * 0.25,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
