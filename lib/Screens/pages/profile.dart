import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:frontend_vesta/Screens/pages/settings.dart' as app_settings;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _uploadProfileImage(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$uid.jpg');

      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'profileImageUrl': downloadUrl}, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profile picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(PhosphorIconsRegular.image),
              title: const Text("Choose from gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(PhosphorIconsRegular.camera),
              title: const Text("Take a photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 512,
      maxHeight: 512,
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile != null) {
      await _uploadProfileImage(File(pickedFile.path));
    }
  }

  Future<void> _confirmLogout() async {
    final neg = context.vesta.neg;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: neg),
            child: const Text("Log out"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SecureStorage().deleteAll();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
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
            ? const Center(child: Text("Not logged in"))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final username =
                      userData["username"] ?? user?.displayName ?? "User";
                  final email =
                      userData["email"] ?? user?.email ?? "No email";
                  final phone = userData["phoneNumber"] ?? "";
                  final createdAt = userData["createdAt"] as Timestamp?;
                  final householdIds =
                      (userData["householdIds"] as List?)?.length ?? 0;
                  final dayOfMonth = userData["dayOfMonth"];

                  final initials = _getInitials(username);
                  final profileImageUrl =
                      userData["profileImageUrl"] as String?;
                  final memberSince = createdAt != null
                      ? _formatDate(createdAt.toDate())
                      : "N/A";

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      VestaSpace.gutter,
                      VestaSpace.xs,
                      VestaSpace.gutter,
                      VestaSpace.xl,
                    ),
                    children: [
                      _buildHeader(
                        initials: initials,
                        profileImageUrl: profileImageUrl,
                        username: username,
                        email: email,
                        phone: phone,
                        memberSince: memberSince,
                      ),
                      const SizedBox(height: VestaSpace.lg),

                      // Stats row
                      VestaCard(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(uid)
                              .collection("accounts")
                              .where('linked', isEqualTo: true)
                              .snapshots(),
                          builder: (context, accountSnap) {
                            final accountCount =
                                accountSnap.data?.docs.length ?? 0;

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(uid)
                                  .collection("savings")
                                  .snapshots(),
                              builder: (context, savingsSnap) {
                                final savingsCount =
                                    savingsSnap.data?.docs.length ?? 0;

                                return IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      _statItem(
                                        accountCount.toString(),
                                        "Accounts",
                                      ),
                                      const VerticalDivider(),
                                      _statItem(
                                        householdIds.toString(),
                                        "Households",
                                      ),
                                      const VerticalDivider(),
                                      _statItem(
                                        savingsCount.toString(),
                                        "Savings goals",
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Menu items
                      _menuCard([
                        _menuTile(
                          icon: PhosphorIconsRegular.wallet,
                          title: "Accounts",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccountsPage(),
                              ),
                            );
                          },
                        ),
                        _menuTile(
                          icon: PhosphorIconsRegular.calendarBlank,
                          title: "Budget reset day",
                          subtitle: dayOfMonth != null
                              ? "Day $dayOfMonth of each month"
                              : null,
                          onTap: () {
                            inputDayOfMonth(context);
                          },
                        ),
                        _menuTile(
                          icon: PhosphorIconsRegular.slidersHorizontal,
                          title: "Settings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const app_settings.Settings(),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 14),

                      // Logout
                      _menuCard([
                        _menuTile(
                          icon: PhosphorIconsRegular.signOut,
                          title: "Log out",
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

  Widget _buildHeader({
    required String initials,
    required String? profileImageUrl,
    required String username,
    required String email,
    required String phone,
    required String memberSince,
  }) {
    final v = context.vesta;
    final scheme = Theme.of(context).colorScheme;
    final small = TextStyle(fontSize: 13, color: v.muted);

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: v.tint,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? Text(
                        initials,
                        style: headingStyle(24, color: v.tintText),
                      )
                    : null,
              ),
              if (_isUploading)
                const Positioned.fill(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.black45,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.camera,
                    size: 12,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: headingStyle(20),
              ),
              const SizedBox(height: 2),
              Text(email, style: small, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (phone.isNotEmpty) Text(phone, style: small),
              Text(
                "Member since $memberSince",
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: amountStyle(20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.vesta.muted),
          ),
        ],
      ),
    );
  }

  /// One rounded card of menu rows with hairlines between them.
  Widget _menuCard(List<Widget> rows) {
    final v = context.vesta;
    return VestaCard(
      padding: EdgeInsets.zero,
      radius: VestaRadius.lg,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: v.divider)),
              ),
              child: rows[i],
            ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? color,
    bool showCaret = true,
  }) {
    final v = context.vesta;
    final c = color ?? v.accentInk;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: v.muted)),
                ],
              ),
            ),
            if (showCaret)
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: v.muted),
          ],
        ),
      ),
    );
  }
}
