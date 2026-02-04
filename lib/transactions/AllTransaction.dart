// lib/widgets/all_transactions.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/widgets/safe_avatar.dart';

class AllTransactions extends StatefulWidget {
  final String? image;
  final String wallet_accounts_id;
  final String description;
  final String amount;
  final String date;
  final String currencyName;
  final String tag;
  final String wallet_accounts;

  const AllTransactions({
    Key? key,
    this.image,
    required this.wallet_accounts_id,
    required this.description,
    required this.amount,
    required this.date,
    required this.currencyName,
    required this.tag,
    required this.wallet_accounts,
  }) : super(key: key);

  @override
  _AllTransactionsState createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _expandAnim =
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
  bool _expanded = false;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isIn = widget.tag.startsWith('in');
    final Color amountColor =
        isIn ? const Color(0xFF01A206) : const Color(0xFFF70115);
    final String formattedDate =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.date));

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        color: Colors.grey[200],
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    SafeAvatar(imagePath: widget.image, size: 42, radius: 0, imageUrl: '',),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top row: ID | Amount ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.wallet_accounts_id,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                widget.amount,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: amountColor),
                              ),
                            ],
                          ),

                          // ── Date, aligned right ──
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Expandable description ──
                SizeTransition(
                  sizeFactor: _expandAnim,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 52), 
                        // indent under the avatar
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 14),
                              children: [
                                TextSpan(
                                  text: '${widget.description} ',
                                  style: const TextStyle(
                                      color: secondryColor,
                                      fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: widget.amount,
                                  style: TextStyle(
                                      color: amountColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            maxLines: _expanded ? 5 : 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ],
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
