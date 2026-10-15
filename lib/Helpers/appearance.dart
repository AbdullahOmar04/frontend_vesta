import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';

/// Light, dark, or the phone's setting, as chosen under Preferences >
/// Display. MaterialApp listens to it.
final appearance = ValueNotifier<ThemeMode>(ThemeMode.system);

const _key = 'appearance';

/// Reads the saved choice; called once before the app starts.
Future<void> loadAppearance() async {
  try {
    final saved = await SecureStorage().read(key: _key);
    appearance.value = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  } catch (_) {
    // Keep the phone's setting
  }
}

Future<void> setAppearance(ThemeMode mode) async {
  appearance.value = mode;
  await SecureStorage().write(key: _key, value: mode.name);
}
