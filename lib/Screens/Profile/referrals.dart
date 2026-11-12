import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/referral_codes.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Profile/subscriptions.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// What points buy (the prototype's numbers).
const _plusPoints = 1000;
const _premiumPoints = 1500;

/// Codes being reserved for accounts that don't have one yet, so a rebuild
/// doesn't start a second reservation.
final _reserving = <String, Future<String?>>{};

class ReferralsPage extends StatelessWidget {
  const ReferralsPage({super.key});

  void _howItWorks(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => VestaDialog(
        icon: PhosphorIconsRegular.gift,
        title: context.l10n.howReferralsWork,
        message: context.l10n.referralsHowBody(
          '$referralReward',
          '$referralWelcome',
        ),
        cancelLabel: null,
        confirmLabel: context.l10n.gotIt,
      ),
    );
  }

  /// Accounts from before referrals get their code the first time they look.
  void _reserveCode(String uid) {
    _reserving.putIfAbsent(
      uid,
      () => ensureReferralCode(uid).catchError((Object e) {
        debugPrint('⚠️ Could not reserve a referral code: $e');
        _reserving.remove(uid);
        return null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: VestaAppBar(title: context.l10n.profileReferrals),
      body: VestaBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userRef.snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? const <String, dynamic>{};
            final points = (data['referralPoints'] as num?)?.toInt() ?? 0;
            final code = data['referralCode'] as String?;
            if (snap.hasData && code == null) _reserveCode(uid);
            final link = 'https://vestaapp.co/r/${code ?? ''}';
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
        ? context.l10n.enoughPremium
        : points >= _plusPoints
        ? context.l10n.enoughPlusMore(
            NumberFormat.decimalPattern().format(_premiumPoints - points),
          )
        : context.l10n.moreForPlus(
            NumberFormat.decimalPattern().format(_plusPoints - points),
          );
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
                      context.l10n.yourPoints,
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                    Text(
                      context.l10n.pointsShort(
                        NumberFormat.decimalPattern().format(points),
                      ),
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
                label: Text(context.l10n.howItWorks),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          VestaProgressBar(value: (points / goal).clamp(0, 1).toDouble()),
          const SizedBox(height: VestaSpace.sm),
          Text(note, style: TextStyle(fontSize: 12, color: v.muted)),
          const SizedBox(height: VestaSpace.md),
          PrimaryButton(
            label: context.l10n.usePoints,
            onPressed: points >= _plusPoints
                ? () => showPlansComingSoon(context)
                : null,
          ),
        ],
      ),
    );
  }

  /// The user's code, or a placeholder with the buttons off while one is
  /// being reserved.
  Widget _codeCard(BuildContext context, String? code, String link) {
    final v = context.vesta;
    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.yourReferralCode,
            style: TextStyle(fontSize: 12, color: v.muted),
          ),
          const SizedBox(height: VestaSpace.sm),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
            decoration: BoxDecoration(
              border: Border.all(color: v.divider),
              borderRadius: BorderRadius.circular(VestaRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code ?? '····-····',
                    style: amountStyle(15).copyWith(
                      letterSpacing: 2,
                      color: code == null ? v.muted : null,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.copyCode,
                  onPressed: code == null
                      ? null
                      : () => _copy(context, code, context.l10n.codeCopied),
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
                  label: context.l10n.copyLink,
                  onPressed: code == null
                      ? null
                      : () => _copy(context, link, context.l10n.linkCopied),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: context.l10n.share,
                  onPressed: code == null
                      ? null
                      : () => SharePlus.instance.share(
                          ShareParams(
                            text: context.l10n.referralShareText(code, link),
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
                      context.l10n.peopleInvited,
                      style: headingStyle(16),
                    ),
                  ),
                  if (people.isNotEmpty)
                    Text(
                      context.l10n.peopleCount(people.length),
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                ],
              ),
              const SizedBox(height: VestaSpace.sm),
              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: VestaSpace.md),
                  child: Text(
                    context.l10n.noOneInvitedYet,
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
    final name = (p['name'] ?? context.l10n.friend).toString();
    final joined = p['joinedAt'] is Timestamp
        ? DateFormat.yMMMd().format((p['joinedAt'] as Timestamp).toDate())
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
                    context.l10n.joinedOn(joined),
                    style: TextStyle(fontSize: 12, color: v.muted),
                  ),
              ],
            ),
          ),
          Text(
            context.l10n.pointsShort(
              '\u2066+${(p['points'] as num?)?.toInt() ?? referralReward}\u2069',
            ),
            style: TextStyle(fontSize: 13, color: v.pos),
          ),
        ],
      ),
    );
  }
}
