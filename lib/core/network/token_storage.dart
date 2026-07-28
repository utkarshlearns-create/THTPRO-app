import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-adaptive token storage.
///
/// On native (iOS / Android) → [FlutterSecureStorage] (Keychain / EncryptedSharedPrefs).
/// On web → [SharedPreferences] (localStorage), because `flutter_secure_storage`
/// relies on the Web Crypto API (`crypto.subtle`) which throws `OperationError`
/// in many browser configurations. Since the web is inherently a dev/preview
/// target and the tokens are short-lived JWTs, localStorage is acceptable here.
class TokenStorage {
  TokenStorage._();

  static const _secureStorage = FlutterSecureStorage();

  // Lazy-init for SharedPreferences (only used on web).
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static const _accessKey = 'access';
  static const _refreshKey = 'refresh';
  static const _roleKey = 'role';
  static const _preLeaderRoleKey = 'pre_leader_role';
  static const _usernameKey = 'username';
  static const _phoneKey = 'phone';
  static const _departmentKey = 'department';
  static const _nameKey = 'name';

  // ── Platform-adaptive read / write / delete ──

  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await _sharedPrefs;
      return prefs.getString(key);
    }
    return _secureStorage.read(key: key);
  }

  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await _sharedPrefs;
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  static Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await _sharedPrefs;
      await Future.wait([
        prefs.remove(_accessKey),
        prefs.remove(_refreshKey),
        prefs.remove(_roleKey),
        prefs.remove(_preLeaderRoleKey),
        prefs.remove(_usernameKey),
        prefs.remove(_phoneKey),
        prefs.remove(_departmentKey),
        prefs.remove(_nameKey),
      ]);
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ── Tokens ──

  static Future<String?> getAccessToken() => _read(_accessKey);

  static Future<String?> getRefreshToken() => _read(_refreshKey);

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _write(_accessKey, access),
      _write(_refreshKey, refresh),
    ]);
  }

  static Future<void> saveAccessToken(String access) =>
      _write(_accessKey, access);

  // ── User metadata ──

  static Future<String?> getRole() => _read(_roleKey);

  static Future<void> saveRole(String role) => _write(_roleKey, role);

  static Future<String?> getPreLeaderRole() => _read(_preLeaderRoleKey);

  static Future<void> savePreLeaderRole(String role) =>
      _write(_preLeaderRoleKey, role);

  static Future<String?> getUsername() => _read(_usernameKey);

  static Future<void> saveUsername(String username) =>
      _write(_usernameKey, username);

  static Future<String?> getPhone() => _read(_phoneKey);

  static Future<void> savePhone(String phone) => _write(_phoneKey, phone);

  static Future<String?> getName() => _read(_nameKey);

  static Future<void> saveName(String name) => _write(_nameKey, name);

  static Future<void> saveDepartment(String dept) =>
      _write(_departmentKey, dept);

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

  static Future<void> clearAll() => _deleteAll();
}
