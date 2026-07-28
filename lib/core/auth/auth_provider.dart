import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/network/token_storage.dart';

/// User roles — mirrors the Django/Next.js role strings stored in the JWT.
enum UserRole {
  parent('PARENT'),
  teacher('TEACHER'),
  counsellor('COUNSELLOR'),
  tutorAdmin('TUTOR_ADMIN'),
  teamLeader('TEAM_LEADER'),
  superadmin('SUPERADMIN'),
  institution('INSTITUTION'),
  student('STUDENT');

  const UserRole(this.value);
  final String value;

  static UserRole? fromString(String? s) {
    if (s == null) return null;
    final upper = s.toUpperCase();
    return UserRole.values.cast<UserRole?>().firstWhere(
          (r) => r!.value == upper,
          orElse: () => null,
        );
  }
}

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
}

/// Global auth notifier — manages login/logout state and exposes it to GoRouter.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    // Artificial delay to ensure the beautiful splash screen animation plays (2 seconds)
    await Future.delayed(const Duration(milliseconds: 2000));

    // Wire the force-logout callback from the Dio interceptor
    ApiClient.onForceLogout = logout;

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
          state = AuthState(
            isAuthenticated: true,
            role: role,
            preLeaderRole: preLeaderRole,
            isLoading: false,
          );
          return;
        }
        // Access expired — try refresh
        final refresh = await TokenStorage.getRefreshToken();
        if (refresh != null && !JwtDecoder.isExpired(refresh)) {
          // Let the interceptor handle it on the next API call
          final storedRole = await TokenStorage.getRole();
          final storedPreLeader = await TokenStorage.getPreLeaderRole();
          state = AuthState(
            isAuthenticated: true,
            role: UserRole.fromString(storedRole),
            preLeaderRole: storedPreLeader,
            isLoading: false,
          );
          return;
        }
      } catch (e) {
        debugPrint('Auth init error: $e');
      }
    }

    // No valid session
    state = const AuthState(isAuthenticated: false, isLoading: false);
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
  }

  /// Called after a role change.
  Future<void> updateRole(String newRole) async {
    final role = UserRole.fromString(newRole);
    await TokenStorage.saveRole(newRole);
    state = state.copyWith(role: role);
  }

  /// Full sign-out — clears storage and resets state.
  Future<void> logout() async {
    await TokenStorage.clearAll();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

/// Riverpod provider for the global auth state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
