import 'package:asalpay/utils/network_utils.dart';
import 'package:flutter/material.dart';

class NetworkProvider with ChangeNotifier {
  bool hasNetwork = false;
  Future<void> checkNetwork() async {
    bool isConnected = await checkNetworkConnectivity();
    hasNetwork = isConnected;
    notifyListeners();
    if (!isConnected) {
      loadData();
    }
  }

  void loadData() {
    hasNetwork = false;
    notifyListeners();
  }

  Future<bool> checkNetworkConnectivity() async {
    return !(await checkConnectivityIndicatesOffline());
  }

}