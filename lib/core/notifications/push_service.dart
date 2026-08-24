import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tht_app/core/repositories/users_repository.dart';

/// Handles a push that arrives while the app is terminated or backgrounded.
///
/// Must be a top-level annotated function: Android runs it in a *separate*
/// isolate with none of the app's state, so anything captured from the UI
/// isolate would be null here.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Nothing to do — Android has already drawn the notification from the
  // payload. This exists so the plugin has a registered handler rather than
  // warning on every delivery.
}

/// Push notifications, end to end.
///
/// The device token belongs to the *install*, not the account. It has to be
/// registered after a login and cleared on logout, or the next person to sign
/// in on this phone starts receiving the previous user's notifications.
class PushService {
  PushService._();

  static final instance = PushService._();

  static const _channel = AndroidNotificationChannel(
    'tht_default',
    'The Home Tuitions',
    description: 'Leads, demos, payments and account updates.',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Where a tap should land, parked until the router is listening.
  ///
  /// A tap can arrive before the first frame — the app may be launching
  /// *because* of it — so the destination waits here rather than being pushed
  /// into a Navigator that does not exist yet.
  String? pendingRoute;

  /// Set by the router once it can navigate.
  void Function(String route)? onNavigate;

  /// Boots Firebase and the notification channel.
  ///
  /// Never throws: an unconfigured or unreachable Firebase leaves push off
  /// rather than stopping the app from starting.
  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      // Android suppresses notifications while the app is foregrounded, so one
      // is drawn by hand from the payload.
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (route != null && route.isNotEmpty) _handleRoute(route);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp
          .listen((m) => _handleRoute(routeForData(m.data)));

      // A tap that launched the app from cold.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) pendingRoute = routeForData(initial.data);

      _ready = true;
    } catch (e) {
      debugPrint('push init failed, notifications are off: $e');
    }
  }

  /// Asks permission, then attaches this device to the signed-in account.
  ///
  /// Android 13+ needs a runtime prompt; below that the grant is implicit.
  /// Called after login rather than at startup, so the prompt arrives when the
  /// user has a reason to say yes.
  Future<void> registerDevice() async {
    if (!_ready) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await UsersRepository().registerDeviceToken(token);

      // FCM rotates tokens, and a stale one stops delivering silently.
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        try {
          await UsersRepository().registerDeviceToken(t);
        } catch (e) {
          debugPrint('push token refresh failed: $e');
        }
      });
    } catch (e) {
      debugPrint('push register failed: $e');
    }
  }

  /// Detaches this device from the account signing out.
  ///
  /// The local token is deleted too, so the next sign-in on this phone gets a
  /// fresh one instead of inheriting the last user's.
  Future<void> unregisterDevice() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await UsersRepository().unregisterDeviceToken(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('push unregister failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: routeForData(message.data),
    );
  }

  void _handleRoute(String route) {
    if (route.isEmpty) return;
    final navigate = onNavigate;
    if (navigate == null) {
      pendingRoute = route;
    } else {
      navigate(route);
    }
  }

  /// Where a notification should open, from the data the server attached.
  ///
  /// An explicit `route` wins. Everything else is derived from the type and the
  /// related job, so a server that sends neither still lands somewhere sensible
  /// rather than nowhere.
  static String routeForData(Map<String, dynamic> data) {
    final explicit = data['route'];
    if (explicit is String && explicit.startsWith('/')) return explicit;

    final jobId = int.tryParse('${data['job_id'] ?? ''}');
    final type =
        '${data['type'] ?? data['notification_type'] ?? ''}'.toUpperCase();

    if (jobId != null) {
      // An application or demo update is about a job the recipient owns; a
      // plain job notification is a lead they might want.
      if (type.contains('APPLIC') || type.contains('DEMO')) {
        return '/my-jobs/$jobId';
      }
      return '/jobs/$jobId';
    }
    if (type.contains('KYC')) return '/tutor-kyc';
    if (type.contains('WALLET') || type.contains('PAYMENT')) return '/wallet';
    if (type.contains('MESSAGE')) return '/messages';
    return '/notifications';
  }

  /// The raw token, for sending a test push from the Firebase console.
  Future<String?> debugToken() async {
    if (!_ready) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
