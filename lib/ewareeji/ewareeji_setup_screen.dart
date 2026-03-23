import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/services/ewareeji_api_config.dart';
import 'package:asalpay/services/ewareeji_api_service.dart';
import 'package:flutter/material.dart';

/// E-Wareeji Setup – wallet dropdown from API; Submit → POST customer-wallets.
/// wallet_accounts_id = AsalPay wallet account of the user (la diriyo API-ga as wallet_account_id).
class EwareejiSetupScreen extends StatefulWidget {
  const EwareejiSetupScreen({super.key, this.wallet_accounts_id});

  final String? wallet_accounts_id;

  @override
  State<EwareejiSetupScreen> createState() => _EwareejiSetupScreenState();
}

class _EwareejiSetupScreenState extends State<EwareejiSetupScreen> {
  List<EwareejiWallet> _walletsFromApi = [];
  bool _loadingWallets = true;
  int? _selectedWalletId;
  String? _selectedWalletLabel;
  /// Wallet IDs this customer has already registered (so we can show "Already added").
  Set<int> _alreadyAddedWalletIds = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int _step = 0; // 0=form, 1=confirmation (review), 2=success

  bool get _isAlreadyAdded =>
      _selectedWalletId != null && _alreadyAddedWalletIds.contains(_selectedWalletId);

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadMyCustomerWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => _loadingWallets = true);
    try {
      final list =
          await EwareejiApiService.instance.getWallets(activeOnly: true);
      final err = EwareejiApiService.instance.lastError;
      if (mounted) {
        setState(() {
          _walletsFromApi = list;
          _loadingWallets = false;
          if (list.isNotEmpty && _selectedWalletId == null) {
            _selectedWalletId = list.first.id;
            _selectedWalletLabel = list.first.displayLabel;
          }
        });
        if (list.isEmpty && err != null && err.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debug: $err'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingWallets = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallets error: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadMyCustomerWallets() async {
    final accountId = widget.wallet_accounts_id?.trim();
    if (accountId == null || accountId.isEmpty) return;
    try {
      final svc = EwareejiApiService.instance;
      List<EwareejiCustomerWallet> list =
          await svc.getCustomerWalletsByAccount(accountId, activeOnly: false);
      if (list.isEmpty) {
        final all = await svc.getCustomerWallets(activeOnly: false);
        list = all
            .where((w) => ewareejiWalletAccountIdsMatch(accountId, w.walletAccountId))
            .toList();
        // Never use `all` as fallback — would expose other customers' wallets.
      }
      if (mounted) {
        setState(() {
          _alreadyAddedWalletIds = list.map((w) => w.walletId).toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _confirmSetup() async {
    final address = _addressController.text.trim();
    final walletName = _nameController.text.trim();
    if (address.isEmpty) return;
    if (walletName.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Magaca wallet-ka waa waajib (Wallet name is required)'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    final svc = EwareejiApiService.instance;
    if (!EwareejiApiConfig.isConfigured && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug: Ewareeji API not configured (.env)'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    if (_selectedWalletId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug: No wallet selected. Load wallets first.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    if (_isAlreadyAdded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already you added this wallet. Choose another network/wallet.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    final walletAccountId = int.tryParse(widget.wallet_accounts_id ?? '0') ?? 0;
    final err = await svc.registerCustomerWallet(
      _selectedWalletId!,
      address,
      walletName,
      walletAccountId: walletAccountId,
    );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Register failed: $err'),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    if (mounted) {
      setState(() {
        _step = 2;
        _alreadyAddedWalletIds = {..._alreadyAddedWalletIds, _selectedWalletId!};
      });
    }
  }

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
                  child: _step == 0
                      ? _buildForm()
                      : _step == 1
                          ? _buildConfirmationReview()
                          : _buildSuccess(),
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
                ? 'Setup'
                : _step == 1
                    ? 'Confirm'
                    : 'Done',
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
          _loadingWallets
              ? const SizedBox(
                  height: 48,
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)))
              : _walletsFromApi.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No wallets from server. Check API or try again.',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14),
                          ),
                          if (EwareejiApiService.instance.lastError !=
                              null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Debug: ${EwareejiApiService.instance.lastError}',
                              style: TextStyle(
                                  color: Colors.amber.shade200, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      value:
                          _walletsFromApi.any((w) => w.id == _selectedWalletId)
                              ? _selectedWalletId
                              : _walletsFromApi.first.id,
                      decoration: _inputDecoration(),
                      isExpanded: true,
                      selectedItemBuilder: (context) => _walletsFromApi
                          .map((w) => Text(
                                w.displayLabel,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ))
                          .toList(),
                      items: _walletsFromApi
                          .map((w) => DropdownMenuItem<int>(
                                value: w.id,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 280),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (w.iconBytes != null) ...[
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.memory(
                                            w.iconBytes!,
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                                    width: 28, height: 28),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Flexible(
                                        child: Text(
                                          w.displayLabel,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final found =
                            _walletsFromApi.where((w) => w.id == v).toList();
                        setState(() {
                          _selectedWalletId = v;
                          _selectedWalletLabel = found.isNotEmpty
                              ? found.first.displayLabel
                              : _selectedWalletLabel;
                        });
                      },
                    ),
        ),
        if (_isAlreadyAdded) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Already you added this wallet. Choose another network/wallet.',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _sectionCard(
            'Wallet name',
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(hint: 'e.g. My USDT Wallet'),
            )),
        const SizedBox(height: 16),
        _sectionCard(
            'Address',
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration(hint: 'Wallet address'),
            )),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_walletsFromApi.isEmpty || _isAlreadyAdded)
                ? null
                : () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: secondryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
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
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Confirm the information below. This will add a wallet for E-Wareeji on the selected network.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Wallet', _selectedWalletLabel ?? ''),
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
              Icon(Icons.info_outline_rounded,
                  color: Colors.white.withOpacity(0.95), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Setup-kaan wuxuu kuu darayaa wallet-kan E-Wareeji. Waxaad ku heli doontaa lacag bixinta iyo soo celinta ee ku xidhan ${_selectedWalletLabel ?? ""}.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.95), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _confirmSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: secondryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Success screen: Wallet added, Back to E-Wareeji.
  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child: Icon(Icons.done_all, color: primaryColor, size: 72)),
        const SizedBox(height: 16),
        const Center(
            child: Text('Wallet added',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Center(
            child: Text(_nameController.text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 16))),
        const SizedBox(height: 4),
        Center(
            child: Text(_selectedWalletLabel ?? '',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 14))),
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
}
