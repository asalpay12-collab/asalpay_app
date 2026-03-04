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
  bool _didFetch = false;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      _didFetch = true;
      Future.microtask(() async {
        try {
          await Provider.of<HomeSliderAndTransaction>(context, listen: false)
              .fetchAndSetAllTr();
        } catch (_) {}
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listPaths =
        Provider.of<HomeSliderAndTransaction>(context, listen: true);
    final transactions = listPaths.AllTransactions;

    return Scaffold(
      backgroundColor: secondryColor.withOpacity(0.9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "All Transactions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading && transactions.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : transactions.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Card(
                                  elevation: 4,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32, horizontal: 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 64,
                                          color: secondryColor.withOpacity(0.8),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No transactions yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Your transaction history will appear here',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => Navigator.pop(context),
                                          icon: const Icon(Icons.send, size: 20),
                                          label: const Text('Make a Transfer'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: secondryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AllTransactions(
                                  image:
                                      '${ApiUrls.BASE_URL}${transaction.image}',
                                  wallet_accounts_id:
                                      transaction.wallet_accounts_id,
                                  description: transaction.description,
                                  amount: transaction.tag == 'in'
                                      ? '+ ${transaction.currency_name} ${transaction.amount}'
                                      : '- ${transaction.currency_name} ${transaction.amount}',
                                  date: transaction.trx_date,
                                  currencyName: transaction.currency_name,
                                  tag: transaction.tag,
                                ),
                              );
                            },
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

class _AllTransactionsState extends State<AllTransactions>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
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
    Color amountColor = isPositive
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    String formattedDate =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.date));

    return GestureDetector(
      onTap: _toggleExpand,
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.image != null && widget.image!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          widget.image!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: secondryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: secondryColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.wallet_accounts_id,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.amount,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.description,
                    style: const TextStyle(
                      color: secondryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
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
