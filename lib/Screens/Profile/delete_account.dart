import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Household/household_actions.dart';
import 'package:frontend_vesta/Screens/Profile/account_helpers.dart';

const _reasons = [
  "I don't use it enough",
  'I have privacy concerns',
  "It's missing features I need",
  "I'm switching to another app",
  "It's too expensive",
  "I'm having technical issues",
  'Other',
];

/// The prototype's Delete account page: why, a warning, and the button.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _picked = <String>{};
  final _other = TextEditingController();
  String? _error;
  bool _deleting = false;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_picked.isEmpty) {
      setState(() => _error = 'Pick at least one reason.');
      return;
    }
    final sure = await confirmDialog(
      context,
      title: 'Delete your Vesta account?',
      message: 'Everything in it is removed for good. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!sure || !mounted) return;
    // Firebase only deletes an account soon after a sign-in
    if (!await reauthenticate(context)) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await deleteMyAccount(
        reasons: _picked.toList(),
        other: _other.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = "Couldn't delete the account: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Scaffold(
      appBar: const VestaAppBar(title: 'Delete account'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            VestaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Why do you want to delete your account?',
                    style: headingStyle(16),
                  ),
                  const SizedBox(height: VestaSpace.md),
                  Container(
                    decoration: BoxDecoration(
                      color: v.raised,
                      borderRadius: BorderRadius.circular(VestaRadius.md),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < _reasons.length; i++)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : Border(top: BorderSide(color: v.divider)),
                            ),
                            child: CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _picked.contains(_reasons[i]),
                              title: Text(_reasons[i]),
                              onChanged: _deleting
                                  ? null
                                  : (on) => setState(() {
                                      _error = null;
                                      on == true
                                          ? _picked.add(_reasons[i])
                                          : _picked.remove(_reasons[i]);
                                    }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_picked.contains('Other')) ...[
                    const SizedBox(height: VestaSpace.md),
                    TextField(
                      controller: _other,
                      maxLength: 200,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Tell us more (optional)',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: VestaSpace.md),
            Container(
              padding: const EdgeInsets.all(VestaSpace.md),
              decoration: BoxDecoration(
                color: v.neg.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(VestaRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIconsRegular.warning, size: 18, color: v.neg),
                  const SizedBox(width: VestaSpace.sm),
                  const Expanded(
                    child: Text(
                      'If you delete your account, all of your information '
                      'will be gone: your budgets, transactions, savings '
                      'goals, accounts, and shared finances.',
                      style: TextStyle(fontSize: 13),
                    ),
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
            const SizedBox(height: VestaSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: 'Cancel',
                    onPressed: _deleting ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DangerButton(
                    label: 'Delete account',
                    loading: _deleting,
                    onPressed: _delete,
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

/// Removes the signed-in user's data, then their login. The user must have
/// signed in again just before (see reauthenticate). Each data step is best
/// effort, since the security rules may refuse some of them; the
/// onUserDeleted Cloud Function removes whatever is left once the login is
/// gone. Throws only when the login itself can't be deleted.
Future<void> deleteMyAccount({
  required List<String> reasons,
  String other = '',
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final uid = user.uid;
  final db = FirebaseFirestore.instance;
  final userRef = db.collection('users').doc(uid);
  final data = (await userRef.get()).data() ?? const <String, dynamic>{};

  // Why, for us; best effort, it must never block the deletion
  try {
    await db.collection('accountDeletions').add({
      'reasons': reasons,
      if (other.isNotEmpty) 'other': other,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Could not record the deletion reasons: $e');
  }

  // Households: delete the ones this user owns, leave the others
  for (final id in List<String>.from(data['householdIds'] ?? const [])) {
    try {
      final ref = db.collection('households').doc(id);
      final household = await ref.get();
      if (!household.exists) continue;
      final members = List<String>.from(household.data()?['members'] ?? []);
      if (householdOwner(household.data()) == uid) {
        for (final m in members.where((m) => m != uid)) {
          try {
            await db.collection('users').doc(m).update({
              'householdIds': FieldValue.arrayRemove([id]),
            });
          } catch (_) {}
        }
        await _deleteCollection(ref.collection('transactions'));
        await ref.delete();
      } else {
        await ref.update({
          'members': FieldValue.arrayRemove([uid]),
        });
      }
    } catch (e) {
      debugPrint('Could not clear household $id: $e');
    }
  }

  // Accounts and everything under them, then the other lists
  Future<void> tryStep(String what, Future<void> Function() step) async {
    try {
      await step();
    } catch (e) {
      debugPrint('Account deletion: could not delete $what: $e');
    }
  }

  await tryStep('accounts', () async {
    final accounts = await userRef.collection('accounts').get();
    for (final account in accounts.docs) {
      await _deleteCollection(account.reference.collection('transactions'));
      await _deleteCollection(account.reference.collection('sosps'));
      await account.reference.delete();
    }
  });
  for (final name in ['categories', 'savings', 'bills', 'budget']) {
    await tryStep(name, () => _deleteCollection(userRef.collection(name)));
  }

  // Free the username and email for someone else
  final username = (data['username'] ?? '').toString().toLowerCase();
  final email = (data['email'] ?? user.email ?? '').toString().toLowerCase();
  if (username.isNotEmpty) {
    try {
      await db.collection('usernames').doc(username).delete();
    } catch (_) {}
  }
  if (email.isNotEmpty) {
    try {
      await db.collection('emails').doc(email).delete();
    } catch (_) {}
  }

  try {
    await FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$uid.jpg')
        .delete();
  } catch (_) {
    // No photo
  }

  await tryStep('the profile', () => userRef.delete());
  await user.delete();
  await SecureStorage().deleteAll();
  await FirebaseAuth.instance.signOut();
}

Future<void> _deleteCollection(
  CollectionReference<Map<String, dynamic>> c,
) async {
  while (true) {
    final page = await c.limit(400).get();
    if (page.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in page.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
