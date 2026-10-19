abstract interface class MediaPermissionService {
  Future<bool> requestMicrophone();
  Future<bool> requestCamera();
}
