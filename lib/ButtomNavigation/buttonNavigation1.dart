// import 'package:asalpay/home/homescreen.dart';
// import 'package:flutter/material.dart';
//
// import '../Registration2.dart';
// import '../constants/Constant.dart';
// // class ButtonNavigation1 extends StatefulWidget {
// //   const ButtonNavigation1({Key? key}) : super(key: key);
// //
// //   @override
// //   State<ButtonNavigation1> createState() => _ButtonNavigation1State();
// // }
// // class _ButtonNavigation1State extends State<ButtonNavigation1> {
// //   int _selectedIndex = 0;
// //   void _navigationBottomBar(int index) {
// //     setState(() {
// //       _selectedIndex = index;
// //     });
// //   }
// //   final List<Widget> _pages = [
// //     HomeScreen(wallet_accounts_id: '',),
// //   ];
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: _pages[_selectedIndex],
// //       bottomNavigationBar: BottomNavigationBar(
// //         currentIndex: _selectedIndex,
// //         onTap: _navigationBottomBar,
// //         type: BottomNavigationBarType.fixed,
// //         items: [
// //           BottomNavigationBarItem(icon: InkWell(child: Icon(Icons.home)), label: "Home"),
// //           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Message"),
// //           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Setting"),
// //           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Account"),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
// // class Bottom extends StatefulWidget {
// //   const Bottom({Key? key}) : super(key: key);
// //   @override
// //   State<Bottom> createState() => _BottomState();
// // }
// // class _BottomState extends State<Bottom> {
// //   int index_color = 0;
// //   List Screen = [HomeScreen(wallet_accounts_id: '',name: '',),HomeScreen(wallet_accounts_id: '',),HomeScreen(wallet_accounts_id: '',),HomeScreen(wallet_accounts_id: '',), ];
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Screen[index_color],
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () {
// //           // Navigator.of(context)
// //           //     .push(MaterialPageRoute(builder: (context) => Add_Screen()));
// //         },
// //         child: Icon(Icons.qr_code_scanner_sharp, size: 35,),
// //         backgroundColor: secondryColor,
// //       ),
// //       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
// //       bottomNavigationBar: BottomAppBar(
// //         color: primaryColor,
// //         shape: CircularNotchedRectangle(),
// //         child: Padding(
// //           padding: const EdgeInsets.only(top: 7.5, bottom: 7.5),
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceAround,
// //             children: [
// //               GestureDetector(
// //                 onTap: () {
// //                   setState(() {
// //                     index_color = 0;
// //                   });
// //                 },
// //                 child: Icon(
// //                   Icons.home,
// //                   size: 30,
// //                   color: index_color == 0 ? secondryColor : lightContentColor,
// //                 ),
// //               ),
// //               GestureDetector(
// //                 onTap: () {
// //                   setState(() {
// //                     index_color = 1;
// //                   });
// //                 },
// //                 child: Icon(
// //                   Icons.send,
// //                   size: 30,
// //                   color: index_color == 1 ? secondryColor : lightContentColor,
// //                 ),
// //               ),
// //               SizedBox(width: 10),
// //               GestureDetector(
// //                 onTap: () {
// //                   setState(() {
// //                     index_color = 2;
// //                   });
// //                 },
// //                 child: Icon(
// //                   Icons.account_balance_wallet_outlined,
// //                   size: 30,
// //                   color: index_color == 2 ? secondryColor : lightContentColor,
// //                 ),
// //               ),
// //               GestureDetector(
// //                 onTap: () {
// //                   setState(() {
// //                     index_color = 3;
// //                   });
// //                 },
// //                 child: Icon(
// //                   Icons.person_outlined,
// //                   size: 30,
// //                   color: index_color == 3 ? secondryColor : lightContentColor,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// class Bottom extends StatefulWidget {
//   const Bottom({Key? key}) : super(key: key);
//   @override
//   State<Bottom> createState() => _BottomState();
// }
//
// class _BottomState extends State<Bottom> {
//   int index_color = 0;
//
//   // Provide labels for each screen
//   List<String> screenLabels = ["Home", "Send", "Profile", "Setting"];
//   List<Widget> screenWidgets = [
//     HomeScreen(wallet_accounts_id: '', name: ''),
//     HomeScreen(wallet_accounts_id: ''),
//     HomeScreen(wallet_accounts_id: ''),
//     HomeScreen(wallet_accounts_id: ''),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: screenWidgets[index_color],
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Navigator.of(context)
//           //     .push(MaterialPageRoute(builder: (context) => Add_Screen()));
//         },
//         child: Icon(Icons.qr_code_scanner_sharp, size: 35),
//         backgroundColor: secondryColor,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//       bottomNavigationBar: BottomAppBar(
//         color: primaryColor,
//         shape: CircularNotchedRectangle(),
//         child: Padding(
//           padding: const EdgeInsets.only(top: 7.5, bottom: 7.5),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: List.generate(
//               screenLabels.length,
//                   (index) => GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     index_color = index;
//                   });
//                 },
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       index == 0 ? Icons.home : // Add other icons here based on the index
//                       index == 1 ? Icons.send :
//                       index == 2 ? Icons.account_balance_wallet_outlined :
//                       Icons.person_outlined,
//                       size: 30,
//                       color: index_color == index ? secondryColor : lightContentColor,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       screenLabels[index],
//                       style: TextStyle(
//                         color: index_color == index ? secondryColor : lightContentColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
