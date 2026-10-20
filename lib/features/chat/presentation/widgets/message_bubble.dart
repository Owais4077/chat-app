import 'package:flutter/material.dart';
import '../../domain/chat_message.dart';
class MessageBubble extends StatelessWidget { const MessageBubble({super.key, required this.message}); final ChatMessage message; @override Widget build(BuildContext context) => Align(alignment: Alignment.centerRight, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(message.text)))); }
