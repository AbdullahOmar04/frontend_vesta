import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icon_picker.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

/// The prototype's "New savings goal" pop-up. True when a goal was added:
/// to users/{uid}/savings, or wherever [save] puts it (household goals).
/// [save] gets the title, icon key, target, months, monthly amount and
/// target date.
Future<bool> showNewGoalDialog(
  BuildContext context, {
  Future<void> Function(NewGoal goal)? save,
}) async {
  final added = await showDialog<bool>(
    context: context,
    builder: (_) => _NewGoalDialog(save: save),
  );
  return added == true;
}

typedef NewGoal = ({
  String title,
  String icon,
  double target,
  int months,
  double monthly,
  DateTime targetDate,
});

/// Whole months from [from] to [to], at least one.
int monthsBetween(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day > from.day) months += 1;
  return months < 1 ? 1 : months;
}

/// [date] plus [months], clamped to the last day of the target month.
DateTime addMonths(DateTime date, int months) {
  final first = DateTime(date.year, date.month + months, 1);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, date.day.clamp(1, lastDay));
}

class _NewGoalDialog extends StatefulWidget {
  const _NewGoalDialog({this.save});

  final Future<void> Function(NewGoal goal)? save;

  @override
  State<_NewGoalDialog> createState() => _NewGoalDialogState();
}

class _NewGoalDialogState extends State<_NewGoalDialog> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _monthly = TextEditingController();
  final _months = TextEditingController(text: '6');

  String _icon = 'piggy-bank';
  late DateTime _date = addMonths(DateTime.now(), 6);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _target, _monthly, _months]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _targetValue => double.tryParse(_target.text.trim()) ?? 0;
  double get _monthlyValue => double.tryParse(_monthly.text.trim()) ?? 0;
  int get _monthsValue => int.tryParse(_months.text.trim()) ?? 0;

  static String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  // The four figures follow each other: target / months = per month, and
  // months and the target date move together.
  void _onTarget(String _) {
    if (_monthsValue > 0 && _targetValue > 0) {
      _monthly.text = _money(_targetValue / _monthsValue);
    }
    setState(() => _error = null);
  }

  void _onMonthly(String _) {
    if (_monthlyValue > 0 && _targetValue > 0) {
      final months = (_targetValue / _monthlyValue).ceil();
      _months.text = '$months';
      _date = addMonths(DateTime.now(), months);
    }
    setState(() => _error = null);
  }

  void _onMonths(String _) {
    final months = _monthsValue;
    if (months > 0) {
      _date = addMonths(DateTime.now(), months);
      if (_targetValue > 0) _monthly.text = _money(_targetValue / months);
    }
    setState(() => _error = null);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    final months = monthsBetween(now, picked);
    setState(() {
      _date = picked;
      _months.text = '$months';
      if (_targetValue > 0) _monthly.text = _money(_targetValue / months);
      _error = null;
    });
  }

  Future<void> _pickIcon() async {
    final key = await showIconPicker(context, selected: _icon);
    if (key != null) setState(() => _icon = key);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = _targetValue;
    final months = _monthsValue;
    final String? problem = name.isEmpty
        ? 'Give the goal a name.'
        : target <= 0
        ? 'Enter how much you want to save.'
        : months < 1
        ? 'Enter how many months, or pick a target date.'
        : null;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    final monthly = _monthlyValue > 0 ? _monthlyValue : target / months;
    try {
      if (widget.save != null) {
        await widget.save!((
          title: name,
          icon: _icon,
          target: target,
          months: months,
          monthly: double.parse(monthly.toStringAsFixed(2)),
          targetDate: _date,
        ));
        if (mounted) Navigator.pop(context, true);
        return;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('savings')
          .add({
            'goalTitle': name,
            'icon': _icon,
            'targetAmount': target,
            'currentAmount': 0.0,
            'durationMonths': months,
            'monthlyAmount': double.parse(monthly.toStringAsFixed(2)),
            'targetDate': Timestamp.fromDate(_date),
            'createdAt': FieldValue.serverTimestamp(),
            'isCompleted': false,
          });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "Couldn't add the goal: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final amountFormat = FilteringTextInputFormatter.allow(
      RegExp(r'^\d*\.?\d{0,2}'),
    );
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, color: v.muted)),
    );
    String two(int n) => n.toString().padLeft(2, '0');

    return VestaDialog(
      title: 'New savings goal',
      cancelButton: false,
      confirmLabel: 'Add goal',
      onConfirm: _save,
      loading: _saving,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(iconKey: _icon, size: 52, onTap: _pickIcon),
              const SizedBox(width: VestaSpace.md),
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 32,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(
                    hintText: 'Goal name',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.lg),
          label('Total target amount'),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [amountFormat],
            onChanged: _onTarget,
            decoration: InputDecoration(
              prefixIcon: const CurrencyPrefix(),
              prefixIconConstraints: currencyPrefixConstraints,
              hintText: '0.00',
            ),
          ),
          const SizedBox(height: VestaSpace.md),
          label('Target amount per month'),
          TextField(
            controller: _monthly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [amountFormat],
            onChanged: _onMonthly,
            decoration: InputDecoration(
              prefixIcon: const CurrencyPrefix(),
              prefixIconConstraints: currencyPrefixConstraints,
              hintText: '0.00',
            ),
          ),
          const SizedBox(height: VestaSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label('Months'),
                    TextField(
                      controller: _months,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: _onMonths,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label('Target date'),
                    InkWell(
                      borderRadius: BorderRadius.circular(VestaRadius.md),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          suffixIcon: Icon(
                            PhosphorIconsRegular.calendarBlank,
                            size: 18,
                            color: v.accentInk,
                          ),
                        ),
                        child: Text(
                          '${two(_date.day)} / ${two(_date.month)} / ${_date.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: VestaSpace.md),
            Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
          ],
        ],
      ),
    );
  }
}
