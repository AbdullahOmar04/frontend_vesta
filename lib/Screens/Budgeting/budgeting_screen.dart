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
  bool _loadingSosps = false;
  bool _isLoading = true;
  final _totalIncomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBudget();
    getSOSPs().then((_) => _fetchSOSPsFromFirestore());
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
      }

      setState(() {
        _budgetData = doc.data() ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading budget: $e')));
      }
    }
  }

  void _refreshBudget() {
    setState(() {
      _isLoading = true;
    });
    _fetchBudget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Personal Budget",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
              foregroundColor: Theme.of(context).primaryColor,
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

    if (_budgetData.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget Chart
        _buildBudgetChart(
          totalIncome,
          savingAmount,
          spendingAmount,
          luxuriesAmount,
          remainingAmount,
        ),
        const SizedBox(height: 24),

        // Budget Summary Card
        _buildBudgetSummaryCard(totalIncome),
        const SizedBox(height: 24),

        // Budget Breakdown
        _buildBudgetBreakdown(
          savingAmount,
          spendingAmount,
          luxuriesAmount,
          remainingAmount,
        ),
        const SizedBox(height: 24),

        // Upcoming Payments
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

  Widget _buildBudgetChart(
    double income,
    double saving,
    double spending,
    double luxuries,
    double remaining,
  ) {
    final List<PieChartSectionData> sections = [
      if (saving > 0)
        PieChartSectionData(
          color: Colors.green,
          value: saving,
          title: '${(saving / income * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (spending > 0)
        PieChartSectionData(
          color: Colors.blue,
          value: spending,
          title: '${(spending / income * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (luxuries > 0)
        PieChartSectionData(
          color: Colors.orange,
          value: luxuries,
          title: '${(luxuries / income * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (remaining > 0)
        PieChartSectionData(
          color: Colors.grey[300]!,
          value: remaining,
          title: '${(remaining / income * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
    ];

    return Container(
      height: 220,
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.black87),
                const SizedBox(width: 8),
                const Text(
                  "Budget Distribution",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: sections.isEmpty
                ? const Center(child: Text("No data to display"))
                : PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard(double income) {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Income for ${monthNames[currentMonth]}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "JOD ${income.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white70,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetBreakdown(
    double saving,
    double spending,
    double luxuries,
    double remaining,
  ) {
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
          const Text(
            "Budget Breakdown",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Future<void> _fetchSOSPsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loadingSosps = true);

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

      for (var doc in sospSnap.docs) {
        final data = doc.data();
        all.add(data);
      }
    }

    // Sort by next payment date ascending
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

    setState(() {
      _sosps = all;
      _loadingSosps = false;
    });
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

          if (_loadingSosps) const Center(child: CircularProgressIndicator()),

          if (!_loadingSosps && _sosps.isEmpty)
            const Text(
              "No upcoming payments",
              style: TextStyle(color: Colors.grey),
            ),

          if (!_loadingSosps && _sosps.isNotEmpty)
            ..._sosps.map((sosp) {
              final nickname = sosp["SOSPNickname"] ?? "Scheduled Payment";
              final amount =
                  sosp["paymentSchedule"]?["nextPaymentAmount"]?["amount"] ??
                  0.0;
              final status = (sosp["SOSPStatus"] ?? "").toString();
              final icon = sosp["SOSPType"] == "arrival"
                  ? Icons.call_received
                  : Icons.call_made;

              return _buildPaymentItem(
                nickname.toString(),
                double.tryParse(amount.toString()) ?? 0,
                icon,
                status == "active" ? Colors.green : Colors.grey,
              );
            // ignore: unnecessary_to_list_in_spreads
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
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
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            "- JOD ${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
