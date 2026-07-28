import 'package:dio/dio.dart';

/// A network or API failure, already turned into something worth showing a user.
///
/// Screens should never render a raw `DioException.toString()` — it leaks URLs
/// and stack traces and tells the reader nothing about what to do next.
class ApiFailure implements Exception {
  const ApiFailure(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
    this.isConnectionProblem = false,
  });

  /// One sentence, in the user's language, about what went wrong.
  final String message;

  final int? statusCode;

  /// Per-field messages from a DRF validation error, e.g. `{'phone': '...'}`.
  /// Forms use this to mark the offending input rather than showing a banner.
  final Map<String, String> fieldErrors;

  /// True when the request never reached the server — worth offering "Retry"
  /// rather than asking the user to change their input.
  final bool isConnectionProblem;

  /// The session is gone and the user has to sign in again.
  bool get isUnauthorized => statusCode == 401;

  /// Signed in, but not allowed to do this.
  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  /// Typically "not enough credits" or a rule the backend enforces.
  bool get isValidationError => statusCode == 400;

  @override
  String toString() => message;

  /// Normalises anything thrown inside a repository into an [ApiFailure].
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) return ApiFailure._fromDio(error);
    return const ApiFailure('Something went wrong. Please try again.');
  }

  factory ApiFailure._fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure(
          'The connection timed out. Check your network and try again.',
          isConnectionProblem: true,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiFailure(
          "Can't reach The Home Tuitions. Check your internet connection.",
          isConnectionProblem: true,
        );
      case DioExceptionType.cancel:
        return const ApiFailure('Request cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiFailure('Could not establish a secure connection.');
      case DioExceptionType.badResponse:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    final fields = _fieldErrors(data);
    final detail = _detail(data);

    if (detail != null) {
      return ApiFailure(detail, statusCode: status, fieldErrors: fields);
    }
    if (fields.isNotEmpty) {
      return ApiFailure(fields.values.first, statusCode: status, fieldErrors: fields);
    }

    return ApiFailure(_forStatus(status), statusCode: status);
  }

  /// Pulls the single human-readable message DRF puts at the top level.
  static String? _detail(dynamic data) {
    if (data is String && data.trim().isNotEmpty && !data.trimLeft().startsWith('<')) {
      return data.trim();
    }
    if (data is! Map) return null;
    for (final key in const ['detail', 'error', 'message']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is List && v.isNotEmpty) return v.first.toString();
    }
    final nonField = data['non_field_errors'];
    if (nonField is List && nonField.isNotEmpty) return nonField.first.toString();
    return null;
  }

  /// Flattens `{"phone": ["Enter a valid number."]}` into `{"phone": "..."}`.
  static Map<String, String> _fieldErrors(dynamic data) {
    if (data is! Map) return const {};
    final out = <String, String>{};
    data.forEach((key, value) {
      if (key == 'detail' || key == 'error' || key == 'message') return;
      if (value is List && value.isNotEmpty) {
        out[key.toString()] = value.first.toString();
      } else if (value is String && value.trim().isNotEmpty) {
        out[key.toString()] = value.trim();
      }
    });
    return out;
  }

  static String _forStatus(int? status) {
    switch (status) {
      case 400:
        return 'Some of those details were not accepted. Please check and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return "You don't have access to this.";
      case 404:
        return "We couldn't find that.";
      case 429:
        return 'Too many attempts. Please wait a minute and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'The server is having trouble right now. Please try again shortly.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
