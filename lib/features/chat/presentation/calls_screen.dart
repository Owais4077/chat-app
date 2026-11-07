import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../contacts/presentation/contacts_providers.dart';
import 'call_screen.dart';

class CallLogItem {
  const CallLogItem({
    required this.name,
    required this.time,
    required this.isVideo,
    required this.isMissed,
    required this.isOutgoing,
  });

  final String name;
  final String time;
  final bool isVideo;
  final bool isMissed;
  final bool isOutgoing;
}

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  static const _sampleLogs = [
    CallLogItem(
      name: 'Family Group Call',
      time: 'Today, 8:45 PM',
      isVideo: true,
      isMissed: false,
      isOutgoing: false,
    ),
    CallLogItem(
      name: 'Dad',
      time: 'Today, 6:15 PM',
      isVideo: false,
      isMissed: false,
      isOutgoing: true,
    ),
    CallLogItem(
      name: 'Mom',
      time: 'Yesterday, 9:20 PM',
      isVideo: true,
      isMissed: false,
      isOutgoing: false,
    ),
    CallLogItem(
      name: 'Brother',
      time: 'Yesterday, 4:10 PM',
      isVideo: false,
      isMissed: true,
      isOutgoing: false,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final registeredUsers = ref.watch(registeredUsersProvider).value ?? [];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Create Call Link Card (WhatsApp feature)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF00A884),
              child: const Icon(Icons.link, color: Colors.white),
            ),
            title: const Text(
              'Create a call link',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Share a link for your Relay family call'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call link copied! Share with family: https://chat.owaisahmad.me/call/family'),
                ),
              );
            },
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Recent Family Calls',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          ..._sampleLogs.map((log) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    log.name.isNotEmpty ? log.name[0] : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  log.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: log.isMissed ? Colors.red : null,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      log.isOutgoing
                          ? Icons.call_made
                          : (log.isMissed ? Icons.call_missed : Icons.call_received),
                      size: 16,
                      color: log.isMissed
                          ? Colors.red
                          : const Color(0xFF00A884),
                    ),
                    const SizedBox(width: 4),
                    Text(log.time, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    log.isVideo ? Icons.videocam : Icons.call,
                    color: const Color(0xFF00A884),
                  ),
                  tooltip: log.isVideo ? 'Start video call' : 'Start voice call',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CallScreen(
                        contactName: log.name,
                        isVideo: log.isVideo,
                      ),
                    ),
                  ),
                ),
              )),
          if (registeredUsers.isNotEmpty) ...[
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Call Family Members',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            ...registeredUsers.map((user) => ListTile(
                  leading: CircleAvatar(
                    child: Text(user.displayName.isNotEmpty ? user.displayName[0] : '?'),
                  ),
                  title: Text(user.displayName),
                  subtitle: const Text('Available for Voice & Video'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF00A884)),
                        tooltip: 'Voice call',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              contactName: user.displayName,
                              isVideo: false,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.videocam, color: Color(0xFF00A884)),
                        tooltip: 'Video call',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              contactName: user.displayName,
                              isVideo: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New family call',
        backgroundColor: const Color(0xFF00A884),
        onPressed: () => context.go(RoutePaths.contacts),
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }
}
