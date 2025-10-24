// lib/Screens/pages/transactions.dart
// ignore_for_file: prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_assignement.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
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
    if (context.mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

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

  List<TransactionModel> _applyFilter(List<TransactionModel> txns) {
    if (_selectedAccountId == null) {
      return txns;
    }
    return txns.where((t) => t.accountId == _selectedAccountId).toList();
  }

  void _onFilterChanged(String? accountId) {
    setState(() {
      _selectedAccountId = accountId;
      _filteredTxns = _applyFilter(_txns);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
        actions: [
          if (_syncing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionAssignement(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: _accounts.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AccountFilterDropdown(
                    accounts: _accounts,
                    selectedAccountId: _selectedAccountId,
                    onChanged: _onFilterChanged,
                  ),
                ),
              )
            : null,
      ),
      body: _buildBody(),
    );
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
}
