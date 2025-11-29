// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final String _appDomain = "https://vesta-7e96a.web.app";
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

        // 👇 Get the user's account ID for this transaction (if needed)
        //final accountId = data['accountId'] ?? 'unknown_account';

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

      final inviteLink = "$_appDomain/join?inviteId=${inviteDoc.id}";
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
    final scheme = Theme.of(context).colorScheme;
    final latestTransactions = _getLatestTransactions();
    final categoryNetAmounts = _calculateCategoryNetAmounts();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('households').doc(widget.householdId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: scheme.primary,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data();
        final householdName = data?['householdName'] ?? 'Unnamed Household';
        final List<String> memberUids = List<String>.from(
          data?['members'] ?? [],
        );

        return Scaffold(
          backgroundColor: scheme.primary,
          appBar: AppBar(
            backgroundColor: scheme.primary,
            iconTheme: IconThemeData(color: scheme.surface),
            title: Text(
              householdName,
              style: TextStyle(
                color: scheme.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                onPressed: _createAndShareInviteLink,
                tooltip: "Invite Member",
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- Member Avatars & Names ---
                  _buildMembersList(memberUids),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade400, thickness: 1),
                  const SizedBox(height: 20),

                  /// --- Household Spending Overview ---
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),

                        // ✅ X and Y axis titles
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final now = DateTime.now();
                                final index = value.toInt();

                                // Show last 6 months dynamically
                                final monthDate = DateTime(
                                  now.year,
                                  now.month - 5 + index,
                                );
                                const monthNames = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Aug',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dec',
                                ];
                                final monthLabel =
                                    monthNames[monthDate.month - 1];

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthLabel,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
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
                              color: Colors.grey[400],
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dashArray: [5, 5],
                              dotData: const FlDotData(show: false),
                            ),

                          // Spending line (solid)
                          if (_householdSpendingData.isNotEmpty)
                            LineChartBarData(
                              spots: _householdSpendingData,
                              isCurved: true,
                              color: Theme.of(context).colorScheme.secondary,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.15),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildBudgetTrackerBar(),
                  const SizedBox(height: 20),
                  _buildSpendingCategoriesSection(categoryNetAmounts),
                  const SizedBox(height: 20),
                  _buildLatestTransactionsSection(latestTransactions),
                ],
              ),
            ),
          ),
        );
      },
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
    final percent =
        (_currentCycleHouseholdSpending / _currentCycleHouseholdBudget).clamp(
          0.0,
          1.0,
        );

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
    int cycleYear = now.year;

    return GestureDetector(
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
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Spending Budget for $cycleMonthName $cycleYear",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: percent.isNaN ? 0.0 : percent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "JOD ${_currentCycleHouseholdSpending.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "JOD ${_currentCycleHouseholdBudget.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
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

    return Column(
      children: [
        // Header
        Row(
          children: [
            const Text(
              "Spending Categories",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpendingCategories(),
                  ),
                );
              },
              child: const Text("See All"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // List or Empty State
        if (top5Categories.isEmpty)
          _buildEmptyCategoryState()
        else
          ListView.builder(
            itemCount: top5Categories.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final entry = top5Categories[index];
              return _buildCategoryNetItem(entry);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyCategoryState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No categorized spending yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Assign categories to transactions\nto see your analysis.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNetItem(MapEntry<String, double> entry) {
    final categoryData = _categories[entry.key];
    final netAmount = entry.value;

    final Color amountColor;
    final String sign;
    if (netAmount > 0) {
      amountColor = Colors.green.shade600;
      sign = "+";
    } else if (netAmount < 0) {
      amountColor = Colors.red.shade600;
      sign = "-";
    } else {
      amountColor = Colors.grey.shade600;
      sign = "";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      child: ListTile(
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
        leading: CircleAvatar(
          backgroundColor:
              categoryData?.color.withOpacity(0.2) ??
              Colors.grey.withOpacity(0.2),
          child: Icon(
            categoryData?.icon ?? Icons.category,
            color: categoryData?.color ?? Colors.grey,
          ),
        ),
        title: Text(
          categoryData?.name ?? entry.key,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_getTransactionsForCurrentPeriod().where((t) => t.category == entry.key).length} transactions',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Text(
          "$sign JOD ${netAmount.abs().toStringAsFixed(2)}",
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
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
    return Column(
      children: [
        // Header
        Row(
          children: [
            const Text(
              "Latest Transactions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Transactions(showBack: true),
                  ),
                ).then((_) {
                  _loadData(widget.householdId);
                });
              },
              child: Text(
                "All Transactions",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // List or Empty State
        if (transactions.isEmpty)
          _buildEmptyTransactionState()
        else
          ListView.builder(
            itemCount: transactions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final txn = transactions[index];
              return HouseholdTransactionCard(transaction: txn);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyTransactionState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No transactions found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
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
          return const Center(child: CircularProgressIndicator());
        }

        final userDocs = userSnapshot.data!.docs;

        return SizedBox(
          height: 90, // ✅ gives it fixed height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final userData = userDocs[index].data();
              final username = userData['username'] ?? 'No Name';
              final color = Colors.primaries[index % Colors.primaries.length];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withOpacity(0.8),
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.house_sharp, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Households Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: .w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a household to start managing your budget together.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),

          largeButton(
            context,
            'Create Household',
            Theme.of(context).colorScheme.secondary,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateHousehold()),
              );
            },
          ),
        ],
      ),
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
          return Center(child: CircularProgressIndicator());
        }
        if (householdSnapshot.hasError) {
          return Center(child: Text("Error: ${householdSnapshot.error}"));
        }
        if (!householdSnapshot.hasData ||
            householdSnapshot.data!.docs.isEmpty) {
          return Center(child: Text("Could not find households."));
        }

        final householdDocs = householdSnapshot.data!.docs;

        return ListView.builder(
          itemCount: householdDocs.length,
          itemBuilder: (context, index) {
            final household = householdDocs[index].data();
            final householdId = householdDocs[index].id;

            return ListTile(
              leading: Icon(Icons.house_outlined),
              title: Text(household['householdName'] ?? 'Unnamed Household'),
              subtitle: Text(household['live_text'] ?? 'Tap to open'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HouseholdDetailPage(householdId: householdId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;
    final scheme = Theme.of(context).colorScheme;

    // Handle user not being logged in
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Households")),
        body: Center(child: Text("Please log in to see your households.")),
      );
    }

    // --- FIX 3: Get UID after null check ---
    final String uid = currentUser.uid;

    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Households', style: TextStyle(color: scheme.surface)),
        iconTheme: IconThemeData(color: scheme.surface),
        backgroundColor: scheme.primary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateHousehold()),
          );
        },
        child: Icon(Icons.add, color: scheme.surface),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // 1. OUTER STREAM: Listens to the user's document
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('users')
                .doc(uid)
                .snapshots(), // Use safe uid
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                return Center(child: Text("Error: ${userSnapshot.error}"));
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return Center(child: Text("User data not found."));
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
      ),
    );
  }
}
