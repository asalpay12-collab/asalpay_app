import 'package:asalpay/constants/Constant.dart';
import 'package:asalpay/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FingerprintSettingsScreen extends StatefulWidget {
  const FingerprintSettingsScreen({super.key});

  @override
  State<FingerprintSettingsScreen> createState() => _FingerprintSettingsScreenState();
}

class _FingerprintSettingsScreenState extends State<FingerprintSettingsScreen> {
  bool _biometricAvailable = false;
  bool _useFingerprintLogin = false;
  bool _useFingerprintConfirm = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await BiometricService.isBiometricAvailable();
    final login = await BiometricService.getUseFingerprintLogin();
    final confirm = await BiometricService.getUseFingerprintConfirm();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _useFingerprintLogin = login;
      _useFingerprintConfirm = confirm;
      _loading = false;
    });
  }

  Future<void> _setUseFingerprintLogin(bool value) async {
    setState(() => _useFingerprintLogin = value);
    await BiometricService.setUseFingerprintLogin(value);
    if (value) {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      if (userData != null && userData.isNotEmpty) {
        await BiometricService.saveUserDataForFingerprintLogin(userData);
      }
    } else {
      await BiometricService.clearUserDataForFingerprintLogin();
    }
  }

  Future<void> _setUseFingerprintConfirm(bool value) async {
    setState(() => _useFingerprintConfirm = value);
    await BiometricService.setUseFingerprintConfirm(value);
    if (!value) await BiometricService.clearPinForFingerprintConfirm();
  }

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
                      'Fingerprint',
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(15, 0, 15, 24 + bottomPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _biometricAvailable
                                            ? secondryColor.withOpacity(0.12)
                                            : Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.fingerprint,
                                        color: _biometricAvailable ? secondryColor : Colors.grey,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _biometricAvailable
                                                ? 'Fingerprint available'
                                                : 'Fingerprint not available',
                                            style: const TextStyle(
                                              color: Color(0xFF1A1A1A),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _biometricAvailable
                                                ? 'You can use fingerprint for login and confirmations.'
                                                : 'Enroll a fingerprint in device settings to use this feature.',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildToggleRow(
                              title: 'Use fingerprint for login',
                              subtitle: 'Log in with fingerprint instead of password next time.',
                              value: _useFingerprintLogin,
                              onChanged: _biometricAvailable ? _setUseFingerprintLogin : null,
                            ),
                            const SizedBox(height: 10),
                            _buildToggleRow(
                              title: 'Use fingerprint for confirmations',
                              subtitle: 'Confirm PIN with fingerprint when making payments.',
                              value: _useFingerprintConfirm,
                              onChanged: _biometricAvailable ? _setUseFingerprintConfirm : null,
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

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: secondryColor.withOpacity(0.5),
              activeColor: secondryColor,
            ),
          ],
        ),
      ),
    );
  }
}
