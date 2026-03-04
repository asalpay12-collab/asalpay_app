import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// E-Wareeji Sell screen – sample data for design.
/// Select Wallet, Currency, Amount, Rate, quick amounts, Process → Details → Confirm → Confirmation; Negotiate.
class EwareejiSellScreen extends StatefulWidget {
  const EwareejiSellScreen({super.key});

  @override
  State<EwareejiSellScreen> createState() => _EwareejiSellScreenState();
}

class _EwareejiSellScreenState extends State<EwareejiSellScreen> {
  static const List<String> _wallets = ['Main Wallet', 'Trading Wallet'];
  static const List<String> _currencies = ['USDT', 'USDC', 'BUSD'];
  static const List<String> _quickAmounts = ['50', '100', '200', '500', '1000'];
  String _selectedWallet = _wallets.first;
  String _selectedCurrency = _currencies.first;
  final TextEditingController _amountController = TextEditingController(text: '100');
  final TextEditingController _rateController = TextEditingController(text: '0.99');
  int _step = 0;
  bool _showNegotiate = false;

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
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
            _step == 0 ? 'Sell' : _step == 1 ? 'Review' : _step == 2 ? 'Confirm' : 'Done',
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
        _sectionCard('Select wallet', DropdownButtonFormField<String>(
          value: _selectedWallet,
          decoration: _inputDecoration(),
          items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
          onChanged: (v) => setState(() => _selectedWallet = v ?? _selectedWallet),
        )),
        const SizedBox(height: 16),
        _sectionCard('Currency', DropdownButtonFormField<String>(
          value: _selectedCurrency,
          decoration: _inputDecoration(),
          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCurrency = v ?? _selectedCurrency),
        )),
        const SizedBox(height: 16),
        _sectionCard('Amount', TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(hint: 'Amount to sell'),
        )),
        const SizedBox(height: 16),
        _sectionCard('Rate', TextFormField(
          controller: _rateController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(hint: 'Rate'),
        )),
        const SizedBox(height: 12),
        const Text('Quick amounts', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((a) => ActionChip(label: Text(a), onPressed: () => setState(() => _amountController.text = a))).toList(),
        ),
        if (_showNegotiate) ...[
          const SizedBox(height: 16),
          _sectionCard('Negotiate', const Text('Request a custom rate from the buyer. (Sample: Negotiate feature)', style: TextStyle(fontSize: 14))),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showNegotiate = !_showNegotiate),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(_showNegotiate ? 'Hide Negotiate' : 'Negotiate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 1),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: secondryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Process'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const String _depositAddress = 'TXYZa1b2c3d4e5f6g7h8i9j0...AsalPay';

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _depositAddress));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Address copied'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDetails() {
    final amount = _amountController.text;
    final rate = _rateController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoRow('Wallet', _selectedWallet),
        _infoRow('Currency', _selectedCurrency),
        _infoRow('Amount', '$amount $_selectedCurrency'),
        _infoRow('Rate', rate),
        _infoRow('You receive', '\$${((double.tryParse(amount) ?? 0) * (double.tryParse(rate) ?? 0)).toStringAsFixed(2)}'),
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

  Widget _addressRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Addresskeena (Deposit address)',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _depositAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _copyAddress(context),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.copy_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: Icon(Icons.check_circle_outline, color: Colors.white, size: 64)),
        const SizedBox(height: 16),
        const Center(child: Text('Confirm sell?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
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
        const Center(child: Text('Sell order placed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Center(child: Text('${_amountController.text} ${_selectedCurrency}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16))),
        const SizedBox(height: 20),
        _addressRow(context),
        const SizedBox(height: 24),
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
