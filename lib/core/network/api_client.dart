import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Singleton Dio client for the entire app.
///
/// Mirrors the web's `installApiFetchInterceptor()` + `apiFetch()`:
/// 1. Attaches `Authorization: Bearer <access>` to every `/api/` request.
/// 2. On 401, refreshes the token via `/api/users/token/refresh/` and retries.
/// 3. If refresh fails, clears storage (handled by the auth notifier in router).
///
/// Skip list: token refresh and login endpoints are NOT intercepted — a 401 on
/// those means "wrong credentials", not "expired session" (same logic as web).
class ApiClient {
  ApiClient._();

  static final Dio _dio = _createDio();
  static Dio get instance => _dio;

  /// A separate Dio for the refresh request, so it bypasses the interceptor.
  static final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  /// Callback that the auth layer sets so the interceptor can trigger a
  /// global sign-out (clear tokens + redirect to login). Avoids a hard
  /// dependency on the router from the network layer.
  static VoidCallback? onForceLogout;

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );

    return dio;
  }

  // ── Request interceptor: attach Bearer token ──

  static Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth endpoints (same as web's AUTH_ENDPOINTS list)
    const skipPaths = [
      '/api/users/login/',
      '/api/users/auth/google/',
      '/api/users/signup/',
      '/api/users/token/refresh/',
    ];
    if (skipPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }

    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  // ── Error interceptor: refresh on 401 & retry ──

  static Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry auth endpoints
    final path = err.requestOptions.path;
    const skipPaths = [
      '/api/users/login/',
      '/api/users/auth/google/',
      '/api/users/signup/',
    ];
    if (skipPaths.any((p) => path.contains(p))) {
      return handler.next(err);
    }

    // Attempt token refresh
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _forceLogout();
      return handler.next(err);
    }

    try {
      final response = await _refreshDio.post(
        '/api/users/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccess = response.data['access'] as String?;
      if (newAccess == null) {
        await _forceLogout();
        return handler.next(err);
      }

      // Save new tokens
      await TokenStorage.saveAccessToken(newAccess);
      final newRefresh = response.data['refresh'] as String?;
      if (newRefresh != null) {
        await TokenStorage.saveTokens(access: newAccess, refresh: newRefresh);
      }

      // Retry the original request with the new token
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException {
      // Refresh failed — try without auth (for public endpoints)
      try {
        final publicOptions = err.requestOptions;
        publicOptions.headers.remove('Authorization');
        final publicResponse = await _refreshDio.fetch(publicOptions);
        return handler.resolve(publicResponse);
      } catch (_) {
        await _forceLogout();
        return handler.next(err);
      }
    }
  }

  static Future<void> _forceLogout() async {
    await TokenStorage.clearAll();
    onForceLogout?.call();
  }
}
