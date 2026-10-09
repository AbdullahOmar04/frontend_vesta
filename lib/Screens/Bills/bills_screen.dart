import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Bills/bills_data.dart';
import 'package:intl/intl.dart';

/// Opens the add/edit bill sheet; true when something was saved or deleted.
Future<bool> showBillSheet(BuildContext context, [UpcomingPayment? bill]) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BillSheet(bill: bill),
  );
  return changed == true;
}

/// Asks before a bill is deleted.
Future<bool> confirmDeleteBill(BuildContext context, String title) {
  return confirmDialog(
    context,
    title: 'Delete this bill?',
    message: '"$title" will be removed.',
    confirmLabel: 'Delete',
  );
}

/// Bills & subscriptions, after the prototype: what is still due this
/// month, the monthly subscriptions total, and every bill and standing
/// order by due date. Bills can be added, edited and marked autopay;
/// standing orders come from the bank and are read-only.
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  bool _loading = true;
  bool _removing = false;
  List<UpcomingPayment> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final payments = await loadUpcomingPayments();
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading bills: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _edit([UpcomingPayment? bill]) async {
    if (await showBillSheet(context, bill)) _load();
  }

  Future<void> _remove(UpcomingPayment bill) async {
    if (!await confirmDeleteBill(context, bill.title)) return;
    try {
      await deleteBill(bill.billId!);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't delete the bill: $e")),
      );
    }
  }

  Future<void> _toggleAutopay(UpcomingPayment bill, bool on) async {
    try {
      await setBillAutopay(bill.billId!, on);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update the bill: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VestaAppBar(title: 'Bills & subscriptions'),
      body: VestaBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _load, child: _content()),
      ),
    );
  }

  Widget _content() {
    final v = context.vesta;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    // A bill whose day has gone this month counts as done for the month
    bool doneThisMonth(UpcomingPayment p) =>
        p.isBill &&
        UpcomingPayment.dueDateIn(now.year, now.month, p.dueDay!)
            .isBefore(today);

    final dueThisMonth = _payments
        .where((p) =>
            !p.incoming &&
            !doneThisMonth(p) &&
            p.nextDate != null &&
            !p.nextDate!.isBefore(today) &&
            !p.nextDate!.isAfter(monthEnd))
        .fold(0.0, (s, p) => s + p.amount);
    final subscriptions = _payments
        .where((p) => p.subscription)
        .fold(0.0, (s, p) => s + p.amount);

    final upcoming = _payments.where((p) => !doneThisMonth(p)).toList();
    final done = _payments.where(doneThisMonth).toList()
      ..sort((a, b) => a.dueDay!.compareTo(b.dueDay!));
    final rows = [...upcoming, ...done];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        VestaSpace.sm,
        VestaSpace.gutter,
        VestaSpace.xl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Still due this month',
                amount: dueThisMonth,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Subscriptions',
                amount: subscriptions,
                suffix: '/mo',
              ),
            ),
          ],
        ),
        const SizedBox(height: VestaSpace.lg),
        if (rows.isEmpty)
          VestaCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: VestaSpace.lg),
              child: Column(
                children: [
                  Icon(PhosphorIconsRegular.receipt, size: 40, color: v.muted),
                  const SizedBox(height: VestaSpace.md),
                  Text('No bills yet', style: headingStyle(17)),
                  const SizedBox(height: VestaSpace.xs),
                  Text(
                    'Add rent, phone, subscriptions and anything else you '
                    'pay each month. Standing orders from your bank show '
                    'up here too.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                  const SizedBox(height: VestaSpace.lg),
                  PrimaryButton(label: 'Add a bill', onPressed: () => _edit()),
                ],
              ),
            ),
          )
        else
          VestaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(VestaSpace.lg, 12, 10, 4),
                  child: SectionHeader(
                    title: 'Bills',
                    trailing: [
                      AddRemoveButtons(
                        onAdd: () => _edit(),
                        addTooltip: 'Add a bill',
                        removing: _removing,
                        canRemove: rows.any((p) => p.isBill),
                        removeTooltip: 'Remove a bill',
                        onToggleRemove: () =>
                            setState(() => _removing = !_removing),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: v.divider),
                  _PaymentRow(
                    payment: rows[i],
                    done: doneThisMonth(rows[i]),
                    today: today,
                    onRemove: _removing && rows[i].isBill
                        ? () => _remove(rows[i])
                        : null,
                    onTap: rows[i].isBill ? () => _edit(rows[i]) : null,
                    onAutopay: rows[i].isBill
                        ? (on) => _toggleAutopay(rows[i], on)
                        : null,
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: VestaSpace.md),
        Text(
          'Toggle on to mark a bill as autopay. Standing orders are set up '
          'at your bank.',
          style: TextStyle(fontSize: 12, color: v.muted),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.amount, this.suffix});

  final String label;
  final double amount;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return VestaCard(
      radius: VestaRadius.lg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: v.muted)),
          const SizedBox(height: VestaSpace.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              MoneyText(amount, size: 19),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    suffix!,
                    style: TextStyle(fontSize: 12, color: v.muted),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Date block, name and status, amount, and the autopay switch for bills
/// (standing orders get a tag instead).
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.done,
    required this.today,
    this.onTap,
    this.onAutopay,
    this.onRemove,
  });

  final UpcomingPayment payment;
  final bool done;
  final DateTime today;
  final VoidCallback? onTap;

  /// Set while the list is in remove mode (bills only).
  final VoidCallback? onRemove;
  final ValueChanged<bool>? onAutopay;

  String _status() {
    final p = payment;
    if (done) {
      return p.autopay
          ? 'Paid'
          : 'Was due ${DateFormat('MMM d').format(UpcomingPayment.dueDateIn(today.year, today.month, p.dueDay!))}';
    }
    final parts = <String>[];
    if (p.nextDate == null) {
      parts.add('No date set');
    } else {
      final next = p.nextDate!;
      final days = DateTime(next.year, next.month, next.day)
          .difference(today)
          .inDays;
      parts.add(switch (days) {
        < 0 => 'Was due ${DateFormat('MMM d').format(next)}',
        0 => 'Due today',
        1 => 'Due tomorrow',
        _ => 'Due in $days days',
      });
    }
    if (p.incoming) parts.add('incoming');
    if (p.autopay && p.isBill) parts.add('autopay');
    if (!p.isBill && p.frequency != null) parts.add(p.frequency!);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final p = payment;
    // Done bills show this month's date, the rest their next one
    final date = done
        ? UpcomingPayment.dueDateIn(today.year, today.month, p.dueDay!)
        : p.nextDate;
    final dueSoon = !done &&
        !p.autopay &&
        p.nextDate != null &&
        p.nextDate!.difference(today).inDays <= 5;

    return Opacity(
      opacity: done ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(VestaSpace.lg, 12, 10, 12),
          child: Row(
            children: [
              if (onRemove != null) ...[
                RemoveBadge(onTap: onRemove),
                const SizedBox(width: VestaSpace.md),
              ],
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Text(
                      date == null ? '—' : DateFormat('MMM').format(date).toUpperCase(),
                      style: TextStyle(fontSize: 10, color: v.muted),
                    ),
                    Text(
                      date == null ? '' : '${date.day}',
                      style: amountStyle(18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VestaSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _status(),
                      style: TextStyle(
                        fontSize: 12,
                        color: dueSoon ? v.accentInk : v.muted,
                      ),
                    ),
                    if (!p.isBill || p.accountName != null)
                      Text(
                        p.accountName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: v.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: VestaSpace.sm),
              MoneyText(
                p.amount,
                currency: p.currency,
                showPlus: p.incoming,
                color: p.incoming ? v.pos : null,
              ),
              const SizedBox(width: VestaSpace.xs),
              SizedBox(
                width: 64,
                child: Center(
                  child: p.isBill
                      ? Switch(value: p.autopay, onChanged: onAutopay)
                      : TagChip.pill('Bank', icon: PhosphorIconsRegular.bank),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add or edit a bill. Pops true when something was saved or deleted.
class _BillSheet extends StatefulWidget {
  const _BillSheet({this.bill});

  final UpcomingPayment? bill;

  @override
  State<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends State<_BillSheet> {
  late final _name = TextEditingController(text: widget.bill?.title ?? '');
  late final _amount = TextEditingController(
    text: widget.bill == null ? '' : widget.bill!.amount.toStringAsFixed(2),
  );
  late int _dueDay = widget.bill?.dueDay ?? DateTime.now().day;
  late bool _subscription = widget.bill?.subscription ?? false;
  late bool _autopay = widget.bill?.autopay ?? false;
  late String? _accountId = widget.bill?.accountId;
  late String? _category = widget.bill?.category;
  List<(String, String)> _accounts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    loadBillAccounts().then((a) {
      if (mounted) setState(() => _accounts = a);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      (double.tryParse(_amount.text.trim()) ?? 0) > 0;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await saveBill(
        billId: widget.bill?.billId,
        name: _name.text.trim(),
        amount: double.parse(_amount.text.trim()),
        dueDay: _dueDay,
        subscription: _subscription,
        autopay: _autopay,
        accountId: _accountId,
        category: _category,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save the bill: $e")),
      );
    }
  }

  Future<void> _delete() async {
    if (!await confirmDeleteBill(context, widget.bill!.title)) return;
    setState(() => _saving = true);
    try {
      await deleteBill(widget.bill!.billId!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't delete the bill: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final categories = categoryLabels;
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
            Text(
              widget.bill == null ? 'Add a bill' : 'Edit bill',
              style: headingStyle(20),
            ),
            const SizedBox(height: VestaSpace.lg),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Rent, phone, Netflix...',
              ),
              onChanged: (_) => setState(() {}),
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'JOD ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: VestaSpace.md),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _dueDay,
                    decoration: const InputDecoration(labelText: 'Due every month on'),
                    items: [
                      for (var d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text('Day $d')),
                    ],
                    onChanged: (d) => setState(() => _dueDay = d ?? _dueDay),
                  ),
                ),
              ],
            ),
            if (_dueDay > 28)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'In shorter months it falls on the last day.',
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
              ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              // Rebuilt once the accounts arrive, so an edited bill shows
              // its account instead of 'Not set'
              key: ValueKey(_accounts.length),
              initialValue: _accounts.any((a) => a.$1 == _accountId)
                  ? _accountId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Paid from'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                for (final (id, label) in _accounts)
                  DropdownMenuItem(value: id, child: Text(label)),
              ],
              onChanged: (id) => setState(() => _accountId = id),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              initialValue: categories.contains(_category) ? _category : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                for (final c in categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: VestaSpace.lg),
            VestaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ToggleRow(
                    title: 'Subscription',
                    subtitle: 'Counted in your monthly subscriptions',
                    icon: PhosphorIconsRegular.arrowsClockwise,
                    value: _subscription,
                    onChanged: (on) => setState(() => _subscription = on),
                  ),
                  Divider(height: 1, color: v.divider),
                  ToggleRow(
                    title: 'Autopay',
                    subtitle: 'Comes out automatically',
                    icon: PhosphorIconsRegular.calendarCheck,
                    value: _autopay,
                    onChanged: (on) => setState(() => _autopay = on),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VestaSpace.lg),
            PrimaryButton(
              label: widget.bill == null ? 'Add bill' : 'Save',
              loading: _saving,
              onPressed: _valid && !_saving ? _save : null,
            ),
            if (widget.bill != null) ...[
              const SizedBox(height: VestaSpace.sm),
              TextButton(
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: v.neg),
                child: const Text('Delete bill'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
