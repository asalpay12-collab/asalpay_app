import 'package:flutter/foundation.dart';

/// Holds 252PAY basket (order items) shared across Categories, Subcategories, Products screens.
class Pay252BasketProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _orderItems = [];

  List<Map<String, dynamic>> get orderItems =>
      List<Map<String, dynamic>>.from(_orderItems);

  int get count => _orderItems.length;

  void addItem(Map<String, dynamic> item) {
    _orderItems.add(Map<String, dynamic>.from(item));
    notifyListeners();
  }

  void removeItem(Map<String, dynamic> item) {
    final productId = item['product_id'];
    _orderItems.removeWhere((e) => e['product_id'] == productId);
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index >= 0 && index < _orderItems.length) {
      _orderItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateItems(List<Map<String, dynamic>> items) {
    _orderItems.clear();
    _orderItems.addAll(items.map((e) => Map<String, dynamic>.from(e)));
    notifyListeners();
  }

  void clear() {
    _orderItems.clear();
    notifyListeners();
  }
}
