import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// The school / coaching requirement, on its way to the institutional desk.
///
/// The endpoint takes no authentication and derives the lead's reference from
/// the answers themselves, which makes two things worth pinning: every answer
/// has to actually leave the app (a dropped `area` or `positions` is a lead the
/// desk has to ring back to re-ask), and the `duplicate` verdict has to survive
/// the trip, because that is the only way the sender learns their second
/// attempt did not create a second lead.
void main() {
  late RequestOptions sent;

  /// A repository whose requests never leave the test, answering [body].
  JobsRepository repo(
    Map<String, dynamic> body, {
    int status = 200,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        sent = options;
        final res = Response<Map<String, dynamic>>(
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
    return JobsRepository(dio);
  }

  final answers = <String, dynamic>{
    'institute_name': 'Sunrise Public School',
    'area': 'Gomti Nagar, Lucknow',
    'requirement': 'Physics faculty for Class 11-12 / NEET batch',
    'positions': '3',
    'qualification': 'M.Sc Physics, 3+ years',
    'salary': '25,000 - 35,000 per month',
    'timing': 'Morning shift, joining immediately',
    'name': 'Anil Verma',
    'phone': '9876543210',
    'extra': 'CBSE, batch of 40',
  };

  test('it reaches the endpoint the website files through', () async {
    await repo({'success': true, 'lead_id': 91}).submitInstituteRequirement(
      answers,
    );
    expect(sent.method, 'POST');
    expect(sent.path, '/api/jobs/institute-requirement/');
  });

  test('every answer the form collected goes with it', () async {
    await repo({'success': true, 'lead_id': 91}).submitInstituteRequirement(
      answers,
    );
    // Named one by one on purpose: the server stores the optional ones as the
    // Q&A block the desk reads off, so a field quietly lost here is a question
    // the institute gets asked twice.
    expect(sent.data, answers);
    for (final key in [
      'institute_name',
      'area',
      'requirement',
      'positions',
      'qualification',
      'salary',
      'timing',
      'name',
      'phone',
      'extra',
    ]) {
      expect((sent.data as Map).containsKey(key), isTrue, reason: key);
    }
  });

  test('a requirement the desk already holds says so', () async {
    final again = await repo({
      'success': true,
      'lead_id': 91,
      'duplicate': true,
    }).submitInstituteRequirement(answers);
    expect(again, isTrue);
  });

  test('a fresh requirement is not reported as a duplicate', () async {
    expect(
      await repo({'success': true, 'lead_id': 92})
          .submitInstituteRequirement(answers),
      isFalse,
      reason: 'a missing flag must read as new, never as already-filed',
    );
  });

  test("a rejection surfaces the server's own sentence", () async {
    try {
      await repo(
        {'error': 'Please enter a valid 10-digit mobile number.'},
        status: 400,
      ).submitInstituteRequirement({...answers, 'phone': '12345'});
      fail('a 400 must not read as a filed requirement');
    } catch (e) {
      // The screen prints failure.message directly, so this is the sentence
      // the institute reads.
      final failure = ApiFailure.from(e);
      expect(failure.message, 'Please enter a valid 10-digit mobile number.');
      expect(failure.statusCode, 400);
    }
  });
}
