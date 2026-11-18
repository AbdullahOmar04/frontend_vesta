import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

// Push notifications (FCM), sent by the Cloud Functions in functions/index.js.
//
// Each signed-in phone keeps its FCM token in users/{uid}/devices/{token};
// logging out deletes it. The user doc's `language` ('en' or 'ar') picks the
// language of the messages, and its reminders.* / notifications.* switches
// which ones are sent.
//
// Every message carries data {type, householdId?}; tapping it opens:
//   invite          Shared finances, where the invite waits
//   inviteAccepted  that household
//   referral        Referrals
//   bill            Bills
// MainScreen does the opening (setNotificationOpener), so a tap that started
// the app waits until the user is signed in and past the fingerprint unlock.
//
// Android only for now; iOS needs the Apple account's APNs key.

/// Android channels, so people can mute one kind in the phone's settings.
/// The functions name them in each message; the manifest makes 'updates'
/// the default.
const _remindersChannel = 'reminders';
const _updatesChannel = 'updates';

const _askedKey = 'notificationsAsked';
const _settingsChannel = MethodChannel('co.vestaapp.app/settings');

final _local = FlutterLocalNotificationsPlugin();
StreamSubscription<String>? _tokenRefresh;
Map<String, dynamic>? _pendingOpen;
void Function(Map<String, dynamic>)? _opener;

bool get _supported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

AndroidFlutterLocalNotificationsPlugin? get _android => _local
    .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();

/// Called once in main(), after Firebase and the language are loaded.
Future<void> initNotifications() async {
  if (!_supported) return;
  try {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      // Tapped a message that arrived while Vesta was open
      onDidReceiveNotificationResponse: (r) => _open(_decode(r.payload)),
    );
    await updateNotificationChannels();

    // Android shows messages itself while Vesta is in the background, but
    // not while it's open
    FirebaseMessaging.onMessage.listen(_showWhileOpen);
    // Tapped while Vesta was in the background
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
    // Tapped while Vesta was closed
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _pendingOpen = initial.data;
    } else {
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _pendingOpen = _decode(launch!.notificationResponse?.payload);
      }
    }
  } catch (e) {
    debugPrint('Notifications: setup failed: $e');
  }
}

/// Creates the channels, or renames them after a language change.
Future<void> updateNotificationChannels() async {
  if (!_supported) return;
  final l10n = l10nNow;
  try {
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        _remindersChannel,
        l10n.notifChannelReminders,
        description: l10n.notifChannelRemindersDesc,
        importance: Importance.high,
      ),
    );
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        _updatesChannel,
        l10n.notifChannelUpdates,
        description: l10n.notifChannelUpdatesDesc,
        importance: Importance.high,
      ),
    );
  } catch (e) {
    debugPrint('Notifications: channels failed: $e');
  }
}

Future<void> _showWhileOpen(RemoteMessage m) async {
  final n = m.notification;
  if (n == null) return;
  final reminders = n.android?.channelId == _remindersChannel;
  final l10n = l10nNow;
  await _local.show(
    id: m.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    title: n.title,
    body: n.body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        reminders ? _remindersChannel : _updatesChannel,
        reminders ? l10n.notifChannelReminders : l10n.notifChannelUpdates,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        color: const Color(0xFF6B43F7),
        styleInformation: BigTextStyleInformation(n.body ?? ''),
      ),
    ),
    payload: jsonEncode(m.data),
  );
}

Map<String, dynamic>? _decode(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    return Map<String, dynamic>.from(jsonDecode(payload) as Map);
  } catch (_) {
    return null;
  }
}

void _open(Map<String, dynamic>? data) {
  if (data == null || data['type'] == null) return;
  final opener = _opener;
  if (opener != null) {
    opener(data);
  } else {
    _pendingOpen = data;
  }
}

/// MainScreen registers how to open a tapped message once the user is in;
/// a tap that started the app is opened now.
void setNotificationOpener(void Function(Map<String, dynamic>) opener) {
  _opener = opener;
  final pending = _pendingOpen;
  _pendingOpen = null;
  if (pending != null) opener(pending);
}

/// Called by MainScreen's dispose. A newer MainScreen (after a log in) may
/// already have registered itself, so only its own opener is cleared.
void clearNotificationOpener(void Function(Map<String, dynamic>) opener) {
  if (_opener == opener) _opener = null;
}

DocumentReference<Map<String, dynamic>> _deviceRef(String uid, String token) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token);

Future<void> _saveToken(String uid, String token) {
  return _deviceRef(uid, token).set({
    'platform': 'android',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

/// Signs this phone up for the signed-in user's messages and saves their
/// language. Called when Home first shows after logging in or unlocking.
Future<void> registerThisDevice() async {
  if (!_supported) return;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await saveLanguageForNotifications();
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(uid, token);
    _tokenRefresh ??= FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      final current = FirebaseAuth.instance.currentUser?.uid;
      if (current != null) _saveToken(current, t);
    });
  } catch (e) {
    debugPrint('Notifications: token not saved: $e');
  }
}

/// Puts the app's language on the user doc, so the functions write in it.
/// Writes only when it changed (see updateIfChanged).
Future<void> saveLanguageForNotifications() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    await updateIfChanged(
      FirebaseFirestore.instance.collection('users').doc(uid),
      {'language': activeLanguage},
    );
  } catch (e) {
    debugPrint('Notifications: language not saved: $e');
  }
}

/// After Preferences > Language changes: messages and channel names follow.
Future<void> onLanguageChanged() async {
  await updateNotificationChannels();
  await saveLanguageForNotifications();
}

/// Stops this phone getting the user's messages. Call before signing out,
/// while the user can still delete their own device doc. Gives up after a
/// few seconds (offline) rather than holding up the log out.
Future<void> forgetThisDevice() async {
  _pendingOpen = null;
  if (!_supported) return;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  try {
    await () async {
      final token = await FirebaseMessaging.instance.getToken();
      if (uid != null && token != null) {
        await _deviceRef(uid, token).delete();
      }
      // The next person to log in on this phone gets a fresh token
      await FirebaseMessaging.instance.deleteToken();
    }().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Notifications: device not forgotten: $e');
  }
}

/// Whether Android lets Vesta show notifications.
Future<bool> notificationsAllowed() async {
  if (!_supported) return true;
  try {
    final s = await FirebaseMessaging.instance.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  } catch (_) {
    return true;
  }
}

/// The first time notifications would help (saving a bill, opening Shared
/// finances, sharing a referral code, turning a switch on), explains why and
/// then shows Android's permission prompt. Once per log in, and never when
/// they're already allowed.
Future<void> askForNotificationsOnce(BuildContext context) async {
  if (!_supported || await notificationsAllowed()) return;
  final storage = SecureStorage();
  try {
    if (await storage.read(key: _askedKey) != null) return;
    await storage.write(key: _askedKey, value: 'yes');
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final l10n = context.l10n;
  final ok = await confirmDialog(
    context,
    title: l10n.notifAskTitle,
    message: l10n.notifAskBody,
    confirmLabel: l10n.notifAskAllow,
    cancelLabel: l10n.notifAskLater,
    destructive: false,
    icon: PhosphorIconsRegular.bell,
  );
  if (ok) await FirebaseMessaging.instance.requestPermission();
}

/// Asks Android again, or, when it won't ask any more, opens Vesta's page in
/// the phone's notification settings.
Future<void> turnOnNotifications() async {
  if (!_supported) return;
  final s = await FirebaseMessaging.instance.requestPermission();
  if (s.authorizationStatus == AuthorizationStatus.authorized) return;
  try {
    await _settingsChannel.invokeMethod('openNotificationSettings');
  } catch (e) {
    debugPrint('Notifications: settings not opened: $e');
  }
}

/// A row on the Reminders and Notifications pages while Android blocks
/// Vesta's notifications; tapping it turns them on. Hidden otherwise.
class NotificationsOffRow extends StatefulWidget {
  const NotificationsOffRow({super.key});

  @override
  State<NotificationsOffRow> createState() => _NotificationsOffRowState();
}

class _NotificationsOffRowState extends State<NotificationsOffRow>
    with WidgetsBindingObserver {
  bool _off = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the phone's settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final off = !await notificationsAllowed();
    if (mounted && off != _off) setState(() => _off = off);
  }

  @override
  Widget build(BuildContext context) {
    if (!_off) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: VestaSpace.md),
      child: MenuCard([
        MenuRow(
          icon: PhosphorIconsRegular.bellSlash,
          title: context.l10n.notifOffTitle,
          subtitle: context.l10n.notifOffSubtitle,
          onTap: () async {
            await turnOnNotifications();
            _check();
          },
        ),
      ]),
    );
  }
}
