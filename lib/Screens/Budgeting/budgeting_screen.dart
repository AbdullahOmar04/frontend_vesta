// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Budgeting/plan_budget.dart';

class PersonalBudgetScreen extends StatefulWidget {
  const PersonalBudgetScreen({super.key});

  @override
  State<PersonalBudgetScreen> createState() => _PersonalBudgetScreenState();
}

class _PersonalBudgetScreenState extends State<PersonalBudgetScreen> {
  // Core data
  Map<String, dynamic> _budgetData = {};
  List<Map<String, dynamic>> _sosps = [];
  bool _isLoading = true;
  final _totalIncomeController = TextEditingController();

  List<FlSpot> _essentialData = [];
  List<FlSpot> _luxuryData = [];
  List<FlSpot> _savingsData = [];

  Map<String, Map<String, String>> _categoryMeta = {};

  double _essentialBudget = 0.0;
  double _essentialSpending = 0.0;
  double _luxuryBudget = 0.0;
  double _luxurySpending = 0.0;
  double _savingsBudget = 0.0;
  double _savingsTransfers = 0.0;
  double _expectedIncome = 0.0;
  double _actualIncome = 0.0;
  double _uncategorizedSpending = 0.0;

  int _budgetResetDay = 28;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _totalIncomeController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    // Fire off API call (non-blocking)
    getSOSPs();

    // Load budget and user settings first
    await _fetchBudget();

    // Load category metadata (shared by cycle data and chart)
    await _loadCategoryMetadata();

    // Load remaining data in parallel
    await Future.wait([
      _fetchSOSPsFromFirestore(),
      _fetchCurrentCycleData(),
      _fetchChartData(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _refreshBudget() {
    _loadAllData();
  }

  /// Loads category metadata once, shared by all calculation functions
  Future<void> _loadCategoryMetadata() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();

      final meta = <String, Map<String, String>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        meta[doc.id] = {
          'type': (data['type'] ?? 'expense') as String,
          'bucket': (data['bucket'] ?? '') as String,
        };
      }

      if (mounted) {
        setState(() => _categoryMeta = meta);
      }
    } catch (e) {
      debugPrint('⚠️ Error loading category metadata: $e');
    }
  }

  /// Helper: Get bucket for a category (with fallback inference)
  String _getBucketForCategory(String category) {
    final meta = _categoryMeta[category];
    final bucketRaw = meta?['bucket'] ?? '';
    return bucketRaw.isEmpty
        ? inferBucketFromCategoryName(category)
        : bucketRaw.toLowerCase();
  }

  /// Helper: Get type for a category
  String _getTypeForCategory(String category) {
    final meta = _categoryMeta[category];
    return (meta?['type'] ?? 'expense').toLowerCase();
  }

  /// Helper: Parse amount from transaction data
  double _getAmountFromData(Map<String, dynamic> data) {
    try {
      final raw = data['amount'];
      if (raw == null) return 0.0;
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? 0.0;
      return 0.0;
    } catch (e) {
      debugPrint('Error parsing amount: $e');
      return 0.0;
    }
  }

  /// Helper: Parse date from transaction data
  DateTime? _getDateTimeFromData(Map<String, dynamic> data) {
    try {
      final raw = data['date'];
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return null;
    }
  }

  /// Helper: Calculate cycle date range for a given reference date
  ({DateTime start, DateTime end}) _getCycleDateRange(DateTime referenceDate) {
    DateTime startDate;
    DateTime endDate;

    if (referenceDate.day >= _budgetResetDay) {
      startDate = DateTime(referenceDate.year, referenceDate.month, _budgetResetDay);
      final nextMonth = DateTime(referenceDate.year, referenceDate.month + 1, _budgetResetDay);
      endDate = nextMonth.subtract(const Duration(days: 1));
    } else {
      startDate = DateTime(referenceDate.year, referenceDate.month - 1, _budgetResetDay);
      final thisMonth = DateTime(referenceDate.year, referenceDate.month, _budgetResetDay);
      endDate = thisMonth.subtract(const Duration(days: 1));
    }

    // Set end date to end of day
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return (start: startDate, end: endDate);
  }

  /// Helper: Check if a date falls within a cycle range
  bool _isDateInCycle(DateTime date, DateTime cycleStart, DateTime cycleEnd) {
    return !date.isBefore(cycleStart) && !date.isAfter(cycleEnd);
  }

  /// Processes a single transaction and returns bucket amounts
  ({double essential, double luxury, double savings, double income, double uncategorized})
      _processTransaction(Map<String, dynamic> data) {
    double essential = 0.0;
    double luxury = 0.0;
    double savings = 0.0;
    double income = 0.0;
    double uncategorized = 0.0;

    final amount = _getAmountFromData(data);
    if (amount == 0) return (essential: 0, luxury: 0, savings: 0, income: 0, uncategorized: 0);

    final transactionType = (data['type'] ?? '').toString().toLowerCase();
    final category = data['category'] as String?;

    // Handle uncategorized transactions
    if (category == null || category.isEmpty) {
      if (transactionType == 'debit') {
        uncategorized = amount;
      }
      return (essential: 0, luxury: 0, savings: 0, income: 0, uncategorized: uncategorized);
    }

    final categoryType = _getTypeForCategory(category);
    final bucket = _getBucketForCategory(category);

    // Route transaction to appropriate bucket
    if (transactionType == 'debit') {
      switch (bucket) {
        case 'essential':
          essential = amount;
          break;
        case 'luxury':
          luxury = amount;
          break;
        case 'savings':
          savings = amount;
          break;
        default:
          // Fallback: treat as essential if expense category
          if (categoryType == 'expense') {
            essential = amount;
          }
      }
    } else if (transactionType == 'credit') {
      // Incoming money
      if (categoryType == 'income' || bucket == 'income') {
        income = amount;
      }
    }

    return (
      essential: essential,
      luxury: luxury,
      savings: savings,
      income: income,
      uncategorized: uncategorized
    );
  }

  Future<void> _fetchBudget() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final String monthId =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch budget for current month
      final budgetDoc = await firestore
          .collection("users")
          .doc(uid)
          .collection("budget")
          .doc(monthId)
          .get();

      // Fetch user settings
      final userDoc = await firestore.collection("users").doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _totalIncomeController.text = (data["totalIncome"] ?? 0).toString();

        if (mounted) {
          setState(() {
            _budgetResetDay = (data["dayOfMonth"] ?? 28) as int;
          });
        }
      }

      if (mounted) {
        setState(() {
          _budgetData = budgetDoc.data() ?? {};
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading budget: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget: $e')),
        );
      }
    }
  }

  Future<void> _fetchCurrentCycleData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_budgetData.isEmpty) return;

    final now = DateTime.now();
    final cycle = _getCycleDateRange(now);

    // Per-bucket tracking
    double essentialSpending = 0.0;
    double luxurySpending = 0.0;
    double savingsTransfers = 0.0;
    double actualIncome = 0.0;
    double uncategorizedSpending = 0.0;
    double totalSavingsBalance = 0.0;

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);

      // Load all linked accounts
      final accountsSnap = await userRef
          .collection('accounts')
          .where('linked', isEqualTo: true)
          .get();

      for (final account in accountsSnap.docs) {
        final accountData = account.data();

        // Check if this is a savings account and add its balance
        final accountTypeCode = (accountData['accountTypeCode'] ?? '').toString();
        if (accountTypeCode == 'SAV.IND') {
          final balance = (accountData['balanceAmount'] ?? 0).toDouble();
          totalSavingsBalance += balance;
        }

        final transactionsSnap = await userRef
            .collection('accounts')
            .doc(account.id)
            .collection('transactions')
            .get();

        for (final txDoc in transactionsSnap.docs) {
          final data = txDoc.data();

          // Parse and validate transaction date
          final transactionDate = _getDateTimeFromData(data);
          if (transactionDate == null) continue;

          // Check if within current cycle
          if (!_isDateInCycle(transactionDate, cycle.start, cycle.end)) {
            continue;
          }

          // Process transaction
          final result = _processTransaction(data);
          essentialSpending += result.essential;
          luxurySpending += result.luxury;
          savingsTransfers += result.savings;
          actualIncome += result.income;
          uncategorizedSpending += result.uncategorized;
        }
      }

      // Calculate budget allocations from percentages
      final totalIncome = double.tryParse(_totalIncomeController.text) ?? 0;
      final savingPercent = (_budgetData['saving'] ?? 0).toDouble();
      final spendingPercent = (_budgetData['spending'] ?? 0).toDouble();
      final luxuriesPercent = (_budgetData['luxuries'] ?? 0).toDouble();

      final essentialBudget = totalIncome * spendingPercent / 100;
      final luxuryBudget = totalIncome * luxuriesPercent / 100;
      final savingsBudget = totalIncome * savingPercent / 100;

      if (mounted) {
        setState(() {
          _essentialBudget = essentialBudget;
          _essentialSpending = essentialSpending;
          _luxuryBudget = luxuryBudget;
          _luxurySpending = luxurySpending;
          _savingsBudget = savingsBudget;
          _savingsTransfers = savingsTransfers;
          _expectedIncome = totalIncome;
          _actualIncome = actualIncome;
          _uncategorizedSpending = uncategorizedSpending;
        });
      }

      // Update Firestore with current totals
      await userRef.update({
        'totalExpense': essentialSpending + luxurySpending,
        'essentialSpending': essentialSpending,
        'luxurySpending': luxurySpending,
        'savingsTransfers': savingsTransfers,
        'totalSavings': totalSavingsBalance,
        'actualIncome': actualIncome,
        'uncategorizedSpending': uncategorizedSpending,
      });
    } catch (e) {
      debugPrint('⚠️ Error fetching cycle data: $e');
    }
  }

  Future<void> _fetchChartData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    List<FlSpot> essentialData = [];
    List<FlSpot> luxuryData = [];
    List<FlSpot> savingsData = [];

    final now = DateTime.now();

    try {
      final accountsSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("accounts")
          .where('linked', isEqualTo: true)
          .get();

      // Collect all transactions once
      final allTransactions = <Map<String, dynamic>>[];
      for (final account in accountsSnap.docs) {
        final txSnap = await account.reference.collection('transactions').get();
        for (final txDoc in txSnap.docs) {
          allTransactions.add(txDoc.data());
        }
      }

      // Process last 6 cycles
      for (int i = 5; i >= 0; i--) {
        // Calculate the reference date for this cycle
        final referenceDate = DateTime(now.year, now.month - i, now.day);
        final cycle = _getCycleDateRange(referenceDate);

        double cycleEssential = 0.0;
        double cycleLuxury = 0.0;
        double cycleSavings = 0.0;

        for (final data in allTransactions) {
          final transactionDate = _getDateTimeFromData(data);
          if (transactionDate == null) continue;

          // Check if within this cycle
          if (!_isDateInCycle(transactionDate, cycle.start, cycle.end)) {
            continue;
          }

          // Process transaction
          final result = _processTransaction(data);
          cycleEssential += result.essential;
          cycleLuxury += result.luxury;
          cycleSavings += result.savings;
        }

        final xValue = (5 - i).toDouble();
        essentialData.add(FlSpot(xValue, cycleEssential));
        luxuryData.add(FlSpot(xValue, cycleLuxury));
        savingsData.add(FlSpot(xValue, cycleSavings));
      }

      if (mounted) {
        setState(() {
          _essentialData = essentialData;
          _luxuryData = luxuryData;
          _savingsData = savingsData;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching chart data: $e');
    }
  }

  Future<void> _fetchSOSPsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final accountsSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("accounts")
          .where("linked", isEqualTo: true)
          .get();

      List<Map<String, dynamic>> all = [];

      for (var account in accountsSnap.docs) {
        final sospSnap = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("accounts")
            .doc(account.id)
            .collection("sosps")
            .get();

        final accountData = account.data();
        final accountName = (accountData['nickname'] ??
                accountData['accountName'] ??
                accountData['name'] ??
                'Account ${account.id}')
            .toString();

        for (var doc in sospSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['associatedAccountName'] = accountName;
          all.add(data);
        }
      }

      // Sort by next payment date
      all.sort((a, b) {
        final aDate = DateTime.tryParse(
                a["paymentSchedule"]?["nextPaymentDateTime"] ?? "") ??
            DateTime.now();
        final bDate = DateTime.tryParse(
                b["paymentSchedule"]?["nextPaymentDateTime"] ?? "") ??
            DateTime.now();
        return aDate.compareTo(bDate);
      });

      if (mounted) {
        setState(() => _sosps = all);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching SOSPs: $e');
    }
  }

  // ==================== BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Personal Budget",
          style: TextStyle(color: scheme.surface, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: scheme.surface),
        backgroundColor: scheme.primary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlanBudgetScreen()),
              );
              if (result == true) {
                _refreshBudget();
              }
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Manage"),
            style: TextButton.styleFrom(foregroundColor: scheme.surface),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refreshBudget(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildContent(),
              ),
            ),
    );
  }

  Widget _buildContent() {
    final totalIncome = double.tryParse(_totalIncomeController.text) ?? 0;
    final savingPercent = (_budgetData["saving"] ?? 0).toDouble();
    final spendingPercent = (_budgetData["spending"] ?? 0).toDouble();
    final luxuriesPercent = (_budgetData["luxuries"] ?? 0).toDouble();

    final savingAmount = totalIncome * savingPercent / 100;
    final spendingAmount = totalIncome * spendingPercent / 100;
    final luxuriesAmount = totalIncome * luxuriesPercent / 100;
    final remainingAmount =
        totalIncome - savingAmount - spendingAmount - luxuriesAmount;

    if (_budgetData.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget tracker bar showing total spending progress
        _buildBudgetTrackerBar(),
        const SizedBox(height: 24),
        _buildBudgetLineChart(),
        const SizedBox(height: 24),
        _buildBudgetBreakdown(remainingAmount, totalIncome),
        const SizedBox(height: 24),
        _buildUpcomingPayments(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Image.asset('assets/images/budgeting.png', width: 150, height: 150),
          const SizedBox(height: 16),
          Text(
            "No Budget Plan Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first budget plan to\nstart managing your finances",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 250,
            child: largeButton(
              context,
              'Create Budget Plan',
              Theme.of(context).colorScheme.secondary,
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlanBudgetScreen()),
                );
                if (result == true) {
                  _refreshBudget();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTrackerBar() {
    final totalSpending = _essentialSpending + _luxurySpending;
    final totalBudget = _essentialBudget + _luxuryBudget;
    final percent = totalBudget > 0
        ? (totalSpending / totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final isOverBudget = totalSpending > totalBudget;

    final now = DateTime.now();
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Spending - ${monthNames[now.month]} ${now.year}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Over Budget!",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    color: isOverBudget ? Colors.red : Colors.white,
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
                "JOD ${totalSpending.toStringAsFixed(0)}",
                style: TextStyle(
                  color: isOverBudget ? Colors.red[300] : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "JOD ${totalBudget.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Show uncategorized warning if present
          if (_uncategorizedSpending > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[300], size: 16),
                const SizedBox(width: 4),
                Text(
                  "JOD ${_uncategorizedSpending.toStringAsFixed(0)} uncategorized",
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetLineChart() {
    final totalBudget = _essentialBudget + _luxuryBudget;

    final List<FlSpot> budgetLineData = [
      FlSpot(0, totalBudget),
      FlSpot(5, totalBudget),
    ];

    final List<String> monthLabels = [];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      monthLabels.add(monthNames[month.month - 1]);
    }

    // Combine essential + luxury for total spending line
    final List<FlSpot> totalSpendingData = [];
    for (int i = 0; i < _essentialData.length; i++) {
      final essential = _essentialData[i].y;
      final luxury = i < _luxuryData.length ? _luxuryData[i].y : 0.0;
      totalSpendingData.add(FlSpot(i.toDouble(), essential + luxury));
    }

    final bool hasData = totalSpendingData.isNotEmpty || _savingsData.isNotEmpty;

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Budget", Colors.grey[400]!, dashed: true),
              const SizedBox(width: 16),
              _buildLegendItem("Spending", Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem("Savings", Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
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
                        final index = value.toInt();
                        if (index >= 0 && index < monthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              monthLabels[index],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: hasData
                    ? [
                        // Budget line (dashed)
                        LineChartBarData(
                          spots: budgetLineData,
                          isCurved: false,
                          color: Colors.grey[300],
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                          dashArray: [5, 5],
                        ),
                        // Total spending line (essential + luxury)
                        if (totalSpendingData.isNotEmpty)
                          LineChartBarData(
                            spots: totalSpendingData,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        // Savings line
                        if (_savingsData.isNotEmpty)
                          LineChartBarData(
                            spots: _savingsData,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.1),
                            ),
                          ),
                      ]
                    : [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool dashed = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed
                ? Border(
                    bottom: BorderSide(
                      color: color,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBudgetBreakdown(double remaining, double income) {
    final currentMonth = DateTime.now().month;
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Budget Plan for ${monthNames[currentMonth]}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            "Based on JOD ${income.toStringAsFixed(0)} income",
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Savings with progress
          _buildBreakdownItemWithProgress(
            label: "Savings",
            budgetAmount: _savingsBudget,
            spentAmount: _savingsTransfers,
            color: Colors.green,
            icon: Icons.savings,
            isInverted: true, // For savings, "spent" means transferred to savings
          ),

          // Essential Spending with progress
          _buildBreakdownItemWithProgress(
            label: "Essential Spending",
            budgetAmount: _essentialBudget,
            spentAmount: _essentialSpending,
            color: Colors.blue,
            icon: Icons.shopping_cart,
          ),

          // Luxuries with progress
          _buildBreakdownItemWithProgress(
            label: "Luxuries",
            budgetAmount: _luxuryBudget,
            spentAmount: _luxurySpending,
            color: Colors.orange,
            icon: Icons.diamond,
          ),

          // Income tracking
          if (_actualIncome > 0 || _expectedIncome > 0) _buildIncomeTracker(),

          // Unallocated
          if (remaining > 0)
            _buildBreakdownItem(
              "Unallocated",
              remaining,
              Colors.grey,
              Icons.help_outline,
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItemWithProgress({
    required String label,
    required double budgetAmount,
    required double spentAmount,
    required Color color,
    required IconData icon,
    bool isInverted = false,
  }) {
    if (budgetAmount <= 0) return const SizedBox.shrink();

    final percent = (spentAmount / budgetAmount).clamp(0.0, 1.0);
    final isOverBudget = !isInverted && spentAmount > budgetAmount;
    final isOnTrack = isInverted && spentAmount >= budgetAmount;
    final percentDisplay = (percent * 100).toStringAsFixed(0);

    // For savings: green when on track, orange when behind
    // For spending: normal when under, red when over
    Color statusColor;
    String statusText;

    if (isInverted) {
      // Savings logic
      statusColor = isOnTrack ? Colors.green : Colors.orange;
      statusText = isOnTrack ? "✓ Done" : "$percentDisplay%";
    } else {
      // Spending logic
      statusColor = isOverBudget ? Colors.red : color;
      statusText = isOverBudget ? "Over!" : "$percentDisplay%";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "JOD ${spentAmount.toStringAsFixed(0)} / ${budgetAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverBudget ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isOverBudget ? Colors.red : color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTracker() {
    final percent = _expectedIncome > 0
        ? (_actualIncome / _expectedIncome).clamp(0.0, 1.5)
        : 0.0;
    final isOnTrack = _actualIncome >= _expectedIncome;
    final percentDisplay = (percent * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Income Received",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "JOD ${_actualIncome.toStringAsFixed(0)} / ${_expectedIncome.toStringAsFixed(0)} expected",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnTrack ? Colors.teal : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnTrack ? Icons.check_circle : Icons.schedule,
                      color: isOnTrack ? Colors.teal : Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnTrack ? "Received" : "$percentDisplay%",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOnTrack ? Colors.teal : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    if (amount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            "JOD ${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPayments() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                "Upcoming Payments",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          if (!_isLoading && _sosps.isEmpty)
            const Text(
              "No upcoming payments",
              style: TextStyle(color: Colors.grey),
            ),

          if (!_isLoading && _sosps.isNotEmpty)
            ..._sosps.map((sosp) => _buildPaymentItemFromData(sosp)),
        ],
      ),
    );
  }

  Widget _buildPaymentItemFromData(Map<String, dynamic> sosp) {
    final nickname = sosp["SOSPNickname"] ?? "Scheduled Payment";
    final beneficiaryName =
        sosp["SOSPBeneficiary"]?["beneficiaryName"]?["enName"] ?? nickname;
    final accountName = sosp['associatedAccountName'] ?? 'Unknown Account';
    final amount =
        (sosp["paymentSchedule"]?["nextPaymentAmount"]?["amount"] ?? 0.0)
            .toDouble();
    final currency =
        sosp["paymentSchedule"]?["nextPaymentAmount"]?["currency"] ?? "JOD";
    final status = (sosp["SOSPStatus"] ?? "unknown").toString();
    final type = (sosp["SOSPType"] ?? "departure").toString();
    final remaining = sosp["paymentSchedule"]?["remainingPayments"];
    final frequency =
        sosp["paymentSchedule"]?["frequencyInfo"]?["frequency"] as String?;

    final nextPaymentDateStr = sosp["paymentSchedule"]?["nextPaymentDateTime"];
    String formattedDate = "No date";
    if (nextPaymentDateStr != null) {
      final parsedDate = DateTime.tryParse(nextPaymentDateStr);
      if (parsedDate != null) {
        final monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        formattedDate =
            "Next: ${parsedDate.day} ${monthNames[parsedDate.month - 1]} ${parsedDate.year}";
      }
    }

    final icon = type == "arrival" ? Icons.call_received : Icons.call_made;
    final color = status == "active"
        ? Theme.of(context).primaryColor
        : Colors.grey;

    return _buildPaymentItem(
      title: beneficiaryName,
      accountName: accountName,
      amount: amount,
      currency: currency,
      type: type,
      status: status,
      nextPaymentDate: formattedDate,
      remainingPayments: remaining as int?,
      frequency: frequency,
      icon: icon,
      color: color,
    );
  }

  Widget _buildPaymentItem({
    required String title,
    required String accountName,
    required double amount,
    required String currency,
    required String type,
    required String status,
    required String nextPaymentDate,
    int? remainingPayments,
    String? frequency,
    required IconData icon,
    required Color color,
  }) {
    final bool isIncoming = type == "arrival";
    final amountColor = isIncoming ? Colors.green[700] : Colors.red[700];
    final amountSign = isIncoming ? "+" : "-";
    final statusText =
        status.substring(0, 1).toUpperCase() + status.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "From: $accountName",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextPaymentDate,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  "Status: $statusText",
                  style: TextStyle(
                    fontSize: 13,
                    color: status == "active"
                        ? Colors.green[700]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (frequency != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Frequency: ${frequency[0].toUpperCase()}${frequency.substring(1)}",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "$amountSign $currency ${amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
              if (remainingPayments != null) ...[
                const SizedBox(height: 4),
                Text(
                  "$remainingPayments payments left",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}