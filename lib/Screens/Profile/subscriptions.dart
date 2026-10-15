import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

/// The plans from the prototype. Paid plans aren't on sale yet, so the
/// buttons explain that instead of charging.
const _plans = [
  (
    name: 'Free',
    price: 0.0,
    features: [
      'Budgeting, Spendings, and Savings',
      'Up to 2 linked bank accounts',
      'Monthly financial health score',
    ],
  ),
  (
    name: 'Plus',
    price: 3.99,
    features: [
      'Everything in Free',
      'Unlimited bank accounts',
      'Shared finances with 1 household and up to 3 shared goals',
      'Smart reminders and alerts',
    ],
  ),
  (
    name: 'Premium',
    price: 6.99,
    features: [
      'Everything in Plus',
      'Up to 3 households with unlimited shared goals',
      'Advanced insights and exports',
      'Priority customer service',
    ],
  ),
];

/// Opens the coming-soon note for a paid plan.
Future<void> showPlansComingSoon(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const VestaDialog(
      icon: PhosphorIconsRegular.crownSimple,
      title: 'Paid plans are coming soon',
      message:
          "You'll be able to subscribe here once they launch. Until then, "
          'everything in Vesta is free.',
      cancelLabel: null,
      confirmLabel: 'OK',
    ),
  );
}

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Scaffold(
      appBar: const VestaAppBar(title: 'Subscriptions'),
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
                    "You don't have a subscription",
                    style: headingStyle(16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You're on the Free plan. Pick a plan to unlock more.",
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                ],
              ),
            ),
            for (final plan in _plans) ...[
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
                            'a month',
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
                        label: 'Get ${plan.name}',
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
