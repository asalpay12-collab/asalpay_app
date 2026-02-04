import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactusPage extends StatefulWidget {
  const ContactusPage({super.key});
  @override
  State<ContactusPage> createState() => _ContactusPageState();
}
class _ContactusPageState extends State<ContactusPage> {
  final number = '27610550967';
  final web = 'https://asalxpress.com/';
  final facebook = 'https://www.facebook.com/AsalExpress';
  final instagram = 'https://www.instagram.com/asal_xpress/';
  final whatsapp = 'https://api.whatsapp.com/send?phone=252625381954';
  final twitter = 'https://www.instagram.com/asal_xpress/';
  @override
  Widget build(BuildContext context) {
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
                    color: primaryColor,
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                const Text(
                  "Contact Us page",
                  style: TextStyle(color: secondryColor, fontSize: 20),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),

                      Container(
                        height: 250,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/help02.png"))),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "For further support, you can call our helpline or Contact us using one of teh below contact options. ",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      //all fields of exchange;
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        height: 65,
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 0,
                          ),
                          child: InkWell(
                            onTap: () async {
                              // final call = 'tel:+$number';
                              // launch('tel://$number');
                              launch('tel:+$number');

                              // if(await canLaunch(call)){
                              // await launch('tel:+$call');
                              // }
                            },
                            child: const Row(
                              children: [
                                SizedBox(width: 10),
                                FaIcon(
                                  Icons.call,
                                  color: primaryColor,
                                  size: 32,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Call Us ",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "| 27610550967",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        height: 65,
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 0,
                          ),
                          child: InkWell(
                            onTap: () async {
                              launch(whatsapp);
                            },
                            child: const Row(
                              children: [
                                SizedBox(width: 10),
                                Icon(
                                  FontAwesomeIcons.whatsapp,
                                  size: 32,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "WhatsApp",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "| 27610550967",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
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
                      //email;
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        height: 65,
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 0,
                          ),
                          child: InkWell(
                            onTap: () async {
                              // launch('mailto:info@asalpay.so?subject=asal pay');
                              launch('mailto:info@asalpay.so?subject');
                            },
                            child: const Row(
                              children: [
                                SizedBox(width: 10),
                                Icon(
                                  FontAwesomeIcons.envelopeOpen,
                                  size: 32,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Email",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "| info@asalpay.so",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        height: 65,
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 0,
                          ),
                          child: InkWell(
                            onTap: () async {
                              // launch('mailto:info@asalpay.so?subject=asal pay');
                              launch('sms:+$number?body = welcome to asal pay');
                            },
                            child: const Row(
                              children: [
                                SizedBox(width: 10),
                                Icon(
                                  FontAwesomeIcons.commentSms,
                                  size: 32,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "SMS",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                   "| 27610550967",
                                  style: TextStyle(
                                    color: secondryColor,
                                    fontSize: 18,
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        height: 65,
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () async {
                                  launch(facebook);
                                },
                                child: const Icon(
                                  FontAwesomeIcons.facebook,
                                  size: 45,
                                  color: primaryColor,
                                ),
                              ),
                              // Icon(
                              //   FontAwesomeIcons.linkedin,
                              //   size: 35,
                              //   color: primaryColor,
                              // ),
                              InkWell(
                                onTap: () async {
                                  launch(instagram);
                                },
                                child: const Icon(
                                  FontAwesomeIcons.instagram,
                                  size: 45,
                                  color: primaryColor,
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  launch(web);
                                },
                                child: const Icon(
                                  FontAwesomeIcons.globe,
                                  size: 45,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
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

//email;
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'smith@example.com',
  );
}
