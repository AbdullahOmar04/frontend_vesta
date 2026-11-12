import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:frontend_vesta/l10n/app_localizations.dart';
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
      final l10n = context.l10n;
      final note = _noteFor(await loadBudgetSummary(), l10n);
      if (mounted) setState(() => _note = note);
    } catch (e) {
      debugPrint('Error loading coach: $e');
    }
  }

  static _CoachNote? _noteFor(
    BudgetSummary? summary,
    AppLocalizations l10n,
  ) {
    if (summary == null) return null;

    if (!summary.hasPlan) {
      return _CoachNote(
        l10n.coachPlanTitle,
        l10n.coachPlanBody,
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
        (l10n.bucketNecessities, essentialSpent - essentialBudget,
            l10n.bucketLuxuriesLower,
            luxuryBudget - luxurySpent),
      if (luxuryBudget > 0 && luxurySpent > luxuryBudget)
        (l10n.bucketLuxuries, luxurySpent - luxuryBudget,
            l10n.bucketNecessitiesLower,
            essentialBudget - essentialSpent),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    if (over.isNotEmpty) {
      final (name, by, otherName, otherLeft) = over.first;
      return _CoachNote(
        ratio <= progress + 0.05
            ? l10n.coachMostlyOnPace
            : l10n.coachRunningHot,
        otherLeft > 0
            ? l10n.coachOverWithOther(
                name,
                money(by),
                money(otherLeft),
                otherName,
                money(otherLeft / daysLeft),
                until,
              )
            : l10n.coachOverUsedUp(name, money(by), until),
      );
    }

    final left = flexBudget - flexSpent;
    if (ratio > progress + 0.08) {
      return _CoachNote(
        l10n.coachAheadTitle,
        l10n.coachAheadBody(
          '${(ratio * 100).round()}',
          '${((1 - progress) * 100).round()}',
          money(left / daysLeft),
        ),
      );
    }
    return _CoachNote(
      l10n.coachOnPaceTitle,
      l10n.coachOnPaceBody(money(left), money(left / daysLeft), daysLeft),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.summary != null ? _noteFor(widget.summary, context.l10n) : _note;
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
                        context.l10n.coachLabel,
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
                      note.needsPlan
                          ? context.l10n.coachPlanLink
                          : context.l10n.coachInsightsLink,
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
