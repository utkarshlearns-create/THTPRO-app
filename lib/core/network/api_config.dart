/// Central API configuration.
///
/// The app talks to the same Django backend as thehometuitions.com, so a login
/// made on the website and a login made here are the same session — same JWT,
/// same roles, same wallet.
///
/// Note the app reaches that backend *directly*, which the website does not:
/// the Next.js app serves relative `/api/...` URLs and proxies them server-side
/// (see the site's `next.config.mjs` rewrites), so the browser there is always
/// same-origin. That is why the site needs no CORS entry and this app does.
///
/// Point it somewhere else at build time without touching this file:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   // Android emulator
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000  // iOS sim / desktop / web
class ApiConfig {
  ApiConfig._();

  /// Base URL for all API requests. Defaults to the Render service that hosts
  /// Django — the same backend the website's rewrites forward to.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://thtpro.onrender.com',
  );

  /// The public site — used for policy pages, receipts and share links.
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://www.thehometuitions.com',
  );

  /// True when pointed at the live backend rather than a local one.
  static bool get isProduction => baseUrl == 'https://thtpro.onrender.com';

  /// Default page size matching DRF's PAGE_SIZE = 20.
  static const int pageSize = 20;

  /// Request timeouts.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
