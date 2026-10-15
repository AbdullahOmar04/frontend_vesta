import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icon_picker.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Household/household_data.dart';
import 'package:frontend_vesta/Screens/Household/household_manage.dart';
import 'package:frontend_vesta/Screens/Savings/new_goal_dialog.dart';
import 'package:intl/intl.dart';

/// The prototype's household Savings tab: what each member shares, what is
/// in goals, this month's savings, and the shared goals.
class HouseholdSavingsTab extends StatefulWidget {
  const HouseholdSavingsTab({
    super.key,
    required this.householdId,
    required this.savings,
    required this.members,
  });

  final String householdId;
  final HouseholdSavings savings;
  final List<HouseholdMember> members;

  @override
  State<HouseholdSavingsTab> createState() => _HouseholdSavingsTabState();
}

class _HouseholdSavingsTabState extends State<HouseholdSavingsTab> {
  bool _removing = false;

  String? get _me => FirebaseAuth.instance.currentUser?.uid;

  void _fail(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
  }

  Future<void> _addGoal() async {
    final added = await showNewGoalDialog(
      context,
      save: (g) => addHouseholdGoal(
        widget.householdId,
        title: g.title,
        icon: g.icon,
        target: g.target,
        monthly: g.monthly,
        targetDate: g.targetDate,
      ),
    );
    if (added && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shared goal added')));
    }
  }

  Future<void> _removeGoal(HouseholdGoal goal) async {
    final sure = await confirmDialog(
      context,
      title: 'Delete ${goal.title}?',
      message:
          "It's removed for everyone. What members put in goes back to their "
          'free share.',
      confirmLabel: 'Delete',
    );
    if (!sure) return;
    try {
      await removeHouseholdGoal(widget.householdId, goal.id);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_summaryCard(), const SizedBox(height: 14), _goalsCard()],
    );
  }

  Widget _summaryCard() {
    final v = context.vesta;
    final s = widget.savings;
    final palette = householdMemberColors(v);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final plan = s.monthlyPlan;
    final savedThisMonth = s.savedIn(monthKey()).clamp(0, double.infinity);
    final toGo = (plan - savedThisMonth).clamp(0, double.infinity);
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
    final freeTotal = widget.members.fold(
      0.0,
      (sum, m) => sum + s.freeFor(m.uid),
    );

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Total saved', style: TextStyle(fontSize: 12, color: v.muted)),
          const SizedBox(height: VestaSpace.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: MoneyText.hero(s.totalSaved, size: 30),
          ),
          const SizedBox(height: VestaSpace.md),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Shared by members',
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
              ),
              Text(
                'Allocated / shared',
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.sm),
          for (var i = 0; i < widget.members.length; i++)
            _memberShare(widget.members[i], palette[i % palette.length]),
          const SizedBox(height: VestaSpace.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Left to allocate',
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
              ),
              MoneyText(freeTotal, color: v.pos),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          OutlinedButton.icon(
            onPressed: _editShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: v.accentInk,
              side: BorderSide(color: v.accentInk),
              minimumSize: const Size.fromHeight(46),
            ),
            icon: const Icon(PhosphorIconsRegular.handCoins, size: 18),
            label: const Text('Set how much you share'),
          ),
          const SizedBox(height: VestaSpace.md),
          const Divider(),
          const SizedBox(height: 10),
          if (plan <= 0)
            Text(
              "Set what you plan to add each month to track the household's "
              'monthly savings.',
              style: TextStyle(fontSize: 12, color: v.muted),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$monthName savings goal ${formatMoney(plan)}',
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                ),
                toGo <= 0
                    ? TagChip('Reached', color: v.pos)
                    : TagChip('Not yet', color: v.bucketLuxury),
              ],
            ),
            const SizedBox(height: VestaSpace.sm),
            VestaProgressBar(
              value: (savedThisMonth / plan).clamp(0, 1).toDouble(),
            ),
            const SizedBox(height: VestaSpace.sm),
            Text(
              toGo <= 0
                  ? '${formatMoney(savedThisMonth.toDouble())} saved this month.'
                  : '${formatMoney(savedThisMonth.toDouble())} saved so far, '
                        '${formatMoney(toGo.toDouble())} to go with '
                        '${daysLeft == 1 ? '1 day' : '$daysLeft days'} left.',
              style: TextStyle(fontSize: 12, color: v.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberShare(HouseholdMember m, Color color) {
    final v = context.vesta;
    final s = widget.savings;
    final share = s.shares[m.uid];
    final shared = share?.amount ?? 0;
    final allocated = s.allocatedBy(m.uid);
    return Padding(
      padding: const EdgeInsets.only(bottom: VestaSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberDot(name: m.name, photo: m.photo, color: color),
          const SizedBox(width: VestaSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.uid == _me ? '${m.name} (you)' : m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    MoneyText(allocated, size: 13),
                    Text(' / ', style: TextStyle(fontSize: 13, color: v.muted)),
                    MoneyText(shared, size: 13, color: v.muted),
                  ],
                ),
                const SizedBox(height: 4),
                VestaProgressBar(
                  value: shared > 0 ? (allocated / shared).clamp(0, 1) : 0,
                  height: 3,
                  color: color,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (share?.monthly ?? 0) > 0
                            ? 'Plans ${formatMoney(share!.monthly)} a month'
                            : 'No monthly plan yet',
                        style: TextStyle(fontSize: 11, color: v.muted),
                      ),
                    ),
                    Text(
                      '${formatMoney(s.freeFor(m.uid))} free',
                      style: TextStyle(fontSize: 11, color: v.pos),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalsCard() {
    final v = context.vesta;
    final goals = widget.savings.goals;
    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Saving goals',
            trailing: [
              AddRemoveButtons(
                onAdd: _addGoal,
                addTooltip: 'New shared goal',
                removing: _removing,
                canRemove: goals.isNotEmpty,
                removeTooltip: 'Remove a goal',
                onToggleRemove: () => setState(() => _removing = !_removing),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.xs),
          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VestaSpace.lg),
              child: Text(
                'No shared goals yet. Add one to save for something '
                'together.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: v.muted),
              ),
            )
          else
            for (var i = 0; i < goals.length; i++) _goalRow(goals[i], i == 0),
        ],
      ),
    );
  }

  Widget _goalRow(HouseholdGoal goal, bool first) {
    final v = context.vesta;
    final progress = goal.target > 0 ? goal.saved / goal.target : 0.0;
    return InkWell(
      onTap: _removing ? null : () => _contribute(goal),
      child: Container(
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: v.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (_removing) ...[
              RemoveBadge(onTap: () => _removeGoal(goal)),
              const SizedBox(width: VestaSpace.md),
            ],
            IconTile(iconKey: goal.icon),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: amountStyle(13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  VestaProgressBar(
                    value: progress.clamp(0, 1).toDouble(),
                    height: 4,
                    color: progress >= 1 ? v.pos : v.accentInk,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatMoney(goal.saved)} of ${formatMoney(goal.target)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (goal.targetDate != null)
                        Text(
                          'By ${DateFormat('MMM yyyy').format(goal.targetDate!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: VestaSpace.sm),
            Icon(PhosphorIconsRegular.caretRight, size: 16, color: v.muted),
          ],
        ),
      ),
    );
  }

  /// Your total share and monthly plan.
  Future<void> _editShare() async {
    final me = _me;
    if (me == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ShareDialog(
        householdId: widget.householdId,
        current: widget.savings.shares[me],
        allocated: widget.savings.allocatedBy(me),
      ),
    );
  }

  /// Put some of your free share into a goal, or take it back out.
  Future<void> _contribute(HouseholdGoal goal) async {
    final me = _me;
    if (me == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ContributeDialog(
        householdId: widget.householdId,
        goal: goal,
        free: widget.savings.freeFor(me),
        mine: goal.contributions[me] ?? 0,
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

final _moneyFormat = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d{0,2}'),
);

/// "Your savings share": the total you share and the monthly plan. A widget
/// of its own so its fields are disposed only once the pop-up is gone.
class _ShareDialog extends StatefulWidget {
  const _ShareDialog({
    required this.householdId,
    required this.current,
    required this.allocated,
  });

  final String householdId;
  final SavingsShare? current;
  final double allocated;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  late final _amount = TextEditingController(
    text: (widget.current?.amount ?? 0) == 0
        ? ''
        : _fmt(widget.current!.amount),
  );
  late final _monthly = TextEditingController(
    text: (widget.current?.monthly ?? 0) == 0
        ? ''
        : _fmt(widget.current!.monthly),
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _monthly.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = double.tryParse(_amount.text.trim()) ?? 0;
    final m = double.tryParse(_monthly.text.trim()) ?? 0;
    if (a < widget.allocated) {
      setState(
        () => _error =
            'You already put ${formatMoney(widget.allocated)} into goals, so '
            'share at least that.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await setMySavingsShare(widget.householdId, amount: a, monthly: m);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't save: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return VestaDialog(
      title: 'Your savings share',
      message:
          'How much of your savings you share with the household, and what '
          'you plan to add each month. Everyone in it sees these.',
      confirmLabel: 'Save',
      loading: _saving,
      onConfirm: _save,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_moneyFormat],
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              labelText: 'Amount you share',
              prefixText: 'JOD ',
            ),
          ),
          const SizedBox(height: VestaSpace.md),
          TextField(
            controller: _monthly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_moneyFormat],
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              labelText: 'You plan to add each month',
              prefixText: 'JOD ',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: VestaSpace.sm),
            Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
          ],
        ],
      ),
    );
  }
}

/// Add to a shared goal from your free share, or take some back out.
class _ContributeDialog extends StatefulWidget {
  const _ContributeDialog({
    required this.householdId,
    required this.goal,
    required this.free,
    required this.mine,
  });

  final String householdId;
  final HouseholdGoal goal;
  final double free;
  final double mine;

  @override
  State<_ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<_ContributeDialog> {
  final _amount = TextEditingController();
  bool _takeOut = false;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final limit = _takeOut ? widget.mine : widget.free;
    if (amount <= 0) {
      setState(() => _error = 'Enter an amount.');
      return;
    }
    if (amount > limit + 0.001) {
      setState(
        () => _error = _takeOut
            ? 'You have ${formatMoney(widget.mine)} in this goal.'
            : 'Your free share is ${formatMoney(widget.free)}. Share more '
                  'first with "Set how much you share".',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await contributeToHouseholdGoal(
        widget.householdId,
        goalId: widget.goal.id,
        delta: _takeOut ? -amount : amount,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't save: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final goal = widget.goal;
    return VestaDialog(
      title: goal.title,
      confirmLabel: _takeOut ? 'Take out' : 'Add',
      destructive: _takeOut,
      loading: _saving,
      onConfirm: _save,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(VestaSpace.md),
            decoration: BoxDecoration(
              color: v.tint,
              borderRadius: BorderRadius.circular(VestaRadius.button),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatMoney(goal.saved)} of ${formatMoney(goal.target)} saved',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: v.tintText,
                  ),
                ),
                const SizedBox(height: VestaSpace.xs),
                Text(
                  'From you: ${formatMoney(widget.mine)} · Your free share: '
                  '${formatMoney(widget.free)}',
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: VestaSpace.md),
          Row(
            children: [
              ChoiceTag(
                label: 'Add',
                icon: PhosphorIconsRegular.plus,
                selected: !_takeOut,
                onTap: () => setState(() {
                  _takeOut = false;
                  _error = null;
                }),
              ),
              const SizedBox(width: VestaSpace.sm),
              ChoiceTag(
                label: 'Take out',
                icon: PhosphorIconsRegular.minus,
                selected: _takeOut,
                onTap: () => setState(() {
                  _takeOut = true;
                  _error = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_moneyFormat],
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: _takeOut ? 'Amount to take out' : 'Amount to add',
              prefixText: 'JOD ',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: VestaSpace.sm),
            Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
          ],
        ],
      ),
    );
  }
}
