import 'package:flutter/material.dart';
import '../domain/chat_repository.dart';
import 'chat_controller.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';
class ConversationScreen extends StatefulWidget { const ConversationScreen({super.key, required this.repository, required this.conversationId}); final ChatRepository repository; final String conversationId; @override State<ConversationScreen> createState() => _ConversationScreenState(); }
class _ConversationScreenState extends State<ConversationScreen> { late final ChatController controller; @override void initState() { super.initState(); controller = ChatController(widget.repository, widget.conversationId)..addListener(_refresh); } void _refresh() => setState(() {}); @override void dispose() { controller.removeListener(_refresh); controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Conversation')), body: Column(children: [Expanded(child: ListView(children: controller.messages.map((message) => MessageBubble(message: message)).toList())), if (controller.error != null) Padding(padding: const EdgeInsets.all(8), child: Text('Could not send message', style: TextStyle(color: Theme.of(context).colorScheme.error))), MessageComposer(onSend: controller.send)])); }
