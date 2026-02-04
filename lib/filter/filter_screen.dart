import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../filter/filteredTransactions.dart';
import 'package:provider/provider.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';

class FilterScreen extends StatefulWidget {
  final String wallet_accounts_id;

  const FilterScreen({super.key, required this.wallet_accounts_id});

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  String? _chosenType;
  DateTimeRange? _dateRange;
  bool _filterByCustomer = false;
  bool _sendOverEmail = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _chosenType = null;
      _dateRange = null;
      _filterByCustomer = false;
      _sendOverEmail = false;
      _phoneController.clear();
      _emailController.clear();
    });
  }

void _applyFilters(BuildContext context) {
  print('Chosen Type: $_chosenType');
  print('Date Range: $_dateRange');
  print('Filter by Customer: $_filterByCustomer');
  print('Send Over Email: $_sendOverEmail');
  print('Phone: ${_phoneController.text}');
  print('Email: ${_emailController.text}');

  final homeSliderAndTransaction = Provider.of<HomeSliderAndTransaction>(context, listen: false);
  final allTransactions = homeSliderAndTransaction.AllTransactions;

  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FilteredTransactions(
      data: {
        'filters': {
          'chosenType': _chosenType,
          'dateRange': _dateRange,
          'filterByCustomer': _filterByCustomer,
          'sendOverEmail': _sendOverEmail,
          'phone': _phoneController.text,
          'email': _emailController.text,
        },
        'transactions': allTransactions,
      },
    ),
  ),
);

}


Future<void> _selectContact() async {
  bool permissionGranted = await FlutterContacts.requestPermission();

  if (permissionGranted) {
    Contact? contact = await FlutterContacts.openExternalPick();

    if (contact != null && contact.phones.isNotEmpty) {
      setState(() {
        _phoneController.text = contact.phones.first.number ?? '';
      });
    } else {
      setState(() {
        _phoneController.text = '';
      });
    }
  } else {
    _showPermissionErrorDialog();
  }
}

void _showPermissionErrorDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Permissions error'),
      content: const Text('Please enable contacts access permission in system settings.'),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    ),
  );
}

  void _showTypeSelection() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text("Wallet"),
              leading: Radio<String>(
                value: "Wallet",
                groupValue: _chosenType,
                onChanged: (value) {
                  setState(() { _chosenType = value; });
                  Navigator.of(ctx).pop();  
                  _showDatePicker();
                },
              ),
            ),
            ListTile(
              title: const Text("Remittance"),
              leading: Radio<String>(
                value: "Remittance",
                groupValue: _chosenType,
                onChanged: (value) {
                  setState(() { _chosenType = value; });
                  Navigator.of(ctx).pop();  
                  _showDatePicker();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    ).then((pickedRange) {
      if (pickedRange != null) {
        setState(() {
          _dateRange = pickedRange;
        });
      }
    });
  }
  
  
  
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Filter By Date'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showTypeSelection,
        ),
      ],
    ),
    body: SingleChildScrollView( 
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterCard('Period', _dateRange != null 
              ? "${_dateFormat.format(_dateRange!.start)} to ${_dateFormat.format(_dateRange!.end)}" 
              : "Not set"),
            
            _buildFilterCard('Type', _chosenType ?? "Not set"),
            
            _buildFilterCard('Account', widget.wallet_accounts_id),
            
            SwitchListTile(
              title: const Text('Filter by Customer'),
              value: _filterByCustomer,
              onChanged: (bool value) => setState(() => _filterByCustomer = value),
            ),
            
            if (_filterByCustomer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts),
                      onPressed: _selectContact,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            
            SwitchListTile(
              title: const Text('Send Over Email'),
              value: _sendOverEmail,
              onChanged: (bool value) => setState(() => _sendOverEmail = value),
            ),
            
            if (_sendOverEmail)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Enter Email Address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.clear, size: 20),
                    label: const Text('Clear Filters'),
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Apply Filters'),
                    onPressed: () => _applyFilters(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFilterCard(String title, String value) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      title: Text(title),
      subtitle: Text(value, style: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500
      )),
    ),
  );
}


}