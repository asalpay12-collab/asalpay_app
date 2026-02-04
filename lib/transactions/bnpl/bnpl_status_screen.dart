import 'package:flutter/material.dart';
import '../../constants/Constant.dart';
import '../../services/bnpl_api_service.dart';

class BnplStatusScreen extends StatefulWidget {
  final String? walletAccountId;
  final int? applicationId;

  const BnplStatusScreen({
    super.key,
    required this.walletAccountId,
    this.applicationId,
  });

  @override
  State<BnplStatusScreen> createState() => _BnplStatusScreenState();
}

class _BnplStatusScreenState extends State<BnplStatusScreen> {
  final BnplApiService _apiService = BnplApiService();
  Map<String, dynamic>? _application;
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.applicationId != null) {
      _loadApplicationDetails();
    } else {
      _loadMyApplications();
    }
  }

  Future<void> _loadApplicationDetails() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getApplicationDetails(
        applicationId: widget.applicationId!,
      );
      setState(() {
        _application = result['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadMyApplications() async {
    setState(() => _isLoading = true);
    try {
      final applications = await _apiService.getMyApplications(
        walletAccount: widget.walletAccountId ?? '',
      );
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'green';
      case 'pending':
        return 'orange';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondryColor,
      appBar: AppBar(
        title: const Text('BNPL Application Status'),
        backgroundColor: primaryColor,
        foregroundColor: pureWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.applicationId != null && _application != null
              ? _buildApplicationDetails()
              : _buildApplicationsList(),
    );
  }

  Widget _buildApplicationDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Application Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_application!['status']) == 'green'
                            ? Colors.green
                            : _getStatusColor(_application!['status']) == 'red'
                                ? Colors.red
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _application!['status']?.toString().toUpperCase() ?? 'PENDING',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Application ID', _application!['application_id']?.toString()),
                _buildDetailRow('Total Amount', '\$${_application!['total_amount']}'),
                _buildDetailRow('Status', _application!['status']?.toString()),
                if (_application!['remarks'] != null)
                  _buildDetailRow('Remarks', _application!['remarks']?.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsList() {
    if (_applications.isEmpty) {
      return const Center(
        child: Text('No applications found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Application #${app['application_id']}'),
            subtitle: Text('Amount: \$${app['total_amount']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(app['status']) == 'green'
                    ? Colors.green
                    : _getStatusColor(app['status']) == 'red'
                        ? Colors.red
                        : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                app['status']?.toString().toUpperCase() ?? 'PENDING',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BnplStatusScreen(
                    walletAccountId: widget.walletAccountId,
                    applicationId: app['application_id'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
