import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/register.dart';

/// The things a new user can pick to work on first, after the prototype.
const _focusOptions = [
  ('spend', 'Manage my spendings', PhosphorIconsRegular.receipt),
  ('goals', 'Start saving goals', PhosphorIconsRegular.piggyBank),
  ('bills', 'Manage bills and scheduled payments', PhosphorIconsRegular.calendarCheck),
  ('shared', 'Manage shared finances', PhosphorIconsRegular.usersThree),
  ('budget', 'Build a monthly budget', PhosphorIconsRegular.chartPieSlice),
  ('clarity', 'Get financial clarity', PhosphorIconsRegular.eye),
];

/// Banks a new user can say they use. Nothing gets connected; it is kept
/// on the user doc for later features.
const _jordanBanks = [
  'Arab Bank',
  'Housing Bank',
  'Bank al Etihad',
  'Capital Bank',
  'Cairo Amman Bank',
  'Jordan Ahli Bank',
  'Jordan Kuwait Bank',
  'Bank of Jordan',
  'Jordan Islamic Bank',
  'Safwa Islamic Bank',
  'Arab Jordan Investment Bank',
  'Investbank',
  'Jordan Commercial Bank',
  'Société Générale de Banque – Jordanie',
  'Bank ABC',
];

/// Suggested starting split, as budget percentages: (label, examples, %).
const _split = [
  ('Necessities', 'Rent, groceries, bills', 50.0),
  ('Luxuries', 'Dining, fun, shopping', 30.0),
  ('Savings', 'Goals and extra payments', 20.0),
];

/// What a new user answered before creating their account. Nothing is
/// saved until the account exists: the OTP step writes it together with
/// the new user doc.
class OnboardingAnswers {
  const OnboardingAnswers({
    required this.username,
    this.income = 0,
    this.useSplit = false,
    this.focus = const [],
    this.banks = const [],
  });

  final String username;
  final double income;
  final bool useSplit;
  final List<String> focus;
  final List<String> banks;

  /// Fields for the new user doc.
  Map<String, dynamic> get userFields => {
    'totalIncome': income,
    'focus': focus,
    'banksUsed': banks,
  };

  /// This month's plan, when the user kept the suggested split. Shaped like
  /// a plan saved from Budgeting, plus the createdAt and currency that let
  /// handleBudgetCycleOnLogin carry it into the next cycle.
  Map<String, dynamic>? get budgetPlan => useSplit && income > 0
      ? {
          'income': income,
          'spending': _split[0].$3,
          'luxuries': _split[1].$3,
          'saving': _split[2].$3,
          'currency': 'JOD',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      : null;
}

/// A few questions before sign-up, after the prototype's onboarding: a
/// username, monthly income with a suggested budget split, what to work on
/// first, and which banks the user has. Then the account is created.
class OnboardingQuestions extends StatefulWidget {
  const OnboardingQuestions({super.key});

  @override
  State<OnboardingQuestions> createState() => _OnboardingQuestionsState();
}

class _OnboardingQuestionsState extends State<OnboardingQuestions> {
  static const _steps = 4;

  int _step = 0;
  final _usernameCtrl = TextEditingController();
  String? _usernameError;
  bool _checkingUsername = false;
  final _incomeCtrl = TextEditingController();
  bool _useSplit = true;
  final Set<String> _focus = {};
  final Set<String> _banks = {};

  String get _username => _usernameCtrl.text.trim();
  double get _income => double.tryParse(_incomeCtrl.text.trim()) ?? 0;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _username.isNotEmpty && !_checkingUsername,
    1 => _income > 0,
    2 => _focus.isNotEmpty,
    _ => true,
  };

  /// Same rules and lookup as the sign-up form, so a name accepted here is
  /// not refused there.
  Future<bool> _usernameAvailable() async {
    final username = _username;
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _usernameError =
          'Use only letters, numbers and underscores');
      return false;
    }
    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });
    try {
      bool taken;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usernames')
            .doc(username.toLowerCase())
            .get();
        taken = doc.exists;
      } catch (_) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        taken = query.docs.isNotEmpty;
      }
      if (!mounted) return false;
      setState(() => _usernameError = taken ? 'That username is taken' : null);
      return !taken;
    } catch (e) {
      if (mounted) {
        setState(() => _usernameError = "Couldn't check the username: $e");
      }
      return false;
    } finally {
      if (mounted) setState(() => _checkingUsername = false);
    }
  }

  OnboardingAnswers _answers() => OnboardingAnswers(
    username: _username,
    income: _income,
    useSplit: _useSplit,
    focus: _focus.toList(),
    banks: _banks.toList(),
  );

  void _createAccount(OnboardingAnswers? answers) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Register(answers: answers)),
    );
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == 0 && !await _usernameAvailable()) return;
    if (_step < _steps - 1) {
      setState(() => _step++);
    } else {
      _createAccount(_answers());
    }
  }

  /// Past the username step, Skip keeps the username and drops the rest.
  void _skip() {
    FocusScope.of(context).unfocus();
    _createAccount(
      _step == 0 ? null : OnboardingAnswers(username: _username),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
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
                        2 => _focusStep(),
                        _ => _banksStep(),
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
                    label: _step == _steps - 1 ? 'Create your account' : 'Continue',
                    loading: _checkingUsername,
                    onPressed: _canContinue ? _next : null,
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
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.sm,
        VestaSpace.sm,
        VestaSpace.sm,
        0,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _step == 0
                  ? Navigator.of(context).maybePop()
                  : setState(() => _step--),
              icon: const Icon(PhosphorIconsRegular.arrowLeft),
              tooltip: 'Back',
            ),
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
          TextButton(onPressed: _skip, child: const Text('Skip')),
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
        const SizedBox(height: VestaSpace.xl),
        TextField(
          controller: _usernameCtrl,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Choose a username',
            prefixIcon: const Icon(PhosphorIconsRegular.userCircle),
            errorText: _usernameError,
          ),
          onChanged: (_) => setState(() => _usernameError = null),
          onSubmitted: (_) => _canContinue ? _next() : null,
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
          'Nice to meet you, $_username. '
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
        const SizedBox(height: VestaSpace.sm),
        Row(
          children: [
            Icon(PhosphorIconsRegular.lockSimple, size: 14, color: v.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Stays on your phone until you create your account.',
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ),
          ],
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
          _ChoiceRow(
            label: label,
            leading: Icon(icon, size: 20),
            selected: _focus.contains(id),
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

  Widget _banksStep() {
    final v = context.vesta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Which banks do you use?', style: headingStyle(22)),
        const SizedBox(height: VestaSpace.sm),
        Text(
          'Pick any that apply. Nothing gets connected; it helps us set '
          'Vesta up around your accounts.',
          style: TextStyle(fontSize: 14, color: v.muted),
        ),
        const SizedBox(height: VestaSpace.xl),
        for (final bank in _jordanBanks) ...[
          _ChoiceRow(
            label: bank,
            leading: BankBadge(bank, size: 28),
            selected: _banks.contains(bank),
            onTap: () => setState(() {
              if (!_banks.remove(bank)) _banks.add(bank);
            }),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// A tappable option with a round tick on the right.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconTheme.merge(
                data: IconThemeData(color: selected ? v.tintText : null),
                child: leading,
              ),
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
