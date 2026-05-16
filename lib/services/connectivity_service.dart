import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has actual internet connection
  /// Returns true if connected to WiFi, mobile, ethernet, or VPN
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();

      final hasConnection = result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn;

      print(
          '📡 [Connectivity] Status: $result → hasConnection: $hasConnection');
      return hasConnection;
    } catch (e) {
      print('⚠️ [Connectivity] Check failed: $e');
      // If we can't check, assume we have connection (better than assuming offline)
      return true;
    }
  }

  /// Get stream of connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
