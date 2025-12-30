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
    // Accept both /join and join (just in case)
    final path = deepLink.path.startsWith('/') ? deepLink.path : '/${deepLink.path}';

    if (path == '/join' && deepLink.queryParameters.containsKey('inviteId')) {
      final inviteId = deepLink.queryParameters['inviteId']!;
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        // Logged out: store link for after login
        print("DeepLinkService: User is logged out. Storing pending link.");
        _pendingInviteLink = deepLink;
        return;
      }

      // Logged in: defer dialog to next frame to avoid context issues
      print("DeepLinkService: User is logged in. Scheduling invite dialog...");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showInviteDialog(inviteId, currentUser.uid, context);
      });
    }
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
      if (!context.mounted) return;
      if (!inviteDoc.exists)
        throw Exception("Invite link is invalid or expired.");

      final inviterUid = inviteDoc.data()!['inviterUid'];

      // Prevent user from accepting their own invite
      if (inviterUid == currentUserUid) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can't accept your own invite.")),
        );
        return;
      }

      // 2. Get the inviter's name
      final inviterDoc = await _db.collection('users').doc(inviterUid).get();
      if (!context.mounted) return;
      final inviterName = inviterDoc.data()?['username'] ?? 'Someone';

      // 3. Get the household's name
      final householdName =
          inviterDoc.data()?['householdName'] ?? 'a household';

      // 4. Show the dialog
      if (!context.mounted) return;
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
