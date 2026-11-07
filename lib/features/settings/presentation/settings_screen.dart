import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showVideoVoiceSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam_outlined, color: Color(0xFF00A884)),
            SizedBox(width: 8),
            Text('Video & Voice Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Camera, Microphone & Speakers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              subtitle: const Text('Default Webcam (HD 1080p)'),
              trailing: const Icon(Icons.check_circle, color: Color(0xFF00A884), size: 18),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mic_outlined),
              title: const Text('Microphone'),
              subtitle: const Text('Built-in Microphone (Noise Cancelling)'),
              trailing: const Icon(Icons.check_circle, color: Color(0xFF00A884), size: 18),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.volume_up_outlined),
              title: const Text('Audio Output'),
              subtitle: const Text('Speakers / Headphones'),
              trailing: const Icon(Icons.check_circle, color: Color(0xFF00A884), size: 18),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Background Noise Suppression'),
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showAgentsSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: Color(0xFF00A884)),
            SizedBox(width: 8),
            Text('Connected AI Agents'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agents connected to this account:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00A884).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00A884).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF00A884),
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Relay Family AI Copilot', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Assists with family reminders, smart quick replies, and voice transcriptions.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Smart Quick Replies'),
              subtitle: const Text('Generates convenient one-tap reply suggestions in family chats'),
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showKeyboardShortcuts() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard_outlined, color: Color(0xFF00A884)),
            SizedBox(width: 8),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShortcutRow(keys: 'Enter', action: 'Send message'),
            _ShortcutRow(keys: 'Shift + Enter', action: 'New line'),
            _ShortcutRow(keys: 'Ctrl + N', action: 'New conversation / group'),
            _ShortcutRow(keys: 'Ctrl + F', action: 'Search messages'),
            _ShortcutRow(keys: 'Ctrl + E', action: 'Open emoji palette'),
            _ShortcutRow(keys: 'Ctrl + Shift + M', action: 'Mute / unmute call'),
            _ShortcutRow(keys: 'Escape', action: 'Close dialog or attachment'),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRepo = ref.watch(authRepositoryProvider);
    final user = authRepo.currentUser();

    final displayName = user?.email.isNotEmpty == true
        ? user!.email.split('@').first
        : 'Family Member';
    final email = user?.email ?? 'relay@family.me';

    final allItems = [
      _SettingsItemData(
        icon: Icons.storefront_outlined,
        title: 'Business tools',
        subtitle: 'Quick replies, labels, catalogue',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick replies & family message templates enabled')),
        ),
      ),
      _SettingsItemData(
        icon: Icons.computer_outlined,
        title: 'General',
        subtitle: 'Startup and close, app preferences',
        onTap: () {},
      ),
      _SettingsItemData(
        icon: Icons.key_outlined,
        title: 'Account',
        subtitle: 'Security notifications, account info',
        onTap: () {},
      ),
      _SettingsItemData(
        icon: Icons.lock_outline,
        title: 'Privacy',
        subtitle: 'Blocked contacts, disappearing messages',
        onTap: () {},
      ),
      _SettingsItemData(
        icon: Icons.smart_toy_outlined,
        title: 'Agents',
        subtitle: 'Agents connected to this account',
        badge: 'AI Copilot',
        onTap: _showAgentsSettings,
      ),
      _SettingsItemData(
        icon: Icons.chat_outlined,
        title: 'Chats',
        subtitle: 'Theme, wallpaper, chat settings',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper & chat theme: WhatsApp Green default')),
        ),
      ),
      _SettingsItemData(
        icon: Icons.videocam_outlined,
        title: 'Video & voice',
        subtitle: 'Camera, microphone & speakers',
        onTap: _showVideoVoiceSettings,
      ),
      _SettingsItemData(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Messages, groups, sounds',
        onTap: () {},
      ),
      _SettingsItemData(
        icon: Icons.swap_horiz_outlined,
        title: 'Your customers\' activity',
        subtitle: 'Analytics & interaction insights',
        onTap: () {},
      ),
      _SettingsItemData(
        icon: Icons.keyboard_outlined,
        title: 'Keyboard shortcuts',
        subtitle: 'Quick actions & productivity',
        onTap: _showKeyboardShortcuts,
      ),
      _SettingsItemData(
        icon: Icons.help_outline,
        title: 'Help and feedback',
        subtitle: 'FAQ, contact us, privacy policy',
        onTap: () {},
      ),
    ];

    final filteredItems = allItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Header matching screenshot
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Search Bar matching screenshot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search settings',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // User Profile Card
          if (_searchQuery.isEmpty) ...[
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF00A884),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
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
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 12),
          ],

          // Filtered Settings List
          ...filteredItems.map((item) => ListTile(
                leading: Icon(item.icon, color: Colors.blueGrey, size: 22),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                trailing: item.badge != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A884).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: Color(0xFF00A884),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                onTap: item.onTap,
              )),

          const Divider(height: 24),

          // Log out Tile
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Sign out from this device'),
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

class _SettingsItemData {
  const _SettingsItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.keys, required this.action});
  final String keys;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              keys,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
