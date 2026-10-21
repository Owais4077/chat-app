abstract interface class ContactRepository {
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  });
}
