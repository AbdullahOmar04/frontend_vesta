import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/appearance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/security_service.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Onboarding/auth_gate.dart';
import 'package:frontend_vesta/firebase_options.dart';
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

  // Proves requests come from the real app; Gemini (Firebase AI Logic) refuses
  // anything else. Debug builds use a debug token registered under App Check >
  // the co.vestaapp.app.debug app > Manage debug tokens: pass one with
  // --dart-define=APP_CHECK_DEBUG_TOKEN=<token>, or register the one the
  // debug provider prints to logcat.
  const debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider(
            debugToken: debugToken.isEmpty ? null : debugToken,
          )
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? AppleDebugProvider(debugToken: debugToken.isEmpty ? null : debugToken)
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  startCategoryListener();
  await loadAppearance();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appearance,
      builder: (context, mode, _) => MaterialApp(
        navigatorKey: navigatorKey,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: mode,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
