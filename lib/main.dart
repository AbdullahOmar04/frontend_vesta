import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/appearance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:frontend_vesta/Helpers/referral_codes.dart';
import 'package:frontend_vesta/Helpers/security_service.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Onboarding/auth_gate.dart';
import 'package:frontend_vesta/firebase_options.dart';
import 'package:frontend_vesta/l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global navigator key for deep link handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final LocalAuthentication auth = LocalAuthentication();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars so page backgrounds reach the
  // screen edges; app bars and SafeArea keep content clear of them.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  await dotenv.load(fileName: ".env");

  // V01/V02: Binary protection and root detection
  await SecurityService().initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  startCategoryListener();
  listenForReferralLinks();
  await loadAppearance();
  await loadLanguage();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appearance, appLanguage]),
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: appearance.value,
        // Arabic also turns the layout right to left
        locale: Locale(activeLanguage),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AuthGate(),
        // Flutter has loaded its date data by the time this runs
        builder: (context, child) {
          useLevantineMonthNames();
          return child!;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
