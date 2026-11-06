class RegisteredUser {
  const RegisteredUser({
    required this.id,
    required this.displayName,
    this.username,
  });

  final String id;
  final String displayName;
  final String? username;

  factory RegisteredUser.fromRow(Map<String, dynamic> row) {
    final name = (row['display_name'] as String?)?.trim();
    final uname = (row['username'] as String?)?.trim();
    return RegisteredUser(
      id: row['id'] as String,
      displayName: (name != null && name.isNotEmpty)
          ? name
          : (uname != null && uname.isNotEmpty ? uname : 'User'),
      username: uname,
    );
  }
}

