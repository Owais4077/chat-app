import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
class ChatController extends ChangeNotifier { ChatController(this._repository, this.conversationId); final ChatRepository _repository; final String conversationId; AppFailure? error; final messages = <ChatMessage>[]; Future<void> send(String text) async { if (text.trim().isEmpty) { error = const AppFailure.validation('Write a message before sending.'); notifyListeners(); return; } try { final message = await _repository.sendTextMessage(conversationId: conversationId, text: text); messages.add(message); error = null; notifyListeners(); } catch (_) { error = const AppFailure.unknown(); notifyListeners(); } } }
