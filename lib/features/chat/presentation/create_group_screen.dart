import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contacts/presentation/contacts_providers.dart';
import 'chat_providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _selectedMemberIds = <String>{};
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a group name');
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      setState(() => _error = 'Select at least one member');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final conversationId = await ref
          .read(chatRepositoryProvider)
          .createGroup(name: name, memberIds: _selectedMemberIds.toList());
      if (!mounted) return;
      context.go('/conversation/$conversationId');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not create group');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group name',
                hintText: 'Enter group name',
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Members',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          Expanded(
            child: contacts.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No contacts available'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final contact = items[index];
                    final isRegistered = contact.isRegistered;
                    final userId = contact.registeredUserId;
                    final isSelected =
                        userId != null && _selectedMemberIds.contains(userId);

                    return CheckboxListTile(
                      title: Text(contact.displayName),
                      subtitle: isRegistered
                          ? null
                          : const Text('Not on CHAT APP'),
                      value: isSelected,
                      onChanged: isRegistered
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedMemberIds.add(userId!);
                                } else {
                                  _selectedMemberIds.remove(userId);
                                }
                              });
                            }
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Could not load contacts')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _create,
                child: Text(_submitting ? 'Creating...' : 'Create group'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
