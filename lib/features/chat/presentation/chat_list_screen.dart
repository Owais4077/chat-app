import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import 'chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(chatConversationsProvider);

    return Scaffold(
      body: conversations.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(item.isGroup ? Icons.group : Icons.person),
                ),
                title: Text(item.title),
                subtitle: item.lastMessagePreview.isNotEmpty
                    ? Text(
                        item.lastMessagePreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: item.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.unreadCount}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () => context.push(
                  '/conversation/${item.id}',
                  extra: {
                    'title': item.title,
                    'isGroup': item.isGroup,
                    'myRole': item.myRole,
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load conversations')),
      ),
      floatingActionButton: PopupMenuButton<String>(
        tooltip: 'New chat',
        onSelected: (value) {
          if (value == 'new_message') {
            context.go(RoutePaths.contacts);
          } else if (value == 'new_group') {
            context.push(RoutePaths.newGroup);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'new_message', child: Text('New message')),
          PopupMenuItem(value: 'new_group', child: Text('New group')),
        ],
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
