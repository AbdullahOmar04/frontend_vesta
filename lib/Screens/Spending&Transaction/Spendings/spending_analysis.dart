// lib/screens/pages/spending_analysis.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

const List<String> categoryLabels = [
  'Food And Drinks',
  'Groceries',
  'Entertainment',
  'Others',
];

enum TimeFilter { day, week, month, year }

class SpendingAnalysis extends StatefulWidget {
  const SpendingAnalysis({super.key});

  @override
  State<SpendingAnalysis> createState() => _SpendingAnalysisState();
}

class _SpendingAnalysisState extends State<SpendingAnalysis> {
  TimeFilter _selectedTimeFilter = TimeFilter.day;
  String _selectedType = "Expense";

  bool _loading = true;
  List<TransactionModel> _allTransactions = [];
  Map<String, CategoryData> _categories = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadData();
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
        final data = doc.data();
        categoryMap[doc.id] = CategoryData(
          id: doc.id,
          name: doc.id,
          icon: _getIconForCategory(doc.id),
          color: _getColorForCategory(doc.id),
          total: data['total']?.toDouble() ?? 0.0,
          type: data['type'] ?? 'expense',
        );
        debugPrint("  - ${doc.id}: ${data['total']} JOD");
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

          if (txn.category != null && txn.category!.isNotEmpty) {
            debugPrint(
              "    ✅ Txn ${txDoc.id}: ${txn.amount} JOD → ${txn.category}",
            );
          } else {
            debugPrint(
              "    ⚪ Txn ${txDoc.id}: ${txn.amount} JOD → NO CATEGORY",
            );
          }
        }
      }

      debugPrint("📝 Total transactions loaded: ${transactions.length}");
      debugPrint(
        "📝 Categorized transactions: ${transactions.where((t) => t.category != null && t.category!.isNotEmpty).length}",
      );

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

  List<TransactionModel> _getFilteredTransactions() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeFilter) {
      case TimeFilter.day:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case TimeFilter.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimeFilter.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case TimeFilter.year:
        startDate = DateTime(2023, 1, 1);
        break;
    }

    return _allTransactions.where((txn) {
      // Filter by date
      if (txn.date.isBefore(startDate)) return false;

      // Filter by type
      if (_selectedType == "Expense" && !txn.isDebit) return false;
      if (_selectedType == "Income" && txn.isDebit) return false;

      // CRITICAL: Only include transactions that have a category assigned
      // Check if category exists and is in our predefined list
      if (txn.category == null || txn.category!.isEmpty) return false;
      if (!categoryLabels.contains(txn.category)) return false;

      return true;
    }).toList();
  }

  Map<String, double> _calculateCategorySpending() {
    final filtered = _getFilteredTransactions();
    final spending = <String, double>{};

    for (var txn in filtered) {
      final category = txn.category!;
      spending[category] = (spending[category] ?? 0) + txn.amount;
    }

    return spending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Spending Analysis"),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTimeFilterChips(),
          const SizedBox(height: 16),
          _buildTypeSelector(),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFilterChip('Day', TimeFilter.day),
        _buildFilterChip('Week', TimeFilter.week),
        _buildFilterChip('Month', TimeFilter.month),
        _buildFilterChip('Year', TimeFilter.year),
      ],
    );
  }

  Widget _buildFilterChip(String label, TimeFilter filter) {
    final isSelected = _selectedTimeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      checkmarkColor: Colors.white,
      onSelected: (_) {
        setState(() => _selectedTimeFilter = filter);
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DropdownButton<String>(
          value: _selectedType,
          items: [
            "Expense",
            "Income",
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedType = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildContent() {
    final categorySpending = _calculateCategorySpending();

    if (categorySpending.isEmpty) {
      return _buildEmptyState();
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpending = categorySpending.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );

    return Column(
      children: [
        _buildPieChart(sortedCategories, totalSpending),
        const SizedBox(height: 20),
        _buildTopSpendingsHeader(),
        const SizedBox(height: 10),
        Expanded(child: _buildCategoryList(sortedCategories)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No categorized transactions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Assign categories to your transactions\nto see spending analysis",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Transactions()),
              );
            },
            icon: const Icon(Icons.category),
            label: const Text("Assign Categories"),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
    List<MapEntry<String, double>> categories,
    double total,
  ) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: categories.map((entry) {
            final category = _categories[entry.key];
            final percentage = (entry.value / total) * 100;

            return PieChartSectionData(
              color: category?.color ?? Colors.grey,
              value: entry.value,
              title: "${percentage.toStringAsFixed(0)}%",
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              radius: 60,
            );
          }).toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildTopSpendingsHeader() {
    return Row(
      children: [
        const Text(
          "Top Spendings",
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
    );
  }

  Widget _buildCategoryList(List<MapEntry<String, double>> categories) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final entry = categories[index];
        final categoryData = _categories[entry.key];
        final amount = entry.value;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
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
              '${_getFilteredTransactions().where((t) => t.category == entry.key).length} transactions',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Text(
              "${_selectedType == "Expense" ? "-" : "+"} JOD ${amount.toStringAsFixed(2)}",
              style: TextStyle(
                color: _selectedType == "Expense"
                    ? Colors.red.shade600
                    : Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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

class CategoryData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double total;
  final String type;

  CategoryData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.type,
  });
}
