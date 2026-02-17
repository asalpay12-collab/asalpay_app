
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/widgets/safe_avatar.dart';
import 'package:asalpay/transactions/SeeAllTransactions.dart' as SeeAllTransactionsFile;
import 'package:asalpay/transactions/allServices.dart';
import 'package:asalpay/sendMoney/searchpage.dart';
import 'package:asalpay/topup/TopUp.dart';

import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:asalpay/providers/Walletremit.dart';

import 'dart:ui' show ImageFilter;


class HomeDesignShowcaseScreen extends StatefulWidget {
  final String wallet_accounts_id;
  const HomeDesignShowcaseScreen({super.key, required this.wallet_accounts_id});

  @override
  State<HomeDesignShowcaseScreen> createState() => _HomeDesignShowcaseScreenState();
}

enum _Design { option1, option2, option3, option4, option5 }

class _HomeDesignShowcaseScreenState extends State<HomeDesignShowcaseScreen> {
  // data
  BalanceDisplayModel? _balance;
  List<HomeSliderModel> _sliderModels = [];
  List<HomeTransactionModel> _transactions = [];
  ImageProvider? _avatarProvider;

  // ui
  bool _loading = true;
  _Design _selected = _Design.option1;
  String? _fName, _mName, _imageUrl;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final homeProv   = Provider.of<HomeSliderAndTransaction>(context, listen: false);
      final sliderProv = Provider.of<HomeSliderAndTransaction>(context, listen: false);
      final remitProv  = Provider.of<Walletremit>(context, listen: false);

      // 1) balance / header
      _balance = await homeProv.fetchUserData(widget.wallet_accounts_id);
      _fName   = _balance?.f_name ?? '';
      _mName   = _balance?.m_name ?? '';
      _imageUrl = _balance?.image;
      await _prefetchAvatarIfAny(_imageUrl);

      // 2) slider images
      await remitProv.fetchAndSetCountryFill();
      await sliderProv.fetchAndSetSliderImages();
      _sliderModels = sliderProv.images;

      // 3) transactions
      _transactions = await homeProv.fetchAndSetAllTr();
    } catch (_) {
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _prefetchAvatarIfAny(String? rawUrl) async {
    final url = _validImageUrl(rawUrl);
    if (url.isEmpty) return;
    try {
      final provider = CachedNetworkImageProvider(url);
      await precacheImage(provider, context);
      _avatarProvider = provider;
    } catch (_) {}
  }

  String _validImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return url.startsWith('http') ? url : '${ApiUrls.BASE_URL}$url';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 20) return 'Good Evening';
    return 'Good Night';
  }

  String _fullName() => '${_fName ?? ''} ${_mName ?? ''}'.trim();

  void _onSend() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Searchpage1(wallet_accounts_id: widget.wallet_accounts_id)),
    );
  }

  void _onReceive() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TopUpScreen()));
  }

  void _onMore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AllServices(wallet_accounts_id: widget.wallet_accounts_id)),
    );
  }

  void _onSeeAll() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SeeAllTransactionsFile.Transfer()));
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreview();

    return Scaffold(
      appBar: AppBar(backgroundColor: secondryColor, title: const Text('Home Design Options')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Option 1 (Current)'),
                        selected: _selected == _Design.option1,
                        onSelected: (_) => setState(() => _selected = _Design.option1),
                      ),
                      ChoiceChip(
                        label: const Text('Option 2 '),
                        selected: _selected == _Design.option2,
                        onSelected: (_) => setState(() => _selected = _Design.option2),
                      ),
                      ChoiceChip(
                        label: const Text('Option 3 '),
                        selected: _selected == _Design.option3,
                        onSelected: (_) => setState(() => _selected = _Design.option3),
                      ),

                      ChoiceChip(
                        label: const Text('Option 4 '),
                        selected: _selected == _Design.option4,
                        onSelected: (_) => setState(() => _selected = _Design.option4),
                      ),
                      ChoiceChip(
                        label: const Text('Option 5 '),
                        selected: _selected == _Design.option5,
                        onSelected: (_) => setState(() => _selected = _Design.option5),
                      ),


                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: preview,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    'This is a live preview. After you choose, we’ll replace the current HomeScreen with your selection.',
                    style: TextStyle(color: Colors.black.withOpacity(.6)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPreview() {
    switch (_selected) {
      case _Design.option1:
        return DefaultHomeBody(
          balance: _balance,
          sliderModels: _sliderModels,
          transactions: _transactions,
          isShort: true,
          bottomSafe: 0,
          avatarProvider: _avatarProvider,
          fullName: _fullName,
          greeting: _greeting,
          validImageUrl: _validImageUrl,
          onSend: _onSend,
          onReceive: _onReceive,
          onMore: _onMore,
          onSeeAll: _onSeeAll,
          preview: true,
        );
      case _Design.option2:
        return GlassHomeBody(
          balance: _balance,
          sliderModels: _sliderModels,
          transactions: _transactions,
          isShort: true,
          bottomSafe: 0,
          avatarProvider: _avatarProvider,
          fullName: _fullName,
          greeting: _greeting,
          validImageUrl: _validImageUrl,
          onSend: _onSend,
          onReceive: _onReceive,
          onMore: _onMore,
          onSeeAll: _onSeeAll,
        );
      case _Design.option3:
        return CardyHomeBody(
          balance: _balance,
          sliderModels: _sliderModels,
          transactions: _transactions,
          isShort: true,
          bottomSafe: 0,
          avatarProvider: _avatarProvider,
          fullName: _fullName,
          greeting: _greeting,
          validImageUrl: _validImageUrl,
          onSend: _onSend,
          onReceive: _onReceive,
          onMore: _onMore,
          onSeeAll: _onSeeAll,
        );


      case _Design.option4:
  return NeoHomeBody(
    balance: _balance,
    sliderModels: _sliderModels,
    transactions: _transactions,
    isShort: true,
    bottomSafe: 0,
    avatarProvider: _avatarProvider,
    fullName: _fullName,
    greeting: _greeting,
    validImageUrl: _validImageUrl,
    onSend: _onSend,
    onReceive: _onReceive,
    onMore: _onMore,
    onSeeAll: _onSeeAll,
  );
case _Design.option5:
  return DarkHomeBody(
    balance: _balance,
    sliderModels: _sliderModels,
    transactions: _transactions,
    isShort: true,
    bottomSafe: 0,
    avatarProvider: _avatarProvider,
    fullName: _fullName,
    greeting: _greeting,
    validImageUrl: _validImageUrl,
    onSend: _onSend,
    onReceive: _onReceive,
    onMore: _onMore,
    onSeeAll: _onSeeAll,
  );

    }
  }
}

class DefaultHomeBody extends StatelessWidget {
  final BalanceDisplayModel? balance;
  final List<HomeSliderModel> sliderModels;
  final List<HomeTransactionModel> transactions;
  final bool isShort;
  final double bottomSafe;
  final ImageProvider? avatarProvider;
  final String Function() fullName;
  final String Function() greeting;
  final String Function(String?) validImageUrl;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onMore;
  final VoidCallback onSeeAll;
  final bool preview;

  const DefaultHomeBody({
    super.key,
    required this.balance,
    required this.sliderModels,
    required this.transactions,
    required this.isShort,
    required this.bottomSafe,
    required this.avatarProvider,
    required this.fullName,
    required this.greeting,
    required this.validImageUrl,
    required this.onSend,
    required this.onReceive,
    required this.onMore,
    required this.onSeeAll,
    this.preview = false,
  });

  bool _isCredit(String? tag) {
    if (tag == null) return false;
    final t = tag.toLowerCase();
    return t == 'in' || t == 'credit' || t == 'cr';
  }

  @override
  Widget build(BuildContext context) {
    final sliderH = 200.0;
    final clampedSliderH = sliderH.clamp(140.0, 220.0);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [secondryColor, secondryColor.withOpacity(0.85)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: secondryColor.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(greeting(), style: const TextStyle(color: Colors.white70)),
                  Row(
                    children: [
                      ClipOval(
                        child: avatarProvider != null
                            ? Image(image: avatarProvider!, width: 36, height: 36, fit: BoxFit.cover)
                            : SafeAvatar(imagePath: validImageUrl(balance?.image), size: 36, radius: 0, imageUrl: ''),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fullName().isEmpty ? 'User' : fullName(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${balance?.currency_name ?? 'USD'} ${balance?.balance ?? '0.00'}',
                style: TextStyle(color: Colors.white, fontSize: isShort ? 26 : 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Pill(icon: Icons.arrow_upward, label: 'Send', onTap: onSend, filled: true),
                  const SizedBox(width: 10),
                  _Pill(icon: Icons.arrow_downward, label: 'Receive', onTap: onReceive, filled: true),
                  const SizedBox(width: 10),
                  _Pill(icon: Icons.widgets_outlined, label: 'More', onTap: onMore, filled: false),
                ],
              ),
            ],
          ),
        ),

        if (sliderModels.isNotEmpty)
          Container(
            height: clampedSliderH,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: PageView.builder(
              itemCount: sliderModels.length,
              itemBuilder: (_, index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: '${ApiUrls.BASE_URL}${sliderModels[index].imageUrl}',
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, __) => const SizedBox.expand(),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Transactions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (transactions.isEmpty)
          SizedBox(
            height: 160,
            child: Center(
              child: Text('No transactions yet', style: TextStyle(color: Colors.grey[600])),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, i) {
              if (preview && i >= 5) return const SizedBox.shrink();
              final tx = transactions[i];
              final credit = _isCredit(tx.tag);
              final amtColor = credit ? const Color(0xFF019206) : const Color(0xFFF70115);
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: SafeAvatar(imagePath: tx.image, size: 42, radius: 0, imageUrl: ''),
                  title: Text(tx.wallet_accounts_id ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(tx.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    (credit ? '+ ' : '- ') +
                        '${tx.currency_name ?? ''} ' +
                        (double.tryParse(tx.amount ?? '0')?.toStringAsFixed(2) ?? '0.00'),
                    style: TextStyle(color: amtColor, fontWeight: FontWeight.w900),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: preview ? (transactions.length.clamp(0, 5)) : transactions.length,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _Pill({required this.icon, required this.label, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    final bg = filled ? Colors.white : Colors.white.withOpacity(0.2);
    final fg = filled ? secondryColor : Colors.white;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartChipGridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SmartChipGridTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.black.withOpacity(.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: secondryColor),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}


class GlassHomeBody extends StatelessWidget {
  final BalanceDisplayModel? balance;
  final List<HomeSliderModel> sliderModels;
  final List<HomeTransactionModel> transactions;
  final bool isShort;
  final double bottomSafe;
  final ImageProvider? avatarProvider;
  final String Function() fullName;
  final String Function() greeting;
  final String Function(String?) validImageUrl;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onMore;
  final VoidCallback onSeeAll;

  final VoidCallback? onScanPay;
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;
  final VoidCallback? onBills;

  const GlassHomeBody({
    super.key,
    required this.balance,
    required this.sliderModels,
    required this.transactions,
    required this.isShort,
    required this.bottomSafe,
    required this.avatarProvider,
    required this.fullName,
    required this.greeting,
    required this.validImageUrl,
    required this.onSend,
    required this.onReceive,
    required this.onMore,
    required this.onSeeAll,
    this.onScanPay,
    this.onTopUp,
    this.onWithdraw,
    this.onBills,
  });

  bool _isCredit(String? tag) {
    if (tag == null) return false;
    final t = tag.toLowerCase();
    return t == 'in' || t == 'credit' || t == 'cr';
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [secondryColor, secondryColor.withOpacity(.72)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Container(
                          width: 48, height: 48,
                          color: Colors.white.withOpacity(.28),
                          child: avatarProvider != null
                              ? Image(image: avatarProvider!, fit: BoxFit.cover)
                              : SafeAvatar(imagePath: validImageUrl(balance?.image), size: 48, radius: 0, imageUrl: ''),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              fullName().isEmpty ? 'User' : fullName(),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        '${balance?.currency_name ?? 'USD'} ${balance?.balance ?? '0.00'}',
                        style: TextStyle(color: Colors.white, fontSize: isShort ? 26 : 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _GlassAction(icon: Icons.arrow_upward, label: 'Send', onTap: onSend),
                          const SizedBox(width: 10),
                          _GlassAction(icon: Icons.arrow_downward, label: 'Receive', onTap: onReceive),
                          const SizedBox(width: 10),
                          _GlassAction(icon: Icons.widgets_outlined, label: 'More', onTap: onMore),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (sliderModels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: '${ApiUrls.BASE_URL}${sliderModels.first.imageUrl}',
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, __) => const SizedBox.expand(),
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.grey[200], child: const Icon(Icons.error_outline)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: LayoutBuilder(
    builder: (ctx, c) {
      const spacing = 10.0;
      const perRow = 3;
      final cellW = (c.maxWidth - spacing * (perRow - 1)) / perRow;
      const cellH = 48.0; // chip height target
      final aspect = cellW / cellH;

      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: perRow,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspect,
        ),
        children: [
          _SmartChipGridTile(icon: Icons.qr_code_scanner, label: 'Scan & Pay', onTap: onScanPay),
          _SmartChipGridTile(icon: Icons.account_balance_wallet_outlined, label: 'Top Up', onTap: onTopUp),
          _SmartChipGridTile(icon: Icons.attach_money, label: 'Withdraw', onTap: onWithdraw),
          _SmartChipGridTile(icon: Icons.receipt_long_outlined, label: 'Bills', onTap: onBills),

          _SmartChipGridTile(icon: Icons.receipt_long_outlined, label: 'Pay Bills', onTap: onBills),

          _SmartChipGridTile(icon: Icons.receipt_long_outlined, label: '252PAY', onTap: onBills),
        ],
      );
    },
  ),
),



        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        // const SizedBox(height: 6),

        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _EmptyCard(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Your transaction history will appear here',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemBuilder: (_, i) {
              if (i >= (transactions.length > 6 ? 6 : transactions.length)) {
                return const SizedBox.shrink();
              }
              final tx = transactions[i];
              final credit = _isCredit(tx.tag);
              final amtColor = credit ? const Color(0xFF019206) : const Color(0xFFF70115);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: ListTile(
                  leading: SafeAvatar(imagePath: tx.image, size: 42, radius: 0, imageUrl: ''),
                  title: Text(tx.wallet_accounts_id ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(tx.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (credit ? '+ ' : '- ') +
                            '${tx.currency_name ?? ''} ' +
                            (double.tryParse(tx.amount ?? '0')?.toStringAsFixed(2) ?? '0.00'),
                        style: TextStyle(color: amtColor, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(_shortDate(tx.trx_date), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: transactions.length > 6 ? 6 : transactions.length,
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}


class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(12)});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(.20), width: 1),
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(.22), Colors.white.withOpacity(.10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(.18),
            border: Border.all(color: Colors.white.withOpacity(.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}


class _QuickServicesGlass extends StatelessWidget {
  final VoidCallback? onScanPay;
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;
  final VoidCallback? onBills;
  const _QuickServicesGlass({
    this.onScanPay,
    this.onTopUp,
    this.onWithdraw,
    this.onBills,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: LayoutBuilder(
        builder: (ctx, c) {
          const spacing = 10.0;
          const perRow = 3;
          final itemWidth = (c.maxWidth - (spacing * (perRow - 1))) / perRow;
          final items = <Widget>[
            _ServiceItemGlass(width: itemWidth, icon: Icons.qr_code_scanner, label: 'Scan & Pay', onTap: onScanPay),
            _ServiceItemGlass(width: itemWidth, icon: Icons.account_balance_wallet_outlined, label: 'Top Up', onTap: onTopUp),
            _ServiceItemGlass(width: itemWidth, icon: Icons.attach_money, label: 'Withdraw', onTap: onWithdraw),
            _ServiceItemGlass(width: itemWidth, icon: Icons.receipt_long_outlined, label: 'Bills', onTap: onBills),
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items,
          );
        },
      ),
    );
  }
}

class _ServiceItemGlass extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ServiceItemGlass({
    required this.width,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(.14),
            border: Border.all(color: Colors.white.withOpacity(.22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // circular frosted icon badge
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.18),
                  border: Border.all(color: Colors.white.withOpacity(.24)),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}


class _GlassTxTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String amountText;
  final Color amountColor;
  final String dateText;

  const _GlassTxTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.amountColor,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(.85))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountText, style: TextStyle(color: amountColor, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(.22)),
                ),
                child: Text(dateText, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class CardyHomeBody extends StatelessWidget {
  final BalanceDisplayModel? balance;
  final List<HomeSliderModel> sliderModels;
  final List<HomeTransactionModel> transactions;
  final bool isShort;
  final double bottomSafe;
  final ImageProvider? avatarProvider;
  final String Function() fullName;
  final String Function() greeting;
  final String Function(String?) validImageUrl;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onMore;
  final VoidCallback onSeeAll;

  const CardyHomeBody({
    super.key,
    required this.balance,
    required this.sliderModels,
    required this.transactions,
    required this.isShort,
    required this.bottomSafe,
    required this.avatarProvider,
    required this.fullName,
    required this.greeting,
    required this.validImageUrl,
    required this.onSend,
    required this.onReceive,
    required this.onMore,
    required this.onSeeAll,
  });

  bool _isCredit(String? tag) {
    if (tag == null) return false;
    final t = tag.toLowerCase();
    return t == 'in' || t == 'credit' || t == 'cr';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          decoration: BoxDecoration(
            color: secondryColor,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [BoxShadow(color: secondryColor.withOpacity(.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: ClipOval(
                  child: avatarProvider != null
                      ? Image(image: avatarProvider!, width: 44, height: 44, fit: BoxFit.cover)
                      : SafeAvatar(imagePath: validImageUrl(balance?.image), size: 44, radius: 0, imageUrl: ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting(), style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(fullName().isEmpty ? 'User' : fullName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Balance card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balance', style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${balance?.currency_name ?? 'USD'} ',
                        style: TextStyle(color: Colors.black87, fontSize: isShort ? 18 : 20, fontWeight: FontWeight.bold)),
                    Text(balance?.balance ?? '0.00',
                        style: TextStyle(color: Colors.black, fontSize: isShort ? 26 : 30, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _FilledPill(icon: Icons.arrow_upward, label: 'Send', onTap: onSend),
                    const SizedBox(width: 10),
                    _FilledPill(icon: Icons.arrow_downward, label: 'Receive', onTap: onReceive),
                    const SizedBox(width: 10),
                    _OutlinedPill(icon: Icons.widgets_outlined, label: 'More', onTap: onMore),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Slider row (cards)
        if (sliderModels.isNotEmpty)
          SizedBox(
            height: 146,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: '${ApiUrls.BASE_URL}${sliderModels[i].imageUrl}',
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.error_outline)),
                  ),
                ),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: sliderModels.length,
            ),
          ),
        const SizedBox(height: 16),
        // Smart shortcuts (dummy)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _SmartChip(icon: Icons.qr_code_scanner, label: 'Scan & Pay'),
              _SmartChip(icon: Icons.account_balance_wallet_outlined, label: 'Top Up'),
              _SmartChip(icon: Icons.attach_money, label: 'Withdraw'),
              _SmartChip(icon: Icons.receipt_long_outlined, label: 'Bills'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Transactions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _EmptyCard(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Your transaction history will appear here',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemBuilder: (_, i) {
              if (i >= (transactions.length > 6 ? 6 : transactions.length)) {
                return const SizedBox.shrink();
              }
              final tx = transactions[i];
              final credit = _isCredit(tx.tag);
              final amtColor = credit ? const Color(0xFF019206) : const Color(0xFFF70115);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: ListTile(
                  leading: SafeAvatar(imagePath: tx.image, size: 42, radius: 0, imageUrl: ''),
                  title: Text(tx.wallet_accounts_id ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(tx.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (credit ? '+ ' : '- ') +
                            '${tx.currency_name ?? ''} ' +
                            (double.tryParse(tx.amount ?? '0')?.toStringAsFixed(2) ?? '0.00'),
                        style: TextStyle(color: amtColor, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(_shortDate(tx.trx_date), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: transactions.length > 6 ? 6 : transactions.length,
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}



class NeoHomeBody extends StatelessWidget {
  final BalanceDisplayModel? balance;
  final List<HomeSliderModel> sliderModels;
  final List<HomeTransactionModel> transactions;
  final bool isShort;
  final double bottomSafe;
  final ImageProvider? avatarProvider;
  final String Function() fullName;
  final String Function() greeting;
  final String Function(String?) validImageUrl;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onMore;
  final VoidCallback onSeeAll;

  const NeoHomeBody({
    super.key,
    required this.balance,
    required this.sliderModels,
    required this.transactions,
    required this.isShort,
    required this.bottomSafe,
    required this.avatarProvider,
    required this.fullName,
    required this.greeting,
    required this.validImageUrl,
    required this.onSend,
    required this.onReceive,
    required this.onMore,
    required this.onSeeAll,
  });

  bool _isCredit(String? tag) {
    if (tag == null) return false;
    final t = tag.toLowerCase();
    return t == 'in' || t == 'credit' || t == 'cr';
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEFF3F7); 
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card 
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _NeoCard(
              child: Row(
                children: [
                  _NeoCircle(
                    child: ClipOval(
                      child: avatarProvider != null
                          ? Image(image: avatarProvider!, width: 44, height: 44, fit: BoxFit.cover)
                          : SafeAvatar(imagePath: validImageUrl(balance?.image), size: 44, radius: 0, imageUrl: ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting(), style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 2),
                        Text(
                          fullName().isEmpty ? 'User' : fullName(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Balance card 
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _NeoInset(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Balance', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${balance?.currency_name ?? 'USD'} ',
                            style: TextStyle(color: Colors.black87, fontSize: isShort ? 18 : 20, fontWeight: FontWeight.bold)),
                        Text(balance?.balance ?? '0.00',
                            style: TextStyle(color: Colors.black, fontSize: isShort ? 26 : 30, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _NeoButton(icon: Icons.arrow_upward, label: 'Send', onTap: onSend),
                        const SizedBox(width: 10),
                        _NeoButton(icon: Icons.arrow_downward, label: 'Receive', onTap: onReceive),
                        const SizedBox(width: 10),
                        _NeoButton(icon: Icons.widgets_outlined, label: 'More', onTap: onMore, outlined: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Slider
          if (sliderModels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _NeoCard(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: '${ApiUrls.BASE_URL}${sliderModels.first.imageUrl}',
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      placeholder: (_, __) => Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.error_outline)),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Transactions title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transactions list in soft cards
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _NeoCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: Text('No transactions yet', style: TextStyle(color: Colors.black54))),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemBuilder: (_, i) {
                if (i >= (transactions.length > 6 ? 6 : transactions.length)) return const SizedBox.shrink();
                final tx = transactions[i];
                final credit = _isCredit(tx.tag);
                final amtColor = credit ? const Color(0xFF019206) : const Color(0xFFF70115);
                return _NeoCard(
                  child: ListTile(
                    leading: SafeAvatar(imagePath: tx.image, size: 42, radius: 0, imageUrl: ''),
                    title: Text(tx.wallet_accounts_id ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(tx.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      (credit ? '+ ' : '- ') +
                          '${tx.currency_name ?? ''} ' +
                          (double.tryParse(tx.amount ?? '0')?.toStringAsFixed(2) ?? '0.00'),
                      style: TextStyle(color: amtColor, fontWeight: FontWeight.w900),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: transactions.length,
            ),
        ],
      ),
    );
  }
}

class _NeoCard extends StatelessWidget {
  final Widget child;
  const _NeoCard({required this.child});
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEFF3F7);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 16),
          BoxShadow(color: Color(0xFFCFD5DB), offset: Offset(6, 6), blurRadius: 16),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _NeoInset extends StatelessWidget {
  final Widget child;
  const _NeoInset({required this.child});
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEFF3F7);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xFFCFD5DB), offset: Offset(6, 6), blurRadius: 16, spreadRadius: 1),
          BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

class _NeoCircle extends StatelessWidget {
  final Widget child;
  const _NeoCircle({required this.child});
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEFF3F7);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-4, -4), blurRadius: 10),
          BoxShadow(color: Color(0xFFCFD5DB), offset: Offset(4, 4), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }
}

class _NeoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const _NeoButton({required this.icon, required this.label, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEFF3F7);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: outlined
                ? const [
                    BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-3, -3), blurRadius: 6),
                    BoxShadow(color: Color(0xFFCFD5DB), offset: Offset(3, 3), blurRadius: 6),
                  ]
                : const [
                    BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-4, -4), blurRadius: 12),
                    BoxShadow(color: Color(0xFFCFD5DB), offset: Offset(4, 4), blurRadius: 12),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: secondryColor, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}


class DarkHomeBody extends StatelessWidget {
  final BalanceDisplayModel? balance;
  final List<HomeSliderModel> sliderModels;
  final List<HomeTransactionModel> transactions;
  final bool isShort;
  final double bottomSafe;
  final ImageProvider? avatarProvider;
  final String Function() fullName;
  final String Function() greeting;
  final String Function(String?) validImageUrl;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onMore;
  final VoidCallback onSeeAll;

  const DarkHomeBody({
    super.key,
    required this.balance,
    required this.sliderModels,
    required this.transactions,
    required this.isShort,
    required this.bottomSafe,
    required this.avatarProvider,
    required this.fullName,
    required this.greeting,
    required this.validImageUrl,
    required this.onSend,
    required this.onReceive,
    required this.onMore,
    required this.onSeeAll,
  });

  bool _isCredit(String? tag) {
    if (tag == null) return false;
    final t = tag.toLowerCase();
    return t == 'in' || t == 'credit' || t == 'cr';
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0D);
    const card = Color(0xFF131316);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF101014), Color(0xFF0B0B0D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: avatarProvider != null
                      ? Image(image: avatarProvider!, width: 44, height: 44, fit: BoxFit.cover)
                      : SafeAvatar(imagePath: validImageUrl(balance?.image), size: 44, radius: 0, imageUrl: ''),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting(), style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(fullName().isEmpty ? 'User' : fullName(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Balance + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(.06)),
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${balance?.currency_name ?? 'USD'} ',
                          style: TextStyle(color: Colors.white70, fontSize: isShort ? 18 : 20, fontWeight: FontWeight.bold)),
                      Text(balance?.balance ?? '0.00',
                          style: TextStyle(color: Colors.white, fontSize: isShort ? 26 : 30, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _DarkButton(icon: Icons.arrow_upward, label: 'Send', onTap: onSend, filled: true),
                      const SizedBox(width: 10),
                      _DarkButton(icon: Icons.arrow_downward, label: 'Receive', onTap: onReceive, filled: true),
                      const SizedBox(width: 10),
                      _DarkButton(icon: Icons.widgets_outlined, label: 'More', onTap: onMore, filled: false),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Slider 
          if (sliderModels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: '${ApiUrls.BASE_URL}${sliderModels.first.imageUrl}',
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, __) => Container(color: Colors.black12),
                    errorWidget: (_, __, ___) => Container(color: Colors.black26, child: const Icon(Icons.error_outline, color: Colors.white)),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Transactions header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transactions list
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(.06)),
                ),
                child: const Center(
                  child: Text('No transactions yet', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemBuilder: (_, i) {
                if (i >= (transactions.length > 7 ? 7 : transactions.length)) return const SizedBox.shrink();
                final tx = transactions[i];
                final credit = _isCredit(tx.tag);
                final amtColor = credit ? const Color(0xFF1DDC8D) : const Color(0xFFFF4D67);
                return Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(.06)),
                  ),
                  child: ListTile(
                    leading: SafeAvatar(imagePath: tx.image, size: 42, radius: 0, imageUrl: ''),
                    title: Text(tx.wallet_accounts_id ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    subtitle: Text(tx.description ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (credit ? '+ ' : '- ') +
                              '${tx.currency_name ?? ''} ' +
                              (double.tryParse(tx.amount ?? '0')?.toStringAsFixed(2) ?? '0.00'),
                          style: TextStyle(color: amtColor, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(_shortDate(tx.trx_date), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: transactions.length,
            ),
        ],
      ),
    );
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _DarkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _DarkButton({required this.icon, required this.label, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: filled ? secondryColor : Colors.transparent,
            border: Border.all(color: filled ? Colors.transparent : Colors.white.withOpacity(.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Colors.white : Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilledPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FilledPill({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlinedPill({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryColor.withOpacity(.35), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: primaryColor,
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SmartChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SmartChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.black.withOpacity(.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: secondryColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyCard({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.black38),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
