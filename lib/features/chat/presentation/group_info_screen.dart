import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts/presentation/contacts_providers.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation_summary.dart';
import 'chat_providers.dart';

class GroupInfoScreen extends ConsumerStatefulWidget {
  const GroupInfoScreen({
    super.key,
    required this.conversationId,
    this.title = 'Group info',
    this.myRole = GroupMemberRole.member,
    this.repository,
  });

  final String conversationId;
  final String title;
  final GroupMemberRole myRole;
  final ChatRepository? repository;

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  var _loading = true;
  String? _error;
  List<GroupMember> _members = [];

  ChatRepository get _repo =>
      widget.repository ?? ref.read(chatRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.getGroupMembers(widget.conversationId);
      if (mounted) {
        setState(() {
          _members = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load group members.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    setState(() => _error = null);
    try {
      await _repo.removeGroupMember(
        conversationId: widget.conversationId,
        userId: userId,
      );
      await _loadMembers();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not update group member.');
      }
    }
  }

  Future<void> _toggleAdminRole(GroupMember member) async {
    setState(() => _error = null);
    final newRole = member.role == GroupMemberRole.admin
        ? GroupMemberRole.member
        : GroupMemberRole.admin;
    try {
      await _repo.setGroupMemberRole(
        conversationId: widget.conversationId,
        userId: member.userId,
        role: newRole,
      );
      await _loadMembers();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not update group member.');
      }
    }
  }

  Future<void> _showAddMemberDialog() async {
    final contacts = await ref.read(contactsProvider.future);
    final registered = contacts.where((c) => c.isRegistered).toList();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: registered.length,
        itemBuilder: (_, index) {
          final contact = registered[index];
          return ListTile(
            title: Text(contact.displayName),
            subtitle: Text(contact.phoneE164),
            trailing: TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repo.addGroupMember(
                    conversationId: widget.conversationId,
                    userId: contact.registeredUserId!,
                  );
                  await _loadMembers();
                } catch (_) {
                  if (mounted) {
                    setState(() => _error = 'Could not update group member.');
                  }
                }
              },
              child: const Text('Add'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManageMembers =
        widget.myRole == GroupMemberRole.owner ||
        widget.myRole == GroupMemberRole.admin;
    final isOwner = widget.myRole == GroupMemberRole.owner;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: canManageMembers
            ? [
                TextButton(
                  onPressed: _showAddMemberDialog,
                  child: const Text('Add member'),
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Members (${_members.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _members.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isSelf = false;
                      final canRemove =
                          (isOwner && member.role != GroupMemberRole.owner) ||
                          (widget.myRole == GroupMemberRole.admin &&
                              member.role == GroupMemberRole.member);
                      final canChangeRole =
                          isOwner && member.role != GroupMemberRole.owner;

                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            member.role == GroupMemberRole.owner
                                ? Icons.star
                                : Icons.person,
                          ),
                        ),
                        title: Text(member.displayName),
                        subtitle: Text(switch (member.role) {
                          GroupMemberRole.owner => 'Owner',
                          GroupMemberRole.admin => 'Admin',
                          GroupMemberRole.member => 'Member',
                        }),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canChangeRole)
                              TextButton(
                                onPressed: () => _toggleAdminRole(member),
                                child: Text(
                                  member.role == GroupMemberRole.admin
                                      ? 'Dismiss admin'
                                      : 'Make admin',
                                ),
                              ),
                            if (canRemove)
                              TextButton(
                                onPressed: () => _removeMember(member.userId),
                                child: const Text('Remove'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
