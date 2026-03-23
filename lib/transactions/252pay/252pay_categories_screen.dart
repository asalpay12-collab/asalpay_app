import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/Constant.dart';
import '../../models/category.dart';
import '../../providers/252pay_basket_provider.dart';
import '../../services/252pay_api_service.dart';
import '../basket_screen.dart';
import '../my_orders_screen.dart';
import '../bnpl/bnpl_tracking_screen.dart';
import '../bnpl/bnpl_application_screen.dart';
import '../DiscountProductsDrawer.dart';
import '../ProductPurchaseScreen.dart';
import '252pay_search_bar.dart';
import '252pay_screen_background.dart';
import '252pay_subcategories_screen.dart';

class Pay252CategoriesScreen extends StatefulWidget {
  const Pay252CategoriesScreen({
    super.key,
    required this.walletAccountId,
  });

  final String? walletAccountId;

  @override
  State<Pay252CategoriesScreen> createState() => _Pay252CategoriesScreenState();
}

class _Pay252CategoriesScreenState extends State<Pay252CategoriesScreen> {
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();
  static String get baseUrl => ApiService.imgURL;

  List<Category> categories = [];
  List<Category> filteredCategories = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    searchController.addListener(_applyFilter);
  }

  void _applyFilter() {
    setState(() {
      final q = searchController.text.trim().toLowerCase();
      if (q.isEmpty) {
        filteredCategories = List.from(categories);
      } else {
        filteredCategories =
            categories.where((c) => c.categoryName.toLowerCase().contains(q)).toList();
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    try {
      final fetched = await api.fetchCategories();
      if (mounted) {
        setState(() {
          categories = fetched;
          _applyFilter();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cloth')) return Icons.checkroom;
    if (lower.contains('electronic')) return Icons.electrical_services;
    return Icons.category;
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
      backgroundColor: secondryColor,
      appBar: _buildAppBar(context, basket),
      body: Pay252ScreenBackground(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pay252SearchBar(
                        controller: searchController,
                        hint: 'Search categories…',
                        onChanged: (_) => _applyFilter(),
                      ),
                      const SizedBox(height: 20),
                      Expanded(child: _buildCategoryGrid()),
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Pay252BasketProvider basket) {
    return AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: pay252AppBarGradient(),
        ),
        foregroundColor: pureWhite,
        title: PopupMenuButton<String>(
          child: Text(
            kEasyShopServiceName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          offset: const Offset(0, 50),
          onSelected: (value) {
            if (value == 'my_bnpl_applications') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BnplTrackingScreen(
                    walletAccountId: widget.walletAccountId ?? '',
                  ),
                ),
              );
            } else if (value == 'my_orders') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyOrdersScreen(
                    walletAccountId: widget.walletAccountId!,
                  ),
                ),
              );
            } else if (value == 'draft_applications') {
              _handleDraftApplications();
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'my_bnpl_applications',
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: secondryColor),
                  const SizedBox(width: 12),
                  Text('My BNPL Applications', style: GoogleFonts.poppins()),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'my_orders',
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: secondryColor),
                  const SizedBox(width: 12),
                  Text('My Orders', style: GoogleFonts.poppins()),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'draft_applications',
              child: Row(
                children: [
                  Icon(Icons.drafts, color: secondryColor),
                  const SizedBox(width: 12),
                  Text('Draft Applications', style: GoogleFonts.poppins()),
                ],
              ),
            ),
          ],
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
                              context.read<Pay252BasketProvider>().updateItems(updated),
                          onPayNow: (totalAmount, items) {
                            if (context.mounted) {
                              _payNowFromCategories(context, totalAmount, items);
                            }
                          },
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
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
      );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pureWhite,
          boxShadow: [
            BoxShadow(
              color: secondryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
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
              backgroundColor: secondryColor,
              foregroundColor: pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: br12),
              elevation: 2,
              shadowColor: secondryColor.withValues(alpha: 0.3),
            ),
          ),
        ),
    );
  }

  Widget _buildCategoryGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : 3;
    if (filteredCategories.isEmpty) {
      return Center(
        child: Text(
          categories.isEmpty ? 'No categories available.' : 'No categories match your search.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9)),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: filteredCategories.length,
      itemBuilder: (_, idx) {
        final cat = filteredCategories[idx];
        return InkWell(
          borderRadius: br12,
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Pay252SubcategoriesScreen(
                  walletAccountId: widget.walletAccountId,
                  selectedCategory: cat,
                ),
              ),
            );
          },
          child: Container(
            decoration: pay252CardDecoration(),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    '$baseUrl/${cat.productImage}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      _getIconForCategory(cat.categoryName),
                      size: 40,
                      color: secondryColor.withValues(alpha: 0.6),
                    ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: secondryColor,
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.categoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _payNowFromCategories(
    BuildContext context,
    double totalAmount,
    List<Map<String, dynamic>> items,
  ) {
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

  Future<void> _handleDraftApplications() async {
    if (widget.walletAccountId == null || widget.walletAccountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet account ID is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final draft = await api.getApplicationDraft(widget.walletAccountId!);
      if (draft != null && draft['application_id'] != null && mounted) {
        List<Map<String, dynamic>> draftOrderItems = [];
        double draftTotalAmount = 0.0;
        if (draft['product_price'] != null) {
          draftTotalAmount = (draft['product_price'] is num)
              ? (draft['product_price'] as num).toDouble()
              : double.tryParse(draft['product_price'].toString()) ?? 0.0;
        }
        if (draft['order_items'] != null && draft['order_items'] is List) {
          draftOrderItems = List<Map<String, dynamic>>.from(draft['order_items']);
        } else if (draft['product_id'] != null) {
          draftOrderItems = [
            {
              'product_id': draft['product_id'],
              'quantity': 1,
              'subtotal': draftTotalAmount,
            },
          ];
        }
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BnplApplicationScreen(
              walletAccountId: widget.walletAccountId!,
              totalOrderAmount: draftTotalAmount,
              orderItems: draftOrderItems,
              initialStep: null,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No draft applications found.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
