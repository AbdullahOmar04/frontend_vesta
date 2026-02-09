import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper using Android KeyStore and EncryptedSharedPreferences
/// Fixes V06 - Insecure Local Storage
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'vesta_secure_prefs',
      preferencesKeyPrefix: 'vesta_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'VestaApp',
    ),
  );

  /// Store a value securely
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a secure value
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Delete a secure value
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Delete all secure values
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  // Common secure storage keys
  static const String keyUserToken = 'user_auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyLastUserId = 'last_user_id';
}
