// lib/screens/pages/spending_analysis.dart
// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/spending_categories.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
// import 'package:fl_chart/fl_chart.dart'; // No longer needed

const List<String> categoryLabels = [
  'Food And Drinks',
  'Groceries',
  'Entertainment',
  'Others',
];

enum TimeFilter { day, week, month, year }

class NewSpendingAnalysis extends StatefulWidget {
  const NewSpendingAnalysis({super.key});

  @override
  State<NewSpendingAnalysis> createState() => _SpendingAnalysisState();
}

class _SpendingAnalysisState extends State<NewSpendingAnalysis> {
  final TimeFilter _selectedTimeFilter = TimeFilter.day;

  bool _loading = true;
  List<TransactionModel> _allTransactions = [];
  Map<String, CategoryData> _categories = {};

  double _currentCycleBudget = 0.01;
  double _currentCycleSpending = 0.0;

  Map<String, dynamic> _budgetData = {};
  final _totalIncomeController = TextEditingController();
  bool _isLoading = true;
  int _budgetResetDay = 28;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadData();
    await _fetchBudget();
    _fetchCurrentCycleData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No user logged in");

      debugPrint("📊 Loading spending data for user: $uid");

      // Load categories from Firestore
      final categoriesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();

      debugPrint("📁 Found ${categoriesSnap.docs.length} categories");

      final categoryMap = <String, CategoryData>{};
      for (var doc in categoriesSnap.docs) {
        categoryMap[doc.id] = CategoryData(
          id: doc.id,
          name: doc.id,
          icon: _getIconForCategory(doc.id),
          color: _getColorForCategory(doc.id),
        );
      }

      // Load all transactions
      final accountsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .get();

      debugPrint("💳 Found ${accountsSnap.docs.length} accounts");

      final transactions = <TransactionModel>[];
      for (var accDoc in accountsSnap.docs) {
        final txSnap = await accDoc.reference.collection('transactions').get();

        debugPrint(
          "  - Account ${accDoc.id}: ${txSnap.docs.length} transactions",
        );

        for (var txDoc in txSnap.docs) {
          final data = txDoc.data();
          final txn = TransactionModel.fromFirestore(accDoc.id, txDoc.id, data);
          transactions.add(txn);
        }
      }

      debugPrint("📝 Total transactions loaded: ${transactions.length}");

      setState(() {
        _categories = categoryMap;
        _allTransactions = transactions;
        _loading = false;
      });
    } catch (e) {
      debugPrint("⚠️ Error loading data: $e");
      setState(() => _loading = false);
    }
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

  /// Gets the 5 most recent transactions from all accounts.
  List<TransactionModel> _getLatestTransactions() {
    final sorted = List<TransactionModel>.from(_allTransactions);
    // Sort by date, most recent first
    sorted.sort((a, b) => b.date.compareTo(a.date));
    // Return the first 5, or fewer if not available
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          "Spending Analysis",
          style: TextStyle(color: scheme.surface),
        ),
        iconTheme: IconThemeData(color: scheme.surface),
        centerTitle: true,
        backgroundColor: scheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final scheme = Theme.of(context).colorScheme;

    // We calculate these here to pass them to the builder methods
    final categoryNetAmounts = _calculateCategoryNetAmounts();
    final latestTransactions = _getLatestTransactions();

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBudgetTrackerBar(),
                    const SizedBox(height: 24),
                    _buildSpendingCategoriesSection(categoryNetAmounts),
                    const SizedBox(height: 24),
                    _buildLatestTransactionsSection(latestTransactions),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              builder: (context) => const Transactions(),
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

  /// SECTION: Latest Transactions
  /// Displays the 5 most recent transactions.
  Widget _buildLatestTransactionsSection(List<TransactionModel> transactions) {
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
                  MaterialPageRoute(builder: (context) => const Transactions()),
                );
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
              return TransactionCard(transaction: txn);
            },
          ),
      ],
    );
  }

  Widget _buildBudgetTrackerBar() {
    final percent = (_currentCycleSpending / _currentCycleBudget).clamp(
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
          // The progress bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percent.isNaN ? 0.0 : percent, // Avoid NaN errors
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
                "JOD ${_currentCycleSpending.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "JOD ${_currentCycleBudget.toStringAsFixed(0)}",
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
    );
  }

  /// WIDGET: Empty State (for categories)
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

        final transactionType = (data['transactionType'] ?? '')
            .toString()
            .toLowerCase();
        if (transactionType != 'debit') {
          continue;
        }

        final transactionDate = _getDateTimeFromData(data);
        if (transactionDate == null) continue;

        // ✅ Check if date within range
        if (!transactionDate.isBefore(startDate) &&
            !transactionDate.isAfter(endDate)) {
          currentSpending += _getAmountFromData(data);
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
    // Persist totalExpense for the current budget cycle
    FirebaseFirestore.instance.collection("users").doc(uid).update({
      "totalExpense": currentSpending,
    });
  }

  /// WIDGET: Empty State (for transactions)
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

  // --- Helper Functions for Icons/Colors ---

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

// Still needs the CategoryData helper class
class CategoryData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  // final double total; // Not used in this version
  // final String type; // Not used in this version

  CategoryData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    // required this.total,
    // required this.type,
  });
}

// The TransactionModel class from the other file is assumed to be correct
// and is imported at the top.
