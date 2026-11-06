import 'package:flutter/material.dart';

class MessageComposer extends StatelessWidget {
  const MessageComposer({super.key, required this.onSend});
  final ValueChanged<String> onSend;
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Message'),
            ),
          ),
          Semantics(
            label: 'Send message',
            button: true,
            child: IconButton(
              tooltip: 'Send message',
              onPressed: () {
                onSend(controller.text);
                controller.clear();
              },
              icon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
