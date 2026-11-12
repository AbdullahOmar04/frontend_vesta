import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/appearance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/language.dart';
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

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return Scaffold(
      appBar: VestaAppBar(title: context.l10n.prefsTitle),
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
                    title: context.l10n.prefsDisplay,
                    subtitle: context.l10n.prefsDisplaySubtitle,
                    onTap: () => open(const DisplayPage()),
                  ),
                  MenuRow(
                    icon: PhosphorIconsRegular.calendarBlank,
                    title: context.l10n.prefsResetDay,
                    subtitle: day != null
                        ? context.l10n.prefsResetDaySubtitle('$day')
                        : null,
                    onTap: () => inputDayOfMonth(context),
                  ),
                  MenuRow(
                    icon: PhosphorIconsRegular.squaresFour,
                    title: context.l10n.prefsFeatures,
                    tag: context.l10n.comingSoon,
                  ),
                  MenuRow(
                    icon: PhosphorIconsRegular.alarm,
                    title: context.l10n.prefsReminders,
                    subtitle: context.l10n.prefsRemindersSubtitle,
                    onTap: () => open(const RemindersPage()),
                  ),
                  MenuRow(
                    icon: PhosphorIconsRegular.bell,
                    title: context.l10n.prefsNotifications,
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
    final l10n = context.l10n;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: VestaSpace.sm),
      child: Text(text, style: TextStyle(fontSize: 12, color: v.muted)),
    );
    const gap = SizedBox(width: VestaSpace.sm);

    return Scaffold(
      appBar: VestaAppBar(title: l10n.displayTitle),
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
                    label(l10n.displayAppearance),
                    Row(
                      children: [
                        _Choice(
                          label: l10n.displayLight,
                          icon: PhosphorIconsRegular.sun,
                          selected: mode == ThemeMode.light,
                          onTap: () => setAppearance(ThemeMode.light),
                        ),
                        gap,
                        _Choice(
                          label: l10n.displayDark,
                          icon: PhosphorIconsRegular.moon,
                          selected: mode == ThemeMode.dark,
                          onTap: () => setAppearance(ThemeMode.dark),
                        ),
                        gap,
                        _Choice(
                          label: l10n.displayAuto,
                          icon: PhosphorIconsRegular.deviceMobile,
                          selected: mode == ThemeMode.system,
                          onTap: () => setAppearance(ThemeMode.system),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.displayAutoNote,
                      style: TextStyle(fontSize: 11, color: v.muted),
                    ),
                    const SizedBox(height: VestaSpace.lg),
                    label(l10n.displayLanguage),
                    // Each language is written in itself, so it can be
                    // found whichever one the app is in
                    Row(
                      children: [
                        _Choice(
                          label: 'English',
                          icon: PhosphorIconsRegular.translate,
                          selected: activeLanguage == 'en',
                          onTap: () => setLanguage('en'),
                        ),
                        gap,
                        _Choice(
                          label: 'العربية',
                          icon: PhosphorIconsRegular.translate,
                          selected: activeLanguage == 'ar',
                          onTap: () => setLanguage('ar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: VestaSpace.lg),
                    label(l10n.displayCurrency),
                    DropdownButtonFormField<String>(
                      initialValue: 'JOD',
                      items: [
                        DropdownMenuItem(
                          value: 'JOD',
                          child: Text(l10n.displayCurrencyJod),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.displayMoreCurrencies,
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
      padding: const EdgeInsetsDirectional.only(start: 6),
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: VestaAppBar(title: l10n.prefsReminders),
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
                padding: const EdgeInsetsDirectional.fromSTEB(47, 0, 14, 12),
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
                  l10n.remindersIntro,
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
                const SizedBox(height: VestaSpace.md),
                MenuCard([
                  Column(
                    children: [
                      ToggleRow(
                        icon: PhosphorIconsRegular.calendarCheck,
                        title: l10n.remindersUpcoming,
                        subtitle: l10n.remindersUpcomingSubtitle,
                        value: on('upcoming', true),
                        onChanged: (x) => set('upcoming', x),
                      ),
                      choices(
                        l10n.remindersRemindMe,
                        [for (final d in [1, 3, 7]) (l10n.remindersDays(d), d)],
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
                        title: l10n.remindersOverBudget,
                        subtitle: l10n.remindersOverBudgetSubtitle,
                        value: on('overBudget', true),
                        onChanged: (x) => set('overBudget', x),
                      ),
                      choices(
                        l10n.remindersAlertAt,
                        [('80%', 80), ('90%', 90), ('100%', 100)],
                        at,
                        'overBudgetAt',
                        on('overBudget', true),
                      ),
                    ],
                  ),
                  ToggleRow(
                    icon: PhosphorIconsRegular.tag,
                    title: l10n.remindersCategoryLimits,
                    subtitle: l10n.remindersCategoryLimitsSubtitle,
                    value: on('categoryLimits', true),
                    onChanged: (x) => set('categoryLimits', x),
                  ),
                  ToggleRow(
                    icon: PhosphorIconsRegular.piggyBank,
                    title: l10n.remindersSavings,
                    subtitle: l10n.remindersSavingsSubtitle,
                    value: on('savingsGoals', true),
                    onChanged: (x) => set('savingsGoals', x),
                  ),
                  ToggleRow(
                    icon: PhosphorIconsRegular.warningDiamond,
                    title: l10n.remindersLarge,
                    subtitle: l10n.remindersLargeSubtitle(formatMoney(100)),
                    value: on('largeTransactions', false),
                    onChanged: (x) => set('largeTransactions', x),
                  ),
                ]),
                const SizedBox(height: VestaSpace.md),
                Text(
                  l10n.remindersNotYet,
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: VestaAppBar(title: l10n.prefsNotifications),
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
                  l10n.notificationsIntro,
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
                const SizedBox(height: VestaSpace.md),
                MenuCard([
                  row(
                    PhosphorIconsRegular.receipt,
                    'perTransaction',
                    l10n.notificationsPerTransaction,
                    l10n.notificationsPerTransactionSubtitle,
                    true,
                  ),
                  row(
                    PhosphorIconsRegular.handPointing,
                    'requiredActions',
                    l10n.notificationsRequired,
                    l10n.notificationsRequiredSubtitle,
                    true,
                  ),
                  row(
                    PhosphorIconsRegular.confetti,
                    'motivational',
                    l10n.notificationsMotivational,
                    l10n.notificationsMotivationalSubtitle,
                    true,
                  ),
                  row(
                    PhosphorIconsRegular.megaphone,
                    'promotional',
                    l10n.notificationsPromotional,
                    l10n.notificationsPromotionalSubtitle,
                    false,
                  ),
                  row(
                    PhosphorIconsRegular.headset,
                    'customerService',
                    l10n.notificationsSupport,
                    l10n.notificationsSupportSubtitle,
                    true,
                  ),
                ]),
                const SizedBox(height: VestaSpace.md),
                Text(
                  l10n.remindersNotYet,
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
