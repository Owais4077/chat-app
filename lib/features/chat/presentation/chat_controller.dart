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
  Timer? _pollingTimer;
  AppFailure? sendError;
  final messages = <ChatMessage>[];

  AppFailure? get error => sendError;

  void startListening() {
    _messageSubscription?.cancel();
    _messageSubscription = _repository
        .watchMessages(conversationId)
        .listen(
          _mergeMessages,
          onError: (_, _) {
            // Keep existing messages; do not show send error for stream updates
          },
        );

    // Fallback sync ensures two-sided conversation updates even if WebSocket stalls
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      try {
        final latest = await _repository.watchMessages(conversationId).first;
        _mergeMessages(latest);
      } catch (_) {}
    });

    _repository.markConversationRead(conversationId).ignore();
  }

  void _mergeMessages(List<ChatMessage> incoming) {
    if (incoming.isEmpty && messages.isNotEmpty) return;
    
    // Check if new items arrived or changed
    final incomingIds = incoming.map((m) => m.id).toList();
    final currentIds = messages.map((m) => m.id).toList();
    
    if (listEquals(incomingIds, currentIds)) return;

    messages
      ..clear()
      ..addAll(incoming);
    notifyListeners();
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

  Future<void> sendMedia({
    required String mediaUrl,
    required MessageType type,
  }) async {
    try {
      final message = await _repository.sendMediaMessage(
        conversationId: conversationId,
        mediaUrl: mediaUrl,
        type: type,
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
    _pollingTimer?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
