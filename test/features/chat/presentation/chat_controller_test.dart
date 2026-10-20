import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/data/mock_chat_repository.dart';
import 'package:relay_messenger/features/chat/presentation/chat_controller.dart';
void main() { test('rejects blank messages with a validation error', () async { final controller = ChatController(MockChatRepository(), 'demo-conversation'); await controller.send('   '); expect(controller.error, isNotNull); }); }
