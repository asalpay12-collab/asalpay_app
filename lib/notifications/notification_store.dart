import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persist notifications per customer (wallet_accounts_id). 252pay and Qows Kaab.
const _key252Prefix = 'pay252_notification_list_';
const _keyQowsPrefix = 'qows_kaab_notification_list_';
const _maxItems = 50;

class NotificationStore {
  static Future<String?> _getWalletId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return null;
    try {
      final data = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      return data['wallet_accounts_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> save252pay(Map<String, dynamic> data) async {
    final walletId = await _getWalletId();
    if (walletId == null || walletId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _key252Prefix + walletId;
    final title = data['title']?.toString() ?? data['notificationTitle']?.toString() ?? '';
    final message = data['message']?.toString() ?? data['notificationBody']?.toString() ?? data['body']?.toString() ?? '';
    if (title.isEmpty && message.isEmpty) return;
    final list = await _getList(prefs, key);
    list.insert(0, {'title': title, 'message': message, 'time': DateTime.now().toIso8601String()});
    await _saveList(prefs, key, list);
  }

  static Future<void> saveQowsKaab(Map<String, dynamic> data) async {
    final walletId = await _getWalletId();
    if (walletId == null || walletId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyQowsPrefix + walletId;
    final title = data['title']?.toString() ?? data['notificationTitle']?.toString() ?? '';
    final body = data['body']?.toString() ?? data['notificationBody']?.toString() ?? data['message']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;
    final list = await _getList(prefs, key);
    list.insert(0, {'title': title, 'body': body, 'time': DateTime.now().toIso8601String()});
    await _saveList(prefs, key, list);
  }

  static Future<List<Map<String, dynamic>>> _getList(SharedPreferences prefs, String key) async {
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>?;
      return list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveList(SharedPreferences prefs, String key, List<Map<String, dynamic>> list) async {
    if (list.length > _maxItems) list = list.sublist(0, _maxItems);
    await prefs.setString(key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> get252payList() async {
    final walletId = await _getWalletId();
    if (walletId == null || walletId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    return _getList(prefs, _key252Prefix + walletId);
  }

  static Future<List<Map<String, dynamic>>> getQowsKaabList() async {
    final walletId = await _getWalletId();
    if (walletId == null || walletId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    return _getList(prefs, _keyQowsPrefix + walletId);
  }

  static Future<void> clear252pay() async {
    final walletId = await _getWalletId();
    if (walletId == null || walletId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key252Prefix + walletId);
  }

  static Future<void> clearQowsKaab() async {
    final walletId = await _getWalletId();
    if (walletId == null || walletId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyQowsPrefix + walletId);
  }

  static Future<void> clearAll() async {
    final walletId = await _getWalletId();
    if (walletId == null || walletId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key252Prefix + walletId);
    await prefs.remove(_keyQowsPrefix + walletId);
  }

  static Future<List<Map<String, dynamic>>> getAllMerged() async {
    final list252 = await get252payList();
    final listQows = await getQowsKaabList();
    for (final e in list252) {
      e['type'] = '252pay';
      if (!e.containsKey('message') && e.containsKey('body')) e['message'] = e['body'];
    }
    for (final e in listQows) {
      e['type'] = 'qows_kaab';
      if (!e.containsKey('body') && e.containsKey('message')) e['body'] = e['message'];
    }
    final merged = [...list252, ...listQows];
    merged.sort((a, b) {
      final tA = a['time']?.toString() ?? '';
      final tB = b['time']?.toString() ?? '';
      return tB.compareTo(tA);
    });
    return merged;
  }
}
