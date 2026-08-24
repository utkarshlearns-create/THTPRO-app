import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// One turn in a Genie conversation.
class GenieTurn {
  const GenieTurn({required this.role, required this.content});

  /// `user` or `assistant`.
  final String role;
  final String content;

  bool get isMine => role == 'user';

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// THT Helper — the assistant on `POST /api/jobs/genie/chat/`.
///
/// Stateless server-side: it holds no thread, so the whole conversation is
/// posted on every turn and the history lives in the client.
class GenieRepository extends Repository {
  GenieRepository([super.dio]);

  /// Sends the conversation so far and returns the next reply.
  ///
  /// [phone] lets the assistant recognise the caller and answer about their own
  /// leads rather than in generalities. The endpoint is `AllowAny` and rate
  /// limited per visitor, so a signed-out user can use it too.
  Future<String> chat(
    List<GenieTurn> history, {
    String? phone,
  }) async {
    final data = await postMap('/api/jobs/genie/chat/', body: {
      // Server truncates each message at 2000 characters and drops empty ones.
      'messages': history.map((t) => t.toJson()).toList(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
    final reply = data['reply'];
    return reply is String && reply.trim().isNotEmpty
        ? reply.trim()
        : 'Sorry, I could not answer that. Please try asking another way.';
  }
}

final genieRepositoryProvider =
    Provider<GenieRepository>((ref) => GenieRepository());
