// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Bills/bills_data.dart';
import 'package:frontend_vesta/Screens/Bills/bills_screen.dart';
import 'package:frontend_vesta/Screens/Budgeting/plan_budget.dart';

class PersonalBudgetScreen extends StatefulWidget {
  const PersonalBudgetScreen({super.key});

  @override
  State<PersonalBudgetScreen> createState() => _PersonalBudgetScreenState();
}

class _PersonalBudgetScreenState extends State<PersonalBudgetScreen> {
  // Core data
  Map<String, dynamic> _budgetData = {};
  List<UpcomingPayment> _upcoming = [];
  bool _removingBills = false;
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
      _loadUpcoming(),
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
        });
      }

      // Update Firestore with current totals
      await updateIfChanged(userRef, {
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

  /// Bills and the standing orders on linked accounts, soonest first.
  Future<void> _loadUpcoming() async {
    try {
      final upcoming = await loadUpcomingPayments();
      if (mounted) setState(() => _upcoming = upcoming);
    } catch (e) {
      debugPrint('⚠️ Error fetching upcoming payments: $e');
    }
  }

  // ==================== BUILD METHODS ====================

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Future<void> _openPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanBudgetScreen()),
    );
    if (result == true) {
      _refreshBudget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VestaAppBar(title: "Budgeting"),
      body: VestaBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _refreshBudget(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    VestaSpace.gutter,
                    VestaSpace.xs,
                    VestaSpace.gutter,
                    VestaSpace.xl,
                  ),
                  children: [_buildContent()],
                ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBudgetLineChart(),
        const SizedBox(height: 14),
        _buildBudgetBreakdown(remainingAmount, totalIncome),
        const SizedBox(height: 14),
        _buildUpcomingPayments(),
      ],
    );
  }

  Widget _buildEmptyState() {
    final v = context.vesta;
    return Padding(
      padding: const EdgeInsets.only(top: 96),
      child: Column(
        children: [
          const PixelIcon(PixelArt.budget, size: 72),
          const SizedBox(height: 14),
          Text("No budget plan yet", style: headingStyle(22)),
          const SizedBox(height: VestaSpace.sm),
          Text(
            "Split your income into savings, necessities and luxuries, and see how each cycle tracks against it.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: v.muted),
          ),
          const SizedBox(height: VestaSpace.xl),
          PrimaryButton(label: 'Create budget plan', onPressed: _openPlan),
        ],
      ),
    );
  }

  Widget _buildBudgetLineChart() {
    final v = context.vesta;

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

    final series = [
      (_savingsData, v.bucketSavings),
      (_essentialData, v.bucketEssential),
      (_luxuryData, v.bucketLuxury),
    ];
    final allY = [
      for (final s in series) ...s.$1.map((p) => p.y),
    ];
    final bool hasData = allY.any((y) => y > 0);
    final top = niceChartTop(allY.isEmpty ? 0 : allY.reduce(math.max));

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Spending by bucket",
            style: TextStyle(fontSize: 12, color: v.muted),
          ),
          const SizedBox(height: VestaSpace.md),
          SizedBox(
            height: 170,
            child: !hasData
                ? Center(
                    child: Text(
                      "No spending in the last six months yet",
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
                              if (index < 0 || index >= monthLabels.length) {
                                return const SizedBox.shrink();
                              }
                              final current = index == monthLabels.length - 1;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthLabels[index],
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
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        for (final s in series)
                          if (s.$1.isNotEmpty) line(s.$1, s.$2),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: VestaSpace.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildLegendItem("Savings", v.bucketSavings),
              _buildLegendItem("Necessities", v.bucketEssential),
              _buildLegendItem("Luxuries", v.bucketLuxury),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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

  Widget _statTile(String label, double amount, Color color, {String? sub}) {
    final v = context.vesta;
    return Container(
      padding: const EdgeInsets.all(VestaSpace.md),
      decoration: BoxDecoration(
        color: v.raised,
        borderRadius: BorderRadius.circular(VestaRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: v.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(amount, size: 20, color: color),
          ),
          if (sub != null)
            Text(sub, style: TextStyle(fontSize: 11, color: v.muted)),
        ],
      ),
    );
  }

  Widget _buildBudgetBreakdown(double remaining, double income) {
    final v = context.vesta;
    final currentMonth = DateTime.now().month;
    final totalSpending = _essentialSpending + _luxurySpending;
    final totalBudget = _essentialBudget + _luxuryBudget;

    // Each bucket's share of income, for the split bar.
    final segments = [
      (_savingsTransfers, v.bucketSavings),
      (_essentialSpending, v.bucketEssential),
      (_luxurySpending, v.bucketLuxury),
    ];

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Budget plan for ${_monthNames[currentMonth]}",
            trailing: [
              OutlineIconButton(
                icon: PhosphorIconsRegular.pencilSimple,
                tooltip: "Edit budget plan",
                onPressed: _openPlan,
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          Row(
            children: [
              Expanded(child: _statTile("Total income", income, v.pos)),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  "Spent so far",
                  totalSpending,
                  totalSpending > totalBudget && totalBudget > 0
                      ? v.neg
                      : Theme.of(context).colorScheme.onSurface,
                  sub: totalBudget > 0 ? "of ${formatMoney(totalBudget)}" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  // Lay segments end to end, capped at the bar's width in
                  // case spending runs past income.
                  final parts = <Widget>[];
                  var left = w;
                  for (final s in segments) {
                    if (income <= 0 || s.$1 <= 0 || left <= 0) continue;
                    final width = math.min(w * (s.$1 / income), left);
                    parts.add(
                      SizedBox(width: width, child: ColoredBox(color: s.$2)),
                    );
                    left -= width;
                    if (left > 2) {
                      parts.add(const SizedBox(width: 2));
                      left -= 2;
                    }
                  }
                  return Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: v.track)),
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: parts,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: VestaSpace.sm),
          _buildBreakdownItemWithProgress(
            label: "Savings",
            budgetAmount: _savingsBudget,
            spentAmount: _savingsTransfers,
            color: v.bucketSavings,
            isInverted: true, // For savings, "spent" means transferred to savings
          ),
          _buildBreakdownItemWithProgress(
            label: "Necessities",
            budgetAmount: _essentialBudget,
            spentAmount: _essentialSpending,
            color: v.bucketEssential,
          ),
          _buildBreakdownItemWithProgress(
            label: "Luxuries",
            budgetAmount: _luxuryBudget,
            spentAmount: _luxurySpending,
            color: v.bucketLuxury,
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
    bool isInverted = false,
  }) {
    if (budgetAmount <= 0) return const SizedBox.shrink();

    final v = context.vesta;
    final percent = (spentAmount / budgetAmount).clamp(0.0, 1.0);
    final isOverBudget = !isInverted && spentAmount > budgetAmount;
    final isOnTrack = isInverted && spentAmount >= budgetAmount;

    final amountColor = isOverBudget
        ? v.neg
        : isOnTrack
        ? v.pos
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: VestaSpace.sm),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: VestaSpace.sm),
              MoneyText(spentAmount, color: amountColor),
              Text(
                " / ${formatMoney(budgetAmount)}",
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          VestaProgressBar(
            value: percent,
            height: 4,
            color: isOverBudget ? v.neg : color,
          ),
        ],
      ),
    );
  }

  Future<void> _openBills() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillsScreen()),
    );
    _loadUpcoming();
  }

  Future<void> _addBill() async {
    if (await showBillSheet(context)) _loadUpcoming();
  }

  Future<void> _removeBill(UpcomingPayment bill) async {
    if (!await confirmDeleteBill(context, bill.title)) return;
    try {
      await deleteBill(bill.billId!);
      _loadUpcoming();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't delete the bill: $e")),
      );
    }
  }

  Widget _buildUpcomingPayments() {
    final v = context.vesta;
    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Upcoming payments",
            trailing: [
              AddRemoveButtons(
                onAdd: _addBill,
                addTooltip: 'Add a bill',
                removing: _removingBills,
                canRemove: _upcoming.any((p) => p.isBill),
                removeTooltip: 'Remove a bill',
                onToggleRemove: () =>
                    setState(() => _removingBills = !_removingBills),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.sm),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          if (!_isLoading && _upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VestaSpace.md),
              child: Text(
                "No upcoming payments yet. Tap + to add a bill.",
                style: TextStyle(fontSize: 13, color: v.muted),
              ),
            ),

          if (!_isLoading && _upcoming.isNotEmpty)
            ..._upcoming.take(4).map(_buildUpcomingItem),

          if (!_isLoading && _upcoming.length > 4)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _openBills,
                child: Text("See all ${_upcoming.length}"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem(UpcomingPayment p) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = p.nextDate;
    final formattedDate = date == null
        ? "No date"
        : "Next: ${date.day} ${monthNames[date.month - 1]} ${date.year}";

    final icon = p.isBill
        ? categoryIcon(p.category ?? p.title)
        : p.incoming
        ? PhosphorIconsRegular.arrowDownLeft
        : PhosphorIconsRegular.arrowUpRight;
    final active = p.isBill || p.status == "active";

    return _buildPaymentItem(
      title: p.title,
      accountName: p.accountName,
      amount: p.amount,
      currency: p.currency,
      type: p.incoming ? "arrival" : "departure",
      status: p.isBill ? (p.autopay ? "autopay" : "manual") : (p.status ?? "unknown"),
      nextPaymentDate: formattedDate,
      remainingPayments: p.remaining,
      frequency: p.frequency,
      icon: icon,
      color: active ? context.vesta.accentInk : context.vesta.muted,
      onTap: _openBills,
      onRemove: _removingBills && p.isBill ? () => _removeBill(p) : null,
    );
  }

  Widget _buildPaymentItem({
    required String title,
    required String? accountName,
    required double amount,
    required String currency,
    required String type,
    required String status,
    required String nextPaymentDate,
    int? remainingPayments,
    String? frequency,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    VoidCallback? onRemove,
  }) {
    final v = context.vesta;
    final bool isIncoming = type == "arrival";
    final statusText =
        status.substring(0, 1).toUpperCase() + status.substring(1);
    final details = [
      nextPaymentDate,
      if (frequency != null)
        "${frequency[0].toUpperCase()}${frequency.substring(1)}",
      statusText,
    ].join(" · ");

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VestaRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onRemove != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: RemoveBadge(onTap: onRemove),
              ),
              const SizedBox(width: VestaSpace.md),
            ],
            IconBadge(icon, size: 40, circle: false, color: color),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (accountName != null)
                    Text(
                      "From $accountName",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(details, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: VestaSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  isIncoming ? amount : -amount,
                  currency: currency,
                  showPlus: true,
                  color: isIncoming ? v.pos : null,
                ),
                if (remainingPayments != null)
                  Text(
                    "$remainingPayments left",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
