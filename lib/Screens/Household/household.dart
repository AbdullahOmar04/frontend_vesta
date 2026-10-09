// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Household/create_household.dart';
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

/// A household member as the screens show them.
typedef _Member = ({String uid, String name, String? photo});

class HouseholdDetailPage extends StatefulWidget {
  final String householdId;

  const HouseholdDetailPage({super.key, required this.householdId});

  @override
  State<HouseholdDetailPage> createState() => _HouseholdDetailPageState();
}

class _HouseholdDetailPageState extends State<HouseholdDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final String _appDomain = "https://vestaapp.co";
  List<HouseholdTransactionModel> _allTransactions = [];
  Map<String, CategoryData> _categories = {};
  double _currentCycleHouseholdBudget = 0;
  double _currentCycleHouseholdSpending = 0;
  int _budgetResetDay = 28;
  List<FlSpot> _householdSpendingData = [];
  List<FlSpot> _householdBudgetData = [];
  double _manualHouseholdBudget = 0;

  bool _loading = true;

  /// 0 = Budget, 1 = Spendings
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadData(widget.householdId);
    _fetchHouseholdCycleData(widget.householdId);
    _fetchHouseholdChartData(widget.householdId);
    _loadHouseholdBudget();
  }

  Future<void> _editHouseholdName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => VestaDialog(
        title: 'Rename household',
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Household name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
        ),
        confirmLabel: 'Save',
        onConfirm: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(context, controller.text.trim());
          }
        },
      ),
    );

    if (newName != null && newName != currentName) {
      await _db.collection('households').doc(widget.householdId).update({
        'householdName': newName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Household name updated')),
        );
      }
    }
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
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('users')
              .where(FieldPath.documentId, whereIn: memberUids)
              .snapshots(),
          builder: (context, usersSnapshot) {
            final profiles = {
              for (final d in usersSnapshot.data?.docs ?? const [])
                d.id: d.data(),
            };
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
                        _openManage(householdName, members, ownerUid),
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
                      _buildBudgetTrackerBar(),
                    ] else ...[
                      _buildMemberSpending(members),
                      const SizedBox(height: 14),
                      _buildSpendingCategoriesSection(categoryNetAmounts),
                      const SizedBox(height: 14),
                      _buildLatestTransactionsSection(latestTransactions),
                    ],
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

  /// Overlapping avatars and "Name (owner) · Name", after the prototype.
  Widget _membersHeader(List<_Member> members, String? ownerUid) {
    final v = context.vesta;
    final palette = _memberColors(v);
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
              m.uid == ownerUid ? '${m.name} (owner)' : m.name,
          ].join(' · '),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: v.muted),
        ),
      ],
    );
  }

  List<Color> _memberColors(VestaColors v) =>
      [v.pxPurple, v.pxBlue, v.pxYellow, v.pxGreen, v.pxTeal];

  /// Budget / Spendings switch. The prototype's Savings tab waits for
  /// shared savings data.
  Widget _tabSwitcher() {
    final v = context.vesta;
    final accent = Theme.of(context).colorScheme.primary;
    const labels = ['Budget', 'Spendings'];
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
    final palette = _memberColors(v);
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

  /// Members, invite, rename, budget, and Delete (owner) or Leave (others).
  Future<void> _openManage(
    String householdName,
    List<_Member> members,
    String? ownerUid,
  ) async {
    final me = _auth.currentUser?.uid;
    final isOwner = ownerUid != null && ownerUid == me;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final v = sheetContext.vesta;
        final palette = _memberColors(v);
        return SafeArea(
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
                Text('Manage household', style: headingStyle(20)),
                const SizedBox(height: VestaSpace.lg),
                VestaCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VestaSpace.lg,
                    vertical: VestaSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Members'),
                      const SizedBox(height: VestaSpace.xs),
                      for (var i = 0; i < members.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: palette[i % palette.length],
                                backgroundImage: members[i].photo != null
                                    ? NetworkImage(members[i].photo!)
                                    : null,
                                child: members[i].photo == null
                                    ? Text(
                                        members[i].name.isNotEmpty
                                            ? members[i].name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: v.pxInk,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: VestaSpace.md),
                              Expanded(
                                child: Text(
                                  members[i].uid == me
                                      ? '${members[i].name} (you)'
                                      : members[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (members[i].uid == ownerUid)
                                TagChip.pill('Owner', color: v.accentInk),
                              if (isOwner && members[i].uid != ownerUid)
                                TextButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final removed = await removeHouseholdMember(
                                      sheetContext,
                                      householdId: widget.householdId,
                                      memberUid: members[i].uid,
                                      memberName: members[i].name,
                                    );
                                    if (!removed || !sheetContext.mounted) {
                                      return;
                                    }
                                    Navigator.pop(sheetContext);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${members[i].name} was removed',
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: v.neg,
                                  ),
                                  child: const Text('Remove'),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: VestaSpace.md),
                VestaCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VestaSpace.lg,
                    vertical: VestaSpace.xs,
                  ),
                  child: Column(
                    children: [
                      ListRow(
                        title: 'Invite a member',
                        leading: Icon(
                          PhosphorIconsRegular.userPlus,
                          color: v.accentInk,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _createAndShareInviteLink();
                        },
                      ),
                      ListRow(
                        title: 'Rename household',
                        leading: Icon(
                          PhosphorIconsRegular.pencilSimple,
                          color: v.accentInk,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _editHouseholdName(householdName);
                        },
                      ),
                      ListRow(
                        title: 'Household budget',
                        subtitle: _manualHouseholdBudget > 0
                            ? formatMoney(_manualHouseholdBudget)
                            : 'Not set',
                        leading: Icon(
                          PhosphorIconsRegular.wallet,
                          color: v.accentInk,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _editBudget();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VestaSpace.lg),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: v.neg,
                    side: BorderSide(color: v.neg.withValues(alpha: 0.6)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VestaRadius.button),
                    ),
                  ),
                  icon: Icon(
                    isOwner
                        ? PhosphorIconsRegular.trash
                        : PhosphorIconsRegular.signOut,
                    size: 18,
                  ),
                  label: Text(isOwner ? 'Delete household' : 'Leave household'),
                  onPressed: () async {
                    final done = isOwner
                        ? await deleteHousehold(
                            sheetContext,
                            householdId: widget.householdId,
                            name: householdName,
                            members: members.map((m) => m.uid).toList(),
                          )
                        : await leaveHousehold(
                            sheetContext,
                            householdId: widget.householdId,
                            name: householdName,
                          );
                    if (!done || !sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (mounted) Navigator.pop(context);
                  },
                ),
                if (!isOwner)
                  Padding(
                    padding: const EdgeInsets.only(top: VestaSpace.sm),
                    child: Text(
                      'Only the owner can remove members or delete the household.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart() {
    final v = context.vesta;
    final allY = [
      ..._householdBudgetData.map((p) => p.y),
      ..._householdSpendingData.map((p) => p.y),
    ];
    final hasData = allY.any((y) => y > 0);
    final top = niceChartTop(allY.isEmpty ? 0 : allY.reduce(math.max));
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Household spending",
            style: TextStyle(fontSize: 12, color: v.muted),
          ),
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
                              final now = DateTime.now();
                              final index = value.toInt();

                              // Show last 6 months dynamically
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
                        if (_householdBudgetData.isNotEmpty)
                          LineChartBarData(
                            spots: _householdBudgetData,
                            isCurved: false,
                            color: v.muted,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),

                        // Spending line (solid)
                        if (_householdSpendingData.isNotEmpty)
                          LineChartBarData(
                            spots: _householdSpendingData,
                            isCurved: false,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: VestaSpace.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              _legendItem("Spending", Theme.of(context).colorScheme.primary),
              _legendItem("Budget", v.muted),
            ],
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
      final manualBudget = (data["budget"] ?? 0).toDouble();
      final resetDay = (data["budgetResetDay"] ?? _budgetResetDay).toInt();

      List<FlSpot> spendingPoints = [];
      List<FlSpot> budgetPoints = [];

      // Loop through the past 6 cycles (5 previous + current)
      for (int i = 5; i >= 0; i--) {
        // 1️⃣ Determine start & end dates for each cycle
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

        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );

        // 2️⃣ Query household transactions for that month
        double totalSpending = 0;
        final txSnap = await FirebaseFirestore.instance
            .collection("households")
            .doc(householdId)
            .collection("transactions")
            .get();

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
          if (!txDate.isBefore(startDate) && !txDate.isAfter(endDate)) {
            final amtStr = (tData["amount"] ?? 0).toString();
            final amount = double.tryParse(amtStr) ?? 0;
            totalSpending += amount;
          }
        }

        // 3️⃣ Add chart points
        final x = (5 - i).toDouble();
        spendingPoints.add(FlSpot(x, totalSpending));
        budgetPoints.add(FlSpot(x, manualBudget));
      }

      if (mounted) {
        setState(() {
          _householdSpendingData = spendingPoints;
          _householdBudgetData = budgetPoints;
        });
      }
    } catch (e, st) {
      debugPrint("⚠️ Error fetching household chart data: $e\n$st");
    }
  }

  /// Edits the household budget, then refreshes the figures that use it.
  Future<void> _editBudget() async {
    final newBudget = await inputHouseholBudget(
      context,
      widget.householdId,
      _manualHouseholdBudget,
    );
    if (newBudget == null || !mounted) return;

    setState(() {
      _manualHouseholdBudget = newBudget;
      _currentCycleHouseholdBudget = newBudget;
    });
    await _fetchHouseholdCycleData(widget.householdId);
    await _fetchHouseholdChartData(widget.householdId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Budget updated to ${formatMoney(newBudget)}"),
      ),
    );
  }

  /// The prototype's "Budget plan for (month)" card: the household budget
  /// against what has been spent this cycle.
  Widget _buildBudgetTrackerBar() {
    final v = context.vesta;
    // The cycle loader stores 0.01 when no budget is set, to avoid dividing
    // by zero, so anything at or below that counts as no budget.
    final hasBudget = _currentCycleHouseholdBudget > 0.01;
    final budget = hasBudget ? _currentCycleHouseholdBudget : 0.0;
    final spent = _currentCycleHouseholdSpending;
    final left = budget - spent;
    final over = hasBudget && spent > budget;
    final monthName = DateFormat('MMMM').format(DateTime.now());

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
                tooltip: 'Edit budget',
                onPressed: _editBudget,
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
          VestaProgressBar(
            value: hasBudget ? spent / budget : 0,
            height: 8,
            color: over ? v.neg : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: VestaSpace.sm),
          Text(
            !hasBudget
                ? 'No budget set yet. Tap the pencil to add one.'
                : left >= 0
                ? '${formatMoney(left)} left this cycle'
                : '${formatMoney(-left)} over this cycle',
            style: TextStyle(fontSize: 12, color: over ? v.neg : v.muted),
          ),
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

  void _openCreateHousehold() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateHousehold()),
    ).then((_) {
      setState(() {}); // Refresh on return
    });
  }

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

  Widget _buildHouseholdList(List<String> householdIds) {
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
          _heal(householdIds);
          return const Center(child: CircularProgressIndicator());
        }

        final all = householdSnapshot.data?.docs ?? [];
        // Only households this user is still a member of
        final householdDocs = all
            .where(
              (d) => List<String>.from(d.data()['members'] ?? []).contains(uid),
            )
            .toList();
        if (householdDocs.length != householdIds.length) _heal(householdIds);
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
            IconBadge(
              PhosphorIconsRegular.houseLine,
              size: 40,
              circle: false,
              color: v.accentInk,
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
              .snapshots(),
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

            // HERE IS YOUR LOGIC
            if (householdIds.isEmpty) {
              return _buildEmptyState();
            } else {
              return _buildHouseholdList(householdIds);
            }
          },
        ),
      ),
    );
  }
}
