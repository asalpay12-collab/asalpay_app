import 'package:asalpay/SettingPage/complete_profile_screen.dart';
// Biometric disabled
// import 'package:asalpay/SettingPage/fingerprint_settings_screen.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/notifications/notifications_hub_screen.dart';
import 'package:asalpay/diaglogs/policyDialog.dart';
import 'package:asalpay/providers/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../OTP/PINOPT.dart';
import '../login/ChangePIN.dart';
import '../login/ChangePassword.dart';
import '../splash/SplashScrn1.dart';
import 'Contactuspage.dart';

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
		final bottomPadding = MediaQuery.of(context).padding.bottom;
		return Scaffold(
			body: Container(
				width: double.infinity,
				height: double.infinity,
				decoration: BoxDecoration(
					gradient: LinearGradient(
						colors: [
							secondryColor,
							secondryColor.withOpacity(0.72),
						],
						begin: Alignment.topCenter,
						end: Alignment.bottomCenter,
					),
				),
				child: SafeArea(
					child: Column(
						children: [
							Padding(
								padding: const EdgeInsets.fromLTRB(15, 12, 15, 16),
								child: Row(
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
											'Settings',
											style: TextStyle(
												color: Colors.white,
												fontSize: 20,
												fontWeight: FontWeight.w600,
											),
										),
									],
								),
							),
							Expanded(
								child: SingleChildScrollView(
									physics: const BouncingScrollPhysics(),
									padding: EdgeInsets.fromLTRB(15, 0, 15, 24 + bottomPadding),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: <Widget>[
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
							icon: Icons.notifications_outlined,
							text: "Notifications",
							onTap: () {
								Navigator.pushNamed(context, NotificationsHubScreen.routeName);
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
						// Biometric disabled: users could not log in with session
						// _buildCard(
						// 	icon: Icons.fingerprint,
						// 	text: "Fingerprint",
						// 	onTap: () {
						// 		Navigator.push(
						// 			context,
						// 			MaterialPageRoute(builder: (context) => const FingerprintSettingsScreen()),
						// 		);
						// 	},
						// ),
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
							),
						],
					),
				),
			),
		);
	}

	Widget _buildCard({
		required IconData icon,
		required String text,
		required VoidCallback? onTap,
	}) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 10),
			child: Material(
				color: Colors.transparent,
				child: InkWell(
					onTap: onTap,
					borderRadius: BorderRadius.circular(20),
					child: Card(
						elevation: 4,
						color: Colors.white,
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(20),
						),
						child: Padding(
							padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
							child: Row(
								children: [
									Container(
										width: 44,
										height: 44,
										decoration: BoxDecoration(
											color: secondryColor.withOpacity(0.12),
											borderRadius: BorderRadius.circular(14),
										),
										child: Icon(icon, color: secondryColor, size: 24),
									),
									const SizedBox(width: 16),
									Expanded(
										child: Text(
											text,
											style: const TextStyle(
												color: Color(0xFF1A1A1A),
												fontSize: 16,
												fontWeight: FontWeight.w600,
											),
										),
									),
									if (onTap != null)
										Icon(
											Icons.arrow_forward_ios_rounded,
											size: 16,
											color: secondryColor.withOpacity(0.7),
										),
								],
							),
						),
					),
				),
			),
		);
	}
}
