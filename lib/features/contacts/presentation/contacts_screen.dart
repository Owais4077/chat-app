import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../chat/domain/conversation_summary.dart';
import '../../chat/presentation/chat_providers.dart';
import '../domain/phone_number.dart';
import 'contacts_providers.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});
  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _myPhone = TextEditingController();
  bool _saving = false;
  bool _savingMyPhone = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _myPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _show('Enter a contact name');
      return;
    }
    try {
      final phone = PhoneNumber.parse(_phone.text);
      setState(() => _saving = true);
      await ref
          .read(contactRepositoryProvider)
          .saveContact(displayName: name, phoneE164: phone.value);
      if (!mounted) return;
      _phone.clear();
      _show('Contact saved');
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Could not save contact');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveMyPhone() async {
    try {
      final phone = PhoneNumber.parse(_myPhone.text);
      setState(() => _savingMyPhone = true);
      await ref
          .read(contactRepositoryProvider)
          .setMyPhoneIdentity(phone.value);
      if (!mounted) return;
      _myPhone.clear();
      _show('Your phone number has been linked!');
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Could not link phone number');
    } finally {
      if (mounted) setState(() => _savingMyPhone = false);
    }
  }

  Future<void> _startChatWithUser(String userId, String displayName) async {
    try {
      final conversationId = await ref
          .read(chatRepositoryProvider)
          .startDirectConversation(userId);
      if (!mounted) return;
      context.push(
        '/conversation/$conversationId',
        extra: {
          'title': displayName,
          'isGroup': false,
          'myRole': GroupMemberRole.owner,
        },
      );
    } catch (_) {
      _show('Could not start conversation');
    }
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    final registeredUsers = ref.watch(registeredUsersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Contacts', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '+923001234567',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save contact'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use international format. Contacts are saved only after you choose Save.',
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Link My Phone Number'),
            subtitle: const Text('Allow friends to find you by your phone number'),
            leading: const Icon(Icons.phone_android),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              TextField(
                controller: _myPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'My Phone Number',
                  hintText: '+923269796217',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _savingMyPhone ? null : _saveMyPhone,
                child: Text(_savingMyPhone ? 'Linking...' : 'Link My Phone'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Saved contacts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          contacts.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No saved contacts yet.')),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final contact = items[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(contact.displayName),
                    subtitle: contact.isRegistered
                        ? const Text('On CHAT APP')
                        : const Text('Not on CHAT APP'),
                    trailing: contact.isRegistered
                        ? FilledButton.tonal(
                            onPressed: () => _startChatWithUser(
                              contact.registeredUserId!,
                              contact.displayName,
                            ),
                            child: const Text('Message'),
                          )
                        : null,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Could not load contacts')),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered Relay Users',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh users',
                onPressed: () => ref.refresh(registeredUsersProvider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          registeredUsers.when(
            data: (users) {
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No other registered users found yet.'),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(user.displayName),
                    subtitle: user.username != null
                        ? Text('@${user.username}')
                        : null,
                    trailing: FilledButton(
                      onPressed: () =>
                          _startChatWithUser(user.id, user.displayName),
                      child: const Text('Chat'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Could not load registered users')),
          ),
        ],
      ),
    );
  }
}
