abstract interface class ConnectivityService {
  Stream<bool> watchConnection();
  Future<bool> get isConnected;
}
