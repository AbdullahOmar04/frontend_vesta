import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Bills/bills_data.dart';
import 'package:frontend_vesta/Screens/Bills/bills_screen.dart';
import 'package:frontend_vesta/Screens/Budgeting/budgeting_screen.dart';
import 'package:frontend_vesta/Screens/Savings/savings.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:frontend_vesta/Screens/pages/budget_summary.dart';
import 'package:frontend_vesta/Screens/pages/coach_card.dart';
import 'package:intl/intl.dart';

/// The prototype's Dashboard tab: total balance and this month's change,
/// the coach, the budget at a glance, what is coming up, goals and recent
/// transactions. Read-only; every section links to its full screen.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onOpenWallet});

  /// Switches to the Wallet tab.
  final VoidCallback? onOpenWallet;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _user = FirebaseAuth.instance.currentUser;

  bool _loading = true;
  BudgetSummary? _budget;
  List<UpcomingPayment> _upcoming = [];
  List<Map<String, dynamic>> _goals = [];
  List<TransactionModel> _recent = [];
  Map<String, String> _accountLabels = {};
  int _accountCount = 0;
  double _monthChange = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _user?.uid;
    if (uid == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final results = await Future.wait([
        loadBudgetSummary(),
        loadUpcomingPayments(),
        userRef
            .collection('savings')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .get(),
        userRef.collection('accounts').where('linked', isEqualTo: true).get(),
      ]);

      final accounts = results[3] as QuerySnapshot<Map<String, dynamic>>;
      final labels = <String, String>{
        for (final d in accounts.docs)
          d.id: AccountInfo(
            id: d.id,
            name: (d.data()['accountName'] ?? d.id).toString(),
            type: d.data()['accountTypeName'] as String?,
          ).label,
      };

      // Same transactions Spendings reads
      final transactions = <TransactionModel>[];
      for (final account in accounts.docs) {
        final snap = await account.reference.collection('transactions').get();
        for (final doc in snap.docs) {
          transactions.add(TransactionModel.fromFirestore(doc.id, doc.data()));
        }
      }
      transactions.sort((a, b) => b.date.compareTo(a.date));

      // Money in minus money out since the 1st
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      var change = 0.0;
      for (final t in transactions) {
        if (t.date.isBefore(monthStart) || t.date.isAfter(now)) continue;
        change += t.isDebit ? -t.amount.abs() : t.amount.abs();
      }

      if (!mounted) return;
      setState(() {
        _budget = results[0] as BudgetSummary?;
        _upcoming = results[1] as List<UpcomingPayment>;
        _goals = [
          for (final d
              in (results[2] as QuerySnapshot<Map<String, dynamic>>).docs)
            d.data(),
        ];
        _accountLabels = labels;
        _accountCount = accounts.docs.length;
        _recent = transactions.take(4).toList();
        _monthChange = change;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opens a full screen, then refreshes what it may have changed.
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final name = _user?.displayName ?? _user?.email ?? 'there';

    return Scaffold(
      body: VestaBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                10,
                VestaSpace.gutter,
                VestaSpace.xl,
              ),
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/images/LOGO_APP-ICON-DARK.png',
                        width: 32,
                        height: 32,
                        cacheWidth: 96,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${homePageGreeting()} $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: v.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VestaSpace.xl),
                _balance(),
                // Shares the figures loaded here instead of loading its own
                if (_budget != null)
                  CoachCard(
                    summary: _budget,
                    showLink: true,
                    margin: const EdgeInsets.only(top: VestaSpace.xl),
                  ),
                const SizedBox(height: VestaSpace.xl),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: VestaSpace.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _budgetSection(),
                  const SizedBox(height: 28),
                  _comingUp(),
                  const SizedBox(height: 28),
                  _goalsSection(),
                  const SizedBox(height: 28),
                  _recentSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _balance() {
    final v = context.vesta;
    final uid = _user?.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: uid == null
          ? null
          : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final total = (data['totalBalance'] as num?)?.toDouble() ?? 0;
        final currency = (data['currency'] ?? 'JOD').toString();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total balance', style: TextStyle(fontSize: 13, color: v.muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyText(total, currency: currency, size: 36),
            ),
            const SizedBox(height: VestaSpace.xs),
            Row(
              children: [
                if (!_loading) ...[
                  Text(
                    '${formatMoney(_monthChange, currency: currency, showPlus: true)} this month',
                    style: TextStyle(
                      fontSize: 13,
                      color: _monthChange < 0 ? v.neg : v.pos,
                    ),
                  ),
                  Text('  ·  ', style: TextStyle(fontSize: 13, color: v.muted)),
                ],
                GestureDetector(
                  onTap: widget.onOpenWallet,
                  child: Text(
                    _accountCount == 1 ? '1 account ›' : '$_accountCount accounts ›',
                    style: TextStyle(fontSize: 13, color: v.accentInk),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _budgetSection() {
    final v = context.vesta;
    final b = _budget;
    final month = DateFormat('MMMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '$month budget',
          actionLabel: 'See all',
          onAction: () => _open(const PersonalBudgetScreen()),
        ),
        const SizedBox(height: VestaSpace.md),
        if (b == null || !b.hasPlan)
          _emptyLine(
            'No budget plan for this month yet.',
            'Plan your budget',
            () => _open(const PersonalBudgetScreen()),
          )
        else ...[
          VestaProgressBar(
            value: b.flexBudget > 0 ? b.flexSpent / b.flexBudget : 0,
            marker: b.progress,
            height: 8,
            color: b.flexSpent > b.flexBudget
                ? v.neg
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: VestaSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMoney(b.flexSpent)} of ${formatMoney(b.flexBudget)} to spend',
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
              ),
              Text(
                b.daysLeft == 1 ? '1 day left' : '${b.daysLeft} days left',
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          _bucketRow(
            'Necessities',
            PhosphorIconsRegular.houseLine,
            v.bucketEssential,
            b.essentialSpent,
            b.essentialBudget,
          ),
          _bucketRow(
            'Luxuries',
            PhosphorIconsRegular.sparkle,
            v.bucketLuxury,
            b.luxurySpent,
            b.luxuryBudget,
          ),
          _bucketRow(
            'Savings',
            PhosphorIconsRegular.piggyBank,
            v.bucketSavings,
            b.savingsMoved,
            b.savingsBudget,
            saving: true,
          ),
        ],
      ],
    );
  }

  /// One bucket: spent against its share of the plan. Savings counts up
  /// towards its target instead of down.
  Widget _bucketRow(
    String name,
    IconData icon,
    Color color,
    double used,
    double planned, {
    bool saving = false,
  }) {
    final v = context.vesta;
    final over = !saving && used > planned;
    final String note;
    if (planned <= 0) {
      note = 'Not in the plan';
    } else if (saving) {
      note = used >= planned
          ? 'Target reached'
          : '${formatMoney(planned - used)} to go';
    } else {
      note = over
          ? '${formatMoney(used - planned)} over'
          : '${formatMoney(planned - used)} left';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          IconBadge(icon, size: 36, circle: false, color: color),
          const SizedBox(width: VestaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name)),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: over ? v.neg : v.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                VestaProgressBar(
                  value: planned > 0 ? used / planned : 0,
                  height: 4,
                  color: over ? v.neg : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comingUp() {
    final v = context.vesta;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = _upcoming
        .where(
          (p) => !p.incoming && p.nextDate != null && !p.nextDate!.isBefore(today),
        )
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Coming up',
          actionLabel: 'All bills',
          onAction: () => _open(const BillsScreen()),
        ),
        const SizedBox(height: VestaSpace.md),
        if (next.isEmpty)
          _emptyLine(
            'Nothing due soon.',
            'Add your bills',
            () => _open(const BillsScreen()),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: next.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final p = next[i];
                return SizedBox(
                  width: 140,
                  child: VestaCard(
                    radius: VestaRadius.lg,
                    padding: const EdgeInsets.all(VestaSpace.md),
                    onTap: () => _open(const BillsScreen()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              p.isBill
                                  ? categoryIcon(p.category ?? p.title)
                                  : PhosphorIconsRegular.bank,
                              size: 18,
                              color: v.accentInk,
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('MMM d').format(p.nextDate!),
                              style: TextStyle(fontSize: 11, color: v.muted),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        MoneyText(p.amount, currency: p.currency, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _goalsSection() {
    final v = context.vesta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Goals',
          actionLabel: 'See all',
          onAction: () => _open(const SavingsPage()),
        ),
        const SizedBox(height: VestaSpace.sm),
        if (_goals.isEmpty)
          _emptyLine(
            'No saving goals yet.',
            'Create a goal',
            () => _open(const SavingsPage()),
          )
        else
          for (final g in _goals)
            Builder(
              builder: (context) {
                final target = (g['targetAmount'] as num?)?.toDouble() ?? 0;
                final saved = (g['currentAmount'] as num?)?.toDouble() ?? 0;
                return InkWell(
                  onTap: () => _open(const SavingsPage()),
                  borderRadius: BorderRadius.circular(VestaRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: v.raised,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (g['emoji'] ?? '💰').toString(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: VestaSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (g['goalTitle'] ?? 'Goal').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${formatMoney(saved)} / ${formatMoney(target)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: v.muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              VestaProgressBar(
                                value: target > 0 ? saved / target : 0,
                                height: 4,
                                color: v.accentInk,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }

  Widget _recentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent',
          actionLabel: 'See all',
          onAction: () => _open(const Transactions(showBack: true)),
        ),
        const SizedBox(height: VestaSpace.xs),
        if (_recent.isEmpty)
          _emptyLine(
            'No transactions yet.',
            'Add one',
            () => _open(const Transactions(showBack: true)),
          )
        else
          for (final t in _recent)
            TransactionCard(
              key: ValueKey(t.id),
              transaction: t,
              accountName: _accountLabels[t.accountId],
              onDeleted: _load,
              onCategoryChanged: _load,
            ),
      ],
    );
  }

  /// A muted line with a link, for sections with nothing to show yet.
  Widget _emptyLine(String text, String action, VoidCallback onTap) {
    final v = context.vesta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VestaSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: v.muted)),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: TextStyle(fontSize: 13, color: v.accentInk),
            ),
          ),
        ],
      ),
    );
  }
}
