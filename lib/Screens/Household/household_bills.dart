import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icon_picker.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Bills/bills_data.dart';
import 'package:frontend_vesta/Screens/Household/household_data.dart';
import 'package:frontend_vesta/Screens/Household/household_manage.dart';
import 'package:intl/intl.dart';

/// The prototype's household "Upcoming payments": shared bills by due date,
/// each with who pays what.
class HouseholdBillsCard extends StatefulWidget {
  const HouseholdBillsCard({
    super.key,
    required this.householdId,
    required this.bills,
    required this.members,
  });

  final String householdId;
  final List<HouseholdBill> bills;
  final List<HouseholdMember> members;

  @override
  State<HouseholdBillsCard> createState() => _HouseholdBillsCardState();
}

class _HouseholdBillsCardState extends State<HouseholdBillsCard> {
  bool _removing = false;

  Future<void> _remove(HouseholdBill bill) async {
    final sure = await confirmDialog(
      context,
      title: 'Delete this bill?',
      message: '"${bill.name}" will be removed for everyone.',
      confirmLabel: 'Delete',
    );
    if (!sure) return;
    try {
      await removeHouseholdBill(widget.householdId, bill.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Couldn't delete the bill: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final sorted = [...widget.bills]
      ..sort(
        (a, b) => UpcomingPayment.nextDueDate(
          a.dueDay,
          day,
        ).compareTo(UpcomingPayment.nextDueDate(b.dueDay, day)),
      );

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Upcoming payments',
            trailing: [
              AddRemoveButtons(
                onAdd: () => showHouseholdBillSheet(
                  context,
                  householdId: widget.householdId,
                  members: widget.members,
                ),
                addTooltip: 'Add a shared bill',
                removing: _removing,
                canRemove: widget.bills.isNotEmpty,
                removeTooltip: 'Remove a bill',
                onToggleRemove: () => setState(() => _removing = !_removing),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.xs),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VestaSpace.lg),
              child: Text(
                'No shared bills yet. Add rent, utilities, or subscriptions '
                'you split.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: v.muted),
              ),
            )
          else
            for (final bill in sorted) _row(bill, day),
        ],
      ),
    );
  }

  Widget _row(HouseholdBill bill, DateTime today) {
    final v = context.vesta;
    final palette = householdMemberColors(v);
    final due = UpcomingPayment.nextDueDate(bill.dueDay, today);
    final days = due.difference(today).inDays;
    final when = days == 0
        ? 'today'
        : days == 1
        ? 'tomorrow'
        : 'in $days days';
    final payers = [
      for (var i = 0; i < widget.members.length; i++)
        if ((bill.split[widget.members[i].uid] ?? 0) > 0)
          (widget.members[i], palette[i % palette.length]),
    ];

    return InkWell(
      onTap: _removing
          ? null
          : () => showHouseholdBillSheet(
              context,
              householdId: widget.householdId,
              members: widget.members,
              bill: bill,
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_removing) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RemoveBadge(onTap: () => _remove(bill)),
              ),
              const SizedBox(width: VestaSpace.md),
            ],
            IconTile(
              iconKey: bill.icon,
              fallback: PhosphorIconsRegular.receipt,
            ),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.name),
                            Text(
                              'Due ${DateFormat('MMM d').format(due)} · $when · '
                              'Monthly',
                              style: TextStyle(fontSize: 12, color: v.muted),
                            ),
                          ],
                        ),
                      ),
                      MoneyText(bill.amount),
                    ],
                  ),
                  if (payers.isNotEmpty) ...[
                    const SizedBox(height: VestaSpace.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (m, color) in payers)
                          Container(
                            padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
                            decoration: BoxDecoration(
                              color: v.raised,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MemberDot(name: m.name, color: color, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  m.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatMoney(bill.split[m.uid] ?? 0),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: v.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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

/// Add or edit a shared bill: name, icon, amount, due day, and the split.
Future<void> showHouseholdBillSheet(
  BuildContext context, {
  required String householdId,
  required List<HouseholdMember> members,
  HouseholdBill? bill,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _BillSheet(householdId: householdId, members: members, bill: bill),
  );
}

class _BillSheet extends StatefulWidget {
  const _BillSheet({
    required this.householdId,
    required this.members,
    this.bill,
  });

  final String householdId;
  final List<HouseholdMember> members;
  final HouseholdBill? bill;

  @override
  State<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends State<_BillSheet> {
  late final _name = TextEditingController(text: widget.bill?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.bill == null ? '' : _fmt(widget.bill!.amount),
  );
  late final _day = TextEditingController(
    text: widget.bill == null ? '' : '${widget.bill!.dueDay}',
  );
  late String _icon = widget.bill?.icon ?? 'receipt';
  late final Map<String, TextEditingController> _shares = {
    for (final m in widget.members)
      m.uid: TextEditingController(
        text: widget.bill == null ? '' : _fmt(widget.bill!.split[m.uid] ?? 0),
      ),
  };
  late bool _even = widget.bill == null || _isEven(widget.bill!);
  bool _saving = false;
  String? _error;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  bool _isEven(HouseholdBill b) {
    if (widget.members.isEmpty) return true;
    final each = b.amount / widget.members.length;
    return widget.members.every(
      (m) => ((b.split[m.uid] ?? 0) - each).abs() < 0.02,
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _amount, _day, ..._shares.values]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amountValue => double.tryParse(_amount.text.trim()) ?? 0;

  Map<String, double> _split() {
    if (_even) {
      final n = widget.members.length;
      // Round to fils and give the remainder to the first member
      final each = (_amountValue / n * 1000).floor() / 1000;
      final rest = _amountValue - each * n;
      return {
        for (var i = 0; i < n; i++)
          widget.members[i].uid: i == 0 ? each + rest : each,
      };
    }
    return {
      for (final e in _shares.entries)
        e.key: double.tryParse(e.value.text.trim()) ?? 0,
    };
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final day = int.tryParse(_day.text.trim()) ?? 0;
    final amount = _amountValue;
    final split = _split();
    final splitTotal = split.values.fold(0.0, (s, a) => s + a);
    final String? problem = name.isEmpty
        ? 'Give the bill a name.'
        : amount <= 0
        ? 'Enter the amount.'
        : day < 1 || day > 31
        ? 'Pick a due day from 1 to 31.'
        : (splitTotal - amount).abs() > 0.01
        ? 'The shares add up to ${formatMoney(splitTotal)}, not '
              '${formatMoney(amount)}.'
        : null;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _saving = true);
    try {
      await saveHouseholdBill(
        widget.householdId,
        HouseholdBill(
          id: widget.bill?.id ?? newHouseholdItemId(),
          name: name,
          amount: amount,
          dueDay: day,
          icon: _icon,
          split: split,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't save the bill: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final amountFormat = FilteringTextInputFormatter.allow(
      RegExp(r'^\d*\.?\d{0,3}'),
    );
    final palette = householdMemberColors(v);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          VestaSpace.gutter,
          0,
          VestaSpace.gutter,
          VestaSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.bill == null ? 'New shared bill' : 'Edit bill',
                    style: headingStyle(20),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIconsRegular.x, color: v.muted),
                ),
              ],
            ),
            const SizedBox(height: VestaSpace.md),
            Row(
              children: [
                IconTile(
                  iconKey: _icon,
                  size: 52,
                  fallback: PhosphorIconsRegular.receipt,
                  onTap: () async {
                    final key = await showIconPicker(context, selected: _icon);
                    if (key != null) setState(() => _icon = key);
                  },
                ),
                const SizedBox(width: VestaSpace.md),
                Expanded(
                  child: TextField(
                    controller: _name,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() => _error = null),
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Rent',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [amountFormat],
                    onChanged: (_) => setState(() => _error = null),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'JOD ',
                    ),
                  ),
                ),
                const SizedBox(width: VestaSpace.md),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _day,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (_) => setState(() => _error = null),
                    decoration: const InputDecoration(
                      labelText: 'Due day',
                      hintText: '1-31',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VestaSpace.md),
            VestaCard(
              padding: EdgeInsets.zero,
              child: ToggleRow(
                icon: PhosphorIconsRegular.usersThree,
                title: 'Split evenly',
                subtitle: _even && widget.members.isNotEmpty && _amountValue > 0
                    ? '${formatMoney(_amountValue / widget.members.length)} each'
                    : 'Or set what each member pays',
                value: _even,
                onChanged: (x) => setState(() {
                  _even = x;
                  _error = null;
                }),
              ),
            ),
            if (!_even) ...[
              const SizedBox(height: VestaSpace.md),
              for (var i = 0; i < widget.members.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      MemberDot(
                        name: widget.members[i].name,
                        color: palette[i % palette.length],
                        size: 26,
                      ),
                      const SizedBox(width: VestaSpace.md),
                      Expanded(
                        child: Text(
                          widget.members[i].uid == me
                              ? '${widget.members[i].name} (you)'
                              : widget.members[i].name,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _shares[widget.members[i].uid],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [amountFormat],
                          onChanged: (_) => setState(() => _error = null),
                          decoration: const InputDecoration(
                            isDense: true,
                            prefixText: 'JOD ',
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: VestaSpace.sm),
              Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
            ],
            const SizedBox(height: VestaSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: 'Cancel',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: widget.bill == null ? 'Add bill' : 'Save',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
