// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Household/create_household.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/new_spending.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/spending_categories.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';

const List<String> categoryLabels = [
  'Food And Drinks',
  'Groceries',
  'Entertainment',
  'Others',
];

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
      builder: (context) => AlertDialog(
        title: const Text('Rename household'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
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
            backgroundColor: Colors.red,
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

        return Scaffold(
          appBar: VestaAppBar(
            title: householdName,
            actions: [
              IconButton(
                icon: const Icon(PhosphorIconsRegular.userPlus),
                onPressed: _createAndShareInviteLink,
                tooltip: "Invite member",
              ),
              HeaderButton(
                label: "Rename",
                onPressed: () => _editHouseholdName(householdName),
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
                /// --- Member Avatars & Names ---
                _buildMembersList(memberUids),
                const SizedBox(height: 14),

                /// --- Household Spending Overview ---
                _buildChart(),
                const SizedBox(height: 14),
                _buildBudgetTrackerBar(),
                const SizedBox(height: 14),
                _buildSpendingCategoriesSection(categoryNetAmounts),
                const SizedBox(height: 14),
                _buildLatestTransactionsSection(latestTransactions),
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

  Widget _buildBudgetTrackerBar() {
    final v = context.vesta;
    // The cycle loader stores 0.01 when no budget is set, to avoid dividing
    // by zero, so anything at or below that counts as no budget.
    final hasBudget = _currentCycleHouseholdBudget > 0.01;
    final used = hasBudget
        ? _currentCycleHouseholdSpending / _currentCycleHouseholdBudget
        : 0.0;
    final left = _currentCycleHouseholdBudget - _currentCycleHouseholdSpending;

    final now = DateTime.now();
    final monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    String cycleMonthName = monthNames[now.month];
    final small = TextStyle(fontSize: 12, color: v.muted);
    final leftColor = used > 1 ? v.neg : v.muted;

    return VestaCard(
      onTap: () async {
        final newBudget = await inputHouseholBudget(
          context,
          widget.householdId,
          _manualHouseholdBudget,
        );

        if (newBudget != null && mounted) {
          // 1) Update local state for the bar
          setState(() {
            _manualHouseholdBudget = newBudget;
            _currentCycleHouseholdBudget = newBudget;
          });

          // 2) Recompute cycle spending + chart lines using new budget
          await _fetchHouseholdCycleData(widget.householdId);
          await _fetchHouseholdChartData(widget.householdId);

          if (!mounted) return;

          // 3) Confirm to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Budget updated to JOD ${newBudget.toStringAsFixed(0)}",
              ),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  "Household budget for $cycleMonthName",
                  style: small,
                ),
              ),
              Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: v.accentInk),
            ],
          ),
          const SizedBox(height: VestaSpace.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              MoneyText.hero(_currentCycleHouseholdSpending, size: 30),
              if (hasBudget)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    "of ${formatMoney(_currentCycleHouseholdBudget)}",
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),

          // Progress bar
          VestaProgressBar(
            value: used,
            height: 12,
            color: used > 1 ? v.neg : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: VestaSpace.sm),

          // Labels
          Text(
            !hasBudget
                ? "No budget set yet. Tap to add one."
                : left >= 0
                ? "${formatMoney(left)} left"
                : "${formatMoney(-left)} over",
            style: small.copyWith(color: leftColor),
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

  Widget _buildMembersList(List<String> memberUids) {
    if (memberUids.isEmpty) {
      return const Center(child: Text("No members found."));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('users')
          .where(
            FieldPath.documentId,
            whereIn: memberUids.isNotEmpty ? memberUids : ['_'],
          )
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final userDocs = userSnapshot.data!.docs;
        // Light avatar colours that keep the dark initial readable.
        final v = context.vesta;
        final palette = [v.pxBlue, v.pxGreen, v.pxYellow, v.pxTeal];

        return VestaCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: userDocs.length,
              itemBuilder: (context, index) {
                final userData = userDocs[index].data();
                final username = userData['username'] ?? 'No Name';
                final profileImageUrl =
                    userData['profileImageUrl'] as String?;
                final color = palette[index % palette.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: color,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl == null
                            ? Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : '?',
                                style: headingStyle(
                                  18,
                                  color: context.vesta.pxInk,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(username, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
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
          return Center(child: Text(kDebugMode
              ? "Error: ${householdSnapshot.error}"
              : "Something went wrong. Please try again later."));
        }
        if (!householdSnapshot.hasData ||
            householdSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Could not find households."));
        }

        final householdDocs = householdSnapshot.data!.docs;
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
                  for (var index = 0; index < householdDocs.length; index++)
                    _householdRow(householdDocs, index, v),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: VestaSpace.md),
              child: Text(
                "Hold a household to delete it.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _householdRow(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> householdDocs,
    int index,
    VestaColors v,
  ) {
    final household = householdDocs[index].data();
    final householdId = householdDocs[index].id;

    final members = List<String>.from(household['members'] ?? []);
    final memberCount = members.length;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HouseholdDetailPage(householdId: householdId),
          ),
        );
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete household'),
            content: const Text(
              'Are you sure you want to delete this household? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Remove household reference from ALL members
                  for (final memberUid in members) {
                    final userDocRef = _db
                        .collection('users')
                        .doc(memberUid);
                    await userDocRef.update({
                      'householdIds': FieldValue.arrayRemove([
                        householdId,
                      ]),
                    });
                  }

                  // Delete the household document itself
                  await _db
                      .collection('households')
                      .doc(householdId)
                      .delete();

                  Navigator.pop(context); // Close dialog
                  setState(() {}); // Refresh list
                },
                style: TextButton.styleFrom(foregroundColor: v.neg),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: index == 0
              ? null
              : Border(top: BorderSide(color: v.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
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
                  Text(
                    household['householdName'] ?? 'Unnamed Household',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    household['live_text'] ?? 'Tap to open',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(PhosphorIconsRegular.usersThree, size: 16, color: v.muted),
            const SizedBox(width: VestaSpace.xs),
            Text('$memberCount', style: TextStyle(fontSize: 13, color: v.muted)),
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
      appBar: VestaAppBar(
        title: 'Shared finances',
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.plus),
            tooltip: 'New household',
            onPressed: _openCreateHousehold,
          ),
        ],
      ),
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
