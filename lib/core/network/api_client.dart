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

    // In debug builds, print what actually failed. "You're offline" is the right
    // thing to show a user, but it hides whether the cause was a blocked CORS
    // preflight, a bad hostname, or a 500 — and those need different fixes.
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('→ ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '← ${response.statusCode} ${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (err, handler) {
            debugPrint(
              '✗ ${err.type.name} ${err.requestOptions.uri}\n'
              '  status: ${err.response?.statusCode ?? "no response"}\n'
              '  message: ${err.message}',
            );
            handler.next(err);
          },
        ),
      );
    }

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

    // A request that already carried a *fresh* token and still came back 401
    // has not expired — the new token was rejected too — so refreshing again
    // would loop, and each loop burns a rotation. The session is over.
    if (err.requestOptions.extra[_retriedKey] == true) {
      await _forceLogout();
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

    // One refresh for however many requests hit 401 together.
    final newAccess = await _refreshOnce();
    if (newAccess == null) {
      // The refresh token is dead, so the session is over. Retrying the
      // request without auth was tempting but wrong: on any endpoint with a
      // public fallback it turns "you have been signed out" into "you have no
      // data", and the user sits looking at an empty dashboard that should
      // have asked them to sign in.
      await _forceLogout();
      return handler.next(err);
    }

    final retryOptions = _retryableCopy(err.requestOptions);
    if (retryOptions == null) return handler.next(err);

    try {
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Marks a request that has already been through a refresh-and-retry.
  static const _retriedKey = 'tht.retried_after_refresh';

  /// The request made sendable a second time, or null if it cannot be.
  ///
  /// **A `FormData` body is single-use.** Dio finalises each part as it writes
  /// the request, so handing the same instance back to [Dio.fetch] throws
  /// `StateError: The MultipartFile has already been finalized` rather than
  /// retrying. That is exactly the case the refresh exists for: KYC documents
  /// and a profile photo or intro video are the slowest requests the app makes,
  /// so they are the likeliest to straddle a token expiry — and the failure
  /// surfaced as an unexplained error the teacher could only escape by picking
  /// every file again.
  ///
  /// `clone()` rebuilds each part from the byte source it was created with,
  /// which is what every upload here uses ([MultipartFile.fromBytes], because a
  /// picked file has no readable path on web). The boundary is carried over, so
  /// the content-type header already on the request stays correct.
  static RequestOptions? _retryableCopy(RequestOptions options) {
    final data = options.data;
    if (data is FormData) {
      try {
        options.data = data.clone();
      } catch (_) {
        // A part built from a stream that has been drained genuinely cannot be
        // rebuilt. Nothing in this app builds one, but a caller that did should
        // see its own 401 rather than a finalisation StateError from in here.
        return null;
      }
    }
    options.extra = {...options.extra, _retriedKey: true};
    return options;
  }

  /// The retry preparation above, for the test that pins it.
  @visibleForTesting
  static RequestOptions? debugRetryableCopy(RequestOptions options) =>
      _retryableCopy(options);

  /// The refresh currently in flight, shared by every caller that wants one.
  static Future<String?>? _inFlight;

  /// Refreshes the access token, at most once at a time.
  ///
  /// **The lock is the whole point.** The server rotates refresh tokens and
  /// blacklists the old one (`ROTATE_REFRESH_TOKENS` + `BLACKLIST_AFTER_ROTATION`),
  /// so the first refresh to land invalidates the token every other in-flight
  /// refresh is holding. Without this, an access token expiring while a screen
  /// has several requests open — which is every screen — meant one refresh
  /// succeeded and the rest were rejected against a blacklisted token and
  /// signed the user out. It reads as being randomly logged out, and it is
  /// worst on the busiest screens.
  ///
  /// Returns the new access token, or null when the session is genuinely over.
  static Future<String?> _refreshOnce() {
    return _inFlight ??= _performRefresh().whenComplete(() {
      // Cleared on completion, so a later expiry starts a fresh one rather
      // than reusing a token that has since been rotated again.
      _inFlight = null;
    });
  }

  static Future<String?> _performRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _refreshDio.post(
        '/api/users/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccess = response.data['access'] as String?;
      if (newAccess == null) return null;

      // The rotated refresh token has to be stored with the access token, or
      // the next refresh presents one the server has already blacklisted.
      final newRefresh = response.data['refresh'] as String?;
      if (newRefresh != null) {
        await TokenStorage.saveTokens(access: newAccess, refresh: newRefresh);
      } else {
        await TokenStorage.saveAccessToken(newAccess);
      }
      return newAccess;
    } on DioException {
      return null;
    }
  }

  static Future<void> _forceLogout() async {
    await TokenStorage.clearAll();
    onForceLogout?.call();
  }
}
