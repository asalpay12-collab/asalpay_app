import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/HomeSliderandTransaction.dart';
import '../services/api_urls.dart';

class Transfer extends StatefulWidget {


  const Transfer({super.key});

  @override
  _TransferState createState() => _TransferState();
}

class _TransferState extends State<Transfer> {


  @override
  Widget build(BuildContext context) {
    final listPaths = Provider.of<HomeSliderAndTransaction>(context, listen: false);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: AppBar().preferredSize.height,
          left: 15,
          right: 15,
        ),

        
  child: Container(
      color: const Color.fromARGB(255, 226, 225, 225),
    
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: primaryColor, 
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  "Transactions",
                  style: TextStyle(
                    fontSize: 22,
                  //  color: secondryColor, 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var transaction in listPaths.AllTransactions)
                        AllTransactions(
                          image: '${ApiUrls.BASE_URL}${transaction.image}',
                          wallet_accounts_id: transaction.wallet_accounts_id,
                          description: transaction.description,
                          amount: transaction.tag == 'in' 
                              ? '+ ${transaction.currency_name} ${transaction.amount}'
                              : '- ${transaction.currency_name} ${transaction.amount}',
                          date: transaction.trx_date,
                          currencyName: transaction.currency_name,
                          tag: transaction.tag,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class AllTransactions extends StatefulWidget {
  final String? image;
  final String wallet_accounts_id;
  final String description;
  final String amount;
  final String date;
  final String currencyName;
  final String tag;

  const AllTransactions({
    super.key,
    this.image,
    required this.wallet_accounts_id,
    required this.description,
    required this.amount,
    required this.date,
    required this.currencyName,
    required this.tag,
  });

  @override
  _AllTransactionsState createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isPositive = widget.tag.startsWith('in');
    Color textColor = isPositive ? const Color.fromARGB(255, 2, 247, 10) : const Color.fromARGB(248, 247, 1, 21);
    Color secondaryTextColor = const Color(0xFF005653);  
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.date));

    return GestureDetector(
      onTap: _toggleExpand,
      child: Card(
        //color: secondaryTextColor,
        surfaceTintColor: Colors.white,
        elevation: 4.0,
        margin: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 13.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.image != null) 
                    Padding(
                      padding: const EdgeInsets.only(right: 10, left: 0),
                      child: Container(
                        //width: 42,
                        //height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21.0), 
                          child: Image.network(
                            widget.image!,
                            width: 42.0, 
                            height: 42.0, 
                            //fit: BoxFit.contain,
                            alignment: Alignment.topLeft, 
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.wallet_accounts_id,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.amount,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,  
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
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
}
