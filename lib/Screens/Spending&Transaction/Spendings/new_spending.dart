// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/spending_categories.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

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
  Map<String, String> _categoryBuckets = {};
  Map<String, String> _accountLabels = {};

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
      final bucketMap = <String, String>{};

      for (var doc in categoriesSnap.docs) {
        final data = doc.data();
        final name = doc.id;
        final bucketRaw = (data['bucket'] ?? '') as String;
        final bucket = bucketRaw.isEmpty
            ? inferBucketFromCategoryName(name)
            : bucketRaw;

        bucketMap[doc.id] = bucket;

        categoryMap[doc.id] = CategoryData(
          id: doc.id,
          name: name,
          icon: _getIconForCategory(name),
          color: _getColorForCategory(name),
        );
      }

      // Load all transactions
      final accountsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('linked', isEqualTo: true)
          .get();

      debugPrint("💳 Found ${accountsSnap.docs.length} accounts");

      final accountLabels = <String, String>{
        for (final d in accountsSnap.docs)
          d.id: AccountInfo(
            id: d.id,
            name: d.data()['accountName'] ?? d.id,
            type: d.data()['accountTypeName'] as String?,
          ).label,
      };

      final transactions = <TransactionModel>[];
      for (var accDoc in accountsSnap.docs) {
        final txSnap = await accDoc.reference.collection('transactions').get();

        debugPrint(
          "  - Account ${accDoc.id}: ${txSnap.docs.length} transactions",
        );

        for (var txDoc in txSnap.docs) {
          final data = txDoc.data();
          final txn = TransactionModel.fromFirestore(txDoc.id, data);
          transactions.add(txn);
        }
      }

      debugPrint("📝 Total transactions loaded: ${transactions.length}");

      if (!mounted) return;
      setState(() {
        _categories = categoryMap;
        _allTransactions = transactions;
        _categoryBuckets = bucketMap;
        _accountLabels = accountLabels;
        _loading = false;
      });
    } catch (e) {
      debugPrint("⚠️ Error loading data: $e");
      if (!mounted) return;
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
    return Scaffold(
      appBar: const VestaAppBar(title: "Spendings"),
      body: VestaBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // We calculate these here to pass them to the builder methods
    final categoryNetAmounts = _calculateCategoryNetAmounts();
    final latestTransactions = _getLatestTransactions();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        VestaSpace.xs,
        VestaSpace.gutter,
        VestaSpace.xl,
      ),
      children: [
        _buildBudgetTrackerBar(),
        const SizedBox(height: 14),
        _buildSpendingCategoriesSection(categoryNetAmounts),
        const SizedBox(height: 14),
        _buildLatestTransactionsSection(latestTransactions),
      ],
    );
  }

  Widget _buildSpendingCategoriesSection(Map<String, double> netAmounts) {
    // Sort categories by the absolute value of their net amount, descending
    final sortedCategories = netAmounts.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final top5Categories = sortedCategories.take(3).toList();

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
              ).then((_) {
                _loadData();
                _fetchCurrentCycleData();
              });
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

  Widget _buildCategoryNetItem(MapEntry<String, double> entry) {
    final categoryData = _categories[entry.key];
    final netAmount = entry.value;
    final bucket = bucketStyle(
      _categoryBuckets[entry.key] ?? inferBucketFromCategoryName(entry.key),
      context.vesta,
    );
    final count = _getTransactionsForCurrentPeriod()
        .where((t) => t.category == entry.key)
        .length;

    return ListRow(
      title: categoryData?.name ?? entry.key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      leading: IconBadge(
        categoryIcon(categoryData?.name ?? entry.key),
        size: 40,
        circle: false,
        color: bucket.color,
      ),
      below: Row(
        children: [
          TagChip(bucket.label, color: bucket.color),
          const SizedBox(width: VestaSpace.sm),
          Flexible(
            child: Text(
              count == 1 ? "1 transaction" : "$count transactions",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
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
        ).then((_) {
          _loadData();
          _fetchCurrentCycleData();
        });
      },
    );
  }

  /// SECTION: Latest Transactions
  /// Displays the 5 most recent transactions, grouped by day.
  Widget _buildLatestTransactionsSection(List<TransactionModel> transactions) {
    final groups = <String, List<TransactionModel>>{};
    for (final txn in transactions) {
      groups.putIfAbsent(shortDateLabel(txn.date), () => []).add(txn);
    }

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
                _loadData();
                _fetchCurrentCycleData();
              });
            },
          ),
          if (transactions.isEmpty)
            _buildEmptyTransactionState()
          else
            for (final group in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Text(
                  group.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final txn in group.value)
                TransactionCard(
                  key: ValueKey(txn.id),
                  transaction: txn,
                  accountName: _accountLabels[txn.accountId],
                  showDate: false,
                  onCategoryChanged: _refreshAfterCategoryChange,
                  onDeleted: _refreshAfterCategoryChange,
                ),
            ],
        ],
      ),
    );
  }

  void _refreshAfterCategoryChange() {
    _loadData();
    _fetchCurrentCycleData();
  }

  Widget _buildBudgetTrackerBar() {
    final v = context.vesta;
    final hasBudget = _currentCycleBudget > 0.01;
    final used = hasBudget ? _currentCycleSpending / _currentCycleBudget : 0.0;
    final left = _currentCycleBudget - _currentCycleSpending;

    // Where today falls in the budget cycle, for the even-pace marker.
    final now = DateTime.now();
    final cycleStart = now.day >= _budgetResetDay
        ? DateTime(now.year, now.month, _budgetResetDay)
        : DateTime(now.year, now.month - 1, _budgetResetDay);
    final cycleEnd = DateTime(cycleStart.year, cycleStart.month + 1, _budgetResetDay);
    final totalDays = cycleEnd.difference(cycleStart).inDays;
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = cycleEnd.difference(today).inDays;
    final pace = totalDays > 0 ? (totalDays - daysLeft) / totalDays : 0.0;

    final meterColor = used > 1
        ? v.neg
        : used > pace + 0.05
        ? v.bucketLuxury
        : Theme.of(context).colorScheme.primary;
    final leftColor = used > 1 ? v.neg : v.muted;

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

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Spent in $cycleMonthName so far", style: small),
              ),
              if (hasBudget)
                Text(
                  "${(used * 100).round()}% used",
                  style: small.copyWith(color: leftColor),
                ),
            ],
          ),
          const SizedBox(height: VestaSpace.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              MoneyText.hero(_currentCycleSpending, size: 30),
              if (hasBudget)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    "of ${formatMoney(_currentCycleBudget)}",
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VestaSpace.md),
          VestaProgressBar(
            value: used,
            height: 12,
            color: meterColor,
            marker: hasBudget ? pace : null,
          ),
          const SizedBox(height: VestaSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  !hasBudget
                      ? "No budget plan for this cycle yet"
                      : left >= 0
                      ? "${formatMoney(left)} left"
                      : "${formatMoney(-left)} over",
                  style: small.copyWith(color: leftColor),
                ),
              ),
              Text(
                daysLeft == 1 ? "1 day to go" : "$daysLeft days to go",
                style: small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// WIDGET: Empty State (for categories)
  Widget _buildEmptyCategoryState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        "No categorized spending yet.\nAssign categories to transactions to see them here.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: context.vesta.muted),
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
      if (data.containsKey('amount') &&
          data['amount'] != null &&
          data['amount'] != null) {
        return double.tryParse(data['amount'].toString()) ?? 0.0;
      }
      return 0.0; // No amount found
    } catch (e) {
      print('Error parsing amount: $e');
      return 0.0;
    }
  }

  DateTime? _getDateTimeFromData(Map<String, dynamic> data) {
    try {
      if (data.containsKey('date') && data['date'] != null) {
        return DateTime.tryParse(data['date'] as String);
      }
      return null;
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  Future<void> _fetchCurrentCycleData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_budgetData.isEmpty) return;

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

    double currentSpending = 0;
    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .get();

    for (var account in accountsSnap.docs) {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("accounts")
          .doc(account.id)
          .collection("transactions")
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();

        final transactionType = (data['type'] ?? '').toString().toLowerCase();
        if (transactionType != 'debit') continue;

        final transactionDate = _getDateTimeFromData(data);
        if (transactionDate == null) continue;
        if (transactionDate.isBefore(startDate) ||
            transactionDate.isAfter(endDate)) {
          continue;
        }

        final category = data['category'] as String?;
        if (category == null || category.isEmpty) continue;

        final bucket =
            _categoryBuckets[category] ?? inferBucketFromCategoryName(category);

        if (bucket != 'essential' && bucket != 'luxury') continue;

        currentSpending += _getAmountFromData(data);
      }
    }

    final totalIncome = double.tryParse(_totalIncomeController.text) ?? 0;
    final spendingPercent = (_budgetData["spending"] ?? 0).toDouble();
    final luxuriesPercent = (_budgetData["luxuries"] ?? 0).toDouble();
    final totalBudget = totalIncome * (spendingPercent + luxuriesPercent) / 100;

    if (mounted) {
      setState(() {
        _currentCycleBudget = totalBudget > 0 ? totalBudget : 0.01;
        _currentCycleSpending = currentSpending;
      });
    }
    updateIfChanged(FirebaseFirestore.instance.collection("users").doc(uid), {
      "totalExpense": currentSpending,
    });
  }

  Widget _buildEmptyTransactionState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        "No transactions yet.",
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

class CategoryData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  CategoryData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
