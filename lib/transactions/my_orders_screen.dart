import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/252pay_api_service.dart';

class MyOrdersScreen extends StatefulWidget {
  final String walletAccountId;

  const MyOrdersScreen({super.key, required this.walletAccountId});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];
  final api = ApiService();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await api.getMyOrders(widget.walletAccountId);
      setState(() {
        orders = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: ${e.toString()}')),
      );
    }
  }

  void _cancelOrder({required String orderId}) async {
    try {
      await api.cancelOrder(orderId: orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order Cancelled successfully')),
      );
      fetchOrders(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void showConfirmDialog(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Cancellation"),
          content: const Text("Are you sure you want to cancel this order?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelOrder(orderId: orderId);
              },
              child: const Text("Yes, Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF005653);
    final Size screenSize = MediaQuery.of(context).size;
    final double textScale = MediaQuery.of(context).textScaleFactor;

    Map<String, List<Map<String, dynamic>>> groupedOrders = {};
    for (var order in orders) {
      final orderId = order['order_id'].toString();
      groupedOrders.putIfAbsent(orderId, () => []).add(order);
    }

    final groupedList = groupedOrders.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18 * textScale,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : groupedList.isEmpty
                ? Center(
                    child: Text(
                      "No orders found",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: groupedList.length,
                    itemBuilder: (context, index) {
                      final entry = groupedList[index];
                      final items = entry.value;

                      final orderDate = items.first['order_date'];
                      final status = items.first['status'];
                      final orderId = items.first['order_id'];
                      final totalAmount = double.tryParse(
                              items.first['total_amount'].toString()) ??
                          0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Header row with Order # and Cancel button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Order #${index + 1}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16 * textScale,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                    if (status.toString().toLowerCase() ==
                                            'pending' ||
                                        status.toString().toLowerCase() ==
                                            'processing' ||
                                        status.toString().toLowerCase() ==
                                            'accepted')
                                      ElevatedButton(
                                        onPressed: () =>
                                            showConfirmDialog(orderId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                /// Order meta info
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Date: $orderDate",
                                        style: GoogleFonts.poppins()),
                                    Text("Status: $status",
                                        style: GoogleFonts.poppins()),
                                    Text(
                                      "Total: \$${totalAmount.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                /// Table of order items
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: screenSize.width - 24,
                                    ),
                                    child: DataTable(
                                      columnSpacing: 16,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                              Colors.grey.shade200),
                                      columns: const [
                                        DataColumn(label: Text("Name")),
                                        DataColumn(label: Text("Qty")),
                                        DataColumn(label: Text("Unit Price")),
                                        DataColumn(label: Text("Subtotal")),
                                      ],
                                      rows: items.map((item) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                                Text(item['name'].toString())),
                                            DataCell(Text(
                                                item['quantity'].toString())),
                                            DataCell(Text(
                                                "\$${item['unit_price']}")),
                                            DataCell(
                                                Text("\$${item['subtotal']}")),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
