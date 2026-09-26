import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/network/api_client.dart';

/// The one request shape the refresh-and-retry used to break on.
///
/// A `FormData` body is written once and then finalised, so re-sending the same
/// `RequestOptions` after a refresh threw instead of retrying. KYC documents and
/// a profile photo are the slowest requests the app makes, so they are the ones
/// most likely to straddle a token expiry — the retry has to work there most of
/// all, and that is where it did not.
void main() {
  FormData upload() {
    final form = FormData();
    form.fields.add(const MapEntry('field', 'aadhaar_front'));
    form.files.add(MapEntry(
      'aadhaar_front',
      MultipartFile.fromBytes(const [1, 2, 3, 4], filename: 'front.jpg'),
    ));
    return form;
  }

  RequestOptions request(Object? body) =>
      RequestOptions(path: '/api/users/kyc/upload/', method: 'POST', data: body);

  test('an upload can be sent a second time after the token is refreshed',
      () async {
    final form = upload();
    final options = request(form);

    // What the first attempt did before it came back 401: the body went out on
    // the wire, and every part in it is now spent.
    await form.finalize().drain<void>();
    // The defect, stated: this is what the old retry did with it.
    expect(() => form.finalize(), throwsStateError);

    final retry = ApiClient.debugRetryableCopy(options);
    expect(retry, isNotNull);

    final body = retry!.data as FormData;
    expect(body, isNot(same(form)),
        reason: 'the spent body must not be the one the retry sends');
    // The assertion that matters: this is the call that used to throw
    // "The MultipartFile has already been finalized". Reading it to the end
    // proves the parts were rebuilt from their bytes, not merely re-wrapped.
    final sent = await body.finalize().fold<int>(0, (n, c) => n + c.length);
    expect(sent, form.length);
  });

  test('the retried copy carries the same document', () {
    final form = upload();
    final retry = ApiClient.debugRetryableCopy(request(form))!;
    final body = retry.data as FormData;

    expect(body.fields, form.fields);
    expect(body.files.single.key, 'aadhaar_front');
    expect(body.files.single.value.filename, 'front.jpg');
    // A changed boundary would invalidate the content-type header already set
    // on the request, and the server would reject the retry as malformed.
    expect(body.boundary, form.boundary);
  });

  test('a JSON body is passed through as it is', () {
    final body = {'terms_accepted': true};
    final retry = ApiClient.debugRetryableCopy(request(body))!;

    expect(retry.data, same(body),
        reason: 'only a multipart body needs rebuilding; cloning anything else '
            'risks changing what the server is sent');
  });

  test('the copy is marked so a second 401 signs out instead of looping', () {
    final first = ApiClient.debugRetryableCopy(request(null))!;
    final marker =
        first.extra.entries.singleWhere((e) => e.value == true, orElse: () {
      fail('the retry is unmarked, so a rejected fresh token would refresh '
          'again — and each rotation blacklists the one before it');
    });

    // The marker has to survive onto the request the interceptor actually
    // inspects, which is the same object it was set on.
    expect(request(null).extra.containsKey(marker.key), isFalse);
  });
}
