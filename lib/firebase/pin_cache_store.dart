import 'dart:convert';

import 'package:asalpay/chat/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsKey = 'asalpay.pending_pin';

Future<void> savePendingPin(Map<String, dynamic> data) async {

  if (data['command'] == 'ChatMsg') {
    await ChatService.saveFCM(data);
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPrefsKey, jsonEncode(data));
  debugPrint('💾 savePendingPin → wrote ${prefs.getString(_kPrefsKey)}');
}

Future<Map<String, dynamic>?> takePendingPin() async {
  final prefs = await SharedPreferences.getInstance();

  final raw = prefs.getString(_kPrefsKey);
  debugPrint('🔍 takePendingPin → read: $raw');

  if (raw == null) return null;

  await prefs.remove(_kPrefsKey);        
  return jsonDecode(raw) as Map<String, dynamic>;
}
