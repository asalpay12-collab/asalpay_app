import 'package:asalpay/filter/StyledWalletTransactionWidget.dart';
import 'package:flutter/material.dart';
// import 'package:contacts_service/contacts_service.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:provider/provider.dart';

import 'styled_transaction_widgetTwo.dart'; 


class FilteredTransactionsTwo extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String walletId;
  final Function(String selectedType) handleTypeSelection;

  FilteredTransactionsTwo({
    super.key,
    this.data,
    required this.walletId,
    required this.handleTypeSelection,
  });

  List<WalletTransactionModel> _filteredTransactionsWallet = [];

  @override
  _FilteredTransactionsTwoState createState() => _FilteredTransactionsTwoState();
}

class _FilteredTransactionsTwoState extends State<FilteredTransactionsTwo> {
  DateTimeRange? _dateRange;
  List<HomeTransactionModelRemittance> _filteredTransactionsTwo = [];
  bool _dataLoaded = false;


  //22/5/24

  bool? _filterByCustomer;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      final filters = widget.data!['filters'];
      _dateRange = filters['dateRange'] as DateTimeRange?;

      //22/4
      _filterByCustomer = filters['filterByCustomer'] as bool?;
      _phoneNumber = filters['phoneNumber'] as String?;


      final selectedType = filters['chosenType'] as String;
      _handleTypeSelection(selectedType);
    }
  }

  //22/05


void _fetchAndFilterTransactions(String selectedType) async {
  if (_dateRange == null) {
    print('No date range selected');
    return;
  }

  try {
    final homeSliderAndTransaction = Provider.of<HomeSliderAndTransaction>(context, listen: false);

    List<HomeTransactionModelRemittance> allTransactions = await homeSliderAndTransaction.fetchAndSetAllTrRemittance(
      walletId: widget.walletId,
      startDate: _dateRange!.start.toString(),
      endDate: _dateRange!.end.toString(),
    );

    
    if (_filterByCustomer == true && _phoneNumber != null) {
      allTransactions = allTransactions.where((transaction) =>
        transaction.holderAccount == _phoneNumber).toList();
    }

    _filteredTransactionsTwo = allTransactions;

    setState(() {
      _dataLoaded = true;
    });

    widget.handleTypeSelection(selectedType);

  } catch (error) {
    print("Error occurred while fetching transactions: $error");
  }
}



void _fetchWalletTransactions(String selectedType) async {
  if (_dateRange == null) {
    print('No date range selected');
    return;
  }

  try {
    final homeSliderAndTransaction = Provider.of<HomeSliderAndTransaction>(context, listen: false);

    List<WalletTransactionModel> walletTransactions = await homeSliderAndTransaction.fetchAndSetWalletTransactions(
      walletId: widget.walletId,
      startDate: _dateRange!.start.toString(),
      endDate: _dateRange!.end.toString(),
    );

    if (_filterByCustomer == true && _phoneNumber != null) {
      walletTransactions = walletTransactions.where((transaction) =>
        transaction.walletAccountsIdTo == _phoneNumber).toList();
    }

    setState(() {
      widget._filteredTransactionsWallet = walletTransactions;
      _dataLoaded = true; 
    });

    widget.handleTypeSelection(selectedType);

  } catch (error) {
    print("Error occurred while fetching wallet transactions: $error");
  }
}


// to here 22/05 


  void _handleTypeSelection(String selectedType) {
    print('Selected type is $selectedType');
    if (selectedType == "Wallet") {
      _fetchWalletTransactions(selectedType);
    } else {
      Future.delayed(Duration.zero, () {
        print('Selected type is $selectedType');
        _fetchAndFilterTransactions(selectedType);
      });
    }
  }

@override
Widget build(BuildContext context) {
  print("_filteredTransactionsWallet length: ${widget._filteredTransactionsWallet.length}");

  if (!_dataLoaded) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtered Transactions'),
      ),
      body: const Center(
        child: CircularProgressIndicator(), 
      ),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Filtered Transactions'),
    ),
    body: (_filteredTransactionsTwo.isEmpty && widget._filteredTransactionsWallet.isEmpty)
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 50,
                  color: Colors.grey,
                ),
                SizedBox(height: 20),
                Text(
                  'No transactions found for the selected date range.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _filteredTransactionsTwo.isNotEmpty
                ? _filteredTransactionsTwo.length
                : widget._filteredTransactionsWallet.length,
            itemBuilder: (context, index) {
              final transaction = _filteredTransactionsTwo.isNotEmpty
                  ? _filteredTransactionsTwo[index]
                  : widget._filteredTransactionsWallet[index];

              if (transaction is HomeTransactionModelRemittance) {
                return StyledTransactionWidgetTwo(transaction: transaction);
              } else if (transaction is WalletTransactionModel) {
                return StyledWalletTransactionWidget(transaction: transaction);
              } else {
                return Container();
              }
            },
          ),
  );
}
}