import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/utils/api_error.dart';

DioException _response(int status, dynamic body) => DioException(
      requestOptions: RequestOptions(path: '/api/x/'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/api/x/'),
        statusCode: status,
        data: body,
      ),
    );

void main() {
  group('messages the user actually sees', () {
    test("prefers the backend's own wording over a generic status message", () {
      final f = ApiFailure.from(_response(402, {
        'error': 'Insufficient credits. Please recharge your wallet to unlock '
            'contacts.',
      }));
      expect(f.message, startsWith('Insufficient credits'));
      expect(f.statusCode, 402);
    });

    test('reads DRF detail and non_field_errors too', () {
      expect(
        ApiFailure.from(_response(403, {'detail': 'Not allowed here.'})).message,
        'Not allowed here.',
      );
      expect(
        ApiFailure.from(_response(400, {'non_field_errors': ['Bad combination.']}))
            .message,
        'Bad combination.',
      );
    });

    test('falls back to a plain sentence when the body says nothing useful', () {
      expect(ApiFailure.from(_response(500, null)).message,
          contains('server is having trouble'));
      expect(ApiFailure.from(_response(404, null)).message,
          contains("couldn't find"));
    });

    test('never surfaces an HTML error page as the message', () {
      final f = ApiFailure.from(_response(500, '<html><body>oops</body></html>'));
      expect(f.message, isNot(contains('<html>')));
      expect(f.message, contains('server is having trouble'));
    });
  });

  group('field errors', () {
    test('flattens DRF field arrays so a form can mark the input', () {
      final f = ApiFailure.from(_response(400, {
        'phone': ['A user with this phone number already exists.'],
        'about_me': ['Too short.'],
      }));
      expect(f.fieldErrors['phone'], contains('already exists'));
      expect(f.fieldErrors['about_me'], 'Too short.');
      // With no top-level detail, the banner shows one of the field messages
      // rather than a vague fallback.
      expect(f.message, contains('already exists'));
    });

    test('does not treat detail as a field', () {
      final f = ApiFailure.from(_response(400, {'detail': 'Nope.'}));
      expect(f.fieldErrors, isEmpty);
    });
  });

  group('connection problems', () {
    test('are flagged so the UI can offer retry instead of blaming the input', () {
      final f = ApiFailure.from(DioException(
        requestOptions: RequestOptions(path: '/api/x/'),
        type: DioExceptionType.connectionError,
      ));
      expect(f.isConnectionProblem, isTrue);
      expect(f.message, contains('internet'));
    });

    test('a timeout is a connection problem, not a server error', () {
      final f = ApiFailure.from(DioException(
        requestOptions: RequestOptions(path: '/api/x/'),
        type: DioExceptionType.receiveTimeout,
      ));
      expect(f.isConnectionProblem, isTrue);
    });
  });

  test('classifies the statuses screens branch on', () {
    expect(ApiFailure.from(_response(401, null)).isUnauthorized, isTrue);
    expect(ApiFailure.from(_response(403, null)).isForbidden, isTrue);
    expect(ApiFailure.from(_response(400, null)).isValidationError, isTrue);
  });

  test('passes an existing ApiFailure through unchanged', () {
    const original = ApiFailure('Already friendly.', statusCode: 400);
    expect(ApiFailure.from(original), same(original));
  });
}
