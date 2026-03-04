import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/252pay_basket_provider.dart';
import '../../services/252pay_api_service.dart';
import '../../services/bnpl_api_service.dart';
import '../basket_screen.dart';
import '../DiscountProductsDrawer.dart';
import '../ProductPurchaseScreen.dart';
import '252pay_search_bar.dart';

class Pay252ProductsScreen extends StatefulWidget {
  const Pay252ProductsScreen({
    super.key,
    required this.walletAccountId,
    required this.selectedCategory,
    required this.selectedSubCategory,
  });

  final String? walletAccountId;
  final Category selectedCategory;
  final Category selectedSubCategory;

  @override
  State<Pay252ProductsScreen> createState() => _Pay252ProductsScreenState();
}

class _Pay252ProductsScreenState extends State<Pay252ProductsScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final Color bodyBg = Colors.white;
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();
  final bnplApi = BnplApiService();
  static String get baseUrl => ApiService.imgURL;

  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    searchController.addListener(_applyFilter);
  }

  void _applyFilter() {
    setState(() {
      final q = searchController.text.trim().toLowerCase();
      if (q.isEmpty) {
        filteredProducts = List.from(products);
      } else {
        filteredProducts =
            products.where((p) => p.name.toLowerCase().contains(q)).toList();
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final fetched =
          await api.fetchProducts(widget.selectedSubCategory.subCategoryId);
      if (mounted) {
        setState(() {
          products = fetched;
          _applyFilter();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  void _showOrderDialog(
    Product product,
    double unitPrice,
    String remainingQuantity, {
    void Function(Map<String, dynamic> item)? onItemAdded,
  }) {
    final quantityController = TextEditingController(text: '1');
    final totalController =
        TextEditingController(text: unitPrice.toStringAsFixed(2));
    double currentPrice = unitPrice;

    void updateTotal() {
      final qty = int.tryParse(quantityController.text) ?? 1;
      final total = qty * currentPrice;
      totalController.text = total.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Order ${product.name}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Price per unit'),
                              const SizedBox(height: 4),
                              Text(
                                '\$${currentPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      onChanged: (value) {
                        final qty = int.tryParse(value) ?? 1;
                        if (qty < 1) {
                          quantityController.text = '1';
                          quantityController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: quantityController.text.length),
                          );
                        }
                        updateTotal();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: totalController,
                      decoration: const InputDecoration(labelText: 'Total:'),
                      enabled: false,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: primaryColor)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty =
                        int.tryParse(quantityController.text) ?? 1;
                    final item = {
                      "product_id": product.id,
                      "quantity": qty,
                      "unit_price": currentPrice,
                      "name": product.name,
                    };
                    if (onItemAdded != null) {
                      onItemAdded(item);
                    } else {
                      context.read<Pay252BasketProvider>().addItem(item);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Added to basket'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Basket'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _payNow(double totalAmount, List<Map<String, dynamic>> items) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductPurchaseScreen(
          wallet_accounts_id: widget.walletAccountId,
          initialPaymentItems: items,
          initialPaymentTotal: totalAmount,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilter);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = context.watch<Pay252BasketProvider>();

    return Scaffold(
      backgroundColor: bodyBg,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.selectedSubCategory.subCategoryName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag, color: Colors.white),
                onPressed: () {
                  if (basket.orderItems.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BasketScreen(
                          walletAccountId: widget.walletAccountId,
                          basketItems: basket.orderItems,
                          onBasketUpdated: (updated) =>
                              context
                                  .read<Pay252BasketProvider>()
                                  .updateItems(updated),
                          onPayNow: _payNow,
                          products: products.isNotEmpty ? products : null,
                          onAddProduct: products.isNotEmpty
                              ? (Product product,
                                  void Function(Map<String, dynamic> item)
                                      onItemAdded) {
                                  _showOrderDialog(
                                    product,
                                    double.tryParse(product.unitPrice) ?? 0.0,
                                    product.remainingQuantity,
                                    onItemAdded: onItemAdded,
                                  );
                                }
                              : null,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Your basket is empty')),
                    );
                  }
                },
              ),
              if (basket.count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${basket.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pay252SearchBar(
                    controller: searchController,
                    hint: 'Search products…',
                    onChanged: (_) => _applyFilter(),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Select Product – ${widget.selectedSubCategory.subCategoryName}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Expanded(child: _buildProductGrid()),
                ],
              ),
      ),
      bottomNavigationBar: basket.count > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BasketScreen(
                                walletAccountId: widget.walletAccountId,
                                basketItems: basket.orderItems,
                                onBasketUpdated: (updated) =>
                                    context
                                        .read<Pay252BasketProvider>()
                                        .updateItems(updated),
                                onPayNow: _payNow,
                                products: products.isNotEmpty ? products : null,
                                onAddProduct: products.isNotEmpty
                                    ? (Product product,
                                        void Function(
                                                Map<String, dynamic> item)
                                            onItemAdded) {
                                        _showOrderDialog(
                                          product,
                                          double.tryParse(
                                                  product.unitPrice) ??
                                              0.0,
                                          product.remainingQuantity,
                                          onItemAdded: onItemAdded,
                                        );
                                      }
                                    : null,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag, size: 24),
                        label: Text(
                          'View Basket (${basket.count} items)',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiscountProductPurchaseScreen(
                                wallet_accounts_id: widget.walletAccountId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_offer, size: 20),
                        label: Text(
                          'Discount Products',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiscountProductPurchaseScreen(
                          wallet_accounts_id: widget.walletAccountId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_offer),
                  label: Text(
                    'Discount Products',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: br12),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProductGrid() {
    final crossAxisCount =
        MediaQuery.of(context).size.width < 600 ? 2 : 3;
    if (filteredProducts.isEmpty) {
      return Center(
        child: Text(
          products.isEmpty
              ? 'No products available.'
              : 'No products match your search.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (_, idx) {
        final product = filteredProducts[idx];
        final unitPrice = double.tryParse(product.unitPrice) ?? 0.0;
        return InkWell(
          borderRadius: br12,
          onTap: () => _showOrderDialog(
            product,
            unitPrice,
            product.remainingQuantity,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br12,
              color: cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.network(
                    '$baseUrl/${product.imagePath}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showOrderDialog(
                      product,
                      unitPrice,
                      product.remainingQuantity,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: br12),
                    ),
                    child: const Text('Order', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showProductDetailsSheet(
                    product,
                    unitPrice,
                    product.remainingQuantity,
                  ),
                  child: Text(
                    'View details',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProductDetailsSheet(
    Product product,
    double unitPrice,
    String remainingQuantity,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final screenHeight = mq.size.height;
        final bottomPadding = mq.viewPadding.bottom;
        return Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: br12,
                  child: Image.network(
                    '$baseUrl/${product.imagePath}',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${unitPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description.isEmpty
                              ? 'No description'
                              : product.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding + 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showOrderDialog(
                            product, unitPrice, remainingQuantity);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: br12),
                      ),
                      child: const Text('Order'),
                    ),
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}
