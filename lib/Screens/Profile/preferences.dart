import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/appearance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';

DocumentReference<Map<String, dynamic>> _userRef() => FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser?.uid);

/// Saves one setting inside a map on the user doc (e.g. reminders.upcoming).
Future<void> _saveSetting(String group, String key, Object value) {
  return _userRef().set({
    group: {key: value},
  }, SetOptions(merge: true));
}

/// Shown under reminder and notification settings until Vesta sends them.
const _notYetNote =
    "Vesta doesn't send these yet. Your choices are saved for when it does.";

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return Scaffold(
      appBar: const VestaAppBar(title: 'Preferences'),
      body: VestaBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userRef().snapshots(),
          builder: (context, snap) {
            final day = snap.data?.data()?['dayOfMonth'];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                VestaSpace.xs,
                VestaSpace.gutter,
                VestaSpace.xl,
              ),
              children: [
                MenuCard([
                  MenuRow(
                    icon: PhosphorIconsRegular.monitor,
                    title: 'Display',
                    subtitle: 'Appearance, language, and currency',
                    onTap: () => open(const DisplayPage()),
                  ),
                  MenuRow(
                    icon: PhosphorIconsRegular.calendarBlank,
                    title: 'Budget reset day',
                    subtitle: day != null ? 'Day $day of each month' : null,
                    onTap: () => inputDayOfMonth(context),
                  ),
                  const MenuRow(
                    icon: PhosphorIconsRegular.squaresFour,
                    title: 'Features management',
                    tag: 'Coming soon',
                  ),
                  MenuRow(
                    icon: PhosphorIconsRegular.alarm,
                    title: 'Reminders and alerts',
                    subtitle: 'Upcoming payments, budgets, and goals',
                    onTap: () => open(const RemindersPage()),
                  ),
                  MenuRow(
                    icon: PhosphorIconsRegular.bell,
                    title: 'Notifications',
                    onTap: () => open(const NotificationsPage()),
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

/// One of a row of equal-width choices, as on the prototype's Display page.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final fg = selected ? v.accentInk : null;
    return Expanded(
      child: Material(
        color: selected ? v.accentWash : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VestaRadius.button),
          side: BorderSide(color: selected ? v.accentInk : v.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label, style: TextStyle(fontSize: 13, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: VestaSpace.sm),
      child: Text(text, style: TextStyle(fontSize: 12, color: v.muted)),
    );
    const gap = SizedBox(width: VestaSpace.sm);

    return Scaffold(
      appBar: const VestaAppBar(title: 'Display'),
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
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: appearance,
                builder: (context, mode, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label('Appearance'),
                    Row(
                      children: [
                        _Choice(
                          label: 'Light',
                          icon: PhosphorIconsRegular.sun,
                          selected: mode == ThemeMode.light,
                          onTap: () => setAppearance(ThemeMode.light),
                        ),
                        gap,
                        _Choice(
                          label: 'Dark',
                          icon: PhosphorIconsRegular.moon,
                          selected: mode == ThemeMode.dark,
                          onTap: () => setAppearance(ThemeMode.dark),
                        ),
                        gap,
                        _Choice(
                          label: 'Auto',
                          icon: PhosphorIconsRegular.deviceMobile,
                          selected: mode == ThemeMode.system,
                          onTap: () => setAppearance(ThemeMode.system),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Auto follows your phone's setting.",
                      style: TextStyle(fontSize: 11, color: v.muted),
                    ),
                    const SizedBox(height: VestaSpace.lg),
                    label('Language'),
                    Row(
                      children: [
                        _Choice(
                          label: 'English',
                          icon: PhosphorIconsRegular.translate,
                          selected: true,
                          onTap: () {},
                        ),
                        gap,
                        _Choice(
                          label: 'العربية',
                          icon: PhosphorIconsRegular.translate,
                          selected: false,
                          onTap: () => ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('Arabic is coming soon.'),
                              ),
                            ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VestaSpace.lg),
                    label('Currency'),
                    DropdownButtonFormField<String>(
                      initialValue: 'JOD',
                      items: const [
                        DropdownMenuItem(
                          value: 'JOD',
                          child: Text('JOD · Jordanian dinar'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'More currencies are coming.',
                      style: TextStyle(fontSize: 11, color: v.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small chip in a "Remind me 1 day / 3 days / 7 days" row.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: selected ? v.accentWash : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? v.accentInk : v.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? v.accentInk : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Scaffold(
      appBar: const VestaAppBar(title: 'Reminders and alerts'),
      body: VestaBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userRef().snapshots(),
          builder: (context, snap) {
            final r = Map<String, dynamic>.from(
              snap.data?.data()?['reminders'] ?? const {},
            );
            bool on(String key, bool fallback) => r[key] as bool? ?? fallback;
            void set(String key, Object value) =>
                _saveSetting('reminders', key, value);
            final days = (r['upcomingDays'] as num?)?.toInt() ?? 3;
            final at = (r['overBudgetAt'] as num?)?.toInt() ?? 90;

            Widget choices(
              String lead,
              List<(String, int)> opts,
              int current,
              String key,
              bool enabled,
            ) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(47, 0, 14, 12),
                child: Row(
                  children: [
                    Text(lead, style: TextStyle(fontSize: 12, color: v.muted)),
                    const SizedBox(width: 4),
                    for (final (label, value) in opts)
                      _Pill(
                        label: label,
                        selected: current == value,
                        onTap: enabled ? () => set(key, value) : null,
                      ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                VestaSpace.xs,
                VestaSpace.gutter,
                VestaSpace.xl,
              ),
              children: [
                Text(
                  'Choose what Vesta should remind you about.',
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
                const SizedBox(height: VestaSpace.md),
                MenuCard([
                  Column(
                    children: [
                      ToggleRow(
                        icon: PhosphorIconsRegular.calendarCheck,
                        title: 'Upcoming payments',
                        subtitle: 'Before a scheduled payment is due',
                        value: on('upcoming', true),
                        onChanged: (x) => set('upcoming', x),
                      ),
                      choices(
                        'Remind me',
                        [('1 day', 1), ('3 days', 3), ('7 days', 7)],
                        days,
                        'upcomingDays',
                        on('upcoming', true),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      ToggleRow(
                        icon: PhosphorIconsRegular.gauge,
                        title: 'Going over budget',
                        subtitle: 'When your spending gets close to the budget',
                        value: on('overBudget', true),
                        onChanged: (x) => set('overBudget', x),
                      ),
                      choices(
                        'Alert at',
                        [('80%', 80), ('90%', 90), ('100%', 100)],
                        at,
                        'overBudgetAt',
                        on('overBudget', true),
                      ),
                    ],
                  ),
                  ToggleRow(
                    icon: PhosphorIconsRegular.tag,
                    title: 'Category limits',
                    subtitle: 'When a category reaches its monthly limit',
                    value: on('categoryLimits', true),
                    onChanged: (x) => set('categoryLimits', x),
                  ),
                  ToggleRow(
                    icon: PhosphorIconsRegular.piggyBank,
                    title: 'Savings goals',
                    subtitle: "When you haven't reached this month's target",
                    value: on('savingsGoals', true),
                    onChanged: (x) => set('savingsGoals', x),
                  ),
                  ToggleRow(
                    icon: PhosphorIconsRegular.warningDiamond,
                    title: 'Large transactions',
                    subtitle:
                        'When a single transaction is over ${formatMoney(100)}',
                    value: on('largeTransactions', false),
                    onChanged: (x) => set('largeTransactions', x),
                  ),
                ]),
                const SizedBox(height: VestaSpace.md),
                Text(
                  _notYetNote,
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Scaffold(
      appBar: const VestaAppBar(title: 'Notifications'),
      body: VestaBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userRef().snapshots(),
          builder: (context, snap) {
            final n = Map<String, dynamic>.from(
              snap.data?.data()?['notifications'] ?? const {},
            );
            Widget row(
              IconData icon,
              String key,
              String title,
              String sub,
              bool fallback,
            ) {
              return ToggleRow(
                icon: icon,
                title: title,
                subtitle: sub,
                value: n[key] as bool? ?? fallback,
                onChanged: (x) => _saveSetting('notifications', key, x),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                VestaSpace.xs,
                VestaSpace.gutter,
                VestaSpace.xl,
              ),
              children: [
                Text(
                  'Choose which notifications you want to get.',
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
                const SizedBox(height: VestaSpace.md),
                MenuCard([
                  row(
                    PhosphorIconsRegular.receipt,
                    'perTransaction',
                    'Per transaction',
                    'Every time money comes in or goes out',
                    true,
                  ),
                  row(
                    PhosphorIconsRegular.handPointing,
                    'requiredActions',
                    'Required actions',
                    'Things that need you, like a bill to confirm',
                    true,
                  ),
                  row(
                    PhosphorIconsRegular.confetti,
                    'motivational',
                    'Motivational',
                    'Milestones and encouragement',
                    true,
                  ),
                  row(
                    PhosphorIconsRegular.megaphone,
                    'promotional',
                    'Promotional and app updates',
                    'Offers and new features',
                    false,
                  ),
                  row(
                    PhosphorIconsRegular.headset,
                    'customerService',
                    'Customer service',
                    'Replies to your support requests',
                    true,
                  ),
                ]),
                const SizedBox(height: VestaSpace.md),
                Text(
                  _notYetNote,
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
