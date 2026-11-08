import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

// Every user gets a code like MAYA-25K9, reserved in referralCodes/{code} so no
// two users share one. A new user may enter a friend's code at sign-up; it is
// saved as referredBy, and the onUserCreated Cloud Function hands out the
// points. The rules keep codes, referredBy and points out of the app's reach
// once set.

/// Points the friend who shared the code gets when someone signs up with it.
const referralReward = 250;

/// Points the new user gets for signing up with a code.
const referralWelcome = 100;

/// Letters and digits that can't be mistaken for each other (no O/0, I/1).
const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

final _codeShape = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$');

/// [input] the way codes are stored: upper case, with the dash put back when
/// someone typed "maya25k9".
String normalizeReferralCode(String input) {
  final plain = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return plain.length == 8
      ? '${plain.substring(0, 4)}-${plain.substring(4)}'
      : input.trim().toUpperCase();
}

/// The uid behind [code], or null when no account has it. Works before
/// sign-up, like the username check.
Future<String?> referralCodeOwner(String code) async {
  if (!_codeShape.hasMatch(code)) return null;
  final snap = await FirebaseFirestore.instance
      .collection('referralCodes')
      .doc(code)
      .get();
  return snap.data()?['uid'] as String?;
}

/// The user's referral code, reserving one first if they have none yet (new
/// sign-ups, and accounts from before referrals). Null if every try clashed.
Future<String?> ensureReferralCode(String uid) async {
  final fire = FirebaseFirestore.instance;
  final userRef = fire.collection('users').doc(uid);
  final data = (await userRef.get()).data() ?? const <String, dynamic>{};
  final stored = data['referralCode'] as String?;
  if (stored != null && stored.isNotEmpty) return stored;

  final username = (data['username'] ?? '').toString();
  for (var attempt = 0; attempt < 5; attempt++) {
    final code = _newCode(username, uid, attempt);
    final batch = fire.batch()
      ..set(fire.collection('referralCodes').doc(code), {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(userRef, {'referralCode': code}, SetOptions(merge: true));
    try {
      await batch.commit();
      return code;
    } on FirebaseException catch (e) {
      // Someone already has this code: the rules won't overwrite it
      if (e.code != 'permission-denied') rethrow;
    }
  }
  return null;
}

/// Four letters of the username, then four characters of the uid on the first
/// try and random ones after a clash.
String _newCode(String username, String uid, int attempt) {
  final name = username.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final head = name.length >= 4 ? name.substring(0, 4) : name.padRight(4, 'X');
  if (attempt == 0) {
    final id = uid.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return '$head-${id.padRight(4, 'X').substring(0, 4)}';
  }
  final random = Random.secure();
  final tail = List.generate(
    4,
    (_) => _codeChars[random.nextInt(_codeChars.length)],
  ).join();
  return '$head-$tail';
}
