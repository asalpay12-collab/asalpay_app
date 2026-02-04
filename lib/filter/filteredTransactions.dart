import 'package:flutter/material.dart';
// import 'package:contacts_service/contacts_service.dart';


import 'package:asalpay/providers/HomeSliderandTransaction.dart';

import 'styled_transaction_widget.dart'; 


class FilteredTransactions extends StatefulWidget {
  final Map<String, dynamic>? data;

  const FilteredTransactions({super.key, this.data});

  @override
  _FilteredTransactionsState createState() => _FilteredTransactionsState();
}

class _FilteredTransactionsState extends State<FilteredTransactions> {
  List<HomeTransactionModel> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      final filters = widget.data!['filters'];
      final transactions = widget.data!['transactions'];
      _fetchAndFilterTransactions(filters, transactions);
    }
  }

  void _fetchAndFilterTransactions(
      Map<String, dynamic> filters, List<HomeTransactionModel> transactions) {
    // Implement filtering logic based on the filters received
    _filteredTransactions = transactions.where((transaction) {
      // Filter by date range
      if (filters['dateRange'] != null) {
        DateTime trxDate = DateTime.parse(transaction.trx_date);
        if (trxDate.isBefore(filters['dateRange'].start) ||
            trxDate.isAfter(filters['dateRange'].end)) {
          return false;
        }
      }

      if (filters['walletAccountId'] != null &&
          filters['walletAccountId'].isNotEmpty &&
          filters['walletAccountId'] != transaction.wallet_accounts_id) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtered Transactions'),
      ),
      body: ListView.builder(
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          return StyledTransactionWidget(transaction: transaction);
        },
      ),
    );
  }
}