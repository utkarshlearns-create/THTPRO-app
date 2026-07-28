import 'package:dio/dio.dart';
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

  /// GET returning a JSON array, tolerating a paginated envelope.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final res =
            await dio.get(path, queryParameters: query, cancelToken: cancelToken);
        final data = res.data;
        if (data is List) {
          return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        }
        if (data is Map && data['results'] is List) {
          return (data['results'] as List)
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
        return const [];
      });

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
