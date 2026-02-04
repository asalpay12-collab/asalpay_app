import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import 'OrderItemsScreen.dart';

class OrderScreen extends StatelessWidget {
  final Product product;

  const OrderScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF005653);
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${product.name}', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: primaryColor)),
            const SizedBox(height: 20),
            Text('Order Items:', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            // Expanded(child: OrderItemsScreen(product: product)),
          ],
        ),
      ),
    );
  }
}
