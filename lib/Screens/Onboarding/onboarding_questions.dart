import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/pages/main_screen.dart';

/// The things a new user can pick to work on first, after the prototype
/// (its "bills" option is left out until the app has bills).
const _focusOptions = [
  ('spend', 'Manage my spendings', PhosphorIconsRegular.receipt),
  ('goals', 'Start saving goals', PhosphorIconsRegular.piggyBank),
  ('shared', 'Manage shared finances', PhosphorIconsRegular.usersThree),
  ('budget', 'Build a monthly budget', PhosphorIconsRegular.chartPieSlice),
  ('clarity', 'Get financial clarity', PhosphorIconsRegular.eye),
];

/// Suggested starting split, as budget percentages: (label, examples, %).
const _split = [
  ('Necessities', 'Rent, groceries, bills', 50.0),
  ('Luxuries', 'Dining, fun, shopping', 30.0),
  ('Savings', 'Goals and extra payments', 20.0),
];

/// A few questions right after sign-up, after the prototype's onboarding:
/// a welcome, monthly income with a suggested budget split, and what to
/// work on first. Skip goes straight to the app without saving anything.
class OnboardingQuestions extends StatefulWidget {
  const OnboardingQuestions({super.key, required this.username});

  final String username;

  @override
  State<OnboardingQuestions> createState() => _OnboardingQuestionsState();
}

class _OnboardingQuestionsState extends State<OnboardingQuestions> {
  static const _steps = 3;

  int _step = 0;
  final _incomeCtrl = TextEditingController();
  bool _useSplit = true;
  final Set<String> _focus = {};
  bool _saving = false;

  double get _income => double.tryParse(_incomeCtrl.text.trim()) ?? 0;

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  void _openApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  bool get _canContinue => switch (_step) {
    1 => _income > 0,
    2 => _focus.isNotEmpty,
    _ => true,
  };

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    await _finish();
  }

  /// Saves the income and focus on the user doc, and the split as this
  /// month's plan the same way the Budgeting screen saves one.
  Future<void> _finish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _openApp();
    setState(() => _saving = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final income = _income;
      final batch = FirebaseFirestore.instance.batch();

      batch.update(userRef, {
        'totalIncome': income,
        'focus': _focus.toList(),
      });

      if (_useSplit) {
        final now = DateTime.now();
        final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";
        final budgetRef = userRef.collection('budget').doc(monthId);
        final exists = (await budgetRef.get()).exists;
        batch.set(budgetRef, {
          'income': income,
          'spending': _split[0].$3,
          'luxuries': _split[1].$3,
          'saving': _split[2].$3,
          'updatedAt': FieldValue.serverTimestamp(),
          // A new month's doc needs createdAt, or the plan is never copied
          // into the next cycle (see handleBudgetCycleOnLogin)
          if (!exists) 'currency': 'JOD',
          if (!exists) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      if (mounted) _openApp();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save your answers: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0 && !_saving) setState(() => _step--);
      },
      child: Scaffold(
        body: VestaBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      VestaSpace.gutter,
                      VestaSpace.xl,
                      VestaSpace.gutter,
                      VestaSpace.xl,
                    ),
                    children: [
                      switch (_step) {
                        0 => _welcome(),
                        1 => _incomeStep(),
                        _ => _focusStep(),
                      },
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VestaSpace.gutter,
                    VestaSpace.sm,
                    VestaSpace.gutter,
                    VestaSpace.lg,
                  ),
                  child: PrimaryButton(
                    label: switch (_step) {
                      0 => "Let's go",
                      1 => 'Continue',
                      _ => 'Finish',
                    },
                    loading: _saving,
                    onPressed: _canContinue && !_saving ? _next : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Back arrow, step dots and Skip.
  Widget _topBar() {
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VestaSpace.sm, VestaSpace.sm, VestaSpace.sm, 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: _step > 0
                ? IconButton(
                    onPressed: _saving ? null : () => setState(() => _step--),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft),
                    tooltip: 'Back',
                  )
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _step ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step ? accent : v.track,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _saving ? null : _openApp,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _welcome() {
    final v = context.vesta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/images/LOGO_APP-ICON-DARK.png',
            width: 56,
            height: 56,
            cacheWidth: 168,
          ),
        ),
        const SizedBox(height: VestaSpace.xl),
        Text(
          "Let's get your money into one calm view.",
          style: headingStyle(26),
        ),
        const SizedBox(height: VestaSpace.md),
        Text(
          "A few questions and you'll have a starting budget, your accounts "
          'in one place, and a coach that keeps an eye on your spending.',
          style: TextStyle(fontSize: 15, color: v.muted),
        ),
      ],
    );
  }

  Widget _incomeStep() {
    final v = context.vesta;
    final income = _income;
    final colors = [v.bucketEssential, v.bucketLuxury, v.bucketSavings];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nice to meet you, ${widget.username}. '
          'What lands in your account each month?',
          style: headingStyle(22),
        ),
        const SizedBox(height: VestaSpace.sm),
        Text(
          "Your take-home pay after taxes. We'll suggest a split you can "
          'change anytime.',
          style: TextStyle(fontSize: 14, color: v.muted),
        ),
        const SizedBox(height: VestaSpace.xl),
        TextField(
          controller: _incomeCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: amountStyle(26),
          decoration: const InputDecoration(
            prefixText: 'JOD  ',
            suffixText: '/ month',
            hintText: '0',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: VestaSpace.xl),
        VestaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUGGESTED STARTING SPLIT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: v.muted,
                ),
              ),
              const SizedBox(height: VestaSpace.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      for (var i = 0; i < _split.length; i++)
                        Expanded(
                          flex: _split[i].$3.round(),
                          child: Container(color: colors[i]),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VestaSpace.md),
              for (var i = 0; i < _split.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: VestaSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_split[i].$1} · ${_split[i].$3.round()}%',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _split[i].$2,
                              style: TextStyle(fontSize: 12, color: v.muted),
                            ),
                          ],
                        ),
                      ),
                      MoneyText(income * _split[i].$3 / 100),
                    ],
                  ),
                ),
              const Divider(height: VestaSpace.xl),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Use this as my starting budget',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Switch(
                    value: _useSplit,
                    onChanged: (on) => setState(() => _useSplit = on),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _focusStep() {
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What do you want to work on first?', style: headingStyle(22)),
        const SizedBox(height: VestaSpace.sm),
        Text(
          'Pick up to three. Your coach will focus here.',
          style: TextStyle(fontSize: 14, color: v.muted),
        ),
        const SizedBox(height: VestaSpace.xl),
        for (final (id, label, icon) in _focusOptions) ...[
          _FocusOption(
            label: label,
            icon: icon,
            selected: _focus.contains(id),
            accent: accent,
            onTap: () => setState(() {
              if (_focus.contains(id)) {
                _focus.remove(id);
              } else if (_focus.length < 3) {
                _focus.add(id);
              }
            }),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FocusOption extends StatelessWidget {
  const _FocusOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Material(
      color: selected ? v.tint : Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.button),
        side: BorderSide(color: selected ? accent : v.edge),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? v.tintText : null),
              const SizedBox(width: VestaSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? v.tintText : null,
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent : Colors.transparent,
                  border: Border.all(color: selected ? accent : v.muted),
                ),
                child: selected
                    ? const Icon(
                        PhosphorIconsRegular.check,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
