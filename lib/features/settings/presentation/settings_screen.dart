import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authRepo = ref.watch(authRepositoryProvider);
    final user = authRepo.currentUser();

    final displayName = user?.email.isNotEmpty == true
        ? user!.email.split('@').first
        : 'Family Member';
    final email = user?.email ?? 'relay@family.me';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Profile Header (WhatsApp style)
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile details: Edit display name and photo')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF00A884),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Family first ❤️ | Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF00A884),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code, color: Color(0xFF00A884)),
                    tooltip: 'QR Code',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Your Family QR Code for quick adding')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),

          // Settings Items
          ListTile(
            leading: const Icon(Icons.key, color: Colors.blueGrey),
            title: const Text('Account'),
            subtitle: const Text('Security notifications, change phone number'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.blueGrey),
            title: const Text('Privacy'),
            subtitle: const Text('Last seen, profile photo, read receipts'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined, color: Colors.blueGrey),
            title: const Text('Chats'),
            subtitle: const Text('Theme, wallpapers, chat history'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Colors.blueGrey),
            title: const Text('Notifications'),
            subtitle: const Text('Message tones, call ringtones'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.data_usage_outlined, color: Colors.blueGrey),
            title: const Text('Storage and data'),
            subtitle: const Text('Network usage, media auto-download'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.group_add_outlined, color: Color(0xFF00A884)),
            title: const Text('Invite a family member'),
            subtitle: const Text('Share https://chat.owaisahmad.me with family'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite link copied: https://chat.owaisahmad.me'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blueGrey),
            title: const Text('Help & About Relay'),
            subtitle: const Text('Family Messenger v1.0.0 (Encrypted)'),
            onTap: () {},
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Sign out of this device'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out of Relay?'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await authRepo.signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}
