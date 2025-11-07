// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Screens/Budgeting/plan_budget.dart';

class PersonalBudgetScreen extends StatefulWidget {
  const PersonalBudgetScreen({super.key});

  @override
  State<PersonalBudgetScreen> createState() => _PersonalBudgetScreenState();
}

class _PersonalBudgetScreenState extends State<PersonalBudgetScreen> {
  Map<String, dynamic> _budgetData = {};
  List<Map<String, dynamic>> _sosps = [];
  bool _isLoading = true; // Main loading state for the whole screen
  final _totalIncomeController = TextEditingController();

  List<FlSpot> _expenseData = [];
  List<FlSpot> _savingsData = [];
  double _currentCycleBudget = 0.01;
  double _currentCycleSpending = 0.0;

  // ------------------------------------------

  int _budgetResetDay = 28;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    getSOSPs();
    if (mounted) {
      setState(() => _isLoading = true);
    }

    await _fetchBudget();

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

  Future<void> _fetchBudget() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String monthId =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("budget")
          .doc(monthId)
          .get();

      final doc2 = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (doc2.exists) {
        final data = doc2.data()!;
        _totalIncomeController.text = (data["totalIncome"] ?? 0).toString();

        if (mounted) {
          setState(() {
            _budgetResetDay = (data["dayOfMonth"] ?? 28) as int;
          });
        }
      }

      if (mounted) {
        setState(() {
          _budgetData = doc.data() ?? {};
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading budget: $e')));
      }
    }
  }

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
            style: TextButton.styleFrom(
              foregroundColor: scheme.surface,
            ),
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

    // Calculate amounts based on percentages
    final savingAmount = (totalIncome * savingPercent / 100);
    final spendingAmount = (totalIncome * spendingPercent / 100);
    final luxuriesAmount = (totalIncome * luxuriesPercent / 100);
    final remainingAmount =
        totalIncome - savingAmount - spendingAmount - luxuriesAmount;

    final totalBudgetAmount = spendingAmount + luxuriesAmount;

    if (_budgetData.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBudgetLineChart(totalBudgetAmount),
        const SizedBox(height: 24),

        _buildBudgetBreakdown(
          savingAmount,
          spendingAmount,
          luxuriesAmount,
          remainingAmount,
          totalIncome,
        ),
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
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
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
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlanBudgetScreen()),
              );
              if (result == true) {
                _refreshBudget();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Create Budget Plan"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetLineChart(double totalBudgetAmount) {
    final List<FlSpot> budgetLineData = [
      FlSpot(0, totalBudgetAmount),
      FlSpot(5, totalBudgetAmount),
    ];

    // Get month labels for the X-axis
    final List<String> monthLabels = [];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthNames = [
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
      monthLabels.add(monthNames[month.month - 1]);
    }

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
          // Only show charts if there is data
          lineBarsData: _expenseData.isEmpty && _savingsData.isEmpty
              ? []
              : [
                  // Line 1: Budget (The Plan)
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
                  // Line 2: Actual Expenses
                  if (_expenseData.isNotEmpty)
                    LineChartBarData(
                      spots: _expenseData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  // Line 3: Actual Savings
                  if (_savingsData.isNotEmpty)
                    LineChartBarData(
                      spots: _savingsData,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                ],
        ),
      ),
    );
  }

  Widget _buildBudgetBreakdown(
    double saving,
    double spending,
    double luxuries,
    double remaining,
    double income,
  ) {
    final currentMonth = DateTime.now().month;
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
          _buildBreakdownItem("Savings", saving, Colors.green, Icons.savings),
          _buildBreakdownItem(
            "Essential Spending",
            spending,
            Colors.blue,
            Icons.shopping_cart,
          ),
          _buildBreakdownItem(
            "Luxuries",
            luxuries,
            Colors.orange,
            Icons.diamond,
          ),
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

  // --- CHANGED: Removed internal loading state ---
  Future<void> _fetchSOSPsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // The main _loadAllData function handles loading state
    // setState(() => _loadingSosps = true);

    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
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
      final accountName =
          (accountData['nickname'] ??
                  accountData['accountName'] ??
                  accountData['name'] ??
                  'Account ${account.id}')
              .toString();

      for (var doc in sospSnap.docs) {
        final data = doc.data();
        data['associatedAccountName'] = accountName;
        all.add(data);
      }
    }

    all.sort((a, b) {
      final aDate =
          DateTime.tryParse(
            a["paymentSchedule"]?["nextPaymentDateTime"] ?? "",
          ) ??
          DateTime.now();
      final bDate =
          DateTime.tryParse(
            b["paymentSchedule"]?["nextPaymentDateTime"] ?? "",
          ) ??
          DateTime.now();
      return aDate.compareTo(bDate);
    });
    if (mounted) {
      setState(() {
        _sosps = all;
        // _loadingSosps = false; // Handled by _loadAllData
      });
    }
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
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.black87),
              const SizedBox(width: 8),
              const Text(
                "Upcoming Payments",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // _isLoading is now the master loading state
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          if (!_isLoading && _sosps.isEmpty)
            const Text(
              "No upcoming payments",
              style: TextStyle(color: Colors.grey),
            ),

          if (!_isLoading && _sosps.isNotEmpty)
            ..._sosps.map((sosp) {
              final nickname = sosp["SOSPNickname"] ?? "Scheduled Payment";
              final beneficiaryName =
                  sosp["SOSPBeneficiary"]?["beneficiaryName"]?["enName"] ??
                  nickname;
              final accountName =
                  sosp['associatedAccountName'] ?? 'Unknown Account';
              final amount =
                  (sosp["paymentSchedule"]?["nextPaymentAmount"]?["amount"] ??
                          0.0)
                      .toDouble();
              final currency =
                  sosp["paymentSchedule"]?["nextPaymentAmount"]?["currency"] ??
                  "JOD";
              final status = (sosp["SOSPStatus"] ?? "unknown").toString();
              final type = (sosp["SOSPType"] ?? "departure")
                  .toString(); // Default to outgoing
              final remaining =
                  sosp["paymentSchedule"]?["remainingPayments"]; // Can be null or int

              final nextPaymentDateStr =
                  sosp["paymentSchedule"]?["nextPaymentDateTime"];
              String formattedDate = "No date";
              if (nextPaymentDateStr != null) {
                final parsedDate = DateTime.tryParse(nextPaymentDateStr);
                if (parsedDate != null) {
                  final monthNames = [
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
                  formattedDate =
                      "Next: ${parsedDate.day} ${monthNames[parsedDate.month - 1]} ${parsedDate.year}";
                }
              }

              final icon = type == "arrival"
                  ? Icons.call_received
                  : Icons.call_made;

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
                icon: icon,
                color: color,
              );
            }).toList(),
        ],
      ),
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
                  title, // Beneficiary Name
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

  // --- NEW: Helper function to get amount from your JSON structure ---
  double _getAmountFromData(Map<String, dynamic> data) {
    try {
      // First, try to get the converted JOD amount
      if (data.containsKey('currencyExchange') &&
          data['currencyExchange'] != null &&
          data['currencyExchange']['targetAmount'] != null) {
        return double.tryParse(
              data['currencyExchange']['targetAmount'].toString(),
            ) ??
            0.0;
      }
      // If no conversion, get the primary amount
      if (data.containsKey('transactionAmount') &&
          data['transactionAmount'] != null &&
          data['transactionAmount']['amount'] != null) {
        return double.tryParse(
              data['transactionAmount']['amount'].toString(),
            ) ??
            0.0;
      }
      return 0.0; // No amount found
    } catch (e) {
      print('Error parsing amount: $e');
      return 0.0;
    }
  }

  // --- NEW: Helper function to get date from your JSON structure ---
  DateTime? _getDateTimeFromData(Map<String, dynamic> data) {
    try {
      if (data.containsKey('settlementDateTime') &&
          data['settlementDateTime'] != null) {
        return DateTime.tryParse(data['settlementDateTime'] as String);
      }
      return null; // No date found
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  // --- REPLACED: Corrected data fetching logic ---
  Future<void> _fetchCurrentCycleData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_budgetData.isEmpty) return;

    // 1. Determine the current budget cycle dates
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

    // 2. Query transactions
    double currentSpending = 0;
    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .get();

    for (var account in accountsSnap.docs) {
      // Get all transactions and filter in Dart
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("accounts")
          .doc(account.id)
          .collection("transactions")
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        final transactionDate = _getDateTimeFromData(data);

        if (transactionDate != null) {
          // Check if the date falls within our cycle
          if (!transactionDate.isBefore(startDate) &&
              !transactionDate.isAfter(endDate)) {
            currentSpending += _getAmountFromData(data);
          }
        }
      }
    }

    // 3. Get the budget for this cycle
    final totalIncome = double.tryParse(_totalIncomeController.text) ?? 0;
    final spendingPercent = (_budgetData["spending"] ?? 0).toDouble();
    final luxuriesPercent = (_budgetData["luxuries"] ?? 0).toDouble();
    final totalBudget = totalIncome * (spendingPercent + luxuriesPercent) / 100;

    // 4. Update the state
    if (mounted) {
      setState(() {
        _currentCycleBudget = totalBudget > 0 ? totalBudget : 0.01;
        _currentCycleSpending = currentSpending;
      });
    }
  }

  // --- REPLACED: Corrected data fetching logic ---
  Future<void> _fetchChartData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    List<FlSpot> realExpenseData = [];
    List<FlSpot> realSavingsData = [];
    final now = DateTime.now();

    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .get();

    for (int i = 5; i >= 0; i--) {
      // 3. Calculate start/end dates for each past cycle
      DateTime cycleStartDate;
      DateTime cycleEndDate;

      if (now.day >= _budgetResetDay) {
        cycleStartDate = DateTime(now.year, now.month - i, _budgetResetDay);
        final nextMonth = DateTime(
          now.year,
          now.month - i + 1,
          _budgetResetDay,
        );
        cycleEndDate = nextMonth.subtract(const Duration(days: 1));
      } else {
        cycleStartDate = DateTime(now.year, now.month - i - 1, _budgetResetDay);
        final thisMonth = DateTime(now.year, now.month - i, _budgetResetDay);
        cycleEndDate = thisMonth.subtract(const Duration(days: 1));
      }

      cycleEndDate = DateTime(
        cycleEndDate.year,
        cycleEndDate.month,
        cycleEndDate.day,
        23,
        59,
        59,
      );

      // 4. Query logic
      double totalSpending = 0;
      double totalSavings = 0;

      for (var account in accountsSnap.docs) {
        final snap = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("accounts")
            .doc(account.id)
            .collection("transactions")
            .get();

        // 5. Aggregate totals
        for (var doc in snap.docs) {
          final data = doc.data();
          final category = data['category'] as String?;
          final transactionDate = _getDateTimeFromData(data);

          if (transactionDate != null) {
            // Check if the date falls within this cycle
            if (!transactionDate.isBefore(cycleStartDate) &&
                !transactionDate.isAfter(cycleEndDate)) {
              final amount = _getAmountFromData(data);
              if (category == 'Groceries' ||
                  category == 'Entertainment' ||
                  category == 'Food And Drinks' ||
                  category == 'Others') {
                totalSpending += amount;
              } else if (category == 'Savings') {
                totalSavings += amount;
              }
            }
          }
        }
      }

      // 6. Add to the lists:
      final xValue = (5 - i).toDouble(); // x-axis value (0, 1, 2, 3, 4, 5)
      realExpenseData.add(FlSpot(xValue, totalSpending));
      realSavingsData.add(FlSpot(xValue, totalSavings));
    }

    // 7. setState()
    if (mounted) {
      setState(() {
        _expenseData = realExpenseData;
        _savingsData = realSavingsData;
      });
    }
  }
}
