import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constant.dart';
import '../models/product.dart';
import '../services/252pay_api_service.dart';
import '252pay/252pay_screen_background.dart';
import 'bnpl/bnpl_eligibility_check_screen.dart';

class BasketScreen extends StatefulWidget {
  final String? walletAccountId;
  final List<Map<String, dynamic>> basketItems;
  final Function(List<Map<String, dynamic>>)? onBasketUpdated;
  final Function(double totalAmount, List<Map<String, dynamic>> items)?
      onPayNow;
  final List<Product>? products;
  final void Function(Product product,
      void Function(Map<String, dynamic> item) onItemAdded)? onAddProduct;

  const BasketScreen({
    super.key,
    required this.walletAccountId,
    required this.basketItems,
    this.onBasketUpdated,
    this.onPayNow,
    this.products,
    this.onAddProduct,
  });

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  static final String baseUrl = ApiService.imgURL;

  late List<Map<String, dynamic>> _basketItems;
  bool _showAddMore = false;

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

  void _updateQuantity(int index, int delta) {
    setState(() {
      final qty = (_basketItems[index]['quantity'] as int) + delta;
      if (qty < 1) {
        _basketItems.removeAt(index);
      } else {
        _basketItems[index]['quantity'] = qty;
      }
    });
    widget.onBasketUpdated?.call(_basketItems);
  }

  void _addOrMergeItem(Map<String, dynamic> item) {
    setState(() {
      final productId = item['product_id'];
      final existingIndex =
          _basketItems.indexWhere((b) => b['product_id'] == productId);
      if (existingIndex >= 0) {
        _basketItems[existingIndex]['quantity'] =
            (_basketItems[existingIndex]['quantity'] as int) +
                (item['quantity'] as int);
      } else {
        _basketItems.add(item);
      }
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
      backgroundColor: secondryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: secondryColor,
        surfaceTintColor: Colors.transparent,
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

      body: Pay252ScreenBackground(
        child: SafeArea(
          top: false,
          child: _basketItems.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemsSection(),
                      if (widget.products != null &&
                          widget.products!.isNotEmpty &&
                          widget.onAddProduct != null)
                        _buildAddMoreSection(),
                      _buildTotalCard(totalAmount),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              size: 64, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Your basket is empty',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Basket',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text(
                  '${_basketItems.length} item${_basketItems.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_basketItems.length, (index) {
            final item = _basketItems[index];
            final quantity = item['quantity'] as int;
            final unitPrice = (item['unit_price'] as num).toDouble();
            final subtotal = quantity * unitPrice;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Product',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${unitPrice.toStringAsFixed(2)} each',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: primaryColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () =>
                                          _updateQuantity(index, -1),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                      style: IconButton.styleFrom(
                                        foregroundColor: primaryColor,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        '$quantity',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () =>
                                          _updateQuantity(index, 1),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                      style: IconButton.styleFrom(
                                        foregroundColor: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _removeItem(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'Remove',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildAddMoreSection() {
    final products = widget.products!;
    final crossAxisCount = MediaQuery.of(context).size.width < 600 ? 2 : 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showAddMore = !_showAddMore),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_shopping_cart,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add more products',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        Text(
                          'Browse and add more items without leaving',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showAddMore ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withOpacity(0.9),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_showAddMore) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Select a product to add',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final unitPrice = double.tryParse(product.unitPrice) ?? 0.0;
                final isInBasket =
                    _basketItems.any((b) => b['product_id'] == product.id);

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isInBasket
                          ? null
                          : () {
                              widget.onAddProduct!(product, _addOrMergeItem);
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '$baseUrl/${product.imagePath}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${unitPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: ElevatedButton(
                                onPressed: isInBasket
                                    ? null
                                    : () {
                                        widget.onAddProduct!(
                                            product, _addOrMergeItem);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  isInBasket ? 'In basket' : 'Add',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double totalAmount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: pay252CardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Amount',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: primaryColor.withOpacity(0.75),
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
        Expanded(
          child: SizedBox(
            height: 52,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onPayNow?.call(totalAmount, _basketItems);
                },
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withOpacity(0.2),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, color: primaryColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Pay Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
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
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withOpacity(0.15),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card,
                          color: Colors.white.withOpacity(0.95), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'BNPL',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
