import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/repositories/repository.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// `Repository.unwrapList` is the whole of the list-shape contract.
///
/// It earns its own test because the version that returned `const []` for an
/// unrecognised shape hid a real outage: `/api/jobs/tutor/applications/` answers
/// with `{'applications': [...]}`, so every teacher's list came back empty and
/// rendered as "you haven't applied to anything yet". The last case here is the
/// guard — an envelope we do not understand must throw, not read as empty.
void main() {
  group('unwrapList', () {
    test('reads a bare array', () {
      final rows = Repository.unwrapList(
        [
          {'id': 1},
          {'id': 2},
        ],
        path: '/x/',
      );
      expect(rows, hasLength(2));
      expect(rows.first['id'], 1);
    });

    test('reads a DRF paginated envelope', () {
      final rows = Repository.unwrapList(
        {
          'count': 1,
          'results': [
            {'id': 7},
          ],
        },
        path: '/x/',
      );
      expect(rows.single['id'], 7);
    });

    test('reads the named key the endpoint actually uses', () {
      final rows = Repository.unwrapList(
        {
          'applications': [
            {'id': 3},
          ],
          'stats': {'total': 1},
        },
        path: '/api/jobs/tutor/applications/',
        key: 'applications',
      );
      expect(rows.single['id'], 3);
    });

    test('prefers the named key over results when both are present', () {
      final rows = Repository.unwrapList(
        {
          'demos': [
            {'id': 1},
          ],
          'results': [
            {'id': 2},
            {'id': 3},
          ],
        },
        path: '/x/',
        key: 'demos',
      );
      expect(rows.single['id'], 1);
    });

    test('throws on an envelope it does not recognise', () {
      expect(
        () => Repository.unwrapList(
          {
            'applications': [
              {'id': 3},
            ],
          },
          // No key passed — the exact mistake that caused the outage.
          path: '/api/jobs/tutor/applications/',
        ),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('throws when the named key is absent rather than reading empty', () {
      expect(
        () => Repository.unwrapList(
          {'items': <dynamic>[]},
          path: '/x/',
          key: 'applications',
        ),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('throws on a scalar body', () {
      expect(
        () => Repository.unwrapList('nope', path: '/x/'),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('an empty list is a legitimate empty result, not a failure', () {
      expect(Repository.unwrapList(const [], path: '/x/'), isEmpty);
      expect(
        Repository.unwrapList({'applications': <dynamic>[]},
            path: '/x/', key: 'applications'),
        isEmpty,
      );
    });

    test('skips non-object entries instead of crashing', () {
      final rows = Repository.unwrapList(
        [
          {'id': 1},
          'garbage',
          null,
        ],
        path: '/x/',
      );
      expect(rows, hasLength(1));
    });
  });
}
