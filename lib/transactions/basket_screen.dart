import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bnpl/bnpl_eligibility_check_screen.dart';

class BasketScreen extends StatefulWidget {
  final String? walletAccountId;
  final List<Map<String, dynamic>> basketItems;
  final Function(List<Map<String, dynamic>>)? onBasketUpdated;
  final Function(double totalAmount, List<Map<String, dynamic>> items)?
      onPayNow;

  const BasketScreen({
    super.key,
    required this.walletAccountId,
    required this.basketItems,
    this.onBasketUpdated,
    this.onPayNow,
  });

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  final Color primaryColor = const Color(0xFF005653);

  late List<Map<String, dynamic>> _basketItems;

  @override
  void initState() {
    super.initState();
    _basketItems = List.from(widget.basketItems);
  }

  void _removeItem(int index) {
    setState(() {
      _basketItems.removeAt(index);
    });
    widget.onBasketUpdated?.call(_basketItems);
  }

  double _calculateTotal() {
    return _basketItems.fold<double>(0.0, (sum, item) {
      final quantity = item['quantity'] as int;
      final unitPrice = (item['unit_price'] as num).toDouble();
      return sum + (quantity * unitPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotal();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.shopping_bag, size: 24),
            const SizedBox(width: 8),
            Text(
              'Basket (${_basketItems.length} items)',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (_basketItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear basket',
              onPressed: () {
                setState(() {
                  _basketItems.clear();
                });
                widget.onBasketUpdated?.call(_basketItems);
              },
            ),
        ],
      ),

      // ---------------- BODY ----------------
      body: _basketItems.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  _buildItemsSection(),
                  _buildTotalCard(totalAmount),
                ],
              ),
            ),

      // ---------------- FIXED SAFE BUTTONS ----------------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildPaymentButtons(totalAmount),
        ),
      ),
    );
  }

  // ================= UI SECTIONS =================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Your basket is empty',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Items',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_basketItems.length, (index) {
            final item = _basketItems[index];
            final quantity = item['quantity'] as int;
            final unitPrice = (item['unit_price'] as num).toDouble();
            final subtotal = quantity * unitPrice;

            return Card(
              elevation: 3,
              shadowColor: primaryColor.withOpacity(0.15),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Product',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity: $quantity',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${subtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double totalAmount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Amount',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: primaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButtons(double totalAmount) {
    return Row(
      children: [
        // PAY NOW
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onPayNow?.call(totalAmount, _basketItems);
                // Do not pop here – Pay Now flow shows PIN dialog on top of basket,
                // then ProductPurchaseScreen pops basket after PIN is verified.
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // BNPL
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BnplEligibilityCheckScreen(
                      walletAccountId: widget.walletAccountId ?? '',
                      basketItems: _basketItems,
                      totalAmount: totalAmount,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.credit_card),
              label: const Text('Pay with BNPL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
