import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/Constant.dart';
import '../../services/bnpl_api_service.dart';
import 'bnpl_application_screen.dart';

class BnplProductsScreen extends StatefulWidget {
  final String? walletAccountId;

  const BnplProductsScreen({
    super.key,
    required this.walletAccountId,
  });

  @override
  State<BnplProductsScreen> createState() => _BnplProductsScreenState();
}

class _BnplProductsScreenState extends State<BnplProductsScreen> {
  final BnplApiService _apiService = BnplApiService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _totalAmount = 0.0;
  final List<Map<String, dynamic>> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleProduct(Map<String, dynamic> product) {
    setState(() {
      final index =
          _selectedProducts.indexWhere((p) => p['id'] == product['id']);
      if (index >= 0) {
        _selectedProducts.removeAt(index);
      } else {
        _selectedProducts.add(product);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalAmount = _selectedProducts.fold(0.0, (sum, product) {
      final price = (product['price'] ?? 0.0) is double
          ? product['price'] as double
          : double.tryParse(product['price'].toString()) ?? 0.0;
      return sum + price;
    });
  }

  Future<void> _checkEligibilityAndProceed() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product')),
      );
      return;
    }

    try {
      final eligibility = await _apiService.checkEligibility(
        totalOrderAmount: _totalAmount,
      );

      if (eligibility['status'] == true &&
          eligibility['data']['eligible'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BnplApplicationScreen(
              walletAccountId: widget.walletAccountId,
              orderItems: _selectedProducts,
              totalOrderAmount: _totalAmount,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(eligibility['message'] ?? 'You are not eligible for BNPL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondryColor,
      appBar: AppBar(
        title: const Text('BNPL Products'),
        backgroundColor: primaryColor,
        foregroundColor: pureWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isSelected = _selectedProducts.any(
                            (p) => p['id'] == product['id'],
                          );
                          final price = (product['price'] ?? 0.0) is double
                              ? product['price'] as double
                              : double.tryParse(product['price'].toString()) ??
                                  0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected
                                ? primaryColor.withOpacity(0.1)
                                : pureWhite,
                            child: ListTile(
                              leading: product['image'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: product['image'].toString(),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.image),
                                    )
                                  : const Icon(Icons.image, size: 60),
                              title: Text(
                                product['name']?.toString() ??
                                    'Unknown Product',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'Price: \$${price.toStringAsFixed(2)}',
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: primaryColor)
                                  : const Icon(Icons.circle_outlined),
                              onTap: () => _toggleProduct(product),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: pureWhite,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${_totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _checkEligibilityAndProceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: pureWhite,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Apply for BNPL',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
