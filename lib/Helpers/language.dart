import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';
import 'package:frontend_vesta/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// English or Arabic, as chosen under Preferences > Language; null follows
/// the phone. MaterialApp listens to it.
final appLanguage = ValueNotifier<String?>(null);

const supportedLanguages = ['en', 'ar'];
const _key = 'language';

/// The language the app is showing: the saved choice, else the phone's
/// language when Vesta has it, else English.
String get activeLanguage {
  final chosen = appLanguage.value;
  if (chosen != null) return chosen;
  final phone = PlatformDispatcher.instance.locale.languageCode;
  return supportedLanguages.contains(phone) ? phone : 'en';
}

bool get isArabic => activeLanguage == 'ar';

/// Reads the saved choice; called once before the app starts.
Future<void> loadLanguage() async {
  try {
    final saved = await SecureStorage().read(key: _key);
    appLanguage.value = supportedLanguages.contains(saved) ? saved : null;
  } catch (_) {
    // Follow the phone
  }
  _applyToIntl();
}

Future<void> setLanguage(String code) async {
  appLanguage.value = code;
  _applyToIntl();
  await SecureStorage().write(key: _key, value: code);
}

var _levantineMonths = false;

/// Jordan names the months the Levantine way (كانون الثاني، شباط…), but the
/// intl package only has the Egyptian names (يناير، فبراير…). Swaps them into
/// its Arabic date symbols, which every DateFormat (and Material's date
/// picker) reads. Called once Flutter has loaded the date data.
void useLevantineMonthNames() {
  if (_levantineMonths) return;
  try {
    const months = [
      'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
      'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
    ];
    final symbols = DateFormat('MMMM', 'ar').dateSymbols;
    symbols.MONTHS = months;
    symbols.STANDALONEMONTHS = months;
    symbols.SHORTMONTHS = months;
    symbols.STANDALONESHORTMONTHS = months;
    _levantineMonths = true;
  } catch (_) {
    // Date data not loaded yet; the next build tries again
  }
}

/// Month and day names follow the language; digits stay Western (1, 2, 3)
/// in Arabic too, as on Jordanian bank apps.
void _applyToIntl() {
  Intl.defaultLocale = activeLanguage;
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
}

/// The app's texts in the current language, for code with no BuildContext
/// (shared formatters). Widgets use `context.l10n`.
AppLocalizations get l10nNow => lookupAppLocalizations(Locale(activeLanguage));

/// The app's texts in the current language: `context.l10n.profileTitle`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
