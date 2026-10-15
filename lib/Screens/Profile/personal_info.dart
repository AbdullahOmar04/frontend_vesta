import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Profile/account_helpers.dart';
import 'package:frontend_vesta/Screens/Profile/delete_account.dart';
import 'package:frontend_vesta/Screens/pages/profile.dart';

/// The prototype's Personal information page: photo, username, email, phone
/// and the fixed user id, with the way to delete the account.
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _db = FirebaseFirestore.instance;
  final _email = TextEditingController();

  String _savedUsername = '';
  String _savedEmail = '';
  String _phone = '';
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await syncEmailFromAuth();
    final data =
        (await _db.collection('users').doc(user.uid).get()).data() ?? const {};
    _savedUsername = (data['username'] ?? user.displayName ?? '').toString();
    _savedEmail = (data['email'] ?? user.email ?? '').toString();
    _phone = (data['phoneNumber'] ?? user.phoneNumber ?? '').toString();
    _email.text = _savedEmail;
    if (mounted) setState(() => _loading = false);
  }

  bool get _changed =>
      _email.text.trim().toLowerCase() != _savedEmail.toLowerCase();

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final email = _email.text.trim();

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (email.toLowerCase() != _savedEmail.toLowerCase()) {
        final sent = await _changeEmail(user, email);
        if (sent) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'We sent a link to $email. Your email changes once you open it.',
              ),
            ),
          );
          _email.text = _savedEmail;
        }
      }
      if (mounted) setState(() => _saving = false);
    } on _Problem catch (p) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = p.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't save: $e";
        });
      }
    }
  }

  /// Firebase emails a link to the new address; the change (and the profile
  /// update, see syncEmailFromAuth) happens once it is opened.
  Future<bool> _changeEmail(User user, String email) async {
    final taken = await _db.collection('emails').doc(email.toLowerCase()).get();
    if (taken.exists && taken.data()?['uid'] != user.uid) {
      throw _Problem('That email already has a Vesta account.');
    }
    try {
      await user.verifyBeforeUpdateEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login' || !mounted) rethrow;
      if (!await reauthenticate(context)) return false;
      await user.verifyBeforeUpdateEmail(email);
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userId = vestaUserId(uid);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, color: v.muted)),
    );

    return Scaffold(
      appBar: const VestaAppBar(title: 'Personal information'),
      body: VestaBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  VestaSpace.gutter,
                  VestaSpace.xs,
                  VestaSpace.gutter,
                  VestaSpace.xl,
                ),
                children: [
                  Center(
                    child:
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: _db.collection('users').doc(uid).snapshots(),
                          builder: (context, snap) => ProfileAvatar(
                            name: _savedUsername,
                            imageUrl:
                                snap.data?.data()?['profileImageUrl']
                                    as String?,
                            size: 88,
                            busy: _uploading,
                            onTap: () => pickAndUploadProfilePhoto(
                              context,
                              onBusy: (busy) {
                                if (mounted) setState(() => _uploading = busy);
                              },
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: VestaSpace.lg),
                  VestaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label('Username'),
                        // Not changeable for now (the Firestore rules refuse
                        // moving the usernames/{name} reservation)
                        _LockedField(text: '@ $_savedUsername'),
                        const SizedBox(height: VestaSpace.md),
                        label('Email'),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() => _error = null),
                        ),
                        const SizedBox(height: VestaSpace.md),
                        label('Phone number'),
                        _LockedField(
                          text: _phone.isEmpty ? 'Not added' : _phone,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To change your number, contact support.',
                          style: TextStyle(fontSize: 11, color: v.muted),
                        ),
                        const SizedBox(height: VestaSpace.md),
                        label('User ID'),
                        _LockedField(
                          text: userId,
                          trailing: TextButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: userId),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User ID copied'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Copy'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your user ID is given to you and can't be changed.",
                          style: TextStyle(fontSize: 11, color: v.muted),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: VestaSpace.md),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: v.neg),
                    ),
                  ],
                  const SizedBox(height: VestaSpace.md),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: v.neg),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeleteAccountPage(),
                        ),
                      ),
                      icon: const Icon(PhosphorIconsRegular.trash, size: 16),
                      label: const Text('Delete Vesta account'),
                    ),
                  ),
                  const SizedBox(height: VestaSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlineButton(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Save',
                          loading: _saving,
                          onPressed: _changed ? _save : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _Problem implements Exception {
  _Problem(this.message);
  final String message;
}

/// A read-only value in the shape of a text field, with a lock.
class _LockedField extends StatelessWidget {
  const _LockedField({required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 4, trailing == null ? 14 : 4, 4),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: v.raised,
        borderRadius: BorderRadius.circular(VestaRadius.md),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.lock, size: 16, color: v.muted),
          const SizedBox(width: VestaSpace.sm),
          Expanded(child: Text(text, style: amountStyle(14))),
          ?trailing,
        ],
      ),
    );
  }
}
