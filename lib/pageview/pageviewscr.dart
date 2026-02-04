
import 'package:asalpay/login/login.dart';
import 'package:flutter/material.dart';
import 'package:page_view_indicators/circle_page_indicator.dart';

import '../constants/Constant.dart';


class PageViewScreen extends StatefulWidget {
  const PageViewScreen({super.key,});
  static const routeName = '/pageview';

  @override
  _PageViewScreenState createState() => _PageViewScreenState();
}

class Pagedetl {
  String img, txt1, txt2;
  Color color;
  Pagedetl({
    required this.img,
    required this.txt1,
    required this.txt2,
    required this.color,
  });
}

class _PageViewScreenState extends State<PageViewScreen> {
  List<Pagedetl> lstpageview = [
    Pagedetl(
        img: 'assets/p1.png',
        txt1: "Add & Manage Card",
        txt2: "You can add & manage all bank accounts & Credit or debit cards.",
        color: primaryColor,),
    Pagedetl(
        img: 'assets/p2.png',
        txt1: "Transfer & Receive Money",
        txt2: "Easily transfer your money and receive your earnings from others",
        color: secondryColor,),
    Pagedetl(
        img: 'assets/p3.png',
        txt1: "Pay Bills and Payments",
        txt2: "Pay your all bills and Payments all over the world",
        color: primaryColor,),
    Pagedetl(
        img: 'assets/p4.png',
        txt1: "Manage Your Wallet",
        txt2: "Manage Your all earning  ,expenses & every penny anywhere,anytime",
      color: secondryColor,),
  ];

  final _pageController = PageController();
  final _currentPageNotifier = ValueNotifier<int>(0);
  int pageNumber = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  _buildBody() {
    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            _buildPageView(),
            _buildCircleIndicator(),
          ],
        ),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      pageNumber != 3
                          ? setState(
                              () {
                                if (pageNumber != lstpageview.length - 1) {
                                  _pageController.jumpToPage(pageNumber + 1);
                                } else {
                                  _pageController.jumpToPage(0);
                                }
                              },
                            )
                          : Navigator.push(
                              context, MaterialPageRoute(builder: (builder)=>const Login()));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(0),
                            color:primaryColor,),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                pageNumber != 3 ? "Continue" : "Get Started",
                                style: const TextStyle(
                                  color: Colors.white,
                                )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (builder)=>const Login()));
                    },
                    child: Text(
                      pageNumber != 3 ? "Skip Now" : "",
                      style: const TextStyle(
                        color: secondryColor,
                        fontWeight: FontWeight.bold,
                        // color: primaryColor,
                      )
                    ),
                  ),
                ]
                    .map((item) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: item,
                        ))
                    .toList(),
              )),
        ),
      ],
    );
  }

  _buildPageView() {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 1.5,
      child: PageView.builder(
          itemCount: lstpageview.length,
          allowImplicitScrolling: true,
          controller: _pageController,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(child: SizedBox()),
                    Image.asset(
                      lstpageview[index].img,
                      fit: BoxFit.cover,
                      color: lstpageview[index].color,
                      height: 200,
                      width: 200,
                    ),
                    const Expanded(child: SizedBox()),
                    Text(
                      lstpageview[index].txt1,
                        style: const TextStyle(
                          color: secondryColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 24
                          // color: primaryColor,
                        ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      lstpageview[index].txt2,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14
                        // color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            );
          },
          onPageChanged: (int index) {
            _currentPageNotifier.value = index;
            setState(() {
              pageNumber = index;
            });
          }),
    );
  }

  _buildCircleIndicator() {
    return Positioned(
      left: 0.0,
      right: 0.0,
      bottom: 0.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CirclePageIndicator(
          dotColor: Colors.grey,
          selectedDotColor:primaryColor,
          itemCount: lstpageview.length,
          currentPageNotifier: _currentPageNotifier,
        ),
      ),
    );
  }
}
