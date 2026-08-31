import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tht_app/core/auth/user_role.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/network/token_storage.dart';
import 'package:tht_app/core/notifications/push_service.dart';
import 'package:tht_app/core/repositories/users_repository.dart';

export 'package:tht_app/core/auth/user_role.dart';

/// Minimal auth state — what the router needs to decide where to send the user.
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.role,
    this.preLeaderRole,
    this.isLoading = true,
  });

  final bool isAuthenticated;
  final UserRole? role;
  final String? preLeaderRole;
  final bool isLoading;

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? preLeaderRole,
    bool? isLoading,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        role: role ?? this.role,
        preLeaderRole: preLeaderRole ?? this.preLeaderRole,
        isLoading: isLoading ?? this.isLoading,
      );

  /// Effective admin mode for team leaders — same logic as web's getEffectiveAdminMode().
  UserRole? get effectiveAdminMode {
    if (role == UserRole.teamLeader) {
      return preLeaderRole == 'TUTOR_ADMIN'
          ? UserRole.tutorAdmin
          : UserRole.counsellor;
    }
    return role;
  }

  /// Signed in, but with a role the app doesn't serve. The credentials are
  /// valid — they just belong on the website.
  bool get isUnsupportedRole =>
      isAuthenticated && role != null && !role!.isSupportedInApp;
}

/// Global auth notifier — manages login/logout state and exposes it to GoRouter.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  /// How long the splash stays up at minimum.
  ///
  /// Not a wait bolted onto the launch — the auth check runs during it and
  /// usually finishes in milliseconds, so this is the *floor*, not an
  /// addition. Without one the splash was drawn and replaced inside a frame or
  /// two, so its animation never played and the app appeared to snap straight
  /// to a login form. Long enough for the mark to land, short enough that a
  /// signed-in user does not notice it.
  static const _minimumSplash = Duration(milliseconds: 1100);

  final _bootedAt = DateTime.now();

  /// Sets the resolved auth state, but never before the splash has had its
  /// moment.
  Future<void> _settle(AuthState resolved) async {
    final elapsed = DateTime.now().difference(_bootedAt);
    final remaining = _minimumSplash - elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);
    state = resolved;
  }

  Future<void> _init() async {

    // Wire the force-logout callback from the Dio interceptor
    ApiClient.onForceLogout = logout;

    try {
      // Check if we have a valid stored session
      final access = await TokenStorage.getAccessToken();
      if (access != null && access.isNotEmpty) {
        try {
          if (!JwtDecoder.isExpired(access)) {
            final payload = JwtDecoder.decode(access);
            final role = UserRole.fromString(payload['role'] as String?);
            final preLeaderRole = payload['pre_leader_role'] as String?;
            if (preLeaderRole != null) {
              await TokenStorage.savePreLeaderRole(preLeaderRole);
            }
            await _settle(AuthState(
              isAuthenticated: true,
              role: role,
              preLeaderRole: preLeaderRole,
              isLoading: false,
            ));
            return;
          }
          // Access expired — try refresh
          final refresh = await TokenStorage.getRefreshToken();
          if (refresh != null && !JwtDecoder.isExpired(refresh)) {
            // Let the interceptor handle it on the next API call
            final storedRole = await TokenStorage.getRole();
            final storedPreLeader = await TokenStorage.getPreLeaderRole();
            await _settle(AuthState(
              isAuthenticated: true,
              role: UserRole.fromString(storedRole),
              preLeaderRole: storedPreLeader,
              isLoading: false,
            ));
            return;
          }
        } catch (e) {
          debugPrint('Auth init error: $e');
        }
      }

      // No valid session
      await _settle(const AuthState(isAuthenticated: false, isLoading: false));
    } catch (e) {
      // Safety net: if anything throws (e.g. SharedPreferences init on web),
      // always land on the login screen rather than staying on splash forever.
      debugPrint('Auth init fatal error: $e');
      await _settle(const AuthState(isAuthenticated: false, isLoading: false));
    }
  }

  /// Called after a successful login — saves tokens and updates state.
  Future<void> onLoginSuccess({
    required String access,
    required String refresh,
    required Map<String, dynamic> userData,
  }) async {
    await TokenStorage.saveTokens(access: access, refresh: refresh);

    Map<String, dynamic> payload = {};
    try {
      payload = JwtDecoder.decode(access);
    } catch (_) {
      // Allow mock tokens in development to pass through without crashing
    }

    final roleStr = payload['role'] as String? ??
        userData['role'] as String? ??
        'PARENT';
    final role = UserRole.fromString(roleStr);
    final preLeaderRole = payload['pre_leader_role'] as String?;

    await TokenStorage.saveUserInfo(
      role: roleStr,
      username: userData['username'] as String?,
      phone: userData['phone'] as String?,
      name: userData['name'] as String?,
      preLeaderRole: preLeaderRole,
      department: userData['department'] as String?,
    );

    state = AuthState(
      isAuthenticated: true,
      role: role,
      preLeaderRole: preLeaderRole,
      isLoading: false,
    );

    // Attach this device now that there is an account to attach it to, and a
    // reason for the user to accept the permission prompt. Deliberately not
    // awaited: a slow or refused registration must not hold up the redirect
    // into the app, and PushService swallows its own failures.
    unawaited(PushService.instance.registerDevice());
  }

  /// Called after a role change.
  Future<void> updateRole(String newRole) async {
    final role = UserRole.fromString(newRole);
    await TokenStorage.saveRole(newRole);
    state = state.copyWith(role: role);
  }

  /// Full sign-out — clears storage and resets state.
  Future<void> logout() async {
    // Detach this device first, while the token still authenticates. Doing it
    // after clearing would send an unauthenticated request and leave the row
    // behind — the next account on this phone would get the old user's push.
    await PushService.instance.unregisterDevice();
    await TokenStorage.clearAll();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

/// Riverpod provider for the global auth state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// The signed-in user's full account record.
///
/// The JWT carries only id and role, which is enough to route on but not enough
/// to greet someone by name or show their city. This fetches the rest once and
/// every screen reads it from here rather than re-requesting.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return null;

  final user = await ref.watch(usersRepositoryProvider).me();

  // Keep the cached name in sync so the next cold start can greet them before
  // the network comes back.
  final name = user.firstName.trim();
  if (name.isNotEmpty) await TokenStorage.saveName(name);

  return user;
});
