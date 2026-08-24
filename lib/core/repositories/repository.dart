import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// Shared plumbing for every repository.
///
/// One rule holds across all of them: a repository returns a model or throws an
/// [ApiFailure]. Nothing above this layer ever sees a [DioException], so no
/// screen has to know how to read one.
abstract class Repository {
  Repository([Dio? dio]) : dio = dio ?? ApiClient.instance;

  final Dio dio;

  /// Runs [request] and converts anything it throws into an [ApiFailure].
  Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  /// GET returning a JSON object.
  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final res =
            await dio.get(path, queryParameters: query, cancelToken: cancelToken);
        final data = res.data;
        if (data is Map) return data.cast<String, dynamic>();
        return <String, dynamic>{};
      });

  /// GET returning a JSON array, tolerating an envelope around it.
  ///
  /// Three shapes are accepted: a bare array, `{<key>: [...]}` when [key] names
  /// the list, and DRF's `{'results': [...]}`.
  ///
  /// Anything else throws. This used to return an empty list instead, and that
  /// single line hid a real outage: `/api/jobs/tutor/applications/` answers with
  /// `{'applications': [...], 'stats': {...}}`, so every teacher's application
  /// list came back empty and rendered as "you haven't applied to anything yet"
  /// — a lie the screen had no way to tell it was telling. An endpoint whose
  /// shape we do not understand is a failure, not an empty result.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    String? key,
  }) =>
      guard(() async {
        final res =
            await dio.get(path, queryParameters: query, cancelToken: cancelToken);
        return unwrapList(res.data, path: path, key: key);
      });

  /// Pulls the list out of whatever [data] is, or throws naming what it found.
  ///
  /// Separate from [getList] so it can be unit-tested without a socket.
  static List<Map<String, dynamic>> unwrapList(
    Object? data, {
    required String path,
    String? key,
  }) {
    List<Map<String, dynamic>> rows(List raw) =>
        raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

    if (data is List) return rows(data);

    if (data is Map) {
      if (key != null && data[key] is List) return rows(data[key] as List);
      if (data['results'] is List) return rows(data['results'] as List);
      throw _unexpected(
        path,
        // The keys are the whole diagnostic: they name the envelope that
        // actually arrived, which is exactly what fixing the call site needs.
        'expected a list${key == null ? '' : " under '$key'"}, '
            'got an object with keys: ${data.keys.join(', ')}',
      );
    }

    throw _unexpected(path, 'expected a list, got ${data.runtimeType}');
  }

  /// The shape diagnostic goes to the console, never to the user — [ApiFailure]
  /// exists precisely so a screen never renders a URL or an internal detail.
  static ApiFailure _unexpected(String path, String diagnostic) {
    debugPrint('✗ $path: $diagnostic');
    return const ApiFailure(
      'The server sent back something we could not read. Please try again.',
    );
  }

  /// POST returning a JSON object.
  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) =>
      guard(() async {
        final res = await dio.post(path, data: body, queryParameters: query);
        final data = res.data;
        if (data is Map) return data.cast<String, dynamic>();
        return <String, dynamic>{};
      });

  /// PATCH returning a JSON object.
  Future<Map<String, dynamic>> patchMap(String path, {Object? body}) =>
      guard(() async {
        final res = await dio.patch(path, data: body);
        final data = res.data;
        if (data is Map) return data.cast<String, dynamic>();
        return <String, dynamic>{};
      });
}
