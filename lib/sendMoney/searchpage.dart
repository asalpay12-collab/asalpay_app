import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/providers/Walletremit.dart';
import 'package:asalpay/sendMoney/CashCollect.dart';
import 'package:asalpay/sendMoney/MobileMoneytransfer.dart';
import 'package:asalpay/sendMoney/Real_time_Bank_Transfer.dart';

import 'package:asalpay/services/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../login/login.dart';
import '../providers/auth.dart';

// import 'package:asalpay/sendMoney/banktransfer.dart' as Bbanktransfer;

// import 'banktransfer.dart' as Bbanktransfer;
// import 'banktransferChina.dart' as BbanktransferChina;

import 'package:asalpay/sendMoney/banktransfer.dart' as banktransfer;
import 'package:asalpay/sendMoney/banktransferChina.dart' as banktransferChina;

class Searchpage1 extends StatefulWidget {
  final String wallet_accounts_id;

  const Searchpage1({super.key, required this.wallet_accounts_id});

  @override
  State<Searchpage1> createState() => _Searchpage1State();
}

class _Searchpage1State extends State<Searchpage1> {
  bool _isLoadingDrop_data = true; // Start with loading state
  List<CountryMoDelFill> display_list_of_countries = [];

  @override
  void initState() {
    super.initState();
    // Fetch data here
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final countryList = Provider.of<Walletremit>(context, listen: false);
      await countryList.fetchAndSetCountryFill();
      setState(() {
        display_list_of_countries = List<CountryMoDelFill>.from(countryList.countryfill);
        _isLoadingDrop_data = false; 
      });
    } catch (error) {
      print("Error fetching data: $error");
      setState(() {
        _isLoadingDrop_data = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryList = Provider.of<Walletremit>(context, listen: false);
    final allcountries = countryList.countryfill;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoadingDrop_data
          ? const Center(
              child: CircularProgressIndicator(), 
            )
          : Padding(
              padding: EdgeInsets.only(
                top: AppBar().preferredSize.height,
                left: 15,
                right: 15,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: secondryColor,
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      const Text(
                        "Send Money",
                        style: TextStyle(
                          fontSize: 18,
                          color: primaryColor,
                          // fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        display_list_of_countries = countryList.countryfill
                            .where((element) =>
                                element.name.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                        print('all: ${allcountries.length}');
                      });
                    },
                    style: const TextStyle(
                      color: secondryColor,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: secondryColor.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Search",
                      suffixIcon: const Icon(Icons.search),
                      suffixIconColor: primaryColor,
                      contentPadding: const EdgeInsets.only(top: 20, left: 18),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Expanded(
                    child: display_list_of_countries.isEmpty
                        ? const Center(
                            child: Text(
                              "No Result Found!",
                              style: TextStyle(
                                  color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: secondryColor.withOpacity(0.03),
                              ),
                              child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  itemCount: display_list_of_countries.length,
                                  itemBuilder: (context, index) {
                                    final item = display_list_of_countries[index].name;
                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          color: Colors.white,
                                        ),
                                        child: InkWell(
                                          onTap: () async {
                                            await Provider.of<Walletremit>(context,
                                                    listen: false)
                                                .fetchAndSetFillChannelTypes(
                                                    display_list_of_countries[index].id)
                                                .then((_) {
                                              setState(() {
                                                final fillTag = Provider.of<Walletremit>(
                                                    context,
                                                    listen: false);
 
                                                for (var i = 0;
                                                    i < fillTag.FillChannelTypes.length;
                                                    i++) {
                                                  if (fillTag.FillChannelTypes[i].tag ==
                                                          "WRBT" ||
                                                      fillTag.FillChannelTypes[i].tag ==
                                                          "WCC" ||
                                                      fillTag.FillChannelTypes[i].tag ==
                                                          "WBT" ||
                                                      fillTag.FillChannelTypes[i].tag ==
                                                          "WMT" ||
                                                     
                                                      fillTag.FillChannelTypes[i].tag ==
                                                          "BT_CHINA") {
                                                    print(fillTag
                                                        .FillChannelTypes[i].tag);
                                                    _AllinOneOption(
                                                        item, fillTag.FillChannelTypes);
                                                  }
                                                }
                                              });
                                            });
                                          },
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 25,
                                                  backgroundColor: primaryColor,
                                                  child: CircleAvatar(
                                                    radius: 23,
                                                    backgroundImage: NetworkImage(
                                                        '${ApiUrls.BASE_URL}${display_list_of_countries[index].image}'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: secondryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _AllinOneOption(
      String item, List<ChannelTypesModel> fillChannelTypes) async {
    print("Midka Loopka");
    print(fillChannelTypes.length);
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color.fromARGB(255, 251, 250, 252), Color.fromARGB(255, 245, 246, 247)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/asalpay.png',
                        fit: BoxFit.contain,
                        height: 100,
                        width: 100,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Select Payout Method",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.arrowDown, color: Colors.deepPurple),
                          const SizedBox(width: 20),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "Send money to",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: " $item!".toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade700,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: fillChannelTypes.length,
                        itemBuilder: (context, i) {
                          return InkWell(
                            onTap: () {
                              _navigateToPayout(context, fillChannelTypes[i]);
                            },
                            child: CutomClicbleCards(
                              'assets/cash001.png',
                              fillChannelTypes[i].type_name,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToPayout(BuildContext context, ChannelTypesModel channelType) {
    final auth = Provider.of<Auth>(context, listen: false);
    Widget nextPage;
    switch (channelType.tag) {
      case "WRBT":
        nextPage = RealTimeBankTransfer(
          wallet_accounts_id: widget.wallet_accounts_id,
          country: channelType.country_id,
          type: channelType.tag,
        );
        break;
      case "WMT":
        nextPage = MobileMoneytransfer(
          wallet_accounts_id: widget.wallet_accounts_id,
          country: channelType.country_id,
          type: channelType.tag,
        );
        break;
      case "WCC":
        nextPage = CashCollect(
          wallet_accounts_id: widget.wallet_accounts_id,
          country: channelType.country_id,
        );
        break;
      case "WBT":
        nextPage = banktransfer.BbanktransferChina(
          wallet_accounts_id: widget.wallet_accounts_id,
          country: channelType.country_id,
          type: channelType.tag,
        );
        break;
      case "BT_CHINA":
        nextPage = banktransferChina.BbanktransferChina(
          wallet_accounts_id: widget.wallet_accounts_id,
          country: channelType.country_id,
          type: channelType.tag,
        );
        break;
      default:
        nextPage = const Login();
        break;
    }

    if (auth.isAuth) {
      auth.autoLogout(context);
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  }

  Widget CutomClicbleCards(String img, String txt) {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: primaryColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                          image: AssetImage(img), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        txt,
                        style: const TextStyle(
                            fontSize: 11,
                            color: secondryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 5,
        )
      ],
    );
  }
}
