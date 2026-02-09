import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';

/// Biometric authentication service for fingerprint/face login
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are available and enrolled
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({String reason = 'Authenticate to access Vesta'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.message}');
      return false;
    }
  }

  /// Check if biometric login is enabled for this user
  Future<bool> isBiometricLoginEnabled() async {
    final enabled = await SecureStorage().read(key: SecureStorage.keyBiometricEnabled);
    return enabled == 'true';
  }

  /// Enable biometric login for current user
  Future<void> enableBiometricLogin(String userId) async {
    await SecureStorage().write(key: SecureStorage.keyBiometricEnabled, value: 'true');
    await SecureStorage().write(key: SecureStorage.keyLastUserId, value: userId);
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    await SecureStorage().write(key: SecureStorage.keyBiometricEnabled, value: 'false');
    await SecureStorage().delete(key: SecureStorage.keyLastUserId);
  }

  /// Get the last logged in user ID (for biometric login)
  Future<String?> getLastUserId() async {
    return await SecureStorage().read(key: SecureStorage.keyLastUserId);
  }
}
