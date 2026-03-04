import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/252pay_api_service.dart';
import '../../models/qows_kaab_product.dart';
import 'qows_kaab_eligibility_screen.dart';
import 'qows_kaab_tracking_screen.dart';

class QowsKaabProductsScreen extends StatefulWidget {
  final String? walletAccountId;

  const QowsKaabProductsScreen({
    super.key,
    required this.walletAccountId,
  });

  @override
  State<QowsKaabProductsScreen> createState() => _QowsKaabProductsScreenState();
}

class _QowsKaabProductsScreenState extends State<QowsKaabProductsScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();
  static String get baseUrl => ApiService.imgURL;

  List<QowsKaabProduct> products = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController _searchController = TextEditingController();

  List<QowsKaabProduct> _filterProducts(List<QowsKaabProduct> list, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((p) =>
            (p.name ?? '').toLowerCase().contains(q) ||
            (p.categoryName ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await api.getQowsKaabProducts();
      setState(() {
        products = data.map((e) => QowsKaabProduct.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildProductsGrid() {
    final filteredProducts =
        _filterProducts(products, _searchController.text);
    if (filteredProducts.isEmpty && products.isNotEmpty) {
      return Center(
        child: Text(
          'No products match your search',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: br12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QowsKaabEligibilityScreen(
                    walletAccountId: widget.walletAccountId,
                  ),
                ),
              );
            },
            borderRadius: br12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.imagePath != null &&
                            product.imagePath!.isNotEmpty
                        ? Image.network(
                            '$baseUrl/${product.imagePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: cardBg,
                              child: Icon(
                                Icons.shopping_basket,
                                size: 40,
                                color: primaryColor,
                              ),
                            ),
                          )
                        : Container(
                            color: cardBg,
                            child: Icon(
                              Icons.shopping_basket,
                              size: 40,
                              color: primaryColor,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Product',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.categoryName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.categoryName!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'QOYS KAAB Products',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: br12),
            onSelected: (value) {
              if (value == 'my_applications') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QowsKaabTrackingScreen(
                      walletAccountId: widget.walletAccountId ?? '',
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'my_applications',
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'My QOYS KAAB Applications',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : products.isEmpty
                  ? Center(
                      child: Text(
                        'No QOYS KAAB products available',
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: [
                        // Info Card
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: br12,
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'QOYS KAAB offers household essentials on credit. Choose Monthly Pack or Daily Credit.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF005653)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: br12),
                              filled: true,
                              fillColor: cardBg,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Products Grid
                        Expanded(
                          child: _buildProductsGrid(),
                        ),
                        // Apply Button
                        SafeArea(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QowsKaabEligibilityScreen(
                                        walletAccountId: widget.walletAccountId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.credit_card, size: 20),
                                label: Text(
                                  'Apply for QOYS KAAB',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: br12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
