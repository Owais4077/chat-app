import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController(this._repository, this.conversationId);

  final ChatRepository _repository;
  final String conversationId;
  StreamSubscription<List<ChatMessage>>? _messageSubscription;
  AppFailure? sendError;
  final messages = <ChatMessage>[];

  AppFailure? get error => sendError;

  void startListening() {
    _messageSubscription?.cancel();
    _messageSubscription = _repository
        .watchMessages(conversationId)
        .listen(
          (items) {
            messages
              ..clear()
              ..addAll(items);
            notifyListeners();
          },
          onError: (_, _) {
            // Keep existing messages; do not show send error for stream updates
          },
        );
    _repository.markConversationRead(conversationId).ignore();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      sendError = const AppFailure.validation('Write a message before sending.');
      notifyListeners();
      return;
    }
    try {
      final message = await _repository.sendTextMessage(
        conversationId: conversationId,
        text: trimmed,
      );
      if (!messages.any((existing) => existing.id == message.id)) {
        messages.add(message);
      }
      sendError = null;
      notifyListeners();
    } catch (e) {
      final message = e is PostgrestException ? e.message : e.toString();
      sendError = AppFailure.unknown(message);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
