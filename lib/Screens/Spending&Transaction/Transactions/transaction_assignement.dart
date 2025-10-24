import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

class TransactionAssignement extends StatefulWidget {
  const TransactionAssignement({super.key});

  @override
  State<TransactionAssignement> createState() => _TransactionAssignementState();
}

class _TransactionAssignementState extends State<TransactionAssignement> {
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;

  bool _loading = true;
  bool _syncing = false;
  String? _error;
  List<TransactionModel> _txns = [];
  List<TransactionModel> _filteredTxns = [];
  int _syncedAccounts = 0;
  int _totalAccounts = 0;

  // Filter state
  String? _selectedAccountId;
  List<AccountInfo> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions(syncFirst: true);
  }

  Future<void> _loadTransactions({bool syncFirst = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception("No logged-in user.");
      }

      // Get all accounts
      final accountsSnap = await _fire
          .collection("users")
          .doc(uid)
          .collection("accounts")
          .get();

      final accountIds = accountsSnap.docs.map((d) => d.id).toList();

      // Store account info for filter dropdown
      _accounts = accountsSnap.docs.map((doc) {
        final data = doc.data();
        return AccountInfo(id: doc.id, name: data['accountName'] ?? doc.id);
      }).toList();

      if (accountIds.isEmpty) {
        setState(() {
          _txns = [];
          _filteredTxns = [];
          _loading = false;
        });
        return;
      }

      // Read all transactions from Firestore
      final all = <TransactionModel>[];
      for (final accId in accountIds) {
        final txSnap = await _fire
            .collection("users")
            .doc(uid)
            .collection("accounts")
            .doc(accId)
            .collection("transactions")
            .get();

        for (final doc in txSnap.docs) {
          final data = doc.data();
          all.add(TransactionModel.fromFirestore(accId, doc.id, data));
        }
      }

      // Sort newest → oldest by date
      all.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _txns = all;
        _filteredTxns = _applyFilter(all);
        _loading = false;
      });
    } catch (e) {
      debugPrint("⚠️ _loadTransactions error: $e");
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

    final accountsSnap = await _fire
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .get();

    final accountIds = accountsSnap.docs.map((d) => d.id).toList();

    if (accountIds.isEmpty) {
      setState(() {
        _txns = [];
      });
      return;
    }

    await getTransactions();
    await _loadTransactions(syncFirst: false);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () => _loadTransactions(syncFirst: true),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _filteredTxns.isEmpty
          ? _buildEmptyState()
          : _buildTransactionList(),
    );
  }

  void _onFilterChanged(String? accountId) {
    setState(() {
      _selectedAccountId = accountId;
      _filteredTxns = _applyFilter(_txns);
    });
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        _selectedAccountId != null
            ? EmptyFilterState(onClearFilter: () => _onFilterChanged(null))
            : EmptyTransactionsState(
                onSync: () => _loadTransactions(syncFirst: true),
              ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: [
        if (_syncing)
          SyncStatusBanner(
            syncedAccounts: _syncedAccounts,
            totalAccounts: _totalAccounts,
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _filteredTxns.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              return TransactionCard(transaction: _filteredTxns[i]);
            },
          ),
        ),
      ],
    );
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> txns) {
    if (_selectedAccountId == null) {
      return txns;
    }
    return txns.where((t) => t.accountId == _selectedAccountId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Assignement"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  circularCategory(Colors.red, Icons.dining, "Food"),
                  const SizedBox(width: 8),
                  circularCategory(
                    Colors.blue,
                    Icons.shopping_cart,
                    "Groceries",
                  ),
                  const SizedBox(width: 8),
                  circularCategory(
                    Colors.green,
                    Icons.directions_car,
                    "Transport",
                  ),
                  const SizedBox(width: 8),
                  circularCategory(Colors.orange, Icons.movie, "Fun"),
                  const SizedBox(width: 8),
                  circularCategory(
                    Colors.purple,
                    Icons.health_and_safety,
                    "Health",
                  ),
                  const SizedBox(width: 8),
                  circularCategory(Colors.brown, Icons.home, "Rent"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}
