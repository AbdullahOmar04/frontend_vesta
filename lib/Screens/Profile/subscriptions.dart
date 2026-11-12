import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

/// The plans from the prototype. Paid plans aren't on sale yet, so the
/// buttons explain that instead of charging.
List<({String name, double price, List<String> features})> _plans(
  BuildContext context,
) {
  final l10n = context.l10n;
  return [
    (
      name: l10n.planFree,
      price: 0.0,
      features: [l10n.planFeatCore, l10n.planFeat2Banks, l10n.planFeatHealth],
    ),
    (
      name: 'Plus',
      price: 3.99,
      features: [
        l10n.planFeatAllFree,
        l10n.planFeatUnlimitedBanks,
        l10n.planFeatShared1,
        l10n.planFeatReminders,
      ],
    ),
    (
      name: 'Premium',
      price: 6.99,
      features: [
        l10n.planFeatAllPlus,
        l10n.planFeatShared3,
        l10n.planFeatInsights,
        l10n.planFeatPriority,
      ],
    ),
  ];
}

/// Opens the coming-soon note for a paid plan.
Future<void> showPlansComingSoon(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => VestaDialog(
      icon: PhosphorIconsRegular.crownSimple,
      title: context.l10n.paidPlansSoon,
      message: context.l10n.paidPlansSoonBody,
      cancelLabel: null,
      confirmLabel: context.l10n.ok,
    ),
  );
}

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Scaffold(
      appBar: VestaAppBar(title: context.l10n.profileSubscriptions),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.noSubscription,
                    style: headingStyle(16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.onFreePlan,
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                ],
              ),
            ),
            for (final plan in _plans(context)) ...[
              const SizedBox(height: VestaSpace.md),
              VestaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(plan.name, style: headingStyle(18)),
                        ),
                        Text(formatMoney(plan.price), style: amountStyle(14)),
                        if (plan.price > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.aMonth,
                            style: TextStyle(fontSize: 11, color: v.muted),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: VestaSpace.sm),
                    for (final f in plan.features)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              PhosphorIconsRegular.checkCircle,
                              size: 16,
                              color: v.accentInk,
                            ),
                            const SizedBox(width: VestaSpace.sm),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (plan.price > 0) ...[
                      const SizedBox(height: VestaSpace.md),
                      PrimaryButton(
                        label: context.l10n.getPlan(plan.name),
                        onPressed: () => showPlansComingSoon(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
