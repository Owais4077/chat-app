import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
class ChatController extends ChangeNotifier {
  ChatController(this._repository, this.conversationId);

  final ChatRepository _repository;
  final String conversationId;
  StreamSubscription<List<ChatMessage>>? _messageSubscription;
  AppFailure? error;
  final messages = <ChatMessage>[];

  void startListening() {
    _messageSubscription?.cancel();
    _messageSubscription = _repository.watchMessages(conversationId).listen(
      (items) {
        messages
          ..clear()
          ..addAll(items);
        error = null;
        notifyListeners();
      },
      onError: (_, _) {
        error = const AppFailure.unknown();
        notifyListeners();
      },
    );
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) {
      error = const AppFailure.validation('Write a message before sending.');
      notifyListeners();
      return;
    }
    try {
      final message = await _repository.sendTextMessage(
        conversationId: conversationId,
        text: text,
      );
      if (!messages.any((existing) => existing.id == message.id)) {
        messages.add(message);
      }
      error = null;
      notifyListeners();
    } catch (_) {
      error = const AppFailure.unknown();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
