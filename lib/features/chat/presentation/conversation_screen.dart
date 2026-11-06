import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/presentation/auth_providers.dart';
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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final ChatRepository repo =
        widget.repository ?? ref.read(chatRepositoryProvider);
    controller = ChatController(repo, widget.conversationId)
      ..addListener(_onControllerUpdate)
      ..startListening();
  }

  void _onControllerUpdate() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authRepositoryProvider).currentUser()?.id;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF0B141B)
          : const Color(0xFFEFEAE2),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Icon(
                widget.isGroup ? Icons.group : Icons.person,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? 'Conversation',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isGroup ? 'Group' : 'Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            : [
                IconButton(
                  icon: const Icon(Icons.call_outlined),
                  tooltip: 'Voice call',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice calling coming in next update!')),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined),
                  tooltip: 'Video call',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video calling coming in next update!')),
                  ),
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: controller.messages.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Messages are end-to-end secured.\nSay hello to start chatting!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      final isMe = message.senderId == null ||
                          message.senderId == currentUserId;
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          if (controller.error case final err? when err is! ValidationFailure)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      err.messageText != null && err.messageText!.isNotEmpty
                          ? err.messageText!
                          : 'Could not send message. Please retry.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          MessageComposer(onSend: controller.send),
        ],
      ),
    );
  }
}
