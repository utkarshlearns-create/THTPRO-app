import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/conversation.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// Parent ↔ teacher messaging, all of `/api/jobs/messages/`.
///
/// Both sides use the same endpoints; the server works out who is who and
/// names the other party accordingly.
class MessagesRepository extends Repository {
  MessagesRepository([super.dio]);

  /// Every thread, with a preview and an unread count.
  ///
  /// A teacher with no profile gets an empty list rather than an error, so an
  /// empty inbox is a normal state here.
  Future<List<Conversation>> conversations() async =>
      (await getList('/api/jobs/messages/'))
          .map(Conversation.fromJson)
          .toList();

  /// Opens a thread.
  ///
  /// Reading it **marks the other party's messages read** as a side effect, so
  /// this is not a safe thing to call speculatively — only when the user has
  /// actually opened the conversation.
  Future<ConversationThread> thread(int conversationId) async =>
      ConversationThread.fromJson(
        await getMap('/api/jobs/messages/$conversationId/'),
      );

  Future<Message> send(int conversationId, String text) async =>
      Message.fromJson(await postMap(
        '/api/jobs/messages/$conversationId/send/',
        body: {'text': text},
      ));

  /// Starts a thread with a teacher, or returns the existing one.
  ///
  /// Parent-initiated: the server takes `parent` from the caller, so a teacher
  /// cannot open a thread this way. [jobId] ties it to a requirement — and is
  /// part of the uniqueness key, so the same pair get separate threads per job.
  Future<Conversation> start({
    required int tutorProfileId,
    int? jobId,
  }) async {
    final data = await postMap('/api/jobs/messages/start/', body: {
      'tutor_profile_id': tutorProfileId,
      if (jobId != null) 'job_id': jobId,
    });
    return Conversation.fromJson(data);
  }
}

final messagesRepositoryProvider =
    Provider<MessagesRepository>((ref) => MessagesRepository());
