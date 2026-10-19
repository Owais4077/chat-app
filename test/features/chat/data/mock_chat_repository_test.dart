import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/data/mock_chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';

void main() {
  test('sending text produces a sent message', () async {
    final chat = MockChatRepository();

    final sent = await chat.sendTextMessage(
      conversationId: 'demo-conversation',
      text: 'Hello',
    );

    expect(sent.status, MessageStatus.sent);
  });
}
