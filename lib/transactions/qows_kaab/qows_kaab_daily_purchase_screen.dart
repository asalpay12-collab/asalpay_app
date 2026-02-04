import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/252pay_api_service.dart';

class QowsKaabDailyPurchaseScreen extends StatefulWidget {
  final int qowsKaabId;
  final String walletAccountId;

  const QowsKaabDailyPurchaseScreen({
    super.key,
    required this.qowsKaabId,
    required this.walletAccountId,
  });

  @override
  State<QowsKaabDailyPurchaseScreen> createState() =>
      _QowsKaabDailyPurchaseScreenState();
}

class _QowsKaabDailyPurchaseScreenState
    extends State<QowsKaabDailyPurchaseScreen> {
  final Color primaryColor = const Color(0xFF005653);
  final Color cardBg = const Color(0xFFF8FAFA);
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();

  final TextEditingController itemController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<String> items = [];
  bool isSubmitting = false;

  @override
  void dispose() {
    itemController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (itemController.text.trim().isNotEmpty) {
      setState(() {
        items.add(itemController.text.trim());
        itemController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  Future<void> _submitPurchase() async {
    if (items.isEmpty) {
      _showError('Please add at least one item');
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await api.addDailyPurchase(
        qowsKaabId: widget.qowsKaabId,
        items: items,
        amount: amount,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily purchase added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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
          'Add Daily Purchase',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemController,
                    decoration: InputDecoration(
                      hintText: 'Enter item name',
                      prefixIcon: const Icon(Icons.shopping_basket),
                      border: OutlineInputBorder(borderRadius: br12),
                      filled: true,
                      fillColor: cardBg,
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle),
                  color: primaryColor,
                  iconSize: 40,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isNotEmpty)
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text(
              'Amount *',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter purchase amount',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: br12),
                filled: true,
                fillColor: cardBg,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Description (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter purchase description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: br12),
                filled: true,
                fillColor: cardBg,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: br12),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Add Purchase',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


