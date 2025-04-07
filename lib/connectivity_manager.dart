import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityManager {
  bool _isConnected = true;
  final _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription? _subscription;

  ConnectivityManager() {
    _initialize();
  }

  void _initialize() async {
    final connectivity = Connectivity();
    _updateConnectionStatus(await connectivity.checkConnectivity());

    _subscription = connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(Iterable<ConnectivityResult> result) {
    final isConnected = result.singleOrNull != ConnectivityResult.none;

    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectivityController.add(isConnected);
    }
  }

  bool get isConnected => _isConnected;

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
