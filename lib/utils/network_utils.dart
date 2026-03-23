import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:asalpay/constants/Constant.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// [connectivity_plus] 5+ returns [List<ConnectivityResult>], not a single value.
///
/// **Empty list** is treated as *unknown* (not offline). The plugin sometimes
/// emits an empty list briefly; treating it as "no connection" caused false
/// "No Connection" modals while the user still had internet.
///
/// Offline only when we have at least one result and *all* are [ConnectivityResult.none].
bool connectivityResultsIndicateOffline(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.every((r) => r == ConnectivityResult.none);
}

bool connectivityResultsIndicateOnline(List<ConnectivityResult> results) {
  return !connectivityResultsIndicateOffline(results);
}

/// Async check using the same rules as [connectivityResultsIndicateOffline].
Future<bool> checkConnectivityIndicatesOffline() async {
  final results = await Connectivity().checkConnectivity();
  return connectivityResultsIndicateOffline(results);
}

/// Returns true if [error] is typically caused by no internet / network failure,
/// so the app can show a user-friendly "No connection" message instead of raw errors.
bool isNetworkError(Object error) {
  if (error is SocketException) return true;
  if (error is TimeoutException) return true;
  if (error is HandshakeException) return true;
  if (error is OSError) {
    final msg = error.message.toLowerCase();
    if (msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('host') ||
        msg.contains('socket')) return true;
  }
  final str = error.toString().toLowerCase();
  const networkKeywords = [
    'socket',
    'connection refused',
    'connection reset',
    'failed host lookup',
    'network is unreachable',
    'no internet',
    'connection timed out',
    'timeout',
    'handshake',
    'connection closed',
    'network unreachable',
    'address unreachable',
    'host is unreachable',
    'software caused connection abort',
  ];
  return networkKeywords.any((k) => str.contains(k));
}

/// Prevents stacking multiple "No Connection" dialogs (e.g. from home + streams).
bool _noConnectionDialogShowing = false;

/// Shows the app-wide "No Connection" dialog (Open Wi-Fi / Open Data).
/// Call this from any screen when network is missing or a request failed due to no connection.
Future<void> showNoConnectionDialog(BuildContext context) async {
  if (!context.mounted) return;
  if (_noConnectionDialogShowing) return;

  final isSmall = MediaQuery.of(context).size.width < 600;
  _noConnectionDialogShowing = true;
  try {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Image.asset("assets/WD5.png", width: isSmall ? 20 : 30),
            const SizedBox(width: 6),
            const Text('No Connection'),
            const Spacer(),
            Material(
              color: Colors.grey.withOpacity(0.3),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Padding(
                  padding: EdgeInsets.all(isSmall ? 6 : 8),
                  child: const Icon(Icons.close, color: primaryColor, size: 18),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'You are currently disconnected from the network.',
        ),
        actions: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: launchWifiSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Wi-Fi'),
              ),
              ElevatedButton(
                onPressed: launchDataSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Data'),
              ),
            ],
          ),
        ],
      ),
    );
  } finally {
    _noConnectionDialogShowing = false;
  }
}

Future<void> launchWifiSettings() async {
  if (Platform.isAndroid) {
    const AndroidIntent intent =
        AndroidIntent(action: 'android.settings.WIFI_SETTINGS');
    await intent.launch();
  } else if (Platform.isIOS) {
    const url = 'App-Prefs:root=WIFI';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

Future<void> launchDataSettings() async {
  if (Platform.isAndroid) {
    const AndroidIntent intent =
        AndroidIntent(action: 'android.settings.DATA_USAGE_SETTINGS');
    await intent.launch();
  } else if (Platform.isIOS) {
    const url = 'App-Prefs:root=MOBILE_DATA_SETTINGS_ID';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
