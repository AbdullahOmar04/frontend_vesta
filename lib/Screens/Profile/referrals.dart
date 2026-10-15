import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Profile/subscriptions.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Points a friend's sign-up earns, and what points buy (the prototype's
/// numbers).
const referralReward = 250;
const _plusPoints = 1000;
const _premiumPoints = 1500;

/// The user's referral code: their stored one, or one made from the
/// username and uid (e.g. MAYA-25K9).
String referralCode(String uid, Map<String, dynamic> userData) {
  final stored = userData['referralCode'] as String?;
  if (stored != null && stored.isNotEmpty) return stored;
  final name = (userData['username'] ?? 'VEST')
      .toString()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final head = (name.length >= 4
      ? name.substring(0, 4)
      : name.padRight(4, 'X'));
  final tail = uid.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return '$head-${tail.length >= 4 ? tail.substring(0, 4) : tail}';
}

class ReferralsPage extends StatelessWidget {
  const ReferralsPage({super.key});

  void _howItWorks(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const VestaDialog(
        icon: PhosphorIconsRegular.gift,
        title: 'How referrals work',
        message:
            'Share your code. When a friend signs up with it, you get '
            '$referralReward points. 1,000 points get you a free month of '
            'Plus, and 1,500 a free month of Premium. Sign-ups with your code '
            'start counting in an upcoming update.',
        cancelLabel: null,
        confirmLabel: 'Got it',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: const VestaAppBar(title: 'Referrals'),
      body: VestaBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userRef.snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? const <String, dynamic>{};
            final points = (data['referralPoints'] as num?)?.toInt() ?? 0;
            final code = referralCode(uid, data);
            final link = 'https://vestaapp.co/r/$code';
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                VestaSpace.xs,
                VestaSpace.gutter,
                VestaSpace.xl,
              ),
              children: [
                _pointsCard(context, points),
                const SizedBox(height: VestaSpace.md),
                _codeCard(context, code, link),
                const SizedBox(height: VestaSpace.md),
                _invited(context, userRef),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pointsCard(BuildContext context, int points) {
    final v = context.vesta;
    final goal = points >= _plusPoints ? _premiumPoints : _plusPoints;
    final note = points >= _premiumPoints
        ? 'Enough for a free month of Premium'
        : points >= _plusPoints
        ? 'Enough for a free month of Plus · '
              '${NumberFormat.decimalPattern().format(_premiumPoints - points)} '
              'more for Premium'
        : '${NumberFormat.decimalPattern().format(_plusPoints - points)} more '
              'for a free month of Plus';
    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your points',
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                    Text(
                      '${NumberFormat.decimalPattern().format(points)} pts',
                      style: amountStyle(28),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _howItWorks(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: v.accentInk,
                  side: BorderSide(color: v.accentInk),
                  textStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(PhosphorIconsRegular.question, size: 14),
                label: const Text('How it works'),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          VestaProgressBar(value: (points / goal).clamp(0, 1).toDouble()),
          const SizedBox(height: VestaSpace.sm),
          Text(note, style: TextStyle(fontSize: 12, color: v.muted)),
          const SizedBox(height: VestaSpace.md),
          PrimaryButton(
            label: 'Use points',
            onPressed: points >= _plusPoints
                ? () => showPlansComingSoon(context)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context, String code, String link) {
    final v = context.vesta;
    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your referral code',
            style: TextStyle(fontSize: 12, color: v.muted),
          ),
          const SizedBox(height: VestaSpace.sm),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            decoration: BoxDecoration(
              border: Border.all(color: v.divider),
              borderRadius: BorderRadius.circular(VestaRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: amountStyle(15).copyWith(letterSpacing: 2),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  onPressed: () => _copy(context, code, 'Code copied'),
                  icon: Icon(
                    PhosphorIconsRegular.copy,
                    size: 18,
                    color: v.accentInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VestaSpace.md),
          Row(
            children: [
              Expanded(
                child: OutlineButton(
                  label: 'Copy link',
                  onPressed: () => _copy(context, link, 'Link copied'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Share',
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          'I use Vesta to plan my money. Join with my code '
                          '$code: $link',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    }
  }

  Widget _invited(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> userRef,
  ) {
    final v = context.vesta;
    final palette = [v.pxBlue, v.pxYellow, v.pxGreen, v.pxTeal, v.pxPurple];
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: userRef.collection('referrals').snapshots(),
      builder: (context, snap) {
        final people = snap.data?.docs ?? const [];
        return VestaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "People you've invited",
                      style: headingStyle(16),
                    ),
                  ),
                  if (people.isNotEmpty)
                    Text(
                      people.length == 1
                          ? '1 person'
                          : '${people.length} people',
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                ],
              ),
              const SizedBox(height: VestaSpace.sm),
              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: VestaSpace.md),
                  child: Text(
                    'No one yet. Share your code, and the friends who join '
                    'show up here.',
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                )
              else
                for (var i = 0; i < people.length; i++)
                  _person(
                    context,
                    people[i].data(),
                    palette[i % palette.length],
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _person(BuildContext context, Map<String, dynamic> p, Color color) {
    final v = context.vesta;
    final name = (p['name'] ?? 'Friend').toString();
    final joined = p['joinedAt'] is Timestamp
        ? DateFormat(
            'MMM d, yyyy',
          ).format((p['joinedAt'] as Timestamp).toDate())
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 13, color: v.pxInk),
            ),
          ),
          const SizedBox(width: VestaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                if (joined != null)
                  Text(
                    'Joined $joined',
                    style: TextStyle(fontSize: 12, color: v.muted),
                  ),
              ],
            ),
          ),
          Text(
            '+${(p['points'] as num?)?.toInt() ?? referralReward} pts',
            style: TextStyle(fontSize: 13, color: v.pos),
          ),
        ],
      ),
    );
  }
}
