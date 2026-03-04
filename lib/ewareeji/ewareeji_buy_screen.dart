import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

/// E-Wareeji Buy screen – sample data for design.
/// Wallets list, amount, quick amounts, Process → Details → Confirm → Confirmation.
class EwareejiBuyScreen extends StatefulWidget {
  const EwareejiBuyScreen({super.key});

  @override
  State<EwareejiBuyScreen> createState() => _EwareejiBuyScreenState();
}

class _EwareejiBuyScreenState extends State<EwareejiBuyScreen> {
  static const List<String> _sampleWallets = ['Main Wallet', 'Trading Wallet', 'Savings'];
  static const List<String> _quickAmounts = ['50', '100', '200', '500', '1000'];
  String _selectedWallet = _sampleWallets.first;
  final TextEditingController _amountController = TextEditingController(text: '100');
  int _step = 0; // 0=form, 1=details, 2=confirm, 3=done

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [secondryColor, secondryColor.withOpacity(0.82)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _step == 0 ? _buildForm() : _step == 1 ? _buildDetails() : _step == 2 ? _buildConfirm() : _buildConfirmation(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: () {
              if (_step > 0) setState(() => _step--);
              else Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Text(
            _step == 0 ? 'Buy' : _step == 1 ? 'Review' : _step == 2 ? 'Confirm' : 'Done',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          'Select wallet',
          DropdownButtonFormField<String>(
            value: _selectedWallet,
            decoration: _inputDecoration(),
            items: _sampleWallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (v) => setState(() => _selectedWallet = v ?? _selectedWallet),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard('Amount to buy', TextFormField(controller: _amountController, keyboardType: TextInputType.number, decoration: _inputDecoration(hint: 'Enter amount'))),
        const SizedBox(height: 12),
        const Text('Quick amounts', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((a) => ActionChip(label: Text(a), onPressed: () => setState(() => _amountController.text = a))).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: secondryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Process'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    final amount = _amountController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoRow('Wallet', _selectedWallet),
        _infoRow('Amount', '$amount USDT'),
        _infoRow('Rate', '1.00'),
        _infoRow('You pay', '\$$amount'),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: secondryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: Icon(Icons.check_circle_outline, color: Colors.white, size: 64)),
        const SizedBox(height: 16),
        const Center(child: Text('Confirm purchase?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 3),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: secondryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Approve'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: Icon(Icons.done_all, color: primaryColor, size: 72)),
        const SizedBox(height: 16),
        const Center(child: Text('Purchase successful', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Center(child: Text('${_amountController.text} USDT', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16))),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Back to E-Wareeji'),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
