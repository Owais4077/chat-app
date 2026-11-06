enum GroupMemberRole { member, admin, owner }

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.isGroup,
    required this.title,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.myRole,
  });

  factory ConversationSummary.fromSupabaseRow(Map<String, dynamic> row) {
    return ConversationSummary(
      id: row['conversation_id'] as String,
      isGroup: row['is_group'] as bool,
      title: row['title'] as String,
      lastMessagePreview: (row['last_message_preview'] as String? ?? '').trim(),
      lastMessageAt: row['last_message_at'] == null
          ? null
          : DateTime.parse(row['last_message_at'] as String),
      unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
      myRole: GroupMemberRole.values.byName(row['my_role'] as String),
    );
  }

  final String id;
  final bool isGroup;
  final String title;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final GroupMemberRole myRole;
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  factory GroupMember.fromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final name = (profile?['display_name'] as String?)?.trim();
    return GroupMember(
      userId: row['user_id'] as String,
      displayName: (name != null && name.isNotEmpty) ? name : 'Member',
      role: GroupMemberRole.values.byName(row['role'] as String),
    );
  }

  final String userId;
  final String displayName;
  final GroupMemberRole role;
}
