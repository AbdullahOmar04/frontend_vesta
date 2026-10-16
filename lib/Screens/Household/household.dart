// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Helpers/icon_picker.dart';
import 'package:frontend_vesta/Screens/Budgeting/plan_budget.dart';
import 'package:frontend_vesta/Screens/Household/household_bills.dart';
import 'package:frontend_vesta/Screens/Household/household_data.dart';
import 'package:frontend_vesta/Screens/Household/household_manage.dart';
import 'package:frontend_vesta/Screens/Household/household_savings.dart';
import 'package:frontend_vesta/Screens/Household/household_actions.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/new_spending.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/spending_categories.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

const List<String> categoryLabels = [
  'Food And Drinks',
  'Groceries',
  'Entertainment',
  'Others',
];

typedef _Member = HouseholdMember;

/// The three buckets as the categories store them, in the prototype's order.
const _buckets = ['savings', 'essential', 'luxury'];
const _bucketLabels = ['Savings', 'Necessities', 'Luxuries'];

class HouseholdDetailPage extends StatefulWidget {
  final String householdId;

  const HouseholdDetailPage({super.key, required this.householdId});

  @override
  State<HouseholdDetailPage> createState() => _HouseholdDetailPageState();
}

class _HouseholdDetailPageState extends State<HouseholdDetailPage> {
  final _db = FirebaseFirestore.instance;
  Future<Map<String, Map<String, dynamic>>>? _profiles;
  String _profilesFor = '';

  /// Members' names and photos, read one doc at a time: the rules let a
  /// co-member read a user doc, but not run a query over users. Cached until
  /// the member list changes.
  Future<Map<String, Map<String, dynamic>>> _memberProfiles(
    List<String> uids,
  ) {
    final key = uids.join(',');
    if (_profiles == null || key != _profilesFor) {
      _profilesFor = key;
      _profiles = () async {
        final docs = await Future.wait(
          uids.map((m) async {
            try {
              return await _db.collection('users').doc(m).get();
            } catch (_) {
              return null; // Unreadable: shown as "Member"
            }
          }),
        );
        return {
          for (final d in docs)
            if (d != null) d.id: d.data() ?? const <String, dynamic>{},
        };
      }();
    }
    return _profiles!;
  }
  final _auth = FirebaseAuth.instance;
  final String _appDomain = "https://vestaapp.co";
  List<HouseholdTransactionModel> _allTransactions = [];
  Map<String, CategoryData> _categories = {};
  double _currentCycleHouseholdBudget = 0;
  double _currentCycleHouseholdSpending = 0;
  int _budgetResetDay = 28;

  /// Spending per bucket for the last six cycles, for Financial health.
  Map<String, List<FlSpot>> _bucketSeries = {};

  /// Total spending per cycle, oldest first, to tell over-budget months.
  List<double> _cycleTotals = [];

  /// Category name to its bucket (essential, luxury, savings, income).
  Map<String, String> _bucketOf = {};
  double _manualHouseholdBudget = 0;

  bool _loading = true;

  /// 0 = Budget, 1 = Spendings, 2 = Savings
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadData(widget.householdId);
    _fetchHouseholdCycleData(widget.householdId);
    _fetchHouseholdChartData(widget.householdId);
    _loadHouseholdBudget();
  }

  Future<void> _loadHouseholdBudget() async {
    final doc = await FirebaseFirestore.instance
        .collection("households")
        .doc(widget.householdId)
        .get();

    final data = doc.data() ?? {};
    final manualBudget = (data["budget"] ?? 0).toDouble();

    setState(() {
      _manualHouseholdBudget = manualBudget;
      // if you want the tracker to use this:
      _currentCycleHouseholdBudget = manualBudget;
    });
  }

  Future<void> _loadData(String householdId) async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      debugPrint(
        "📊 Loading household transactions for household: $householdId",
      );

      // 1️⃣ Load household transactions
      final transactionSnap = await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('transactions')
          .get();

      debugPrint("📁 Found ${transactionSnap.docs.length} transactions");

      final List<HouseholdTransactionModel> transactions = [];

      for (final txDoc in transactionSnap.docs) {
        final data = txDoc.data();

        if (mounted) {
          setState(() {
            _budgetResetDay = (data["dayOfMonth"] ?? 28) as int;
          });
        }

        // 👇 Extract the user who assigned it
        final assignedBy = data['assignedBy'] as String?;
        if (assignedBy == null) {
          debugPrint(
            "⚠️ Skipping transaction ${txDoc.id} — no assignedBy found",
          );
          continue;
        }

        // Convert to model
        final txn = HouseholdTransactionModel.fromFirestore(txDoc.id, data);
        transactions.add(txn);
      }

      // 2️⃣ Load categories for the current logged-in user
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final categoryMap = <String, CategoryData>{};

      if (uid != null) {
        final categoriesSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('categories')
            .get();

        _bucketOf = {
          for (final doc in categoriesSnap.docs)
            doc.id: (doc.data()['bucket'] ?? '').toString(),
        };
        for (var doc in categoriesSnap.docs) {
          categoryMap[doc.id] = CategoryData(
            id: doc.id,
            name: doc.id,
            icon: _getIconForCategory(doc.id),
            color: _getColorForCategory(doc.id),
          );
        }
      }

      // 3️⃣ Apply to state
      setState(() {
        _categories = categoryMap;
        _allTransactions = transactions;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint("⚠️ Error loading data: $e\n$st");
      setState(() => _loading = false);
    }
  }

  Future<void> _createAndShareInviteLink() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final householdDoc = await _db
          .collection('households')
          .doc(widget.householdId)
          .get();
      final householdName =
          householdDoc.data()?['householdName'] ?? 'a household';

      final inviteDoc = await _db.collection('invites').add({
        'householdId': widget.householdId,
        'inviterUid': user.uid,
        'inviterName': user.displayName ?? user.email,
        'householdName': householdName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final inviteUri = Uri.https("vestaapp.co", "/join", {
        "inviteId": inviteDoc.id,
      });

      final inviteLink = inviteUri.toString();

      await Share.share(
        "Join my household '$householdName' on Vesta! Click here: $inviteLink",
        subject: "You're invited to join my household!",
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating invite: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<HouseholdTransactionModel> _getLatestTransactions() {
    final sorted = List<HouseholdTransactionModel>.from(_allTransactions);
    // Sort by date, most recent first
    sorted.sort((a, b) => b.date.compareTo(a.date));
    // Return the first 5, or fewer if not available
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final latestTransactions = _getLatestTransactions();
    final categoryNetAmounts = _calculateCategoryNetAmounts();
    final uid = _auth.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('households').doc(widget.householdId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: VestaBackground(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data!.data();
        final householdName = data?['householdName'] ?? 'Unnamed Household';
        final List<String> memberUids = List<String>.from(
          data?['members'] ?? [],
        );

        // Deleted, or this user was removed while the screen was open
        if (data == null || !memberUids.contains(uid)) {
          return _noLongerMember();
        }

        final ownerUid = householdOwner(data);
        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: _memberProfiles(memberUids),
          builder: (context, profilesSnapshot) {
            final profiles = profilesSnapshot.data ?? const {};
            // The owner first, then everyone else in joining order
            final ordered = [
              ...memberUids.where((m) => m == ownerUid),
              ...memberUids.where((m) => m != ownerUid),
            ];
            final members = <_Member>[
              for (final m in ordered)
                (
                  uid: m,
                  name: (profiles[m]?['username'] ?? 'Member').toString(),
                  photo: profiles[m]?['profileImageUrl'] as String?,
                ),
            ];

            return Scaffold(
              appBar: VestaAppBar(
                title: householdName,
                actions: [
                  HeaderButton(
                    label: 'Manage',
                    onPressed: () =>
                        _manage(data, householdName, members, ownerUid),
                  ),
                ],
              ),
              body: VestaBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    VestaSpace.gutter,
                    VestaSpace.xs,
                    VestaSpace.gutter,
                    VestaSpace.xl,
                  ),
                  children: [
                    _membersHeader(members, ownerUid),
                    const SizedBox(height: VestaSpace.lg),
                    _tabSwitcher(),
                    const SizedBox(height: 14),
                    if (_tab == 0) ...[
                      _buildChart(),
                      const SizedBox(height: 14),
                      _buildBudgetTrackerBar(data),
                      const SizedBox(height: 14),
                      HouseholdBillsCard(
                        householdId: widget.householdId,
                        bills: householdBills(data),
                        members: members,
                      ),
                    ] else if (_tab == 1) ...[
                      _buildMemberSpending(members),
                      const SizedBox(height: 14),
                      _buildSpendingCategoriesSection(categoryNetAmounts),
                      const SizedBox(height: 14),
                      _buildLatestTransactionsSection(latestTransactions),
                    ] else
                      HouseholdSavingsTab(
                        householdId: widget.householdId,
                        savings: HouseholdSavings.fromHousehold(data),
                        members: members,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _noLongerMember() {
    final v = context.vesta;
    return Scaffold(
      appBar: const VestaAppBar(title: 'Household'),
      body: VestaBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(VestaSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.houseLine, size: 44, color: v.muted),
                const SizedBox(height: VestaSpace.md),
                Text(
                  "You're no longer in this household",
                  textAlign: TextAlign.center,
                  style: headingStyle(18),
                ),
                const SizedBox(height: VestaSpace.sm),
                Text(
                  'It was deleted, or its owner removed you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
                const SizedBox(height: VestaSpace.xl),
                PrimaryButton(
                  label: 'Back to Shared finances',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Overlapping avatars and "Name (admin) · Name", after the prototype.
  Widget _membersHeader(List<_Member> members, String? ownerUid) {
    final v = context.vesta;
    final palette = householdMemberColors(v);
    const size = 56.0;
    const overlap = 18.0;
    final shown = members.take(4).toList();
    final extra = members.length - shown.length;

    Widget avatar(int i, _Member m) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette[i % palette.length], width: 2),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: CircleAvatar(
          backgroundColor: v.raised,
          backgroundImage: m.photo != null ? NetworkImage(m.photo!) : null,
          child: m.photo == null
              ? Text(
                  m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                  style: headingStyle(18),
                )
              : null,
        ),
      );
    }

    final slots = shown.length + (extra > 0 ? 1 : 0);
    return Column(
      children: [
        SizedBox(
          width: size + (slots - 1) * (size - overlap),
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * (size - overlap),
                  child: avatar(i, shown[i]),
                ),
              if (extra > 0)
                Positioned(
                  left: shown.length * (size - overlap),
                  child: CircleAvatar(
                    radius: size / 2,
                    backgroundColor: v.raised,
                    child: Text('+$extra', style: headingStyle(16)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: VestaSpace.sm),
        Text(
          [
            for (final m in members)
              m.uid == ownerUid ? '${m.name} (admin)' : m.name,
          ].join(' · '),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: v.muted),
        ),
      ],
    );
  }

  /// Budget / Spendings / Savings, as in the prototype.
  Widget _tabSwitcher() {
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;
    const labels = ['Budget', 'Spendings', 'Savings'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(VestaRadius.lg),
        border: Border.all(color: v.edge),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _tab == i ? v.tint : Colors.transparent,
                    borderRadius: BorderRadius.circular(VestaRadius.button),
                    border: Border.all(
                      color: _tab == i ? accent : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: headingStyle(
                      14,
                      color: _tab == i ? v.tintText : v.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// This budget cycle's start and end (inclusive), as the cycle loader
  /// works them out.
  ({DateTime start, DateTime end}) _cycleRange() {
    final now = DateTime.now();
    final DateTime start;
    final DateTime endDay;
    if (now.day >= _budgetResetDay) {
      start = DateTime(now.year, now.month, _budgetResetDay);
      endDay = DateTime(now.year, now.month + 1, _budgetResetDay)
          .subtract(const Duration(days: 1));
    } else {
      start = DateTime(now.year, now.month - 1, _budgetResetDay);
      endDay = DateTime(now.year, now.month, _budgetResetDay)
          .subtract(const Duration(days: 1));
    }
    return (
      start: start,
      end: DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59),
    );
  }

  /// The prototype's Spendings card: spent so far against the household
  /// budget, and each member's share of it (by who added the transaction).
  Widget _buildMemberSpending(List<_Member> members) {
    final v = context.vesta;
    final me = _auth.currentUser?.uid;
    final cycle = _cycleRange();
    final perMember = <String, double>{};
    for (final t in _allTransactions) {
      if (!t.isDebit) continue;
      if (t.date.isBefore(cycle.start) || t.date.isAfter(cycle.end)) continue;
      final who = t.assignedBy ?? '';
      perMember[who] = (perMember[who] ?? 0) + t.amount.abs();
    }
    final spent = perMember.values.fold(0.0, (s, a) => s + a);
    final budget = _currentCycleHouseholdBudget > 0.01
        ? _currentCycleHouseholdBudget
        : 0.0;
    final left = budget - spent;
    final today = DateTime.now();
    final daysLeft =
        DateTime(cycle.end.year, cycle.end.month, cycle.end.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays +
        1;
    final palette = householdMemberColors(v);
    final monthName = DateFormat('MMMM').format(today);

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent in $monthName so far',
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
              ),
              if (budget > 0)
                Text(
                  '${(spent / budget * 100).round()}% used',
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
            ],
          ),
          const SizedBox(height: VestaSpace.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              MoneyText.hero(spent, size: 30),
              if (budget > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'of ${formatMoney(budget)}',
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          VestaProgressBar(
            value: budget > 0 ? spent / budget : 0,
            height: 10,
            color: budget > 0 && spent > budget
                ? v.neg
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: VestaSpace.md),
          for (var i = 0; i < members.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: palette[i % palette.length],
                    child: Text(
                      members[i].name.isNotEmpty
                          ? members[i].name[0].toUpperCase()
                          : '?',
                      style: TextStyle(fontSize: 11, color: v.pxInk),
                    ),
                  ),
                  const SizedBox(width: VestaSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                members[i].uid == me
                                    ? '${members[i].name} (you)'
                                    : members[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            MoneyText(perMember[members[i].uid] ?? 0),
                            const SizedBox(width: VestaSpace.sm),
                            SizedBox(
                              width: 36,
                              child: Text(
                                spent > 0
                                    ? '${((perMember[members[i].uid] ?? 0) / spent * 100).round()}%'
                                    : '0%',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 12, color: v.muted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        VestaProgressBar(
                          value: spent > 0
                              ? (perMember[members[i].uid] ?? 0) / spent
                              : 0,
                          height: 3,
                          color: palette[i % palette.length],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: VestaSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  budget <= 0
                      ? 'No household budget yet'
                      : left >= 0
                      ? '${formatMoney(left)} left'
                      : '${formatMoney(-left)} over',
                  style: TextStyle(
                    fontSize: 12,
                    color: left < 0 && budget > 0 ? v.neg : v.muted,
                  ),
                ),
              ),
              Text(
                daysLeft == 1 ? '1 day to go' : '$daysLeft days to go',
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The prototype's Edit household pop-up; leaving or deleting closes the
  /// page too.
  Future<void> _manage(
    Map<String, dynamic> data,
    String householdName,
    List<_Member> members,
    String? ownerUid,
  ) async {
    final result = await showEditHouseholdDialog(
      context,
      householdId: widget.householdId,
      name: householdName,
      icon: (data['icon'] ?? 'house-line').toString(),
      members: members,
      ownerUid: ownerUid,
      onShareLink: _createAndShareInviteLink,
    );
    if (result != null && mounted) Navigator.pop(context);
  }

  /// The prototype's Financial health: spending per bucket over the last six
  /// cycles, with how this month and the last six went against the budget.
  Widget _buildChart() {
    final v = context.vesta;
    final colors = [v.bucketSavings, v.bucketEssential, v.bucketLuxury];
    final allY = [
      for (final s in _bucketSeries.values) ...s.map((p) => p.y),
    ];
    final hasData = allY.any((y) => y > 0);
    final top = niceChartTop(allY.isEmpty ? 0 : allY.reduce(math.max));
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final budget = _manualHouseholdBudget;
    final now = DateTime.now();

    Widget? tag(bool? good, String bad) {
      if (good == null) return null;
      return good ? TagChip('Good', color: v.pos) : TagChip(bad, color: v.bucketLuxury);
    }

    final monthGood = budget > 0 && _cycleTotals.isNotEmpty
        ? _cycleTotals.last <= budget
        : null;
    final overallGood = budget > 0 && _cycleTotals.isNotEmpty
        ? _cycleTotals.every((total) => total <= budget)
        : null;

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial health',
            style: TextStyle(fontSize: 12, color: v.muted),
          ),
          if (monthGood != null) ...[
            const SizedBox(height: VestaSpace.xs),
            Row(
              children: [
                Text(
                  monthNames[now.month - 1],
                  style: TextStyle(fontSize: 12, color: v.muted),
                ),
                const SizedBox(width: 6),
                tag(monthGood, 'Over')!,
                const Spacer(),
                Text('Overall', style: TextStyle(fontSize: 12, color: v.muted)),
                const SizedBox(width: 6),
                tag(overallGood, 'At risk')!,
              ],
            ),
          ],
          const SizedBox(height: VestaSpace.md),
          SizedBox(
            height: 170,
            child: !hasData
                ? Center(
                    child: Text(
                      "No shared spending in the last six months yet",
                      style: TextStyle(fontSize: 13, color: v.muted),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: top,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: top / 2,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: v.divider, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: top / 2,
                            getTitlesWidget: (value, meta) => Text(
                              compactAmount(value),
                              style: TextStyle(fontSize: 10, color: v.muted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              // The last six months, this one last
                              final monthDate = DateTime(
                                now.year,
                                now.month - 5 + index,
                              );
                              final current = index == 5;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthNames[monthDate.month - 1],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: current
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: current
                                        ? Theme.of(context).colorScheme.onSurface
                                        : v.muted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        for (var i = 0; i < _buckets.length; i++)
                          if ((_bucketSeries[_buckets[i]] ?? const []).isNotEmpty)
                            LineChartBarData(
                              spots: _bucketSeries[_buckets[i]]!,
                              isCurved: false,
                              color: colors[i],
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                            ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: VestaSpace.md),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: [
                for (var i = 0; i < _buckets.length; i++)
                  _legendItem(_bucketLabels[i], colors[i]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: context.vesta.muted)),
      ],
    );
  }

  Map<String, double> _calculateCategoryNetAmounts() {
    final filtered = _getTransactionsForCurrentPeriod();
    final netAmounts = <String, double>{};

    for (var txn in filtered) {
      final category = txn.category!;
      double currentAmount = netAmounts[category] ?? 0.0;

      if (txn.isDebit) {
        netAmounts[category] = currentAmount - txn.amount;
      } else {
        netAmounts[category] = currentAmount + txn.amount;
      }
    }

    return netAmounts;
  }

  Future<void> _fetchHouseholdChartData(String householdId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final householdDoc = await FirebaseFirestore.instance
          .collection("households")
          .doc(householdId)
          .get();

      if (!householdDoc.exists) return;

      final data = householdDoc.data()!;
      final resetDay = (data["budgetResetDay"] ?? _budgetResetDay).toInt();

      // Buckets come from the categories; load them if _loadData hasn't yet
      if (_bucketOf.isEmpty) {
        final cats = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .get();
        _bucketOf = {
          for (final d in cats.docs) d.id: (d.data()['bucket'] ?? '').toString(),
        };
      }

      final txSnap = await FirebaseFirestore.instance
          .collection("households")
          .doc(householdId)
          .collection("transactions")
          .get();

      final series = {for (final b in _buckets) b: <FlSpot>[]};
      final totals = <double>[];

      // The past 6 cycles (5 previous + current)
      for (int i = 5; i >= 0; i--) {
        DateTime startDate;
        DateTime endDate;
        final date = DateTime(now.year, now.month - i);

        if (date.day >= resetDay) {
          startDate = DateTime(date.year, date.month, resetDay);
          final nextMonth = DateTime(date.year, date.month + 1, resetDay);
          endDate = nextMonth.subtract(const Duration(days: 1));
        } else {
          startDate = DateTime(date.year, date.month - 1, resetDay);
          final thisMonth = DateTime(date.year, date.month, resetDay);
          endDate = thisMonth.subtract(const Duration(days: 1));
        }
        endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

        final perBucket = {for (final b in _buckets) b: 0.0};
        double total = 0;
        for (final tx in txSnap.docs) {
          final tData = tx.data();
          final type = (tData["type"] ?? "").toString().toLowerCase();
          if (type != "debit") continue;

          DateTime? txDate;
          final rawDate = tData["date"];
          if (rawDate is String && rawDate.isNotEmpty) {
            try {
              txDate = DateTime.parse(rawDate).toLocal();
            } catch (_) {}
          }
          if (txDate == null) continue;
          if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) continue;

          final amount = double.tryParse((tData["amount"] ?? 0).toString()) ?? 0;
          total += amount;
          final bucket = _bucketOf[(tData['category'] ?? '').toString()];
          if (bucket != null && perBucket.containsKey(bucket)) {
            perBucket[bucket] = perBucket[bucket]! + amount;
          }
        }

        final x = (5 - i).toDouble();
        for (final b in _buckets) {
          series[b]!.add(FlSpot(x, perBucket[b]!));
        }
        totals.add(total);
      }

      if (mounted) {
        setState(() {
          _bucketSeries = series;
          _cycleTotals = totals;
        });
      }
    } catch (e, st) {
      debugPrint("⚠️ Error fetching household chart data: $e\n$st");
    }
  }

  /// The household budget and its savings / necessities / luxuries split,
  /// in the same pop-up as the personal plan.
  Future<void> _editBudget(Map<String, dynamic> data) async {
    final saved = await showBudgetSplitDialog(
      context,
      title: 'Household budget plan',
      totalLabel: 'Total monthly budget',
      load: () async => (
        total: _manualHouseholdBudget,
        percents: householdPlan(data) ?? [20, 50, 30],
      ),
      save: (split) => saveHouseholdPlan(
        widget.householdId,
        budget: split.total,
        percents: split.percents,
      ),
    );
    if (!saved || !mounted) return;
    await _loadHouseholdBudget();
    await _fetchHouseholdCycleData(widget.householdId);
    await _fetchHouseholdChartData(widget.householdId);
  }

  /// Spent this cycle per bucket, by the categories' buckets.
  Map<String, double> _bucketSpentThisCycle() {
    final cycle = _cycleRange();
    final spent = {for (final b in _buckets) b: 0.0};
    for (final t in _allTransactions) {
      if (!t.isDebit) continue;
      if (t.date.isBefore(cycle.start) || t.date.isAfter(cycle.end)) continue;
      final bucket = _bucketOf[t.category ?? ''];
      if (bucket != null && spent.containsKey(bucket)) {
        spent[bucket] = spent[bucket]! + t.amount.abs();
      }
    }
    return spent;
  }

  /// The prototype's "Budget plan for (month)" card: the household budget,
  /// what was spent, and each bucket against its share of the budget.
  Widget _buildBudgetTrackerBar(Map<String, dynamic> data) {
    final v = context.vesta;
    // The cycle loader stores 0.01 when no budget is set, to avoid dividing
    // by zero, so anything at or below that counts as no budget.
    final hasBudget = _currentCycleHouseholdBudget > 0.01;
    final budget = hasBudget ? _currentCycleHouseholdBudget : 0.0;
    final spent = _currentCycleHouseholdSpending;
    final over = hasBudget && spent > budget;
    final monthName = DateFormat('MMMM').format(DateTime.now());
    final plan = householdPlan(data);
    final colors = [v.bucketSavings, v.bucketEssential, v.bucketLuxury];
    final bucketSpent = _bucketSpentThisCycle();

    Widget stat(String label, double amount, Color? color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(VestaSpace.md),
          decoration: BoxDecoration(
            color: v.raised,
            borderRadius: BorderRadius.circular(VestaRadius.button),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: v.muted)),
              const SizedBox(height: VestaSpace.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: MoneyText(amount, size: 20, color: color),
              ),
            ],
          ),
        ),
      );
    }

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Budget plan for $monthName',
            trailing: [
              OutlineIconButton(
                icon: PhosphorIconsRegular.pencilSimple,
                tooltip: 'Edit the budget plan',
                onPressed: () => _editBudget(data),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          Row(
            children: [
              stat('Total budget', budget, v.pos),
              const SizedBox(width: 10),
              stat('Spent so far', spent, over ? v.neg : null),
            ],
          ),
          const SizedBox(height: VestaSpace.lg),
          // Spending by bucket against the whole budget
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: hasBudget
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < _buckets.length; i++)
                          if (bucketSpent[_buckets[i]]! > 0)
                            Expanded(
                              flex: (bucketSpent[_buckets[i]]! / budget * 1000)
                                  .round()
                                  .clamp(1, 1000),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: ColoredBox(color: colors[i]),
                              ),
                            ),
                        if (spent < budget)
                          Expanded(
                            flex: ((budget - spent) / budget * 1000)
                                .round()
                                .clamp(1, 1000),
                            child: ColoredBox(color: v.track),
                          ),
                      ],
                    )
                  : ColoredBox(color: v.track),
            ),
          ),
          const SizedBox(height: VestaSpace.md),
          if (!hasBudget)
            Text(
              'No budget set yet. Tap the pencil to plan one.',
              style: TextStyle(fontSize: 12, color: v.muted),
            )
          else if (plan == null)
            Text(
              over
                  ? '${formatMoney(spent - budget)} over this cycle. Tap the '
                        'pencil to split the budget into buckets.'
                  : '${formatMoney(budget - spent)} left this cycle. Tap the '
                        'pencil to split the budget into buckets.',
              style: TextStyle(fontSize: 12, color: over ? v.neg : v.muted),
            )
          else
            for (var i = 0; i < _buckets.length; i++) ...[
              Row(
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
                  Expanded(child: Text(_bucketLabels[i])),
                  MoneyText(
                    bucketSpent[_buckets[i]]!,
                    size: 13,
                    color: bucketSpent[_buckets[i]]! > budget * plan[i] / 100
                        ? v.neg
                        : null,
                  ),
                  Text(' / ', style: TextStyle(fontSize: 12, color: v.muted)),
                  MoneyText(budget * plan[i] / 100, size: 12, color: v.muted),
                ],
              ),
              const SizedBox(height: 6),
              VestaProgressBar(
                value: plan[i] > 0
                    ? (bucketSpent[_buckets[i]]! / (budget * plan[i] / 100))
                          .clamp(0, 1)
                          .toDouble()
                    : 0,
                height: 3,
                color: colors[i],
              ),
              const SizedBox(height: VestaSpace.md),
            ],
        ],
      ),
    );
  }

  Future<void> _fetchHouseholdCycleData(String householdId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      // 1️⃣ Determine current budget cycle dates (same logic)
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      if (now.day >= _budgetResetDay) {
        startDate = DateTime(now.year, now.month, _budgetResetDay);
        final nextMonth = DateTime(now.year, now.month + 1, _budgetResetDay);
        endDate = nextMonth.subtract(const Duration(days: 1));
      } else {
        startDate = DateTime(now.year, now.month - 1, _budgetResetDay);
        final thisMonth = DateTime(now.year, now.month, _budgetResetDay);
        endDate = thisMonth.subtract(const Duration(days: 1));
      }
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final householdDoc = await FirebaseFirestore.instance
          .collection("households")
          .doc(householdId)
          .get();

      if (!householdDoc.exists) throw Exception("Household not found");

      final data = householdDoc.data()!;
      final manualBudget = (data["budget"] ?? 0).toDouble();

      double totalSpending = 0;
      final txSnap = await FirebaseFirestore.instance
          .collection("households")
          .doc(householdId)
          .collection("transactions")
          .get();

      for (final tx in txSnap.docs) {
        final tData = tx.data();

        // Skip non-debit
        final type = (tData["type"] ?? "").toString().toLowerCase();
        if (type != "debit") continue;

        // Parse date
        DateTime? txDate;
        final rawDate = tData["date"];
        if (rawDate is String && rawDate.isNotEmpty) {
          try {
            txDate = DateTime.parse(rawDate).toLocal();
          } catch (_) {}
        }

        if (txDate == null) continue;

        // Check if within current cycle
        if (!txDate.isBefore(startDate) && !txDate.isAfter(endDate)) {
          final amtStr = (tData["amount"] ?? 0).toString();
          final amount = double.tryParse(amtStr) ?? 0;
          totalSpending += amount;
        }
      }

      // 4️⃣ Update local state
      if (mounted) {
        setState(() {
          _currentCycleHouseholdBudget = manualBudget > 0
              ? manualBudget
              : 0.01; // fallback
          _currentCycleHouseholdSpending = totalSpending;
          _loading = false;
        });
      }

      // 5️⃣ Persist household spending
      await FirebaseFirestore.instance
          .collection("households")
          .doc(householdId)
          .update({"totalExpense": totalSpending});
    } catch (e, st) {
      debugPrint("⚠️ Error fetching household budget data: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading household budget: $e")),
        );
      }
      setState(() => _loading = false);
    }
  }

  Widget _buildSpendingCategoriesSection(Map<String, double> netAmounts) {
    // Sort categories by the absolute value of their net amount, descending
    final sortedCategories = netAmounts.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final top5Categories = sortedCategories.take(5).toList();

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Categories",
            actionLabel: "See all",
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpendingCategories(),
                ),
              );
            },
          ),
          const SizedBox(height: VestaSpace.sm),
          if (top5Categories.isEmpty)
            _buildEmptyCategoryState()
          else
            for (final entry in top5Categories) _buildCategoryNetItem(entry),
        ],
      ),
    );
  }

  Widget _buildEmptyCategoryState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        "No categorized spending yet.\nAssign categories to shared transactions to see them here.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: context.vesta.muted),
      ),
    );
  }

  Widget _buildCategoryNetItem(MapEntry<String, double> entry) {
    final categoryData = _categories[entry.key];
    final netAmount = entry.value;
    final name = categoryData?.name ?? entry.key;
    final count = _getTransactionsForCurrentPeriod()
        .where((t) => t.category == entry.key)
        .length;

    return ListRow(
      title: name,
      subtitle: count == 1 ? "1 transaction" : "$count transactions",
      padding: const EdgeInsets.symmetric(vertical: 6),
      leading: IconBadge(
        categoryIcon(name),
        size: 40,
        circle: false,
        color: context.vesta.accentInk,
      ),
      // Spending shows as a plain amount; money that came back into a
      // category (refunds, income) shows with a plus in green.
      trailing: MoneyText(
        netAmount < 0 ? netAmount.abs() : netAmount,
        showPlus: netAmount > 0,
        color: netAmount > 0 ? context.vesta.pos : null,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Transactions(showBack: true),
            settings: RouteSettings(
              arguments: {'selectedCategory': entry.key},
            ),
          ),
        );
      },
    );
  }

  List<TransactionModel> _getTransactionsForCurrentPeriod() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (now.day >= _budgetResetDay) {
      startDate = DateTime(now.year, now.month, _budgetResetDay);
      final nextMonth = DateTime(now.year, now.month + 1, _budgetResetDay);
      endDate = nextMonth.subtract(const Duration(days: 1));
    } else {
      startDate = DateTime(now.year, now.month - 1, _budgetResetDay);
      final thisMonth = DateTime(now.year, now.month, _budgetResetDay);
      endDate = thisMonth.subtract(const Duration(days: 1));
    }

    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _allTransactions.where((txn) {
      // ✅ Must have valid date, category, and within cycle
      if (txn.date.isBefore(startDate) || txn.date.isAfter(endDate)) {
        return false;
      }
      if (txn.category == null || txn.category!.isEmpty) return false;
      if (!categoryLabels.contains(txn.category)) return false;

      return true;
    }).toList();
  }

  Widget _buildLatestTransactionsSection(
    List<HouseholdTransactionModel> transactions,
  ) {
    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Latest transactions",
            actionLabel: "See all",
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Transactions(showBack: true),
                ),
              ).then((_) {
                _loadData(widget.householdId);
              });
            },
          ),
          const SizedBox(height: VestaSpace.xs),
          if (transactions.isEmpty)
            _buildEmptyTransactionState()
          else
            for (final txn in transactions)
              HouseholdTransactionCard(
                key: ValueKey(txn.id),
                transaction: txn,
                householdId: widget.householdId,
                onCategoryChanged: () {
                  _loadData(widget.householdId);
                  _fetchHouseholdCycleData(widget.householdId);
                },
                onDeleted: () {
                  _loadData(widget.householdId);
                  _fetchHouseholdCycleData(widget.householdId);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        "No shared transactions yet.\nAssign one from a transaction's details.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: context.vesta.muted),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case "food and drinks":
        return Icons.restaurant;
      case "groceries":
        return Icons.shopping_bag;
      case "entertainment":
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case "food and drinks":
        return Colors.blue;
      case "groceries":
        return Colors.amber;
      case "entertainment":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// This is the main household list/manager page
class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HouseholdPageState createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _removing = false;
  String? _healedFor;

  void _openCreateHousehold() => showNewHouseholdDialog(context);

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        96,
        VestaSpace.gutter,
        VestaSpace.xl,
      ),
      children: [
        const Center(child: PixelIcon(PixelArt.shared, size: 72)),
        const SizedBox(height: 14),
        Text(
          "No households yet",
          textAlign: TextAlign.center,
          style: headingStyle(22),
        ),
        const SizedBox(height: VestaSpace.sm),
        Text(
          "Create a household to run a budget with the people you live with.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: context.vesta.muted),
        ),
        const SizedBox(height: VestaSpace.xl),
        PrimaryButton(
          label: 'Create a household',
          onPressed: _openCreateHousehold,
        ),
      ],
    );
  }

  /// [pending] is true while the user doc has writes the server hasn't
  /// confirmed, e.g. right after creating a household. Its id is then in the
  /// list before the household exists on the server, so reading it is
  /// refused for a moment; that must not count as having been removed.
  Widget _buildHouseholdList(List<String> householdIds, {bool pending = false}) {
    final uid = _auth.currentUser?.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('households')
          .where(FieldPath.documentId, whereIn: householdIds)
          .snapshots(),
      builder: (context, householdSnapshot) {
        if (householdSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (householdSnapshot.hasError) {
          // Usually a household we were removed from; tidy the list and the
          // user doc stream rebuilds this
          if (!pending) _heal(householdIds);
          return const Center(child: CircularProgressIndicator());
        }

        final all = householdSnapshot.data?.docs ?? [];
        // Only households this user is still a member of
        final householdDocs = all
            .where(
              (d) => List<String>.from(d.data()['members'] ?? []).contains(uid),
            )
            .toList();
        if (householdDocs.length != householdIds.length && !pending) {
          _heal(householdIds);
        }
        if (householdDocs.isEmpty) return _buildEmptyState();

        final v = context.vesta;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            VestaCard(
              padding: const EdgeInsets.symmetric(
                horizontal: VestaSpace.lg,
                vertical: 4,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: SectionHeader(
                      title: 'Shared households',
                      trailing: [
                        AddRemoveButtons(
                          onAdd: _openCreateHousehold,
                          addTooltip: 'New household',
                          removing: _removing,
                          removeTooltip: 'Leave or delete a household',
                          onToggleRemove: () =>
                              setState(() => _removing = !_removing),
                        ),
                      ],
                    ),
                  ),
                  for (var index = 0; index < householdDocs.length; index++)
                    _householdRow(householdDocs[index], index, v),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Drops households this user was removed from (or that were deleted)
  /// from their own list, once per set of ids.
  void _heal(List<String> householdIds) {
    final key = householdIds.join(',');
    if (_healedFor == key) return;
    _healedFor = key;
    healHouseholdIds(householdIds);
  }

  /// The owner deletes; anyone else leaves.
  Future<void> _removeOrLeave(
    String householdId,
    Map<String, dynamic> household,
  ) async {
    final name = (household['householdName'] ?? 'this household').toString();
    if (isHouseholdOwner(household)) {
      await deleteHousehold(
        context,
        householdId: householdId,
        name: name,
        members: List<String>.from(household['members'] ?? []),
      );
    } else {
      await leaveHousehold(context, householdId: householdId, name: name);
    }
  }

  Widget _householdRow(
    QueryDocumentSnapshot<Map<String, dynamic>> householdDoc,
    int index,
    VestaColors v,
  ) {
    final household = householdDoc.data();
    final householdId = householdDoc.id;
    final memberCount = List<String>.from(household['members'] ?? []).length;
    final budget = (household['budget'] as num?)?.toDouble() ?? 0;
    final spent = (household['totalExpense'] as num?)?.toDouble() ?? 0;
    final owner = isHouseholdOwner(household);

    return InkWell(
      onTap: _removing
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HouseholdDetailPage(householdId: householdId),
                ),
              );
            },
      onLongPress: () => _removeOrLeave(householdId, household),
      child: Container(
        decoration: BoxDecoration(
          border: index == 0
              ? null
              : Border(top: BorderSide(color: v.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (_removing) ...[
              RemoveBadge(onTap: () => _removeOrLeave(householdId, household)),
              const SizedBox(width: VestaSpace.md),
            ],
            IconTile(
              iconKey: household['icon'] as String?,
              fallback: PhosphorIconsRegular.houseLine,
            ),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          household['householdName'] ?? 'Unnamed household',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        memberCount == 1 ? '1 member' : '$memberCount members',
                        style: TextStyle(fontSize: 12, color: v.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  VestaProgressBar(
                    value: budget > 0 ? spent / budget : 0,
                    height: 4,
                    color: spent > budget && budget > 0
                        ? v.neg
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    budget > 0
                        ? '${formatMoney(spent)} of ${formatMoney(budget)}'
                        : (owner
                              ? 'No budget yet. Open to set one.'
                              : 'No budget set yet'),
                    style: Theme.of(context).textTheme.bodySmall,
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

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    // Handle user not being logged in
    if (currentUser == null) {
      return const Scaffold(
        appBar: VestaAppBar(title: "Shared finances"),
        body: Center(child: Text("Please log in to see your households.")),
      );
    }

    // --- FIX 3: Get UID after null check ---
    final String uid = currentUser.uid;

    return Scaffold(
      appBar: const VestaAppBar(title: 'Shared finances'),
      body: VestaBackground(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('users')
              .doc(uid)
              .snapshots(includeMetadataChanges: true),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (userSnapshot.hasError) {
              return Center(child: Text("Error: ${userSnapshot.error}"));
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Center(child: Text("User data not found."));
            }

            final userData = userSnapshot.data!.data();
            // This is the correct way to get the array
            final List<String> householdIds = List<String>.from(
              userData?['householdIds'] ?? [],
            );

            return Column(
              children: [
                _PendingInvites(uid: uid),
                Expanded(
                  child: householdIds.isEmpty
                      ? _buildEmptyState()
                      : _buildHouseholdList(
                          householdIds,
                          pending: userSnapshot.data!.metadata.hasPendingWrites,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Invites sent to this user by username or email, with Accept / Decline.
/// Nothing shows when there are none (or they can't be read).
class _PendingInvites extends StatelessWidget {
  const _PendingInvites({required this.uid});

  final String uid;

  Future<void> _answer(
    BuildContext context,
    String inviteId,
    bool accept,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await answerInvite(inviteId, accept: accept);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept ? 'Joining the household...' : 'Invite declined',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't answer the invite: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: myPendingInvites(uid),
      builder: (context, snap) {
        final invites = snap.hasError ? const [] : (snap.data?.docs ?? const []);
        if (invites.isEmpty) return const SizedBox.shrink();
        final v = context.vesta;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.sm,
          ),
          child: Column(
            children: [
              for (final invite in invites)
                Padding(
                  padding: const EdgeInsets.only(bottom: VestaSpace.sm),
                  child: VestaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.usersThree,
                              color: v.accentInk,
                            ),
                            const SizedBox(width: VestaSpace.md),
                            Expanded(
                              child: Text(
                                '${invite.data()['inviterName'] ?? 'Someone'} '
                                'invited you to join '
                                '${invite.data()['householdName'] ?? 'a household'}.',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VestaSpace.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlineButton(
                                label: 'Decline',
                                onPressed: () =>
                                    _answer(context, invite.id, false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Accept',
                                onPressed: () =>
                                    _answer(context, invite.id, true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
