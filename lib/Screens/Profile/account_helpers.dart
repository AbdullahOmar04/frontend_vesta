import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:image_picker/image_picker.dart';

final _db = FirebaseFirestore.instance;

/// Asks for a gallery photo or a camera shot and uploads it as the profile
/// picture. [onBusy] reports the upload starting and finishing.
Future<void> pickAndUploadProfilePhoto(
  BuildContext context, {
  ValueChanged<bool>? onBusy,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final source = await showDialog<ImageSource>(
    context: context,
    builder: (dialogContext) => VestaDialog(
      title: 'Profile picture',
      cancelButton: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(PhosphorIconsRegular.image),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(dialogContext, ImageSource.gallery),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(PhosphorIconsRegular.camera),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(dialogContext, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return;

  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 50,
    maxWidth: 512,
    maxHeight: 512,
    preferredCameraDevice: CameraDevice.front,
  );
  if (picked == null) return;

  onBusy?.call(true);
  try {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$uid.jpg');
    await ref.putFile(
      File(picked.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).set({
      'profileImageUrl': url,
    }, SetOptions(merge: true));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  } finally {
    onBusy?.call(false);
  }
}

/// Firebase only allows changing the email or password, or deleting the
/// account, shortly after signing in. This asks for the password and signs
/// in again. True when that worked.
Future<bool> reauthenticate(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _ReauthDialog(user: user),
  );
  return ok == true;
}

/// A widget of its own so the password field is disposed only once the
/// pop-up has finished closing.
class _ReauthDialog extends StatefulWidget {
  const _ReauthDialog({required this.user});

  final User user;

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_password.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: widget.user.email!,
          password: _password.text,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? "That password isn't right."
            : e.code == 'too-many-requests'
            ? 'Too many tries. Wait a little, then try again.'
            : 'Something went wrong (${e.code}).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VestaDialog(
      title: "Confirm it's you",
      message: 'Enter your Vesta password to continue.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: VestaSpace.sm),
            Text(
              _error!,
              style: TextStyle(fontSize: 12, color: context.vesta.neg),
            ),
          ],
        ],
      ),
      confirmLabel: 'Continue',
      loading: _busy,
      onConfirm: _confirm,
    );
  }
}

/// The short id shown on Personal information, e.g. VST-AB12-CD34.
String vestaUserId(String uid) {
  final s = uid.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final a = s.length >= 4 ? s.substring(0, 4) : s;
  final b = s.length >= 8 ? s.substring(4, 8) : '';
  return b.isEmpty ? 'VST-$a' : 'VST-$a-$b';
}

/// An email change only lands in Firebase Auth once the user opens the link
/// Firebase sent. When it has, copy it to the user doc and move the email
/// reservation, so sign-up checks and the profile agree.
Future<void> syncEmailFromAuth() async {
  final user = FirebaseAuth.instance.currentUser;
  final authEmail = user?.email?.toLowerCase();
  if (user == null || authEmail == null) return;
  try {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final docEmail = (doc.data()?['email'] as String?)?.toLowerCase();
    if (docEmail == null || docEmail == authEmail) return;
    final username = (doc.data()?['username'] as String?)?.toLowerCase();
    final batch = _db.batch();
    batch.update(userRef, {'email': user.email});
    // Username login looks the email up here
    if (username != null && username.isNotEmpty) {
      batch.set(_db.collection('usernames').doc(username), {
        'email': user.email,
      }, SetOptions(merge: true));
    }
    batch.set(_db.collection('emails').doc(authEmail), {
      'uid': user.uid,
      'originalEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_db.collection('emails').doc(docEmail));
    await batch.commit();
  } catch (e) {
    debugPrint('Could not sync the changed email: $e');
  }
}
