import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(chatConversationsProvider);
    return conversations.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No conversations yet'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(items[index].title),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load conversations')),
    );
  }
}
