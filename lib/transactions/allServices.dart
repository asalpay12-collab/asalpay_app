import 'package:asalpay/PayBills/PayBills.dart';
import 'package:asalpay/constants/Constant.dart' as ConstantColors;
import 'package:asalpay/transactions/ProductPurchaseScreen.dart';
import 'package:asalpay/transactions/SeeAllTransactions.dart';
import 'package:asalpay/widgets/mostusedservices.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';


class AllServices extends StatefulWidget {
  final String? wallet_accounts_id;
  const AllServices({super.key, this.wallet_accounts_id});
  @override
  _AllServicesState createState() => _AllServicesState();
}

class _AllServicesState extends State<AllServices> {
  void ShowUpcomingAlert1() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: "Upcoming",
      text: "New Service Coming Soon!",
      confirmBtnText: "Please wait",
      // backgroundColor: secondryColor.withOpacity(0.1),
      barrierDismissible: true,
      onConfirmBtnTap: () => Navigator.pop(context),
      textColor: ConstantColors.primaryColor,
      confirmBtnColor: ConstantColors.primaryColor,
      titleColor: ConstantColors.secondryColor,

      confirmBtnTextStyle: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

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
                    MaterialPageRoute(builder: (context) => ProductPurchaseScreen(wallet_accounts_id: widget.wallet_accounts_id )),
                  );
                },
                // child: card2(Icons.devices_other, ConstantColors.primaryColor, "252PAY"),

                child: card2(Icons.devices_other, ConstantColors.pureWhite, "252PAY"),

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
                child: card2(Icons.payments_outlined,ConstantColors.pureWhite, "PayBill"),
              ),
                InkWell(
                  onTap: () {                   
                     ShowUpcomingAlert1();

                  },
                  child: card2(
                      Icons.account_balance,ConstantColors.pureWhite, "Bank ACC"),
                ),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child: card2(
                    Icons.draw,
                    ConstantColors.pureWhite,
                    "Withdraw",
                  ),
                ),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child: card2(Icons.electrical_services, ConstantColors.pureWhite,
                      "BuyGoods and Services"),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Transfer()));

                      // MaterialPageRoute(builder: (context) => Transfer(walletAccountsId: widget.wallet_accounts_id!,)));

                  },
                  child: card2(Icons.move_to_inbox_outlined, ConstantColors.pureWhite,
                      "Transactions"),
                ),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child: card2(
                      Icons.view_column_outlined, ConstantColors.pureWhite, "Voucher"),
                ),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child: card2(Icons.pie_chart, ConstantColors.pureWhite, "Status"),
                ),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child: card2(
                      Icons.apartment_outlined, ConstantColors.pureWhite, "Find ATM"),
                ),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child:
                      card2(Icons.call_received, ConstantColors.pureWhite, "Receive"),
                ),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child: card3(const AssetImage("assets/asalicon.png"),
                      "Asalpay Advantages",ConstantColors.pureWhite),
                ),
                InkWell(
                    onTap: () {
                      ShowUpcomingAlert1();
                    },
                    child: card2(Icons.credit_card_rounded, ConstantColors.pureWhite,
                        " MyCards")),
                InkWell(
                  onTap: () {
                    ShowUpcomingAlert1();
                  },
                  child: card2(
                      Icons.microwave_outlined, ConstantColors.pureWhite, "Apply MFi"),
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
          height: cardHeight+20,
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
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: cardHeight * 0.25),
                textAlign: TextAlign.center,
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget card3(AssetImage sawir, String txt, Color clr) {
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
          height: cardHeight+20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ConstantColors.primaryColor.withOpacity(0.01),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(image: sawir, width: cardHeight * 0.7, color: clr),

              Text(
                txt,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: cardHeight * 0.25),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}