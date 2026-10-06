import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:intl/intl.dart';

/// Month-to-date spending compared with the same point last month, after the
/// prototype's Insights screen. Read-only: it only reads transactions.
class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  bool _loading = true;
  List<TransactionModel> _spending = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Same accounts and transactions as the Spendings screen.
  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final accountsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('linked', isEqualTo: true)
          .get();

      final spending = <TransactionModel>[];
      for (final accDoc in accountsSnap.docs) {
        final txSnap = await accDoc.reference.collection('transactions').get();
        for (final txDoc in txSnap.docs) {
          final txn = TransactionModel.fromFirestore(txDoc.id, txDoc.data());
          if (txn.isDebit) spending.add(txn);
        }
      }

      if (!mounted) return;
      setState(() {
        _spending = spending;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading insights: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static String _categoryOf(TransactionModel t) {
    final c = t.category?.trim() ?? '';
    return c.isEmpty ? 'Uncategorized' : c;
  }

  double _sum(Iterable<TransactionModel> txns) =>
      txns.fold(0.0, (s, t) => s + t.amount.abs());

  Iterable<TransactionModel> _between(DateTime from, DateTime to) =>
      _spending.where((t) => !t.date.isBefore(from) && !t.date.isAfter(to));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VestaAppBar(title: 'Insights'),
      body: VestaBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _load, child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    final v = context.vesta;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final prevStart = DateTime(now.year, now.month - 1);
    final daysInPrev = DateTime(now.year, now.month, 0).day;
    // The same day last month (clamped to its length), to the end of that day
    final prevSamePoint = DateTime(
      prevStart.year,
      prevStart.month,
      now.day > daysInPrev ? daysInPrev : now.day,
      23,
      59,
      59,
    );

    final current = _between(monthStart, now).toList();
    final previous = _between(prevStart, prevSamePoint).toList();
    final spent = _sum(current);
    final diff = spent - _sum(previous);

    final monthName = DateFormat('MMMM').format(now);
    final prevShort = DateFormat('MMM').format(prevStart);
    final prevLong = DateFormat('MMMM').format(prevStart);

    // Six calendar months, oldest first; the current one is month-to-date
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
    ];
    final monthTotals = [
      for (final m in months)
        _sum(_between(m, DateTime(m.year, m.month + 1).subtract(
          const Duration(microseconds: 1),
        ))),
    ];

    // Per-category month-to-date totals and change against last month
    final names = {
      ...current.map(_categoryOf),
      ...previous.map(_categoryOf),
    };
    final rows = [
      for (final name in names)
        (
          name: name,
          now: _sum(current.where((t) => _categoryOf(t) == name)),
          change: _sum(current.where((t) => _categoryOf(t) == name)) -
              _sum(previous.where((t) => _categoryOf(t) == name)),
        ),
    ]..sort((a, b) => b.now.compareTo(a.now));

    // The cards are advice, so they skip spending with no category
    final named = rows.where((r) => r.name != 'Uncategorized');
    final drops = named.where((r) => r.change < 0).toList()
      ..sort((a, b) => a.change.compareTo(b.change));
    final rises = named.where((r) => r.change > 0).toList()
      ..sort((a, b) => b.change.compareTo(a.change));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        VestaSpace.sm,
        VestaSpace.gutter,
        VestaSpace.xl,
      ),
      children: [
        Text(
          'Spent in $monthName so far',
          style: TextStyle(fontSize: 13, color: v.muted),
        ),
        const SizedBox(height: VestaSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: MoneyText.hero(spent, size: 36),
              ),
            ),
            if (diff != 0)
              Padding(
                padding: const EdgeInsets.only(left: VestaSpace.sm, bottom: 6),
                child: Text(
                  '${formatMoney(diff, showPlus: true)} vs $prevShort',
                  style: TextStyle(fontSize: 12, color: diff > 0 ? v.neg : v.pos),
                ),
              ),
          ],
        ),
        const SizedBox(height: VestaSpace.xl),
        _MonthBars(
          labels: [for (final m in months) DateFormat('MMM').format(m)],
          totals: monthTotals,
        ),
        const SizedBox(height: VestaSpace.xl),
        if (drops.isNotEmpty) ...[
          _InsightCard(
            icon: PhosphorIconsRegular.trendDown,
            title:
                '${drops.first.name} is down ${formatMoney(-drops.first.change)}',
            message: rows.length > 1 && drops.length > 1
                ? 'Compared with this point in $prevLong. '
                      "That's the biggest drop of any category."
                : 'Compared with this point in $prevLong.',
          ),
          const SizedBox(height: VestaSpace.md),
        ],
        if (rises.isNotEmpty) ...[
          _InsightCard(
            icon: PhosphorIconsRegular.trendUp,
            title:
                '${rises.first.name} is up ${formatMoney(rises.first.change)}',
            message: _riseMessage(rises.first.name, current, prevLong),
          ),
          const SizedBox(height: VestaSpace.md),
        ],
        const SizedBox(height: VestaSpace.md),
        const SectionHeader(title: 'By category'),
        const SizedBox(height: VestaSpace.sm),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: VestaSpace.xl),
            child: Text(
              'No spending yet this month or last.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: v.muted),
            ),
          ),
        for (final r in rows) _CategoryRow(name: r.name, amount: r.now, change: r.change),
      ],
    );
  }

  /// Points at the single purchase when it makes up most of the rise.
  String _riseMessage(
    String category,
    List<TransactionModel> current,
    String prevLong,
  ) {
    final txns = current.where((t) => _categoryOf(t) == category).toList();
    if (txns.length > 1) {
      txns.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
      final top = txns.first;
      if (top.amount.abs() >= _sum(txns) / 2) {
        return 'Most of it came from one purchase on '
            '${DateFormat('MMM d').format(top.date)}. '
            'Worth a look before the month closes.';
      }
    }
    return 'Compared with this point in $prevLong.';
  }
}

/// Six monthly totals as bars, the current month in the accent colour.
class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.labels, required this.totals});

  final List<String> labels;
  final List<double> totals;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;
    final top = totals.fold(0.0, (m, t) => t > m ? t : m);
    const barArea = 96.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < totals.length; i++) ...[
          if (i > 0) const SizedBox(width: VestaSpace.md),
          Expanded(
            child: Column(
              children: [
                Text(
                  compactAmount(totals[i]),
                  style: TextStyle(fontSize: 11, color: v.muted),
                ),
                const SizedBox(height: VestaSpace.xs),
                Container(
                  height: top <= 0
                      ? 4
                      : (barArea * totals[i] / top).clamp(4.0, barArea),
                  decoration: BoxDecoration(
                    color: i == totals.length - 1 ? accent : v.raised,
                    borderRadius: BorderRadius.circular(VestaRadius.sm),
                  ),
                ),
                const SizedBox(height: VestaSpace.sm),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: i == totals.length - 1 ? null : v.muted,
                    fontWeight: i == totals.length - 1 ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return VestaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: v.accentInk),
            ),
            child: Icon(icon, size: 16, color: v.accentInk),
          ),
          const SizedBox(width: VestaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(fontSize: 13, color: v.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.change,
  });

  final String name;
  final double amount;
  final double change;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(categoryIcon(name), size: 20),
          const SizedBox(width: VestaSpace.md),
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(
            change == 0 ? '—' : formatMoney(change, showPlus: true),
            style: amountStyle(12, color: change == 0
                ? v.muted
                : change > 0
                ? v.neg
                : v.pos),
          ),
          const SizedBox(width: VestaSpace.md),
          MoneyText(amount),
        ],
      ),
    );
  }
}
