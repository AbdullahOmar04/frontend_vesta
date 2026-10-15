import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

/// A total plus the savings / necessities / luxuries split, in percent.
typedef BudgetSplit = ({double total, List<double> percents});

/// The prototype's "Your budget plan" pop-up for the signed-in user:
/// monthly income split into savings, necessities and luxuries, each as an
/// amount and a percentage. True when a plan was saved.
Future<bool> showBudgetPlanDialog(BuildContext context) {
  return showBudgetSplitDialog(
    context,
    title: 'Your budget plan',
    totalLabel: 'Total monthly income',
    load: _loadPersonalPlan,
    save: _savePersonalPlan,
  );
}

/// The same pop-up for any budget: [load] gives the starting figures,
/// [save] stores them. True when saved.
Future<bool> showBudgetSplitDialog(
  BuildContext context, {
  required String title,
  required String totalLabel,
  required Future<BudgetSplit> Function() load,
  required Future<void> Function(BudgetSplit split) save,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _BudgetPlanDialog(
      title: title,
      totalLabel: totalLabel,
      load: load,
      save: save,
    ),
  );
  return saved == true;
}

Future<BudgetSplit> _loadPersonalPlan() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final results = await Future.wait([
    userRef.collection('budget').doc(_monthId()).get(),
    userRef.get(),
  ]);
  final plan = results[0].data() ?? const {};
  final user = results[1].data() ?? const {};
  double n(Object? v) => double.tryParse('${v ?? 0}') ?? 0;
  return (
    total: n(user['totalIncome']),
    percents: [n(plan['saving']), n(plan['spending']), n(plan['luxuries'])],
  );
}

Future<void> _savePersonalPlan(BudgetSplit split) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  await userRef.collection('budget').doc(_monthId()).set({
    'income': split.total,
    'saving': split.percents[0],
    'spending': split.percents[1],
    'luxuries': split.percents[2],
    'updatedAt': FieldValue.serverTimestamp(),
    // Merge, so the cycle fields handleBudgetCycleOnLogin wrote
    // (currency, startDate, endDate, createdAt) survive a save.
  }, SetOptions(merge: true));
  // Only touch the user doc when the income really changed: rewriting it
  // stalls the screens that stream it.
  final stored =
      double.tryParse('${(await userRef.get()).data()?['totalIncome'] ?? 0}') ??
      0;
  if (split.total != stored) {
    await userRef.update({'totalIncome': split.total});
  }
}

/// This month's budget doc id, as the rest of the app names it.
String _monthId() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}";
}

class _BudgetPlanDialog extends StatefulWidget {
  const _BudgetPlanDialog({
    required this.title,
    required this.totalLabel,
    required this.load,
    required this.save,
  });

  final String title;
  final String totalLabel;
  final Future<BudgetSplit> Function() load;
  final Future<void> Function(BudgetSplit split) save;

  @override
  State<_BudgetPlanDialog> createState() => _BudgetPlanDialogState();
}

class _BudgetPlanDialogState extends State<_BudgetPlanDialog> {
  final _income = TextEditingController();

  // Savings, necessities, luxuries: the stored fields are percentages
  // ("saving", "spending", "luxuries"); amounts follow from the income.
  final _amounts = List.generate(3, (_) => TextEditingController());
  final _percents = List.generate(3, (_) => TextEditingController());

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _income.dispose();
    for (final c in [..._amounts, ..._percents]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final split = await widget.load();
      _income.text = _fmt(split.total);
      for (var i = 0; i < 3; i++) {
        final p = i < split.percents.length ? split.percents[i] : 0.0;
        _percents[i].text = _fmt(p);
        _amounts[i].text = _fmt(split.total * p / 100);
      }
    } catch (e) {
      debugPrint('⚠️ Error loading the budget plan: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Whole numbers without decimals, others to two places.
  static String _fmt(double v) {
    if (v == 0) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  double get _incomeValue => _num(_income);

  void _onIncome(String _) {
    // Keep the split, move the amounts
    for (var i = 0; i < 3; i++) {
      _amounts[i].text = _fmt(_incomeValue * _num(_percents[i]) / 100);
    }
    setState(() {});
  }

  void _onAmount(int i) {
    final income = _incomeValue;
    _percents[i].text = income > 0
        ? _fmt(
            double.parse((_num(_amounts[i]) / income * 100).toStringAsFixed(1)),
          )
        : '';
    setState(() {});
  }

  void _onPercent(int i) {
    _amounts[i].text = _fmt(_incomeValue * _num(_percents[i]) / 100);
    setState(() {});
  }

  double get _totalPercent =>
      _percents.fold(0.0, (total, c) => total + _num(c));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.save((
        total: _incomeValue,
        percents: [for (final c in _percents) _num(c)],
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't save the plan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalPercent;
    final valid = _incomeValue > 0 && total <= 100.05;
    return VestaDialog(
      title: widget.title,
      content: _loading
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : _form(total),
      confirmLabel: 'Save plan',
      onConfirm: valid && !_loading ? _save : null,
      loading: _saving,
    );
  }

  Widget _form(double total) {
    final v = context.vesta;
    final colors = [v.bucketSavings, v.bucketEssential, v.bucketLuxury];
    const labels = ['Savings', 'Necessities', 'Luxuries'];
    final amountFormat = FilteringTextInputFormatter.allow(
      RegExp(r'^\d*\.?\d{0,2}'),
    );
    final income = _incomeValue;
    final planned = income * total / 100;
    final left = income - planned;

    final (String status, Color statusColor) = income <= 0
        ? ('Enter an amount to plan it.', v.muted)
        : total > 100.05
        ? ('Over by ${formatMoney(-left)}', v.neg)
        : left.abs() < 0.01
        ? ('All of it is planned', v.pos)
        : ('${formatMoney(left)} left to plan', v.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.totalLabel, style: TextStyle(fontSize: 12, color: v.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: _income,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [amountFormat],
          style: amountStyle(22),
          onChanged: _onIncome,
          decoration: InputDecoration(
            prefixIcon: const CurrencyPrefix(size: 14),
            prefixIconConstraints: currencyPrefixConstraints,
            hintText: '0',
          ),
        ),
        const SizedBox(height: VestaSpace.lg),
        Row(
          children: [
            const Spacer(),
            SizedBox(
              width: 104,
              child: Text(
                'Amount',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: Text(
                '%',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: VestaSpace.sm),
                Expanded(child: Text(labels[i])),
                SizedBox(
                  width: 104,
                  child: TextField(
                    controller: _amounts[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [amountFormat],
                    style: amountStyle(14),
                    onChanged: (_) => _onAmount(i),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const CurrencyPrefix(size: 10, left: 10),
                      prefixIconConstraints: currencyPrefixConstraints,
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _percents[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}\.?\d{0,1}'),
                      ),
                    ],
                    textAlign: TextAlign.right,
                    style: amountStyle(14),
                    onChanged: (_) => _onPercent(i),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: '%',
                      suffixStyle: TextStyle(fontSize: 11, color: v.muted),
                      hintText: '0',
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: VestaSpace.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 3; i++)
                  if (_num(_percents[i]) > 0)
                    Expanded(
                      flex: (_num(_percents[i]).clamp(0, 100) * 10).round(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: ColoredBox(color: colors[i]),
                      ),
                    ),
                if (total < 100)
                  Expanded(
                    flex: ((100 - total) * 10).round(),
                    child: ColoredBox(color: v.track),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: VestaSpace.md),
        Text(status, style: TextStyle(fontSize: 12, color: statusColor)),
      ],
    );
  }
}
