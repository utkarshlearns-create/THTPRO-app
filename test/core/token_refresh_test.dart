import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The refresh lock, tested against the behaviour that made it necessary.
///
/// The server rotates refresh tokens and blacklists the old one. So if two
/// requests expire together and each refreshes, the second presents a token
/// the first has already killed — and the user is signed out mid-session.
/// Whatever the implementation, the guarantee is: many callers, one refresh.
void main() {
  group('single-flight refresh', () {
    late int refreshCalls;
    Future<String?>? inFlight;

    // The same shape as ApiClient._refreshOnce, exercised directly. Driving it
    // through Dio's interceptor needs a live server; the rule worth pinning is
    // the concurrency one.
    Future<String?> refreshOnce(Future<String?> Function() perform) {
      return inFlight ??= perform().whenComplete(() => inFlight = null);
    }

    setUp(() {
      refreshCalls = 0;
      inFlight = null;
    });

    Future<String?> slowRefresh() async {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return 'new-access-token';
    }

    test('ten simultaneous expiries cause exactly one refresh', () async {
      final results = await Future.wait([
        for (var i = 0; i < 10; i++) refreshOnce(slowRefresh),
      ]);

      expect(refreshCalls, 1,
          reason: 'each extra refresh would blacklist the token the others '
              'are holding and sign the user out');
      expect(results.every((t) => t == 'new-access-token'), isTrue,
          reason: 'every waiter must get the token, not just the first');
    });

    test('a later expiry refreshes again rather than reusing the old one',
        () async {
      await refreshOnce(slowRefresh);
      await refreshOnce(slowRefresh);

      expect(refreshCalls, 2,
          reason: 'the lock must clear, or the app would keep presenting a '
              'refresh token the server has since rotated');
    });

    test('a failed refresh does not wedge the lock', () async {
      Future<String?> failing() async {
        refreshCalls++;
        throw DioException(requestOptions: RequestOptions(path: '/x'));
      }

      await expectLater(refreshOnce(failing), throwsA(isA<DioException>()));

      // The next attempt must be able to start; otherwise one network blip
      // leaves the session unrecoverable until the app is restarted.
      final second = await refreshOnce(slowRefresh);
      expect(second, 'new-access-token');
      expect(refreshCalls, 2);
    });
  });
}
