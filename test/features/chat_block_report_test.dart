import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/conversation.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/messages/widgets/report_sheet.dart';

/// Block and report, the two things Google Play's User Generated Content
/// policy requires wherever people write to each other.
///
/// Chat is that surface in this app, so these endpoints are not a nicety —
/// without them the listing cannot ship. What is worth pinning is that each
/// call lands on the route the server actually serves (a 404 here looks like
/// "block failed" to the user), that `also_block` leaves the app as a real
/// flag rather than a string, that a block the server refuses a thread for is
/// readable as a *state* and not as a retryable error, and that the blocked
/// list never renders a phone number — `username` on this platform IS the
/// phone number.
void main() {
  late RequestOptions sent;

  /// A repository whose requests never leave the test, answering [body].
  MessagesRepository repo(Map<String, dynamic> body, {int status = 200}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        sent = options;
        final res = Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: body,
        );
        if (status >= 400) {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: res,
          ));
          return;
        }
        handler.resolve(res);
      },
    ));
    return MessagesRepository(dio);
  }

  group('block', () {
    test('it posts to the thread it is closing', () async {
      await repo({'blocked': true, 'created': true, 'user_id': 7}).block(41);
      expect(sent.method, 'POST');
      expect(sent.path, '/api/jobs/messages/41/block/');
    });

    test('a reason travels, and a blank one is left out', () async {
      await repo({'blocked': true}).block(41, reason: 'Spam');
      expect((sent.data as Map)['reason'], 'Spam');

      await repo({'blocked': true}).block(41, reason: '   ');
      expect((sent.data as Map).containsKey('reason'), isFalse);
    });

    test('unblocking a thread deletes the same route', () async {
      await repo({'removed': true}).unblock(41);
      expect(sent.method, 'DELETE');
      expect(sent.path, '/api/jobs/messages/41/block/');
    });

    test('unblocking from the list goes by account, not by thread', () async {
      // The thread may be gone by then, so the account id is the only handle
      // the blocked list can offer.
      await repo({'removed': true}).unblockUser(7);
      expect(sent.method, 'DELETE');
      expect(sent.path, '/api/jobs/messages/blocks/7/');
    });
  });

  group('report', () {
    test('it reaches the report route with the reason', () async {
      await repo({'reported': true, 'ticket_id': 12})
          .report(41, reason: 'FRAUD');
      expect(sent.method, 'POST');
      expect(sent.path, '/api/jobs/messages/41/report/');
      expect((sent.data as Map)['reason'], 'FRAUD');
    });

    test('also_block leaves as a boolean, always named', () async {
      // The server reads it with a truth test; sending the string 'false'
      // would block somebody who asked not to.
      await repo({'reported': true}).report(41, reason: 'SPAM');
      expect((sent.data as Map)['also_block'], false);

      await repo({'reported': true})
          .report(41, reason: 'SPAM', alsoBlock: true);
      expect((sent.data as Map)['also_block'], true);
    });

    test('empty details are dropped rather than sent blank', () async {
      await repo({'reported': true}).report(41, reason: 'SPAM', details: '  ');
      expect((sent.data as Map).containsKey('details'), isFalse);

      await repo({'reported': true})
          .report(41, reason: 'SPAM', details: ' asked for money ');
      expect((sent.data as Map)['details'], 'asked for money');
    });

    test('every reason offered is one the server knows', () {
      // ReportUserView.REASONS. A key the server does not know is filed as
      // OTHER rather than refused, but a wrong key here would quietly lose
      // the reason the reporter picked.
      expect(
        ReportReason.all.map((r) => r.key).toList(),
        ['SPAM', 'ABUSE', 'FRAUD', 'FAKE', 'OTHER'],
      );
    });
  });

  group('the blocked list', () {
    test('it reads the accounts route', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = options;
          handler.resolve(Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: [
              {
                'user_id': 7,
                'name': 'Ravi Verma',
                'role': 'TEACHER',
                'reason': 'Spam',
                'created_at': '2026-11-17T10:30:00+05:30',
              },
            ],
          ));
        },
      ));

      final rows = await MessagesRepository(dio).blockedAccounts();
      expect(sent.method, 'GET');
      expect(sent.path, '/api/jobs/messages/blocks/');
      expect(rows.single.userId, 7);
      expect(rows.single.name, 'Ravi Verma');
      expect(rows.single.role, 'TEACHER');
      expect(rows.single.blockedAt, isNotNull);
    });

    test('a nameless row falls back to a word, never to a number', () {
      // The server already refuses to send `username`; this is the app half
      // of the same promise, for a row that arrives with no name at all.
      final row = BlockedAccount.fromJson(const {'user_id': 7});
      expect(row.name, '');
      expect(row.name, isNot(contains('9')));
    });
  });

  group('a blocked thread', () {
    test('reads as a state, not as a failure to retry', () async {
      try {
        await repo(
          {'error': 'This conversation is blocked.', 'blocked': true},
          status: 403,
        ).thread(41);
        fail('a blocked thread must not resolve');
      } catch (e) {
        expect(ApiFailure.from(e).flag('blocked'), isTrue);
      }
    });

    test('an ordinary failure carries no such flag', () async {
      try {
        await repo({'error': 'Not found'}, status: 404).thread(41);
        fail('a missing thread must not resolve');
      } catch (e) {
        expect(ApiFailure.from(e).flag('blocked'), isFalse);
      }
    });

    test('a send refused by a block says so too', () async {
      try {
        await repo(
          {
            'error': 'You can no longer send messages in this chat.',
            'blocked': true,
          },
          status: 403,
        ).send(41, 'hello');
        fail('a blocked send must not resolve');
      } catch (e) {
        expect(ApiFailure.from(e).flag('blocked'), isTrue);
      }
    });
  });

  test('a thread names the account on the far end', () {
    // Report and block are about a person; the thread id alone does not say
    // who that is.
    final t = ConversationThread.fromJson(const {
      'conversation_id': 41,
      'other_name': 'Ravi Verma',
      'other_id': 7,
      'messages': <dynamic>[],
    });
    expect(t.otherId, 7);
    expect(
      ConversationThread.fromJson(const {'conversation_id': 41}).otherId,
      isNull,
    );
  });
}
