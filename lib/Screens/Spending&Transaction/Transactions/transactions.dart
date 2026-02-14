// lib/Screens/pages/transactions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/new_spending.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/add_transaction.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:intl/intl.dart';

enum DateFilter { all, today, lastWeek, lastMonth, customMonth }

class Transactions extends StatefulWidget {
  final bool showBack;
  const Transactions({super.key, required this.showBack});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;

  bool _loading = true;
  bool _syncing = false;
  String? _error;

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];

  List<AccountInfo> _accounts = [];
  List<String> _categories = [];

  String? _selectedAccountId;
  String? _selectedCategory;
  DateFilter _dateFilter = DateFilter.all;
  DateTime? _selectedMonth; // For custom month filter

  @override
  void initState() {
    super.initState();
    getTransactions().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForCategoryFilter();
        _loadTransactions();
      });
    });
  }

  void _checkForCategoryFilter() {
    if (!mounted) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['selectedCategory'] != null) {
      setState(() {
        _selectedCategory = args['selectedCategory'] as String;
      });
    }
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("No logged-in user.");

      // Load accounts
      final accountsSnap = await _fire
          .collection("users")
          .doc(uid)
          .collection("accounts")
          .where('linked', isEqualTo: true)
          .get();

      _accounts = accountsSnap.docs.map((doc) {
        final data = doc.data();
        return AccountInfo(id: doc.id, name: data['accountName'] ?? doc.id);
      }).toList();

      if (accountsSnap.docs.isEmpty) {
        setState(() {
          _allTransactions = [];
          _filteredTransactions = [];
          _loading = false;
        });
        return;
      }

      // Load categories
      final categoriesSnap = await _fire
          .collection("users")
          .doc(uid)
          .collection("categories")
          .get();

      _categories = categoriesSnap.docs.map((d) => d.id).toList();

      // Load all transactions
      final transactions = <TransactionModel>[];
      for (final accDoc in accountsSnap.docs) {
        final txSnap = await accDoc.reference.collection("transactions").get();

        for (final txDoc in txSnap.docs) {
          transactions.add(
            TransactionModel.fromFirestore(txDoc.id, txDoc.data()),
          );
        }
      }

      // Sort by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _allTransactions = transactions;
        _filteredTransactions = _applyFilters(transactions);
        _loading = false;
      });
    } catch (e) {
      debugPrint("⚠️ Error loading transactions: $e");
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      setState(() => _syncing = true);

      await _loadTransactions();

      if (mounted) {
        setState(() => _syncing = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error refreshing: $e");
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> transactions) {
    var filtered = transactions;

    // Filter by account
    if (_selectedAccountId != null) {
      filtered = filtered
          .where((t) => t.accountId == _selectedAccountId)
          .toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    // Filter by date
    filtered = _applyDateFilter(filtered);

    return filtered;
  }

  List<TransactionModel> _applyDateFilter(List<TransactionModel> transactions) {
    if (_dateFilter == DateFilter.all) return transactions;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_dateFilter) {
      case DateFilter.today:
        return transactions.where((t) {
          final txDate = DateTime(t.date.year, t.date.month, t.date.day);
          return txDate.isAtSameMomentAs(today);
        }).toList();

      case DateFilter.lastWeek:
        final weekAgo = today.subtract(const Duration(days: 7));
        return transactions.where((t) {
          final txDate = DateTime(t.date.year, t.date.month, t.date.day);
          return txDate.isAfter(weekAgo.subtract(const Duration(days: 1))) &&
              txDate.isBefore(today.add(const Duration(days: 1)));
        }).toList();

      case DateFilter.lastMonth:
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return transactions.where((t) {
          final txDate = DateTime(t.date.year, t.date.month, t.date.day);
          return txDate.isAfter(monthAgo.subtract(const Duration(days: 1))) &&
              txDate.isBefore(today.add(const Duration(days: 1)));
        }).toList();

      case DateFilter.customMonth:
        if (_selectedMonth == null) return transactions;
        return transactions.where((t) {
          return t.date.year == _selectedMonth!.year &&
              t.date.month == _selectedMonth!.month;
        }).toList();

      case DateFilter.all:
        return transactions;
    }
  }

  void _onAccountFilterChanged(String? accountId) {
    setState(() {
      _selectedAccountId = accountId;
      _filteredTransactions = _applyFilters(_allTransactions);
    });
  }

  void _onCategoryFilterChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      _filteredTransactions = _applyFilters(_allTransactions);
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedAccountId = null;
      _selectedCategory = null;
      _dateFilter = DateFilter.all;
      _selectedMonth = null;
      _filteredTransactions = _applyFilters(_allTransactions);
    });
  }

  void _onDateFilterChanged(DateFilter filter) {
    if (filter == DateFilter.customMonth) {
      _showMonthPicker();
    } else {
      setState(() {
        _dateFilter = filter;
        _selectedMonth = null;
        _filteredTransactions = _applyFilters(_allTransactions);
      });
    }
  }

  void _showMonthPicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Month',
    );

    if (picked != null) {
      setState(() {
        _dateFilter = DateFilter.customMonth;
        _selectedMonth = DateTime(picked.year, picked.month);
        _filteredTransactions = _applyFilters(_allTransactions);
      });
    }
  }

  String _getDateFilterLabel(DateFilter filter) {
    switch (filter) {
      case DateFilter.all:
        return 'All';
      case DateFilter.today:
        return 'Today';
      case DateFilter.lastWeek:
        return 'Last 7 Days';
      case DateFilter.lastMonth:
        return 'Last 30 Days';
      case DateFilter.customMonth:
        if (_selectedMonth != null) {
          return DateFormat('MMM yyyy').format(_selectedMonth!);
        }
        return 'Select Month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: _buildAppBar(),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            _buildFilterSection(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransaction()),
          ).then((_) => _loadTransactions());
        },
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.surface),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: widget.showBack,
      title: Text(
        'Transactions',
        style: TextStyle(color: Theme.of(context).colorScheme.surface),
      ),
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      actions: [
        if (_syncing)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.pie_chart),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewSpendingAnalysis(),
              ),
            ).then((_) => _loadTransactions());
          },
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        // Date filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip(DateFilter.all),
                const SizedBox(width: 8),
                _buildDateChip(DateFilter.today),
                const SizedBox(width: 8),
                _buildDateChip(DateFilter.lastWeek),
                const SizedBox(width: 8),
                _buildDateChip(DateFilter.lastMonth),
                const SizedBox(width: 8),
                _buildMonthChip(),
              ],
            ),
          ),
        ),
        // Account and category filters
        if (_accounts.isNotEmpty || _categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                if (_accounts.isNotEmpty)
                  Expanded(
                    child: AccountFilterDropdown(
                      accounts: _accounts,
                      selectedAccountId: _selectedAccountId,
                      onChanged: _onAccountFilterChanged,
                    ),
                  ),
                if (_accounts.isNotEmpty && _categories.isNotEmpty)
                  const SizedBox(width: 12),
                if (_categories.isNotEmpty)
                  Expanded(
                    child: CategoryFilterDropdown(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onChanged: _onCategoryFilterChanged,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDateChip(DateFilter filter) {
    final isSelected = _dateFilter == filter;
    return FilterChip(
      label: Text(_getDateFilterLabel(filter)),
      selected: isSelected,
      onSelected: (_) => _onDateFilterChanged(filter),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMonthChip() {
    final isSelected = _dateFilter == DateFilter.customMonth;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSelected && _selectedMonth != null
                ? DateFormat('MMM yyyy').format(_selectedMonth!)
                : 'Month',
          ),
          const SizedBox(width: 4),
          const Icon(Icons.calendar_month, size: 16),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _onDateFilterChanged(DateFilter.customMonth),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadTransactions);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _filteredTransactions.isEmpty
          ? _buildEmptyState()
          : _buildTransactionList(),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _selectedAccountId != null ||
        _selectedCategory != null ||
        _dateFilter != DateFilter.all;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        hasFilters
            ? EmptyFilterState(onClearFilter: _clearFilters)
            : EmptyTransactionsState(onSync: _loadTransactions),
      ],
    );
  }

  Widget _buildTransactionList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredTransactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        return TransactionCard(
          transaction: _filteredTransactions[i],
          onDeleted: _loadTransactions,
        );
      },
    );
  }
}
