import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:contacts_service/contacts_service.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import '../services/api_urls.dart';


class StyledTransactionWidget extends StatefulWidget {
  final HomeTransactionModel transaction;

  const StyledTransactionWidget({
    super.key,
    required this.transaction,
  });

  @override
  _StyledTransactionWidgetState createState() => _StyledTransactionWidgetState();
}

class _StyledTransactionWidgetState extends State<StyledTransactionWidget> {
  bool _isDescriptionVisible = false;

  void _toggleDescriptionVisibility() {
    setState(() {
      _isDescriptionVisible = !_isDescriptionVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isPositive = widget.transaction.tag.startsWith('in');
    Color textColor = isPositive ? const Color.fromARGB(255, 2, 247, 10) : const Color.fromARGB(248, 247, 1, 21);
    Color secondaryTextColor = const Color(0xFF401A66);

    // Format the date
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.transaction.trx_date));

    return GestureDetector(
      onTap: _toggleDescriptionVisibility,
      child: Card(
       // color: Colors.grey[800],
       color: secondryColor,
        elevation: 4.0,
        margin: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 13.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.transaction.image != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10, left: 0),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(42),
                          child: Image.network(
                            '${ApiUrls.BASE_URL}${widget.transaction.image}',
                            width: 42,
                            height: 42,
                            fit: BoxFit.contain,
                            alignment: Alignment.topLeft,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.transaction.wallet_accounts_id,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              widget.transaction.amount,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: _isDescriptionVisible,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 16),
                        children: [
                          TextSpan(
                            text: '${widget.transaction.description} ',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 246, 242, 22),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: widget.transaction.amount,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
