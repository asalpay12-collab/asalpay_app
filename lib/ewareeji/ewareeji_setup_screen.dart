import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

/// E-Wareeji Setup screen – sample data for design.
/// Form → Submit → Confirmation (review info + waxa setup sameeyo) → Confirm → Success.
class EwareejiSetupScreen extends StatefulWidget {
  const EwareejiSetupScreen({super.key});

  @override
  State<EwareejiSetupScreen> createState() => _EwareejiSetupScreenState();
}

class _EwareejiSetupScreenState extends State<EwareejiSetupScreen> {
  static const List<String> _networks = ['TRC20', 'ERC20', 'BEP20'];
  String _selectedNetwork = _networks.first;
  final TextEditingController _nameController = TextEditingController(text: 'My USDT Wallet');
  final TextEditingController _addressController = TextEditingController(text: 'TXYZabc123...sample');
  int _step = 0; // 0=form, 1=confirmation (review), 2=success

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
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
                  child: _step == 0 ? _buildForm() : _step == 1 ? _buildConfirmationReview() : _buildSuccess(),
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
            _step == 0 ? 'Setup' : _step == 1 ? 'Confirm' : 'Done',
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
        _sectionCard('Select network', DropdownButtonFormField<String>(
          value: _selectedNetwork,
          decoration: _inputDecoration(),
          items: _networks.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
          onChanged: (v) => setState(() => _selectedNetwork = v ?? _selectedNetwork),
        )),
        const SizedBox(height: 16),
        _sectionCard('Wallet name', TextFormField(
          controller: _nameController,
          decoration: _inputDecoration(hint: 'e.g. My USDT Wallet'),
        )),
        const SizedBox(height: 16),
        _sectionCard('Address', TextFormField(
          controller: _addressController,
          decoration: _inputDecoration(hint: 'Wallet address'),
        )),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: secondryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }

  /// Confirmation screen: muujinta informationka + waxa setup-ku sameeyo, kadib Confirm.
  Widget _buildConfirmationReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            'Review your setup',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Confirm the information below. This will add a wallet for E-Wareeji on the selected network.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Network', _selectedNetwork),
              _infoRow('Wallet name', _nameController.text),
              _infoRow('Address', _addressController.text),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.95), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Setup-kaan wuxuu kuu darayaa wallet-kan E-Wareeji. Waxaad ku heli doontaa lacag bixinta iyo soo celinta ee ku xidhan network-ka $_selectedNetwork.',
                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: secondryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirm setup'),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Success screen: Wallet added, Back to E-Wareeji.
  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: Icon(Icons.done_all, color: primaryColor, size: 72)),
        const SizedBox(height: 16),
        const Center(child: Text('Wallet added', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Center(child: Text(_nameController.text, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16))),
        const SizedBox(height: 4),
        Center(child: Text(_selectedNetwork, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14))),
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
}
