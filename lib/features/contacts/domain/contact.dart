class Contact {
  const Contact({
    required this.id,
    required this.displayName,
    required this.phoneE164,
    required this.registeredUserId,
  });

  factory Contact.fromSupabaseRow(Map<String, dynamic> row) => Contact(
    id: row['id'] as String,
    displayName: row['display_name'] as String,
    phoneE164: row['phone_e164'] as String,
    registeredUserId: row['registered_user_id'] as String?,
  );

  final String id;
  final String displayName;
  final String phoneE164;
  final String? registeredUserId;

  bool get isRegistered => registeredUserId != null;
}
