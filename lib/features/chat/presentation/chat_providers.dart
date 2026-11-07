import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/config_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/mock_chat_repository.dart';
import '../data/supabase_chat_repository.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation_summary.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!ref.watch(appConfigProvider).isSupabaseConfigured) {
    return MockChatRepository();
  }
  return SupabaseChatRepository(
    SupabaseChatDataSource(Supabase.instance.client),
  );
});

final chatConversationsProvider = StreamProvider<List<ConversationSummary>>((
  ref,
) {
  return ref.watch(chatRepositoryProvider).watchConversationSummaries();
});
