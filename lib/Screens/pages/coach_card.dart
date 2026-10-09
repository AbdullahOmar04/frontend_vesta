import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Budgeting/budgeting_screen.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/insights.dart';
import 'package:frontend_vesta/Screens/pages/budget_summary.dart';
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
  const CoachCard({
    super.key,
    this.summary,
    this.showLink = false,
    this.margin = const EdgeInsets.only(top: VestaSpace.xl),
  });

  /// Figures the caller has already loaded (the Dashboard); without them the
  /// card loads its own.
  final BudgetSummary? summary;

  /// Adds the prototype's "See insights" link under the message.
  final bool showLink;
  final EdgeInsetsGeometry margin;

  @override
  State<CoachCard> createState() => _CoachCardState();
}

class _CoachCardState extends State<CoachCard> {
  _CoachNote? _note;

  @override
  void initState() {
    super.initState();
    if (widget.summary == null) _load();
  }

  Future<void> _load() async {
    if (widget.summary != null) return;
    try {
      final note = _noteFor(await loadBudgetSummary());
      if (mounted) setState(() => _note = note);
    } catch (e) {
      debugPrint('Error loading coach: $e');
    }
  }

  static _CoachNote? _noteFor(BudgetSummary? summary) {
    if (summary == null) return null;

    if (!summary.hasPlan) {
      return const _CoachNote(
        "Let's plan this month.",
        'Set your income and split it into savings, necessities and '
            "luxuries. I'll tell you how your spending is pacing against it.",
        needsPlan: true,
      );
    }

    final essentialBudget = summary.essentialBudget;
    final luxuryBudget = summary.luxuryBudget;
    final essentialSpent = summary.essentialSpent;
    final luxurySpent = summary.luxurySpent;
    final daysLeft = summary.daysLeft;
    final progress = summary.progress;
    final until = DateFormat('MMM d').format(summary.end);

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
    final note = widget.summary != null ? _noteFor(widget.summary) : _note;
    if (note == null) return const SizedBox.shrink();
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: widget.margin,
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
                  if (widget.showLink) ...[
                    const SizedBox(height: VestaSpace.md),
                    Text(
                      note.needsPlan ? 'Plan your budget →' : 'See insights →',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: v.accentInk,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
