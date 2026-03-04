import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';
import 'package:provider/provider.dart';

import '../providers/HomeSliderandTransaction.dart';
import '../services/api_urls.dart';

class Profile extends StatefulWidget {
  final String? username;
  final String? midname;
  final String? wallet_accounts_id;
  final BalanceDisplayModel? initialBalance;

  const Profile(
      {this.midname,
      this.username,
      required this.wallet_accounts_id,
      this.initialBalance,
      super.key});

  static const routeName = '/profile-screen';

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  BalanceDisplayModel? currentBalance;

  String initialBalance = "Loading...";

  String? fName = '.';
  String? mName = '.';
  String? balanceTypeName;
  String? balanceDisplay;

  String? _fullName;
  String? _accountID;
  String? _telephone;
  String? _balanceTypeName;

  String? defaultCurrencyDisplay;

  @override
  void initState() {
    super.initState();
    if (widget.initialBalance != null) {
      currentBalance = widget.initialBalance;
      updateStaticUI(currentBalance!);
    } else if (widget.wallet_accounts_id != null) {
      fetchUserData(widget.wallet_accounts_id ?? '');
    }
  }

  void fetchUserData(String accountId) {
    Provider.of<HomeSliderAndTransaction>(context, listen: false)
        .fetchUserData(accountId)
        .then((userData) {
      setState(() {
        currentBalance = userData;
      });
      updateStaticUI(currentBalance!);
    }).catchError((error) {
      print("Error fetching user data: $error");
    });
  }

  void updateStaticUI(BalanceDisplayModel balance) {
    setState(() {
      fName = balance.f_name ?? 'Loading...';
      mName = balance.m_name ?? '';
      balanceTypeName = balance.balance_type_name ?? 'N/A';
      _fullName = "${balance.f_name?.toUpperCase() ?? ''}  ";
      // _fullName = "${balance.f_name?.toUpperCase() ?? ''} ${balance.m_name?.toUpperCase() ?? ''}";
      _accountID =
          balance.wallet_accounts_id?.toUpperCase() ?? 'ID not available';
      _telephone = balance.tell?.toUpperCase() ?? 'N/A';
      _balanceTypeName = balance.balance_type_name?.toUpperCase() ?? 'N/A';
      defaultCurrencyDisplay =
          "Default Currency: ${balance.currency_name?.toUpperCase() ?? 'N/A'}";
    });
  }

  void updateDynamicUI(BalanceDisplayModel balance) {
    setState(() {
      balanceDisplay = "${balance.currency_name} ${balance.balance}";
    });
  }

  final int _index = 0;
  bool _showBalance = false;
  final bool _isLoadingDrop_data = false;
  @override
  Future<void> didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final DisplayBalance =
        Provider.of<HomeSliderAndTransaction>(context, listen: false);

    print('DisplayBalance length: ${DisplayBalance.DisplayBalance.length}');
    print('Current index: $_index');

    if (DisplayBalance.DisplayBalance.isNotEmpty &&
        _index < DisplayBalance.DisplayBalance.length) {
      print('Data at current index: ${DisplayBalance.DisplayBalance[_index]}');
    } else {
      print('No data at current index or DisplayBalance is empty');
    }

    return Scaffold(
      backgroundColor: secondryColor.withOpacity(0.9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "My Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _isLoadingDrop_data
                    ? const Center(
                        child: LogoandSpinner(
                          imageAssets: 'assets/asalicon.png',
                          reverse: true,
                          arcColor: primaryColor,
                          spinSpeed: Duration(milliseconds: 500),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(top: 12, bottom: 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildProfileCard(DisplayBalance),
                          const SizedBox(height: 12),
                          _buildAccountInfoCard(context),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(HomeSliderAndTransaction DisplayBalance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            IndexedStack(
              index: _index,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: secondryColor.withOpacity(0.15),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: DisplayBalance.DisplayBalance.isNotEmpty &&
                              _index < DisplayBalance.DisplayBalance.length
                          ? Image.network(
                              '${ApiUrls.BASE_URL}${DisplayBalance.DisplayBalance[_index].image}',
                              fit: BoxFit.cover,
                              width: 92,
                              height: 92,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/asalicon.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/asalicon.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              fName ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: secondryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              balanceTypeName ?? 'N/A',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            _buildBalanceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Text(
              "Available Balance",
              style: TextStyle(
                fontSize: 15,
                color: secondryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<BalanceDisplayModel>>(
              stream: Provider.of<HomeSliderAndTransaction>(context, listen: false)
                  .fetchAndDisplayBalance(widget.wallet_accounts_id!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  initialBalance =
                      "${snapshot.data!.first.currency_name} ${snapshot.data!.first.balance}";
                }
                return Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: secondryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: secondryColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showBalance ? initialBalance : "********",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showBalance ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () =>
                            setState(() => _showBalance = !_showBalance),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    secondryColor.withOpacity(0.85),
                    secondryColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ACCOUNT INFORMATION",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Image.asset(
                        'assets/asaliconwhite.png',
                        height: 32,
                        width: 32,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const Divider(thickness: 1, color: Colors.white54),
                  _infoRow(Icons.account_circle, "Name:", _fullName ?? "—"),
                  _infoRow(Icons.account_balance_wallet, "Account:", _accountID ?? "—"),
                  _infoRow(Icons.phone_iphone, "Phone:", _telephone ?? "—"),
                  _infoRow(Icons.switch_account, "Account Type:", _balanceTypeName ?? "—"),
                  const Divider(thickness: 1, color: Colors.white54),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      defaultCurrencyDisplay ?? '—',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
