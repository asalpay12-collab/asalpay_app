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
      {
        this.midname,
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

  bool _dataFetched = false;  

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
    _dataFetched = true;  
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
          _dataFetched = true;
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
      _accountID = balance.wallet_accounts_id?.toUpperCase() ?? 'ID not available';
      _telephone = balance.tell?.toUpperCase() ?? 'N/A';
      _balanceTypeName = balance.balance_type_name?.toUpperCase() ?? 'N/A';
      defaultCurrencyDisplay = "Default Currency: ${balance.currency_name?.toUpperCase() ?? 'N/A'}";
    });
  }

  void _subscribeToBalance(String accountId) {
    Provider.of<HomeSliderAndTransaction>(context, listen: false)
      .fetchAndDisplayBalance(accountId)
      .listen((balances) {
        if (balances.isNotEmpty) {
          updateDynamicUI(balances.first);
        }
      }, onError: (error) {
        print("Error receiving balance data: $error");
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


    final DisplayBalance = Provider.of<HomeSliderAndTransaction>(context, listen: false);

      print('DisplayBalance length: ${DisplayBalance.DisplayBalance.length}');
      print('Current index: $_index');

      
      if (DisplayBalance.DisplayBalance.isNotEmpty && _index < DisplayBalance.DisplayBalance.length) {
        print('Data at current index: ${DisplayBalance.DisplayBalance[_index]}');
      } else {
        print('No data at current index or DisplayBalance is empty');
      }


    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: AppBar().preferredSize.height,
          left: 15,
          right: 15,
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Text(
                  "My Profile",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 22),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _isLoadingDrop_data
                      ? const Center(
                          child:
                    // CircularProgressIndicator(),
                      LogoandSpinner(
                        imageAssets:
                        'assets/asalicon.png',
                        reverse: true,
                        arcColor: primaryColor,
                        spinSpeed: Duration(
                            milliseconds: 500),
                      )
                        )
                      : Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    IndexedStack(
                                      index: _index,
                                      children: [
                                        CircleAvatar(
                                          radius: 53,
                                          backgroundColor: primaryColor,
                                          child: CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Colors.white,
                                            child: ClipOval(
                                              child: DisplayBalance.DisplayBalance.isNotEmpty && _index < DisplayBalance.DisplayBalance.length
                                              ? Image.network(
                                                  '${ApiUrls.BASE_URL}${DisplayBalance.DisplayBalance[_index].image}',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    
                                                    return Image.asset(
                                                      'assets/asalicon.png', // Fallback image
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
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
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    IndexedStack(
                                      index: _index,
                                      children: [
                                       Text(
                                        "$fName" , //"$fName  $mName" ,
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                              fontSize: 20,
                                            ),
                                      )

                                      ],
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    IndexedStack(
                                      index: _index,
                                      children: [
                                       Text(
                                        balanceTypeName ?? 'N/A',
                                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, color: Colors.grey),
                                      ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),

                                    //todo:profile balance;
                                    Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
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
                                            const SizedBox(
                                              width: 5,
                                            ),
                             
                                            // StreamBuilder to fetch and display balance
                                            StreamBuilder<List<BalanceDisplayModel>>(
                                              stream: Provider.of<HomeSliderAndTransaction>(context, listen: false).fetchAndDisplayBalance(widget.wallet_accounts_id!),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                                 
                                                  initialBalance = "${snapshot.data!.first.currency_name} ${snapshot.data!.first.balance}";
                                                 // fName=" ${snapshot.data!.first.f_name}";
                                                }
                                                
                                                return Container(
                                                  
                                                  height: 50,
                                                  width: 300,
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.white, width: 1),
                                                    borderRadius: BorderRadius.circular(15),
                                                    color: primaryColor.withOpacity(0.8),
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
                                                          size: 24,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _showBalance = !_showBalance;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          // StreamBuilder integration ends here
                                          

                                      
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            // todo: AccountsCard
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    //todo:Account Info;
                                    LayoutBuilder(
                                      builder: (BuildContext context,
                                          BoxConstraints constraints) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                secondryColor.withOpacity(0.2),
                                                primaryColor,
                                              ],
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                                constraints.maxWidth * 0.02),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      "Account Information"
                                                          .toUpperCase(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge!
                                                          .copyWith(
                                                            fontSize: constraints
                                                                    .maxWidth *
                                                                0.045,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    const Expanded(child: SizedBox()),
                                                   
                                                    Image.asset(
                                                      'assets/asaliconwhite.png',
                                                      height:
                                                          constraints.maxWidth *
                                                              0.2,
                                                      width:
                                                          constraints.maxWidth *
                                                              0.2,
                                                      fit: BoxFit.cover,
                                                      // color: Colors.white,
                                                    )
                                                  ],
                                                ),
                                                const Divider(
                                                  thickness: 1,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(
                                                    height:
                                                        constraints.maxWidth *
                                                            0.02),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Icon(
                                                          Icons.account_circle,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(
                                                            width: constraints
                                                                    .maxWidth *
                                                                0.01),
                                                        Text(
                                                          "Name: ",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        constraints.maxWidth *
                                                                            0.040,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                        ),
                                                        SizedBox(
                                                            width: constraints
                                                                    .maxWidth *
                                                                0.01),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            IndexedStack(
                                                              index: _index,
                                                              children: [
                                                                Text(
                                                              _fullName ?? "Name not available",

                                                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                                    fontSize: constraints.maxWidth * 0.040,
                                                                    color: Colors.white,
                                                                  ),
                                                            ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                        height: constraints
                                                                .maxWidth *
                                                            0.02),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .account_balance_wallet,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(
                                                            width: constraints
                                                                    .maxWidth *
                                                                0.01),
                                                        Text(
                                                          "Account: ",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        constraints.maxWidth *
                                                                            0.040,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            IndexedStack(
                                                              index: _index,
                                                              children: [
                                                            Text(

                                                            _accountID ?? "ID not available",

                                                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                                  fontSize: constraints.maxWidth * 0.040,
                                                                  color: Colors.white,
                                                                ),
                                                          ),

                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    height:
                                                        constraints.maxWidth *
                                                            0.02),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Icon(
                                                          Icons.phone_iphone,
                                                          color: Colors.white,
                                                        ),
                                                        Text(
                                                          "Phone: ",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        constraints.maxWidth *
                                                                            0.040,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            IndexedStack(
                                                              index: _index,
                                                              children: [
                                                                Text(

                                                                  _telephone ?? 'N/A',

                                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                                        fontSize: constraints.maxWidth * 0.040,
                                                                        color: Colors.white,
                                                                      ),
                                                                ),

                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                        height: constraints
                                                                .maxWidth *
                                                            0.02),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Icon(
                                                          Icons.switch_account,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(
                                                            width: constraints
                                                                    .maxWidth *
                                                                0.01),
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "Account Type: ",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        constraints.maxWidth *
                                                                            0.040,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            ),
                                                            SizedBox(
                                                                height: constraints
                                                                        .maxWidth *
                                                                    0.005),
                                                            IndexedStack(
                                                              index: _index,
                                                              children: [
                                                                Text(

                                                                _balanceTypeName ??  'N/A',

                                                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                                      fontSize: constraints.maxWidth * 0.040,
                                                                      color: Colors.white,
                                                                    ),
                                                              ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    height:
                                                        constraints.maxWidth *
                                                            0.005),
                                                const Divider(
                                                  thickness: 1,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(
                                                    height:
                                                        constraints.maxWidth *
                                                            0.02),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          IndexedStack(
                                                            index: _index,
                                                            children: [
                                                             Text(
                                                               defaultCurrencyDisplay ?? 'N/A',
                                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                                    fontSize: constraints.maxWidth * 0.040,
                                                                    color: Colors.white,
                                                                  ),
                                                            ),

                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
 