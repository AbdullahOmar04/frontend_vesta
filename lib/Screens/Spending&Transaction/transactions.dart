// lib/Screens/pages/transactions.dart
// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:http/http.dart' as http;

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
  List<_Txn> _txns = [];
  List<_Txn> _filteredTxns = [];
  Map<String, bool> _accountSyncStatus = {}; // Track per-account sync status
  int _syncedAccounts = 0;
  int _totalAccounts = 0;
  
  // Filter state
  String? _selectedAccountId;
  List<Map<String, String>> _accounts = []; // {id, name}

  @override
  void initState() {
    super.initState();
    _loadTransactions(syncFirst: true);
  }

  /// Load transactions from Firestore with optional sync
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

      // 1) Get all accounts for this user
      final accountsSnap = await _fire
          .collection("users")
          .doc(uid)
          .collection("accounts")
          .get();

      final accountIds = accountsSnap.docs.map((d) => d.id).toList();
      
      // Store account info for filter dropdown
      _accounts = accountsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id.toString(),
          'name': (data['accountName'] ?? doc.id).toString(),
        };
      }).toList();
      
      if (accountIds.isEmpty) {
        setState(() {
          _txns = [];
          _filteredTxns = [];
          _loading = false;
        });
        return;
      }

      // 2) Optionally sync from backend first
      if (syncFirst) {
        await _syncAllAccounts(uid, accountIds);
      }

      // 3) Read all transactions from Firestore (across all accounts)
      final all = <_Txn>[];
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
          all.add(_Txn.fromFirestore(accId, doc.id, data));
        }
      }

      // 4) Sort newest → oldest by date
      all.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _txns = all;
        _filteredTxns = _applyFilter(all);
        _loading = false;
      });
    } catch (e) {
      print("⚠️ _loadTransactions error: $e");
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Sync all accounts with the backend
  Future<void> _syncAllAccounts(String uid, List<String> accountIds) async {
    setState(() {
      _syncing = true;
      _syncedAccounts = 0;
      _totalAccounts = accountIds.length;
      _accountSyncStatus = {for (var id in accountIds) id: false};
    });

    // Show snackbar for sync progress
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Syncing $_totalAccounts account(s)...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      // Sync all accounts in parallel
      final results = await Future.wait(
        accountIds.map((accId) => _syncSingleAccount(uid, accId)),
        eagerError: false,
      );

      // Count successes
      final successCount = results.where((r) => r).length;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount == accountIds.length
                  ? '✅ All accounts synced successfully'
                  : '⚠️ Synced $successCount/${accountIds.length} accounts',
            ),
            backgroundColor: successCount == accountIds.length
                ? Colors.green
                : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("⚠️ _syncAllAccounts error: $e");
    } finally {
      setState(() {
        _syncing = false;
      });
    }
  }

  /// Sync a single account and return success status
  Future<bool> _syncSingleAccount(String uid, String accountId) async {
    try {
      final url = Uri.parse("$baseUrl/get_transactions/$uid/$accountId");
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        print("✅ Synced transactions for account $accountId");
        setState(() {
          _accountSyncStatus[accountId] = true;
          _syncedAccounts++;
        });
        return true;
      } else {
        print("❌ Failed for $accountId: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error syncing $accountId: $e");
      return false;
    }
  }

  Future<void> _onRefresh() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Get account IDs
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

    // Sync then reload
    await _syncAllAccounts(uid, accountIds);
    await _loadTransactions(syncFirst: false); // Don't sync again
  }

  /// Apply account filter
  List<_Txn> _applyFilter(List<_Txn> txns) {
    if (_selectedAccountId == null) {
      return txns;
    }
    return txns.where((t) => t.accountId == _selectedAccountId).toList();
  }

  /// Handle filter change
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
        ],
        bottom: _accounts.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _AccountFilterDropdown(
                    accounts: _accounts,
                    selectedAccountId: _selectedAccountId,
                    onChanged: _onFilterChanged,
                  ),
                ),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(
                  message: _error!,
                  onRetry: () => _loadTransactions(syncFirst: true),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _filteredTxns.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            _selectedAccountId != null
                                ? _EmptyFilterState(
                                    onClearFilter: () => _onFilterChanged(null),
                                  )
                                : _EmptyState(
                                    onSync: () => _loadTransactions(syncFirst: true),
                                  ),
                          ],
                        )
                      : Column(
                          children: [
                            // Sync status banner
                            if (_syncing)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                color: Colors.blue.shade50,
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Syncing $_syncedAccounts/$_totalAccounts accounts...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Transaction list
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filteredTxns.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final t = _filteredTxns[i];
                                  return _TxnCard(txn: t);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
    );
  }
}

/* =========================
   Data model + parsing
   ========================= */

class _Txn {
  final String accountId;
  final String id;
  final double amount;
  final String currency;
  final String type; // debit / credit
  final String status; // accepted / rejected / ...
  final String channel; // "Bank Branch", "CliQ", ...
  final String? note;
  final String fromName;
  final String toName;
  final DateTime date;

  _Txn({
    required this.accountId,
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.channel,
    required this.fromName,
    required this.toName,
    required this.date,
    this.note,
  });

  factory _Txn.fromFirestore(
    String accountId,
    String id,
    Map<String, dynamic> data,
  ) {
    // amount and currency
    final amt = (data["transactionAmount"]?["amount"] ?? 0).toString();
    final amount = double.tryParse(amt) ?? 0.0;
    final currency = data["transactionAmount"]?["currency"] ?? "JOD";

    // type & status
    final type = (data["transactionType"] ?? "").toString();
    final status = (data["transactionStatus"] ?? "").toString();

    // channel
    final channel = (data["transactionChannel"]?["name"] ??
            data["transactionChannel"]?["code"] ??
            "")
        .toString();

    // note
    String? note;
    final rmt = data["rmtInf"];
    if (rmt is Map &&
        rmt["unstructured"] is List &&
        rmt["unstructured"].isNotEmpty) {
      note = rmt["unstructured"][0].toString();
    }

    // names
    final debtorName =
        (data["debtor"]?["debtorPersonal"]?["name"] ?? "").toString();
    final creditorName =
        (data["creditor"]?["creditorPersonal"]?["name"] ?? "").toString();

    // date: prefer settlementDateTime, fallback to presentementDateTime
    DateTime parsed = DateTime.fromMillisecondsSinceEpoch(0);
    String? dt = data["settlementDateTime"] ?? data["presentementDateTime"];
    if (dt is String && dt.isNotEmpty) {
      try {
        parsed = DateTime.parse(dt).toLocal();
      } catch (_) {}
    }

    return _Txn(
      accountId: accountId,
      id: id,
      amount: amount,
      currency: currency,
      type: type,
      status: status,
      channel: channel,
      note: note,
      fromName: debtorName,
      toName: creditorName,
      date: parsed,
    );
  }
}

/* =========================
   UI widgets
   ========================= */

class _AccountFilterDropdown extends StatelessWidget {
  const _AccountFilterDropdown({
    required this.accounts,
    required this.selectedAccountId,
    required this.onChanged,
  });

  final List<Map<String, String>> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedAccountId,
          hint: Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Filter by account',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('All Accounts'),
                ],
              ),
            ),
            ...accounts.map((acc) {
              return DropdownMenuItem<String>(
                value: acc['id'],
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        acc['name']!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TxnCard extends StatelessWidget {
  const _TxnCard({required this.txn});

  final _Txn txn;

  @override
  Widget build(BuildContext context) {
    final isDebit = txn.type.toLowerCase() == "debit";
    final amountStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: isDebit ? Colors.red.shade600 : Colors.green.shade600,
    );

    final statusColor = _statusColor(txn.status);
    final statusBg = statusColor.withOpacity(0.12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: amount + status chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${isDebit ? "- " : "+ "}${txn.amount.toStringAsFixed(2)} ${txn.currency}",
                  style: amountStyle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _capitalizeFirst(txn.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // From → To
          Row(
            children: [
              const Icon(Icons.swap_horiz, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "${txn.fromName.isEmpty ? 'Unknown' : txn.fromName} → ${txn.toName.isEmpty ? 'Unknown' : txn.toName}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Channel + AccountId
          Row(
            children: [
              const Icon(Icons.account_balance, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  txn.channel.isEmpty ? "—" : txn.channel,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.credit_card, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  "Acc • ${txn.accountId}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if ((txn.note ?? "").isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    txn.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          // Date
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _fmtDate(txn.date),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == "accepted" || s == "completed" || s == "success") {
      return Colors.green;
    }
    if (s == "rejected" || s == "failed" || s == "declined") {
      return Colors.red;
    }
    return Colors.orange; // pending, processing, etc
  }

  static String _fmtDate(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return "—";
    final months = const [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    final m = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    return "$m $day, $year • $hour:$min $ampm";
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Failed to load transactions",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSync});
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          "No transactions yet",
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Pull down to refresh or sync with your bank.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onSync,
          icon: const Icon(Icons.sync),
          label: const Text("Sync Now"),
        ),
      ],
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.onClearFilter});
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.filter_list_off, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          "No transactions found",
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Try selecting a different account or clear the filter.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onClearFilter,
          icon: const Icon(Icons.clear),
          label: const Text("Clear Filter"),
        ),
      ],
    );
  }
}