import 'dart:async';

import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/ewareeji/ewareeji_setup_screen.dart';
import 'package:asalpay/services/ewareeji_api_service.dart';
import 'package:flutter/material.dart';

/// E-Wareeji Buy – wallets via [EwareejiApiService.getCustomerWalletsByAccount] only; rate → confirm → BUY.
class EwareejiBuyScreen extends StatefulWidget {
  const EwareejiBuyScreen({super.key, this.wallet_accounts_id});

  final String? wallet_accounts_id;

  @override
  State<EwareejiBuyScreen> createState() => _EwareejiBuyScreenState();
}

class _EwareejiBuyScreenState extends State<EwareejiBuyScreen> {
  static const List<String> _quickAmounts = ['50', '100', '200', '500', '1000'];

  List<EwareejiCustomerWallet> _customerWallets = [];
  bool _loadingWallets = true;
  EwareejiCustomerWallet? _selectedCustomerWallet;
  EwareejiRate? _selectedRate;
  bool _loadingRate = false;
  Timer? _rateDebounce;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _rateDisplayController = TextEditingController();
  int _step = 0; // 0=form, 1=details, 2=confirm, 3=done
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _amountController.addListener(_onAmountOrWalletChanged);
  }

  void _onAmountOrWalletChanged() {
    _rateDebounce?.cancel();
    _rateDebounce =
        Timer(const Duration(milliseconds: 500), _fetchRateIfNeeded);
  }

  Future<void> _fetchRateIfNeeded() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      if (mounted)
        setState(() {
          _selectedRate = null;
          _rateDisplayController.text = 'No rate';
        });
      return;
    }
    final amount = double.tryParse(amountStr);
    if (_selectedCustomerWallet == null || amount == null || amount <= 0) {
      if (mounted)
        setState(() {
          _selectedRate = null;
          _rateDisplayController.text = 'No rate';
        });
      return;
    }
    // Amount not empty and valid → call rate API (by wallet_id from customer wallet).
    if (!mounted) return;
    setState(() => _loadingRate = true);
    final rate = await EwareejiApiService.instance.getRateForAmount(
        _selectedCustomerWallet!.walletId, amount,
        type: 'buy');
    if (!mounted) return;
    final rateVal = rate?.rate ?? rate?.buyRate;
    setState(() {
      _selectedRate = rate;
      _loadingRate = false;
      _rateDisplayController.text = (rateVal != null && rateVal > 0)
          ? rateVal.toStringAsFixed(4)
          : 'No rate';
    });
  }

  Future<void> _loadWallets() async {
    setState(() => _loadingWallets = true);
    final svc = EwareejiApiService.instance;
    List<EwareejiCustomerWallet> cw = [];
    final accountId = widget.wallet_accounts_id?.trim();
    // Only by-account endpoint — no getCustomerWallets() merge (avoids wrong APIs / other users' data).
    if (accountId != null && accountId.isNotEmpty) {
      cw = await svc.getCustomerWalletsByAccount(accountId, activeOnly: false);
    }
    if (!mounted) return;
    setState(() {
      _customerWallets = cw;
      _loadingWallets = false;
      if (cw.isNotEmpty && _selectedCustomerWallet == null) {
        _selectedCustomerWallet = cw.first;
      }
    });
  }

  @override
  void dispose() {
    _rateDebounce?.cancel();
    _amountController.removeListener(_onAmountOrWalletChanged);
    _amountController.dispose();
    _rateDisplayController.dispose();
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
                  child: _step == 0
                      ? _buildStep0Content()
                      : _step == 1
                          ? _buildDetails()
                          : _step == 2
                              ? _buildConfirm()
                              : _buildConfirmation(),
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
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 22),
            onPressed: () {
              if (_step > 0)
                setState(() => _step--);
              else
                Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Text(
            _step == 0
                ? 'Buy'
                : _step == 1
                    ? 'Review'
                    : _step == 2
                        ? 'Confirm'
                        : 'Done',
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _goToReview() {
    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_selectedCustomerWallet == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a wallet')));
      return;
    }
    if (_selectedRate == null && !_loadingRate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(EwareejiApiService.instance.lastError ??
                'No rate for this amount')),
      );
      return;
    }
    setState(() => _step = 1);
  }

  bool get _showAddWalletPrompt =>
      _step == 0 &&
      widget.wallet_accounts_id != null &&
      widget.wallet_accounts_id!.trim().isNotEmpty &&
      !_loadingWallets &&
      _customerWallets.isEmpty;

  Future<void> _openSetupAndReload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EwareejiSetupScreen(wallet_accounts_id: widget.wallet_accounts_id),
      ),
    );
    if (!mounted) return;
    _loadWallets();
  }

  Widget _buildAddWalletPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 72, color: Colors.white.withOpacity(0.9)),
            const SizedBox(height: 24),
            Text(
              'You have no wallet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add a wallet to buy crypto.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openSetupAndReload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: secondryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0Content() {
    if (_showAddWalletPrompt) return _buildAddWalletPrompt();
    return _buildForm();
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          'Select wallet',
          _loadingWallets
              ? const SizedBox(
                  height: 48,
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)))
              : _customerWallets.isEmpty
                  ? const Text('No customer wallets. Tap Add wallet below.')
                  : DropdownButtonFormField<int>(
                      value: _customerWallets
                              .any((w) => w.id == (_selectedCustomerWallet?.id))
                          ? _selectedCustomerWallet?.id
                          : _customerWallets.first.id,
                      decoration: _inputDecoration(),
                      isExpanded: true,
                      selectedItemBuilder: (context) => _customerWallets
                          .map((w) => Text(
                                w.displayLabel,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ))
                          .toList(),
                      items: _customerWallets
                          .map((w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                w.displayLabel,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final found =
                            _customerWallets.where((w) => w.id == v).toList();
                        setState(() {
                          _selectedCustomerWallet = found.isNotEmpty
                              ? found.first
                              : _selectedCustomerWallet;
                        });
                        _onAmountOrWalletChanged();
                      },
                    ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
            'Amount to buy (fiat)',
            TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(hint: 'Enter amount'))),
        const SizedBox(height: 16),
        _sectionCard(
          'Rate',
          _loadingRate
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: secondryColor)),
                      const SizedBox(width: 12),
                      Text('Loading...',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 15)),
                    ],
                  ),
                )
              : TextFormField(
                  controller: _rateDisplayController,
                  readOnly: true,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: secondryColor),
                  decoration: _inputDecoration().copyWith(
                    filled: true,
                    fillColor: secondryColor.withOpacity(0.06),
                    suffixIcon: Icon(Icons.trending_up_rounded,
                        color: secondryColor.withOpacity(0.7), size: 22),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final fiat = double.tryParse(_amountController.text.trim()) ?? 0;
            final rate = _selectedRate?.rate ?? _selectedRate?.buyRate ?? 0;
            final crypto = rate > 0 ? fiat / rate : 0.0;
            final hasCrypto = rate > 0 && crypto > 0;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: secondryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: secondryColor.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.currency_bitcoin,
                      color: secondryColor.withOpacity(0.9), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Crypto amount (you get)',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.85))),
                        const SizedBox(height: 4),
                        Text(
                          hasCrypto ? crypto.toStringAsFixed(8) : '—',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text('Quick amounts',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts
              .map((a) => ActionChip(
                  label: Text(a),
                  onPressed: () => setState(() => _amountController.text = a)))
              .toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _customerWallets.isEmpty ? null : _goToReview,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: secondryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: const Text('Process'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    final amountStr = _amountController.text;
    final fiatAmount = double.tryParse(amountStr) ?? 0;
    final rate = _selectedRate?.rate ?? _selectedRate?.buyRate ?? 0;
    final cryptoAmount = rate > 0 ? fiatAmount / rate : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoRow('Wallet', _selectedCustomerWallet?.displayLabel ?? ''),
        _infoRow('Rate', rate > 0 ? rate.toStringAsFixed(4) : 'No rate'),
        _infoRow('Fiat amount (you pay)', '\$${fiatAmount.toStringAsFixed(2)}'),
        _infoRow('Crypto amount (you get)',
            cryptoAmount > 0 ? cryptoAmount.toStringAsFixed(8) : '—'),
        if (rate > 0 && cryptoAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${fiatAmount.toStringAsFixed(2)} ÷ ${rate.toStringAsFixed(4)} = ${cryptoAmount.toStringAsFixed(8)}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: secondryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Future<void> _onApproveBuy() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final rate = _selectedRate?.rate ?? _selectedRate?.buyRate ?? 0;
    if (amount <= 0 || rate <= 0 || _selectedCustomerWallet == null) return;
    final walletAccountId = int.tryParse(widget.wallet_accounts_id ?? '0') ?? 0;
    if (walletAccountId <= 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Wallet account not set. Open E-Wareeji from home.'),
            duration: Duration(seconds: 4)),
      );
      return;
    }
    final svc = EwareejiApiService.instance;
    final companyWallets = await svc.getCompanyWallets(activeOnly: true);
    final compList = companyWallets
        .where((w) => w.walletId == _selectedCustomerWallet!.walletId)
        .toList();
    final companyWallet = compList.isEmpty ? null : compList.first;
    if (companyWallet == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(svc.lastError ?? 'No company wallet for this network.'),
            duration: const Duration(seconds: 4)),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = true);
    final cryptoAmount = rate > 0 ? amount / rate : 0;
    final buyR = _selectedRate?.buyRate ?? 0.0;
    final sellR = _selectedRate?.sellRate ?? 0.0;
    final spreadAmount = (buyR - sellR).abs() * cryptoAmount;
    final txId = await svc.createTransaction(
      walletAccountId: walletAccountId,
      type: 'BUY',
      customerWalletId: _selectedCustomerWallet!.id,
      companyWalletId: companyWallet!.id,
      fiatAmount: amount.toDouble(),
      cryptoAmount: cryptoAmount.toDouble(),
      rate: rate.toDouble(),
      rateId: _selectedRate?.id,
      spreadAmount: spreadAmount,
      status: 'pending',
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (txId != null) {
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(svc.lastError ?? 'Failed to create transaction'),
            duration: const Duration(seconds: 5)),
      );
    }
  }

  Widget _buildConfirm() {
    final fiatAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    final rate = _selectedRate?.rate ?? _selectedRate?.buyRate ?? 0;
    final cryptoAmount = rate > 0 ? fiatAmount / rate : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child: Icon(Icons.check_circle_outline,
                color: Colors.white, size: 64)),
        const SizedBox(height: 16),
        const Center(
            child: Text('Confirm purchase?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600))),
        if (rate > 0 && cryptoAmount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _infoRow('Fiat amount', '\$${fiatAmount.toStringAsFixed(2)}'),
                _infoRow('Rate', rate.toStringAsFixed(4)),
                _infoRow('Crypto amount', cryptoAmount.toStringAsFixed(8)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _onApproveBuy,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: secondryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: secondryColor))
                : const Text('Approve'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    final fiatAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    final rate = _selectedRate?.rate ?? _selectedRate?.buyRate ?? 0;
    final cryptoAmount = rate > 0 ? fiatAmount / rate : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child: Icon(Icons.done_all, color: primaryColor, size: 72)),
        const SizedBox(height: 16),
        const Center(
            child: Text('Purchase successful',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        Center(
            child: Text(
                'Fiat: \$${fiatAmount.toStringAsFixed(2)} ÷ Rate: ${rate.toStringAsFixed(4)} = Crypto: ${cryptoAmount.toStringAsFixed(8)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 14))),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: const Text('Back to E-Wareeji'),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
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
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
