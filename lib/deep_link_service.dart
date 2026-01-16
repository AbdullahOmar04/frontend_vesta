// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// This service class handles all deep link logic.
/// It should be initialized ONCE in your main app widget.
final DeepLinkService deepLinkService = DeepLinkService();

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Uri? _pendingFinxCallbackLink;
  bool _finxHandledOnce = false;

  Uri? _pendingInviteLink;
  bool _isInitialized = false;

  /// Call this ONCE in the `initState` of your main app screen
  /// (e.g., in your `MainScreen` *after* login).
  void init(BuildContext context) {
    if (_isInitialized) return; // Only init once
    _isInitialized = true;

    print("DeepLinkService: Initializing...");

    // --- 1. Handle links that open the app from a terminated state ---
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print("DeepLinkService: Found initial link: $uri");
        _handleLink(uri, context);
      }
    });

    // --- 2. Handle links that open the app while it's running ---
    _appLinks.uriLinkStream.listen((uri) {
      print("DeepLinkService: Received new link: $uri");
      _handleLink(uri, context);
    });
  }

  /// Private function to process the link.
  void _handleLink(Uri deepLink, BuildContext context) async {
    // ---------------------------
    // 1) INVITE LINKS (existing)
    // ---------------------------
    if (deepLink.path == '/join' &&
        deepLink.queryParameters.containsKey('inviteId')) {
      final inviteId = deepLink.queryParameters['inviteId']!;
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        print(
          "DeepLinkService: User is logged out. Storing pending invite link.",
        );
        _pendingInviteLink = deepLink;
      } else {
        print(
          "DeepLinkService: User is logged in. Processing invite link now.",
        );
        _showInviteDialog(inviteId, currentUser.uid, context);
      }
      return;
    }

    // ---------------------------
    // 2) FINX AUTH CALLBACK (NEW)
    //    https://vestaapp.co/auth/callback?code=...&state=...
    // ---------------------------
    if (deepLink.path == '/auth/callback') {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        print(
          "DeepLinkService: Logged out. Storing pending FINX callback link.",
        );
        _pendingFinxCallbackLink = deepLink;
        return;
      }

      await _handleFinxCallback(deepLink, currentUser.uid, context);
      return;
    }
  }

  Future<void> _handleFinxCallback(
    Uri uri,
    String uid,
    BuildContext context,
  ) async {
    if (_finxHandledOnce) return; // prevents double-fire
    _finxHandledOnce = true;

    final error = uri.queryParameters['error'];
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("FINX error: $error"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("FINX: Missing code"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save it (so you can exchange it on backend later)
    await _db.collection('users').doc(uid).collection('finx').doc('auth').set({
      'code': code,
      'state': state,
      'receivedAt': FieldValue.serverTimestamp(),
      'callbackUri': uri.toString(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("FINX connected (code received)."),
        backgroundColor: Colors.green,
      ),
    );
  }

  void checkPendingFinxCallback(BuildContext context) async {
    if (_pendingFinxCallbackLink == null) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final link = _pendingFinxCallbackLink!;
    _pendingFinxCallbackLink = null;

    await _handleFinxCallback(link, currentUser.uid, context);
  }

  /// --- NEW FUNCTION ---
  /// Call this from your `MainScreen`'s initState AFTER init().
  /// This checks if we have a link that we saved while the user was logged out.
  void checkPendingLink(BuildContext context) {
    if (_pendingInviteLink != null) {
      print("DeepLinkService: Checking for pending link... Found one!");
      // We must check for currentUser again, just to be 100% sure.
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final inviteId = _pendingInviteLink!.queryParameters['inviteId']!;
        _showInviteDialog(inviteId, currentUser.uid, context);

        // Clear the pending link so it doesn't fire again
        _pendingInviteLink = null;
      }
    } else {
      print("DeepLinkService: No pending link found.");
    }
  }

  /// Shows the actual "Accept Invite" dialog
  void _showInviteDialog(
    String inviteId,
    String currentUserUid,
    BuildContext context,
  ) async {
    try {
      // 1. Get the invite data to show the inviter's name
      final inviteDoc = await _db.collection('invites').doc(inviteId).get();
      if (!inviteDoc.exists)
        throw Exception("Invite link is invalid or expired.");

      final inviterUid = inviteDoc.data()!['inviterUid'];

      // Prevent user from accepting their own invite
      if (inviterUid == currentUserUid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can't accept your own invite.")),
        );
        return;
      }

      // 2. Get the inviter's name
      final inviterDoc = await _db.collection('users').doc(inviterUid).get();
      final inviterName = inviterDoc.data()?['username'] ?? 'Someone';

      // 3. Get the household's name
      final householdName =
          inviterDoc.data()?['householdName'] ?? 'a household';

      // 4. Show the dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text("You're Invited!"),
          content: Text("$inviterName has invited you to join $householdName."),
          actions: [
            TextButton(
              child: const Text("Decline"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text("Accept"),
              onPressed: () async {
                // This is the "Trigger" for our Cloud Function!
                try {
                  await _db.collection('invites').doc(inviteId).update({
                    'status': 'accepted',
                    'acceptedByUid': currentUserUid,
                  });
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Invite accepted! Joining household..."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              },
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
