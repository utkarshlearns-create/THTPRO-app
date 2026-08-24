import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/conversation.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';

/// Every thread this user is in, newest activity first.
final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final list = await ref.watch(messagesRepositoryProvider).conversations();
  return list
    ..sort((a, b) {
      final at = a.lastMessageAt, bt = b.lastMessageAt;
      if (at == null && bt == null) return b.id.compareTo(a.id);
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
});

/// One thread's messages.
///
/// Fetching marks the other party's messages as read server-side, so this is
/// only ever watched by the open thread screen — never prefetched.
final threadProvider =
    FutureProvider.autoDispose.family<ConversationThread, int>(
  (ref, id) => ref.watch(messagesRepositoryProvider).thread(id),
);

/// Total unread across every thread, for the inbox badge.
final unreadMessagesProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await ref.watch(conversationsProvider.future);
  return list.fold<int>(0, (sum, c) => sum + c.unreadCount);
});
