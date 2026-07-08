import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over local_auth for biometric / device-credential unlock.
/// On web there is no local_auth support, so lock is treated as unavailable
/// and authentication is a no-op (fails open) — see BR-W-WEB1.
class AppLockService {
  AppLockService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Money Manager',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      // Fail open if auth unavailable (BR-S2).
      return true;
    }
  }
}
