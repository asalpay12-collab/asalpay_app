import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preference for home screen chip grid layout.
/// When [useOption2Layout] is true, uses the option2 style from home_design_showcase (LayoutBuilder, different spacing).
/// When false, uses the current design (GlassCard with mainAxisExtent: 86).
const String _kUseOption2Layout = 'home_use_option2_layout';

class HomeLayoutPref extends ChangeNotifier {
  bool _useOption2Layout = false;

  bool get useOption2Layout => _useOption2Layout;

  HomeLayoutPref() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _useOption2Layout = prefs.getBool(_kUseOption2Layout) ?? false;
    notifyListeners();
  }

  Future<void> setUseOption2Layout(bool value) async {
    if (_useOption2Layout == value) return;
    _useOption2Layout = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseOption2Layout, value);
    notifyListeners();
  }
}
