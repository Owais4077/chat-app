abstract interface class NotificationService {
  Future<void> requestPermission();
  Future<String?> get deviceToken;
}
