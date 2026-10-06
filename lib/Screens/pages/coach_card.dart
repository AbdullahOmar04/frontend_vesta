import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Budgeting/budgeting_screen.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/insights.dart';
import 'package:intl/intl.dart';

/// What the coach says, and whether tapping it should open the budget
/// (no plan yet) or Insights.
class _CoachNote {
  const _CoachNote(this.headline, this.message, {this.needsPlan = false});

  final String headline;
  final String message;
  final bool needsPlan;
}

/// Home's "Your coach" card, after the prototype: how this budget cycle's
/// necessities and luxuries spending is pacing against the plan.
/// Read-only: it reads the plan, categories and transactions.
class CoachCard extends StatefulWidget {
  const CoachCard({super.key});

  @override
  State<CoachCard> createState() => _CoachCardState();
}

class _CoachCardState extends State<CoachCard> {
  _CoachNote? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final note = await _buildNote();
      if (mounted) setState(() => _note = note);
    } catch (e) {
      debugPrint('Error loading coach: $e');
    }
  }

  Future<_CoachNote?> _buildNote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final now = DateTime.now();
    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final userData = (await userRef.get()).data() ?? {};
    final budget = (await userRef.collection('budget').doc(monthId).get())
            .data() ??
        {};

    final income = double.tryParse('${userData['totalIncome'] ?? 0}') ?? 0;
    final essentialPct = double.tryParse('${budget['spending'] ?? 0}') ?? 0;
    final luxuryPct = double.tryParse('${budget['luxuries'] ?? 0}') ?? 0;
    final essentialBudget = income * essentialPct / 100;
    final luxuryBudget = income * luxuryPct / 100;

    if (essentialBudget + luxuryBudget <= 0) {
      return const _CoachNote(
        "Let's plan this month.",
        'Set your income and split it into savings, necessities and '
            "luxuries. I'll tell you how your spending is pacing against it.",
        needsPlan: true,
      );
    }

    // The budget cycle, as the Budgeting screen works it out
    final resetDay = (userData['dayOfMonth'] as num?)?.toInt() ?? 28;
    final DateTime start;
    final DateTime end;
    if (now.day >= resetDay) {
      start = DateTime(now.year, now.month, resetDay);
      end = DateTime(now.year, now.month + 1, resetDay)
          .subtract(const Duration(days: 1));
    } else {
      start = DateTime(now.year, now.month - 1, resetDay);
      end = DateTime(now.year, now.month, resetDay)
          .subtract(const Duration(days: 1));
    }
    final endOfCycle = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final buckets = <String, String>{};
    for (final doc in (await userRef.collection('categories').get()).docs) {
      final raw = (doc.data()['bucket'] ?? '') as String;
      buckets[doc.id] = raw.isEmpty ? inferBucketFromCategoryName(doc.id) : raw;
    }

    var essentialSpent = 0.0;
    var luxurySpent = 0.0;
    final accounts = await userRef
        .collection('accounts')
        .where('linked', isEqualTo: true)
        .get();
    for (final account in accounts.docs) {
      final txns = await account.reference.collection('transactions').get();
      for (final doc in txns.docs) {
        final data = doc.data();
        if ('${data['type'] ?? ''}'.toLowerCase() != 'debit') continue;
        final date = DateTime.tryParse('${data['date'] ?? ''}');
        if (date == null || date.isBefore(start) || date.isAfter(endOfCycle)) {
          continue;
        }
        final category = data['category'] as String?;
        if (category == null || category.isEmpty) continue;
        final bucket = buckets[category] ?? inferBucketFromCategoryName(category);
        final amount = (double.tryParse('${data['amount'] ?? 0}') ?? 0).abs();
        if (bucket == 'essential') essentialSpent += amount;
        if (bucket == 'luxury') luxurySpent += amount;
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final totalDays = end.difference(start).inDays + 1;
    final daysLeft = (end.difference(today).inDays + 1).clamp(1, totalDays);
    final progress = (totalDays - daysLeft + 1) / totalDays;
    final until = DateFormat('MMM d').format(end);

    final flexBudget = essentialBudget + luxuryBudget;
    final flexSpent = essentialSpent + luxurySpent;
    final ratio = flexSpent / flexBudget;
    String money(double v) => formatMoney(v);

    final over = [
      if (essentialBudget > 0 && essentialSpent > essentialBudget)
        ('Necessities', essentialSpent - essentialBudget, 'luxuries',
            luxuryBudget - luxurySpent),
      if (luxuryBudget > 0 && luxurySpent > luxuryBudget)
        ('Luxuries', luxurySpent - luxuryBudget, 'necessities',
            essentialBudget - essentialSpent),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    if (over.isNotEmpty) {
      final (name, by, otherName, otherLeft) = over.first;
      return _CoachNote(
        ratio <= progress + 0.05
            ? "You're mostly on pace."
            : 'Spending is running a little hot.',
        otherLeft > 0
            ? '$name is ${money(by)} over its limit. You still have '
                  '${money(otherLeft)} for $otherName, about '
                  '${money(otherLeft / daysLeft)} a day until $until.'
            : '$name is ${money(by)} over its limit, and your spending '
                  'budget is used up until $until.',
      );
    }

    final left = flexBudget - flexSpent;
    if (ratio > progress + 0.08) {
      return _CoachNote(
        'Spending is running ahead.',
        "You've used ${(ratio * 100).round()}% of your spending budget with "
            '${((1 - progress) * 100).round()}% of the cycle left. '
            '${money(left / daysLeft)} a day keeps you on track.',
      );
    }
    return _CoachNote(
      "You're on pace this cycle.",
      '${money(left)} left to spend, about ${money(left / daysLeft)} a day '
          'for the next $daysLeft ${daysLeft == 1 ? 'day' : 'days'}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    if (note == null) return const SizedBox.shrink();
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: VestaSpace.xl),
      child: VestaCard(
        radius: VestaRadius.lg,
        padding: EdgeInsets.zero,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => note.needsPlan
                ? const PersonalBudgetScreen()
                : const InsightsPage(),
          ),
        ).then((_) => _load()),
        child: Stack(
          children: [
            // Soft accent glow in the corner, as in the prototype
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(VestaSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/LOGO_APP-ICON-DARK.png',
                          width: 22,
                          height: 22,
                          cacheWidth: 66,
                        ),
                      ),
                      const SizedBox(width: VestaSpace.sm),
                      Text(
                        'YOUR COACH',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: v.accentInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VestaSpace.md),
                  Text(note.headline, style: headingStyle(17)),
                  const SizedBox(height: VestaSpace.xs),
                  Text(
                    note.message,
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
