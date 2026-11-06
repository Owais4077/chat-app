import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/chat_repository.dart';
import '../domain/conversation_summary.dart';
import 'chat_controller.dart';
import 'chat_providers.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    this.repository,
    required this.conversationId,
    this.title,
    this.isGroup = false,
    this.myRole = GroupMemberRole.member,
  });

  final ChatRepository? repository;
  final String conversationId;
  final String? title;
  final bool isGroup;
  final GroupMemberRole myRole;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late final ChatController controller;

  @override
  void initState() {
    super.initState();
    final ChatRepository repo =
        widget.repository ?? ref.read(chatRepositoryProvider);
    controller = ChatController(repo, widget.conversationId)
      ..addListener(_refresh)
      ..startListening();
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title ?? 'Conversation'),
      actions: widget.isGroup
          ? [
              TextButton(
                onPressed: () => context.push(
                  '/conversation/${widget.conversationId}/group-info',
                  extra: {'title': widget.title, 'myRole': widget.myRole},
                ),
                child: const Text('Group info'),
              ),
            ]
          : null,
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            children: controller.messages
                .map((message) => MessageBubble(message: message))
                .toList(),
          ),
        ),
        if (controller.error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Could not send message',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        MessageComposer(onSend: controller.send),
      ],
    ),
  );
}
