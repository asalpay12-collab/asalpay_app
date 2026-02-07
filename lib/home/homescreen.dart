import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/transactions/qows_kaab/qows_kaab_products_screen.dart';
import 'package:asalpay/PayBills/PayBills.dart';
import 'package:asalpay/SettingPage/Setting.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/filter/filterScreenTwo.dart';
import 'package:asalpay/firebase/fcm_command_cache.dart';
import 'package:asalpay/firebase/firebase_messaging_setup.dart'
    show tryShowPendingPinCommand;
import 'package:asalpay/firebase/pin_cache_store.dart' as PinCacheStore;
import 'package:asalpay/profile/profile.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import 'package:asalpay/providers/Walletremit.dart';
import 'package:asalpay/providers/auth.dart';
import 'package:asalpay/sendMoney/searchpage.dart';
import 'package:asalpay/services/api_urls.dart';
import 'package:asalpay/services/tokens.dart';
import 'package:asalpay/topup/TopUp.dart';
import 'package:asalpay/transactions/ProductPurchaseScreen.dart';
import 'package:asalpay/transactions/SeeAllTransactions.dart'
    as SeeAllTransactionsFile;
import 'package:asalpay/transactions/allServices.dart';
import 'package:asalpay/transfer/MerchantAccount.dart';
import 'package:asalpay/transfer/Transfer1.dart';
import 'package:asalpay/widgets/safe_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _QuickActionCardV extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  final bool compact;

  const _QuickActionCardV({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double puck = compact ? 32 : 44;
    final double iconSize = compact ? 18 : 22;
    final double gap = compact ? 6 : 10;
    final double fontSize = compact ? 12.0 : 15.0;
    final EdgeInsets tilePad = compact
        ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
        : const EdgeInsets.fromLTRB(12, 12, 12, 10);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: tilePad,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(.96)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient icon puck
              Container(
                width: puck,
                height: puck,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(.72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(.28),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: iconSize, color: Colors.white),
              ),
              SizedBox(height: gap),

              // Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String date;
  final String amountText;
  final Color amountColor;
  final IconData trendIcon;
  final bool isIn;
  final VoidCallback? onTap;

  const _TxCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amountText,
    required this.amountColor,
    required this.trendIcon,
    required this.isIn,
    this.onTap,
  });

  static const _bgTop = Color(0xFF14356E);
  static const _bgBottom = Color(0xFF0E2856);
  static const _border = Color(0x33FFFFFF);

  String _wrapLongTokens(String input) {
    if (input.isEmpty) return input;

    final re = RegExp(r'[A-Za-z0-9]{10,}');
    return input.replaceAllMapped(re, (m) {
      final s = m.group(0)!;
      final b = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        b.write(s[i]);
        if ((i + 1) % 4 == 0) b.write('\u200B');
      }
      return b.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_bgTop, _bgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Leading avatar with soft ring
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(.08),
                        Colors.white.withOpacity(.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(.12)),
                  ),
                ),
                SizedBox(
                    width: 44,
                    height: 44,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: leading)),
              ],
            ),
            const SizedBox(width: 12),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + IN/OUT pill
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _InOutPill(isIn: isIn),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    _wrapLongTokens(subtitle),
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    date,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11.5),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amountText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        height: 1.1,
                        // tabular digits for aligned decimals
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.12),
                        border:
                            Border.all(color: Colors.white.withOpacity(.20)),
                      ),
                      child: Icon(trendIcon, size: 16, color: amountColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InOutPill extends StatelessWidget {
  final bool isIn;
  const _InOutPill({required this.isIn});
  @override
  Widget build(BuildContext context) {
    final Color c = isIn ? const Color(0xFF7CC043) : const Color(0xFFFF6B7D);
    final String t = isIn ? 'IN' : 'OUT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(.45)),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: .6,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String wallet_accounts_id;
  final String? name;
  final bool fromLogin;

  final List<BalanceDisplayModel>? initialBalances;
  final List<HomeSliderModel>? initialSliderImages;
  final List<HomeTransactionModel>? initialTransactions;
  final BalanceDisplayModel? initialHomeBalance;
  final HomeTransactionModel? initialHomeTransaction;

  const HomeScreen({
    super.key,
    required this.wallet_accounts_id,
    this.name,
    required this.fromLogin,
    this.initialBalances,
    this.initialSliderImages,
    this.initialTransactions,
    this.initialHomeBalance,
    this.initialHomeTransaction,
  });

  static const routeName = '/home-screen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TokenClass tokenClass = TokenClass();

  List<HomeSliderModel> _sliderModels = [];
  List<HomeTransactionModel> _transactions = [];
  List<BalanceDisplayModel> _balances = [];
  BalanceDisplayModel? currentBalance;
  HomeTransactionModel? currentTransaction;

  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  int _currentSliderIndex = 0;
  DateTime _lastBackPress = DateTime.now();

  bool _booting = false;
  bool _didRunDidChangeDeps = false;

  String? fName = '';
  String? mName = '';
  String? imageUrl = '';
  ImageProvider? _avatarProvider;

  bool _showBalance = true;

  // Streams
  StreamSubscription<List<BalanceDisplayModel>>? _balanceSubscription;
  StreamSubscription<List<HomeTransactionModel>>? _transactionSubscription;

  // Draggable TX sheet
  final DraggableScrollableController _txSheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sliderModels = widget.initialSliderImages ?? [];
    if (widget.initialHomeBalance != null) {
      currentBalance = widget.initialHomeBalance;
      _applyHeaderFromBalance(currentBalance!);
    }
    if (widget.initialTransactions?.isNotEmpty ?? false) {
      _transactions = widget.initialTransactions!;
      currentTransaction = _transactions.first;
      _applyHeaderFromTransaction(currentTransaction!);
    }

    _startAutoPlay();
    _checkNetworkStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      tryShowPendingPinCommand();
      _refreshPendingPin();

      if (widget.fromLogin) {
        await _boot();
      } else {
        _fetchTransactions();
        _subscribeToTransactions(widget.wallet_accounts_id);
        _subscribeToBalance(widget.wallet_accounts_id);
        if (_sliderModels.isEmpty) _fetchInitialData();
        if (currentBalance == null) _fetchUserData(widget.wallet_accounts_id);
      }
    });
  }

  Future<void> _boot() async {
    setState(() => _booting = true);
    try {
      final sliderProv =
          Provider.of<HomeSliderAndTransaction>(context, listen: false);
      final remitProv = Provider.of<Walletremit>(context, listen: false);
      final homeProv =
          Provider.of<HomeSliderAndTransaction>(context, listen: false);

      currentBalance ??=
          await homeProv.fetchUserData(widget.wallet_accounts_id);
      if (currentBalance != null) _applyHeaderFromBalance(currentBalance!);

      if (_sliderModels.isEmpty) {
        await remitProv.fetchAndSetCountryFill();
        await sliderProv.fetchAndSetSliderImages();
        _sliderModels = sliderProv.images;
        if (_sliderModels.isNotEmpty)
          await prefetchImages(_sliderModels, context);
      }

      if (_transactions.isEmpty) {
        _transactions = await homeProv.fetchAndSetAllTr();
        if (_transactions.isNotEmpty)
          _applyHeaderFromTransaction(_transactions.first);
      }

      _subscribeToBalance(widget.wallet_accounts_id);
      _subscribeToTransactions(widget.wallet_accounts_id);
    } catch (e) {
      debugPrint('Boot error: $e');
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  void _subscribeToTransactions(String accountId) {
    _transactionSubscription?.cancel();
    _transactionSubscription =
        Provider.of<HomeSliderAndTransaction>(context, listen: false)
            .fetchAndStreamAllTransactions()
            .listen((txs) {
      if (!mounted) return;
      setState(() {
        _transactions = txs;
        if (txs.isNotEmpty) _applyHeaderFromTransaction(txs.first);
      });
    }, onError: (e) => debugPrint('TX stream error: $e'));
  }

  void _subscribeToBalance(String accountId) {
    _balanceSubscription?.cancel();
    _balanceSubscription =
        Provider.of<HomeSliderAndTransaction>(context, listen: false)
            .fetchAndDisplayBalance(accountId)
            .listen((balances) {
      if (!mounted) return;
      if (balances.isNotEmpty) {
        setState(() {
          _balances = balances;
          currentBalance = balances.first;
        });
        _applyHeaderFromBalance(currentBalance!);
      }
    }, onError: (e) => debugPrint('Balance stream error: $e'));
  }

  Future<void> _fetchUserData(String accountId) async {
    try {
      final userData =
          await Provider.of<HomeSliderAndTransaction>(context, listen: false)
              .fetchUserData(accountId);
      if (!mounted) return;
      setState(() => currentBalance = userData);
      _applyHeaderFromBalance(currentBalance!);
    } catch (e) {
      debugPrint('fetchUserData error: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final data =
          await Provider.of<HomeSliderAndTransaction>(context, listen: false)
              .fetchAndSetAllTr();
      if (!mounted) return;
      setState(() => _transactions = data);
    } catch (e) {
      debugPrint('fetch tx error: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      final sliderProv =
          Provider.of<HomeSliderAndTransaction>(context, listen: false);
      final remitProv = Provider.of<Walletremit>(context, listen: false);
      await Future.wait([
        remitProv.fetchAndSetCountryFill(),
        sliderProv.fetchAndSetSliderImages(),
      ]);
      if (!mounted) return;
      setState(() => _sliderModels = sliderProv.images);
      if (_sliderModels.isNotEmpty)
        await prefetchImages(_sliderModels, context);
    } catch (e) {
      debugPrint('fetch initial data error: $e');
    }
  }

  void _applyHeaderFromBalance(BalanceDisplayModel b) {
    fName = b.f_name ?? '';
    mName = b.m_name ?? '';
    imageUrl = b.image ?? imageUrl;
    _prefetchAvatarIfAny(imageUrl);
  }

  void _applyHeaderFromTransaction(HomeTransactionModel tx) {
    imageUrl = tx.image ?? imageUrl;
    fName = tx.f_name ?? fName;
    mName = tx.m_name ?? mName;
    _prefetchAvatarIfAny(imageUrl);
  }

  Future<void> _prefetchAvatarIfAny([String? rawUrl]) async {
    final url = _validImageUrl(rawUrl ?? imageUrl);
    if (url.isEmpty) return;
    try {
      final provider = CachedNetworkImageProvider(url);
      await precacheImage(provider, context);
      if (mounted) setState(() => _avatarProvider = provider);
    } catch (_) {}
  }

  void _startAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _sliderModels.isEmpty) return;
      final next = (_currentSliderIndex + 1) % _sliderModels.length;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 20) return 'Good Evening';
    return 'Good Night';
  }

  String _fullName() => '${fName ?? ''} ${mName ?? ''}'.trim();
  String _validImageUrl(String? url) => (url == null || url.isEmpty)
      ? ''
      : (url.startsWith('http') ? url : '${ApiUrls.BASE_URL}$url');

  bool _isCredit(String? tag) {
    if (tag == null) return false;
    final t = tag.toLowerCase();
    return t == 'in' || t == 'credit' || t == 'cr';
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

  Future<void> _checkNetworkStatus() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      await _showNetworkMessage(context);
    }
  }

  Future<void> _refreshPendingPin() async {
    tryShowPendingPinCommand();
    final disk = await PinCacheStore.takePendingPin();
    if (disk != null) {
      FCMCommandCache.setPendingData(disk);
      tryShowPendingPinCommand();
    }
  }

  Future<void> _showNetworkMessage(BuildContext context) async {
    final isSmall = MediaQuery.of(context).size.width < 600;
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Image.asset("assets/WD5.png", width: isSmall ? 20 : 30),
            const SizedBox(width: 6),
            const Text('No Connection'),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.3)),
                padding: EdgeInsets.all(isSmall ? 2 : 4),
                child: const Icon(Icons.close, color: primaryColor, size: 18),
              ),
            ),
          ],
        ),
        content: const Text('You are currently disconnected from the network.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: launchWifiSettings,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white),
                child: const Text('Open Wi-Fi'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: launchDataSettings,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white),
                child: const Text('Open Data'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> launchDataSettings() async {
    if (Platform.isAndroid) {
      const AndroidIntent intent =
          AndroidIntent(action: 'android.settings.DATA_USAGE_SETTINGS');
      await intent.launch();
    } else if (Platform.isIOS) {
      const url = 'App-Prefs:root=MOBILE_DATA_SETTINGS_ID';
      if (await canLaunch(url)) await launch(url);
    }
  }

  Future<void> launchWifiSettings() async {
    if (Platform.isAndroid) {
      const AndroidIntent intent =
          AndroidIntent(action: 'android.settings.WIFI_SETTINGS');
      await intent.launch();
    } else if (Platform.isIOS) {
      const url = 'App-Prefs:root=WIFI';
      if (await canLaunch(url)) await launch(url);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRunDidChangeDeps) return;
    _didRunDidChangeDeps = true;
    tryShowPendingPinCommand();
    final auth = Provider.of<Auth>(context, listen: false);
    if (auth.isAuth) auth.autoLogout(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshPendingPin();
      Future.delayed(const Duration(milliseconds: 2500), _refreshPendingPin);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _carouselTimer?.cancel();
    _balanceSubscription?.cancel();
    _transactionSubscription?.cancel();
    super.dispose();
  }

  static const EdgeInsets kSectionPad = EdgeInsets.fromLTRB(10, 10, 14, 10);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final mq = MediaQuery.of(context);
    final textScaler = mq.textScaler.clamp(maxScaleFactor: 1.15);
    final size = mq.size;

    final isShort = size.height < 700;

    // final sliderH = size.height * 0.23;
    // final clampedSliderH = sliderH.clamp(140.0, 220.0);

    final sliderH = size.height * 0.20;
    final clampedSliderH = sliderH.clamp(120.0, 180.0);

    if (_booting) {
      return Scaffold(
        backgroundColor: secondryColor,
        body: const Center(
          child: LogoandSpinner(
            imageAssets: 'assets/asalicon01.png',
            reverse: true,
            arcColor: primaryColor,
            spinSpeed: Duration(milliseconds: 500),
          ),
        ),
      );
    }

    return MediaQuery(
      data: mq.copyWith(textScaler: textScaler),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => auth.startInactivityTimer(context),
        onPanDown: (_) => auth.startInactivityTimer(context),
        child: Scaffold(
          // backgroundColor: Colors.grey[50],

          backgroundColor: Colors.transparent,
          //  extendBody: true,

          appBar: AppBar(
            // toolbarHeight: 80,

            toolbarHeight: 58,

            elevation: 0,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            clipBehavior: Clip.hardEdge,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [secondryColor, secondryColor.withOpacity(.72)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.white.withOpacity(.28),
                    alignment: Alignment.center,
                    child: SafeAvatar(
                      imagePath: imageUrl,
                      size: 48,
                      radius: 0,
                      imageUrl: _validImageUrl(imageUrl),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fullName().isEmpty ? 'User' : _fullName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _openNotificationsBottomSheet(context),
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
          ),

          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondryColor, secondryColor.withOpacity(.72)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              RefreshIndicator(
                onRefresh: () async {
                  await _fetchInitialData();
                  await _fetchTransactions();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 70),
                  child: Column(
                    children: [
                      // gradient top
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              secondryColor,
                              secondryColor.withOpacity(.72)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Balance (with eye)
                            Padding(
                              // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),

                              child: _GlassCard(
                                // padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),

                                padding:
                                    const EdgeInsets.fromLTRB(14, 14, 14, 12),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text('Available Balance',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ),
                                        IconButton(
                                          tooltip: _showBalance
                                              ? 'Hide balance'
                                              : 'Show balance',
                                          onPressed: () => setState(() =>
                                              _showBalance = !_showBalance),
                                          icon: Icon(
                                            _showBalance
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _showBalance
                                          ? '${currentBalance?.currency_name ?? 'USD'} ${currentBalance?.balance ?? '0.00'}'
                                          : '******',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isShort ? 26 : 30,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _GlassAction(
                                            icon: Icons.arrow_upward,
                                            label: 'Send',
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) => Searchpage1(
                                                          wallet_accounts_id: widget
                                                              .wallet_accounts_id)));
                                            }),
                                        const SizedBox(width: 10),
                                        _GlassAction(
                                            icon: Icons.arrow_downward,
                                            label: 'Receive',
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          TopUpScreen()));
                                            }),
                                        const SizedBox(width: 10),
                                        _GlassAction(
                                            icon: Icons.widgets_outlined,
                                            label: 'More',
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) => AllServices(
                                                          wallet_accounts_id: widget
                                                              .wallet_accounts_id)));
                                            }),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
                              child: _GlassCard(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                child: GridView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 86,
                                  ),
                                  children: [
                                    _QuickActionCardV(
                                      icon: Icons.qr_code_scanner_sharp,
                                      label: 'Pay Merchant',
                                      accent: secondryColor,
                                      compact: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => Merchant(
                                              wallet_accounts_id:
                                                  widget.wallet_accounts_id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickActionCardV(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      label: 'Transfer',
                                      accent: primaryColor,
                                      compact: true,
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => Transfer(
                                                wallet_accounts_id:
                                                    widget.wallet_accounts_id,
                                              ),
                                            ));
                                      },
                                    ),
                                    _QuickActionCardV(
                                      icon: Icons.move_to_inbox_outlined,
                                      label: 'All Transactions',
                                      accent: secondryColor,
                                      compact: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SeeAllTransactionsFile
                                                    .Transfer(),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickActionCardV(
                                      icon: Icons.shopping_basket,
                                      label: 'Qows Kaab',
                                      accent: primaryColor,
                                      compact: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => QowsKaabProductsScreen(
                                              walletAccountId: widget.wallet_accounts_id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickActionCardV(
                                      icon: Icons.devices_other,
                                      label: '252PAY',
                                      accent: secondryColor,
                                      compact: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductPurchaseScreen(
                                              wallet_accounts_id: widget
                                                  .wallet_accounts_id, // non-nullable, no '!' needed
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickActionCardV(
                                      icon: Icons.payments_outlined,
                                      label: 'PayBill',
                                      accent: primaryColor,
                                      compact: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ServicePaymentScreen(
                                              walletAccountsId:
                                                  widget.wallet_accounts_id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_sliderModels.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: clampedSliderH,
                                    child: PageView.builder(
                                      controller: _pageController,
                                      itemCount: _sliderModels.length,
                                      onPageChanged: (i) => setState(
                                          () => _currentSliderIndex = i),
                                      itemBuilder: (_, index) =>
                                          CachedNetworkImage(
                                        imageUrl:
                                            '${ApiUrls.BASE_URL}${_sliderModels[index].imageUrl}',
                                        fit: BoxFit.cover,
                                        fadeInDuration: Duration.zero,
                                        placeholder: (_, __) =>
                                            const SizedBox.expand(),
                                        errorWidget: (_, __, ___) => Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                                Icons.error_outline)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DraggableScrollableSheet(
                controller: _txSheetController,
                // initialChildSize: 0.115,

                initialChildSize: 0.100,
                minChildSize: 0.100,

                // minChildSize: 0.115,
                maxChildSize: 0.80,
                snap: true,
                builder: (context, scrollController) {
                  final bottomInset = MediaQuery.of(context).padding.bottom;

                  String _wrapLongTokens(String input) {
                    if (input.isEmpty) return input;
                    final re = RegExp(r'[A-Za-z0-9]{10,}');
                    return input.replaceAllMapped(re, (m) {
                      final s = m.group(0)!;
                      final b = StringBuffer();
                      for (var i = 0; i < s.length; i++) {
                        b.write(s[i]);
                        if ((i + 1) % 4 == 0) b.write('\u200B');
                      }
                      return b.toString();
                    });
                  }

                  return Container(
                    decoration: const BoxDecoration(
                      // color: secondryColor,
                      // color: primaryColor,

                      color: secondryColor,

                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // drag handle
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              // color: Colors.white.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(62),
                            ),
                          ),
                          const SizedBox(height: 6),

                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _txSheetController.animateTo(
                              0.90,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  // color: const Color(0xFF7CC043),
                                  color: Color(0xB334C759),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'RECENT TRANSACTIONS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // const SizedBox(height: 10),

                          // list
                          Expanded(
                            child: _transactions.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.receipt_long_outlined,
                                              size: 48, color: Colors.white54),
                                          SizedBox(height: 10),
                                          Text('No transactions yet',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: EdgeInsets.fromLTRB(
                                        16, 0, 16, 16 + bottomInset),
                                    itemCount: _transactions.length,
                                    itemBuilder: (_, i) {
                                      final tx = _transactions[i];
                                      final isIn = _isCredit(tx.tag);
                                      final amtColor = isIn
                                          ? const Color(0xFF56D47E)
                                          : const Color(0xFFFF6B7D);
                                      final arrow = isIn
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded;
                                      final sign = isIn ? '' : '-';
                                      final amount =
                                          (double.tryParse(tx.amount ?? '0') ??
                                                  0)
                                              .toStringAsFixed(1);
                                      final currency =
                                          (tx.currency_name ?? 'USD')
                                              .toUpperCase();
                                      final title =
                                          (tx.wallet_accounts_id ?? '')
                                              .toUpperCase();
                                      final subtitle =
                                          (tx.description?.isNotEmpty ?? false)
                                              ? tx.description!
                                              : (isIn
                                                  ? 'Transfer'
                                                  : 'Withdraw');
                                      final date = _shortDate(tx.trx_date);
                                      final hasImg = (tx.image != null &&
                                          tx.image!.isNotEmpty);
                                      final initial = title.trim().isNotEmpty
                                          ? title.trim().substring(0, 1)
                                          : '•';

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // avatar / initial
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: hasImg
                                                  ? ClipOval(
                                                      child: SafeAvatar(
                                                        imagePath: tx.image,
                                                        size: 40,
                                                        radius: 0,
                                                        imageUrl: '',
                                                      ),
                                                    )
                                                  : Text(
                                                      initial,
                                                      style: TextStyle(
                                                        color: secondryColor,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                            ),

                                            const SizedBox(width: 12),

                                            // title + subtitle
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _wrapLongTokens(subtitle),
                                                    softWrap: true,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 15,
                                                      height: 1.45,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '$currency $sign$amount',
                                                      style: TextStyle(
                                                        color: amtColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Icon(arrow,
                                                        size: 14,
                                                        color: amtColor),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  date,
                                                  style: const TextStyle(
                                                    color: Color.fromARGB(
                                                        179, 189, 218, 86),
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) => Container(
                                      height: 1,
                                      margin: const EdgeInsets.only(left: 52),
                                      color: Colors.white.withOpacity(0.10),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          bottomNavigationBar: _BottomNav(
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  return;
                case 1:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => FilterScreenTwo(
                              wallet_accounts_id: widget.wallet_accounts_id)));
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Profile(
                            wallet_accounts_id: widget.wallet_accounts_id,
                            initialBalance: currentBalance)),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SettingPage(
                            wallet_accounts_id: widget.wallet_accounts_id,
                            fullName: _fullName())),
                  );
                  break;
              }
            },
          ),
        ),
      ),
    );
  }

  // ===== Notifications bottom sheet (kept) =====
  void _openNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.52,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          snap: true,
          builder: (bottomSheetContext, scrollController) {
            const bool hasNotifications = false;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, -6))
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(3))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(.75)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: primaryColor.withOpacity(.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6))
                            ],
                          ),
                          child: const Icon(Icons.notifications_active_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Notifications',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: hasNotifications
                        ? ListView.builder(
                            controller: scrollController,
                            itemCount: 0,
                            itemBuilder: (_, __) => const SizedBox.shrink())
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(24),
                            children: const [
                              SizedBox(height: 12),
                              Center(
                                  child: Icon(Icons.notifications_none_rounded,
                                      size: 64, color: Colors.black38)),
                              SizedBox(height: 16),
                              Center(
                                  child: Text('No notifications yet',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700))),
                              SizedBox(height: 8),
                              Center(
                                  child: Text(
                                      'When something important happens, we’ll show it here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14))),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ===== Bottom Nav (unchanged) =====
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _labels = ['Home', 'Filter', 'Profile', 'Setting'];
  static const _icons = [
    Icons.home,
    Icons.filter_list,
    Icons.person_outlined,
    Icons.settings
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Material(
      color: secondryColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: MediaQuery(
            data: mq.copyWith(
                textScaler: mq.textScaler.clamp(maxScaleFactor: 1.0)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, (i) {
                final selected = currentIndex == i;
                return InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icons[i],
                            size: 24,
                            color: selected ? primaryColor : pureWhite),
                        const SizedBox(height: 2),
                        Text(_labels[i],
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.0,
                                color: selected ? primaryColor : pureWhite)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Prefetch =====
Future<void> prefetchImages(
    List<HomeSliderModel> sliderModels, BuildContext context) async {
  for (var m in sliderModels) {
    try {
      final full = '${ApiUrls.BASE_URL}${m.imageUrl}';
      await precacheImage(CachedNetworkImageProvider(full), context);
    } catch (e) {
      debugPrint("cache fail: ${m.imageUrl} -> $e");
    }
  }
}

// ===== Glass helpers =====
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard(
      {required this.child, this.padding = const EdgeInsets.all(12)});
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
              colors: [
                Colors.white.withOpacity(.22),
                Colors.white.withOpacity(.10)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
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
  const _GlassAction(
      {required this.icon, required this.label, required this.onTap});
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
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
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
  const _SmartChipGridTile(
      {required this.icon, required this.label, this.onTap});
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 10,
                offset: const Offset(0, 6))
          ],
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

// ===== TX Row (screenshot style) =====
class _TxRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String amountRight;
  final Color amountColor;
  final IconData trendIcon;
  final String date;

  const _TxRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amountRight,
    required this.amountColor,
    required this.trendIcon,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF11346B),
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        isThreeLine: true, // gives room
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        leading: leading,
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(amountRight,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Icon(trendIcon, size: 16, color: amountColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(date,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
