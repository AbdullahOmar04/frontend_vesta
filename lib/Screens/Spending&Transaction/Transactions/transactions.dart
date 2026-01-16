// lib/Screens/pages/transactions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/new_spending.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/add_transaction.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

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

  @override
  void initState() {
    super.initState();
    getTransactions(bankId: '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCategoryFilter();
      _loadTransactions();
    });
  }

  void _checkForCategoryFilter() {
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

    return filtered;
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
      _filteredTransactions = _applyFilters(_allTransactions);
    });
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
            if (_accounts.isNotEmpty || _categories.isNotEmpty)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    final hasFilters = _selectedAccountId != null || _selectedCategory != null;

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
        return TransactionCard(transaction: _filteredTransactions[i]);
      },
    );
  }
}
