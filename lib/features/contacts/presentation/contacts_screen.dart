import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
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

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    return Padding(
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
          const SizedBox(height: 16),
          const Text(
            'Use international format. Contacts are saved only after you choose Save.',
          ),
          const SizedBox(height: 16),
          Text(
            'Saved contacts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Expanded(
            child: contacts.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No saved contacts yet.'));
                }
                return ListView.builder(
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
                          ? TextButton(
                              onPressed: () => _show(
                                'Choose New message from Chats to begin.',
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
          ),
        ],
      ),
    );
  }
}
