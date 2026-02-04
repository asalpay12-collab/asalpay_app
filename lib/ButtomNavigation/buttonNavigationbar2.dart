import 'package:asalpay/home/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class ButtonNavigationbar2 extends StatefulWidget {
  const ButtonNavigationbar2({super.key});
  @override
  State<ButtonNavigationbar2> createState() => _ButtonNavigationbar2State();
}
class _ButtonNavigationbar2State extends State<ButtonNavigationbar2> {

  int _selectedIndex = 0;
  void _navigationBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  final List<Widget> _pages = [
    HomeScreen(wallet_accounts_id: '', fromLogin: false),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: GNav(
            backgroundColor: Colors.black,
            color: Colors.white,
            activeColor: Colors.white,
            tabBackgroundColor: Colors.grey.shade800,
            gap: 8,
            onTabChange: _navigationBottomBar,
            selectedIndex: _selectedIndex,
            padding: const EdgeInsets.all(16),
            tabs: const [
              GButton(icon: Icons.home, text: "Home"),
              GButton(icon: Icons.favorite_border, text: "favorite"),
              GButton(icon: Icons.search, text: "Search"),
              GButton(icon: Icons.settings, text: "Settings"),
            ],
          ),
        ),
      ),
    );
  }
}
