import 'package:connectivity_plus/connectivity_plus.dart';
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
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

}