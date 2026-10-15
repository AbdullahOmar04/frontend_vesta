import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Profile/account_helpers.dart';
import 'package:frontend_vesta/Screens/Profile/personal_info.dart';
import 'package:frontend_vesta/Screens/Profile/preferences.dart';
import 'package:frontend_vesta/Screens/Profile/referrals.dart';
import 'package:frontend_vesta/Screens/Profile/security.dart';
import 'package:frontend_vesta/Screens/Profile/subscriptions.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    // An email change lands only after the link is opened; catch it up
    syncEmailFromAuth();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Log out of Vesta?',
      message: "You'll need to log in again to see your money.",
      confirmLabel: 'Log out',
      icon: PhosphorIconsRegular.signOut,
    );
    if (confirmed) {
      await SecureStorage().deleteAll();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      appBar: const VestaAppBar.large(title: 'Profile'),
      body: VestaBackground(
        child: uid == null
            ? const Center(child: Text('Not logged in'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data?.data() ?? const {};
                  final username =
                      (data['username'] ?? user?.displayName ?? 'User')
                          .toString();
                  final points = (data['referralPoints'] as num?)?.toInt() ?? 0;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      VestaSpace.gutter,
                      VestaSpace.xs,
                      VestaSpace.gutter,
                      VestaSpace.xl,
                    ),
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(
                            name: username,
                            imageUrl: data['profileImageUrl'] as String?,
                            busy: _uploading,
                            onTap: () => pickAndUploadProfilePhoto(
                              context,
                              onBusy: (busy) {
                                if (mounted) setState(() => _uploading = busy);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: headingStyle(20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VestaSpace.lg),
                      MenuCard([
                        MenuRow(
                          icon: PhosphorIconsRegular.user,
                          title: 'Personal information',
                          onTap: () => _open(const PersonalInfoPage()),
                        ),
                        MenuRow(
                          icon: PhosphorIconsRegular.bank,
                          title: 'Bank accounts management',
                          onTap: () => _open(const AccountsPage()),
                        ),
                        MenuRow(
                          icon: PhosphorIconsRegular.crownSimple,
                          title: 'Subscriptions',
                          subtitle: 'Free plan',
                          onTap: () => _open(const SubscriptionsPage()),
                        ),
                        MenuRow(
                          icon: PhosphorIconsRegular.gift,
                          title: 'Referrals',
                          subtitle:
                              '${NumberFormat.decimalPattern().format(points)} points',
                          onTap: () => _open(const ReferralsPage()),
                        ),
                        MenuRow(
                          icon: PhosphorIconsRegular.slidersHorizontal,
                          title: 'Preferences',
                          onTap: () => _open(const PreferencesPage()),
                        ),
                        MenuRow(
                          icon: PhosphorIconsRegular.lockKey,
                          title: 'Password and security',
                          onTap: () => _open(const SecurityPage()),
                        ),
                        const MenuRow(
                          icon: PhosphorIconsRegular.fileText,
                          title: 'Terms and conditions',
                          tag: 'Coming soon',
                        ),
                      ]),
                      const SizedBox(height: 14),
                      MenuCard([
                        MenuRow(
                          icon: PhosphorIconsRegular.signOut,
                          title: 'Log out',
                          color: context.vesta.neg,
                          showCaret: false,
                          onTap: _confirmLogout,
                        ),
                      ]),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// The round profile photo (or initials) with a camera badge.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 72,
    this.busy = false,
    this.onTap,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool busy;
  final VoidCallback? onTap;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final scheme = Theme.of(context).colorScheme;
    final radius = size / 2;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: v.tint,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Text(
                    initials(name),
                    style: headingStyle(size / 3, color: v.tintText),
                  )
                : null,
          ),
          if (busy)
            Positioned.fill(
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.black45,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: v.divider),
              ),
              child: Icon(
                PhosphorIconsRegular.camera,
                size: 13,
                color: v.accentInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
