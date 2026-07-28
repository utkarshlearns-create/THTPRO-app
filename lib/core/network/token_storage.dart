import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure wrapper around JWT tokens. Uses flutter_secure_storage (Keychain on
/// iOS, EncryptedSharedPreferences on Android) — replaces the web's localStorage.
class TokenStorage {
  TokenStorage._();
  static const _storage = FlutterSecureStorage();

  static const _accessKey = 'access';
  static const _refreshKey = 'refresh';
  static const _roleKey = 'role';
  static const _preLeaderRoleKey = 'pre_leader_role';
  static const _usernameKey = 'username';
  static const _phoneKey = 'phone';
  static const _departmentKey = 'department';
  static const _nameKey = 'name';

  // ── Tokens ──

  static Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: access),
      _storage.write(key: _refreshKey, value: refresh),
    ]);
  }

  static Future<void> saveAccessToken(String access) =>
      _storage.write(key: _accessKey, value: access);

  // ── User metadata ──

  static Future<String?> getRole() => _storage.read(key: _roleKey);

  static Future<void> saveRole(String role) =>
      _storage.write(key: _roleKey, value: role);

  static Future<String?> getPreLeaderRole() =>
      _storage.read(key: _preLeaderRoleKey);

  static Future<void> savePreLeaderRole(String role) =>
      _storage.write(key: _preLeaderRoleKey, value: role);

  static Future<String?> getUsername() => _storage.read(key: _usernameKey);

  static Future<void> saveUsername(String username) =>
      _storage.write(key: _usernameKey, value: username);

  static Future<String?> getPhone() => _storage.read(key: _phoneKey);

  static Future<void> savePhone(String phone) =>
      _storage.write(key: _phoneKey, value: phone);

  static Future<String?> getName() => _storage.read(key: _nameKey);

  static Future<void> saveName(String name) =>
      _storage.write(key: _nameKey, value: name);

  static Future<void> saveDepartment(String dept) =>
      _storage.write(key: _departmentKey, value: dept);

  /// Bulk-save user info after login (mirrors the web's localStorage writes).
  static Future<void> saveUserInfo({
    required String role,
    String? username,
    String? phone,
    String? name,
    String? preLeaderRole,
    String? department,
  }) async {
    await saveRole(role);
    if (username != null) await saveUsername(username);
    if (phone != null) await savePhone(phone);
    if (name != null) await saveName(name);
    if (preLeaderRole != null) await savePreLeaderRole(preLeaderRole);
    if (department != null) await saveDepartment(department);
  }

  // ── Clear ──

  static Future<void> clearAll() => _storage.deleteAll();
}
