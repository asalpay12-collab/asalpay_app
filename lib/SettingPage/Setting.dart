import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/SettingPage/complete_profile_screen.dart';
import 'package:asalpay/diaglogs/policyDialog.dart';
import 'package:asalpay/login/login.dart';
import 'package:asalpay/providers/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../OTP/PINOPT.dart';
import '../login/ChangePIN.dart';
import '../login/ChangePassword.dart';
import '../splash/SplashScrn1.dart';
import 'Contactuspage.dart';
import 'dart:io' show Platform;

class SettingPage extends StatefulWidget {
	final String? wallet_accounts_id;
	final String? fullName;

	const SettingPage({
		this.wallet_accounts_id,
		this.fullName,
		super.key,
	});

	@override
	State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.grey.shade200,
			appBar: AppBar(
				backgroundColor: Colors.blueAccent,
				title: const Text(
					'Settings',
					style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
				),
				elevation: 0,
			),
      
			body: SingleChildScrollView(

        padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),

				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						const SizedBox(height: 10.0),
						Card(
							elevation: 4,
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(12.0),
							),
							margin: const EdgeInsets.symmetric(vertical: 8.0),
							child: SizedBox(
								width: double.infinity,
								height: 200,
								child: Image.asset("assets/help02.png"),
							),
						),
						const SizedBox(height: 10.0),

            _buildCard(
              icon: Icons.verified_user_outlined,
              text: "Complete Profile",
              onTap: () {
                final phone = (widget.wallet_accounts_id != null && widget.wallet_accounts_id!.isNotEmpty)
                    ? '+${widget.wallet_accounts_id}'
                    : ''; // If you keep phone elsewhere, pass it here instead.

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompleteProfileScreen(
                      phone: phone,
                      // walletTypeIdHint: '1', // optional prefill if you want
                    ),
                  ),
                );
              },
            ),


						_buildCard(
							icon: Icons.security,
							text: "Change Password",
							onTap: () {
								Navigator.push(
									context,
									MaterialPageRoute(builder: (context) => const ChangePassWord()),
								);
							},
						),
						_buildCard(
							icon: Icons.security_rounded,
							text: "Change PIN",
							onTap: () {
								Navigator.push(
									context,
									MaterialPageRoute(builder: (context) => const ChangePIN()),
								);
							},
						),
						_buildCard(
							icon: Icons.password,
							text: "Forgot PIN",
							onTap: () {
								Navigator.push(
									context,
									MaterialPageRoute(builder: (context) => const PINdOPT()),
								);
							},
						),
						_buildCard(
							icon: Icons.share,
							text: "Share",
							onTap: () {
								Share.share('Visit AsalPay at https://www.facebook.com/AsalExpress');
							},
						),
						_buildCard(
							icon: Icons.info,
							text: "Info",
							onTap: () {
								Navigator.push(
									context,
									MaterialPageRoute(builder: (context) => const ContactusPage()),
								);
							},
						),
						_buildCard(
							icon: Icons.policy_outlined,
							text: "Privacy Policy",
							onTap: () {
								showDialog(
									context: context,
									builder: (context) {
										return PolicyDialog(
											key: const Key('privacy_policy'),
											mdFileName: 'privacy_policy.md',
											btnName: "Agree",
										);
									},
								);
							},
						),
						_buildCard(
							icon: Icons.indeterminate_check_box_sharp,
							text: "Terms & Conditions",
							onTap: () {
								showDialog(
									context: context,
									builder: (context) {
										return PolicyDialog(
											key: const Key('terms_and_conditions'),
											mdFileName: 'terms_and_conditions.md',
											btnName: "I AGREE",
										);
									},
								);
							},
						),
						_buildCard(
							icon: Icons.help,
							text: "Help",
							onTap: null,
						),
				
        
        _buildCard(
  icon: Icons.logout,
  text: "Logout",
  onTap: () async {
    final authProvider = Provider.of<Auth>(context, listen: false);
    await authProvider.logout();

    // Add a slight delay to ensure logout finishes before navigating
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen1()),
          (route) => false, 
        );
      }
    });
  },
),



					],
				),
			),
		);
	}

	Widget _buildCard({
		required IconData icon,
		required String text,
		required VoidCallback? onTap,
	}) {
		return InkWell(
			onTap: onTap,
			child: Card(
				elevation: 2,
				margin: const EdgeInsets.symmetric(vertical: 8.0),
				child: ListTile(
					leading: Icon(icon, color: Colors.blue, size: 32),
					title: Text(
						text,
						style: const TextStyle(color: Colors.black87, fontSize: 18),
					),
				),
			),
		);
	}
}
