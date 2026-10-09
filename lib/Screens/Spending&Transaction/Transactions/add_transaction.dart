import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';

class AddTransaction extends StatefulWidget {
  const AddTransaction({super.key});

  @override
  State<AddTransaction> createState() => AddTransactionState();
}

class AddTransactionState extends State<AddTransaction> {
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // SMS paste controller
  final _smsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _accounts = [];
  List<String> _categories = [];

  String? _selectedAccountId;
  String? _selectedCategory;
  TransactionType _type = TransactionType.debit;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccountsAndCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _noteCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccountsAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final uid = user.uid;
      final fire = FirebaseFirestore.instance;

      // Accounts
      final accountsSnap = await fire
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('linked', isEqualTo: true)
          .get();

      final accounts = accountsSnap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['accountName'] ?? d.id,
          'type': data['accountTypeName'],
        };
      }).toList();

      // Categories
      final categoriesSnap = await fire
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();

      final categories = categoriesSnap.docs.map((d) => d.id).toList();

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _categories = categories;
          if (_accounts.isNotEmpty) {
            _selectedAccountId = _accounts.first['id'] as String;
          }
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error loading accounts/categories: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final rawAmount = _amountCtrl.text.trim();
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount.")));
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select an account.")));
      return;
    }

    setState(() => _saving = true);

    try {
      final fire = FirebaseFirestore.instance;

      final newDoc = fire
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .doc(_selectedAccountId)
          .collection('transactions')
          .doc();

      final txn = TransactionModel.manual(
        firestoreAccountId: _selectedAccountId!,
        id: newDoc.id,
        amount: amount,
        currency: "JOD",
        type: _type,
        date: _date,
        merchantName: _merchantCtrl.text.trim().isEmpty
            ? null
            : _merchantCtrl.text.trim(),
        description: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
        accountLabel: null,
        category: _selectedCategory,
      );

      await saveTransactionAndApplyBalance(
        uid: uid,
        accountId: _selectedAccountId!,
        txn: txn,
      );
      await calcTotalBalance();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Transaction added.")));
      }
    } catch (e) {
      debugPrint("⚠️ Error saving transaction: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============ SMS PASTE FEATURE ============

  void _openSmsPasteDialog() {
    _smsCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return VestaDialog(
          title: "Paste bank SMS",
          content: TextField(
            controller: _smsCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: "Paste the SMS message from your bank here...",
            ),
          ),
          confirmLabel: "Parse",
          onConfirm: () {
            final smsText = _smsCtrl.text.trim();
            if (smsText.isEmpty) {
              return;
            }
            _fillFromSms(smsText);
            Navigator.pop(ctx);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("SMS parsed. Fields updated.")),
            );
          },
        );
      },
    );
  }

  void _fillFromSms(String sms) {
    final lower = sms.toLowerCase();

    final amountMatch = RegExp(
      r'JOD\s+(\d+(\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (amountMatch != null) {
      _amountCtrl.text = amountMatch.group(1)!; // "3.000"
    }

    final merchantMatch = RegExp(
      r'from\s+(.+?)\s+amount',
      caseSensitive: false,
    ).firstMatch(sms);
    if (merchantMatch != null) {
      _merchantCtrl.text = merchantMatch.group(1)!.trim();
    }

    // 3) Date & time: "on 16/11/2025 18:32"
    final dateMatch = RegExp(
      r'on\s+(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(sms);

    DateTime? parsedDate;
    if (dateMatch != null) {
      final dateStr = dateMatch.group(1)!; // dd/MM/yyyy
      final timeStr = dateMatch.group(2)!; // HH:mm

      final dParts = dateStr.split('/');
      final tParts = timeStr.split(':');

      try {
        final day = int.parse(dParts[0]);
        final month = int.parse(dParts[1]);
        final year = int.parse(dParts[2]);
        final hour = int.parse(tParts[0]);
        final minute = int.parse(tParts[1]);

        parsedDate = DateTime(year, month, day, hour, minute);
      } catch (_) {}
    }

    // 4) Type: "purchase transaction" => debit
    TransactionType guessedType = TransactionType.debit;
    if (lower.contains("received") ||
        (lower.contains("credit") && !lower.contains("credit card"))) {
      guessedType = TransactionType.credit;
    }

    setState(() {
      _type = guessedType;
      if (parsedDate != null) {
        _date = parsedDate;
      }
    });
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    final bodyLarge = Theme.of(context).textTheme.bodyLarge;

    return Scaffold(
      appBar: const VestaAppBar(title: 'Add transaction'),
      body: VestaBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VestaSpace.gutter,
                  VestaSpace.xs,
                  VestaSpace.gutter,
                  VestaSpace.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SMS paste button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _openSmsPasteDialog,
                        icon: const Icon(PhosphorIconsRegular.chatText, size: 18),
                        label: const Text("Paste SMS from bank"),
                      ),
                    ),
                    const SizedBox(height: VestaSpace.sm),

                    // Account
                    if (_accounts.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAccountId,
                        style: bodyLarge,
                        decoration: const InputDecoration(labelText: "Account"),
                        items: _accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a['id'] as String,
                                child: Text(
                                  a['type'] is String &&
                                          (a['type'] as String).isNotEmpty
                                      ? "${a['name']} · ${a['type']}"
                                      : a['name'] as String,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedAccountId = val);
                        },
                      )
                    else
                      Text(
                        "No accounts yet. Add one in Wallet first.",
                        style: TextStyle(color: context.vesta.neg),
                      ),
                    gap,

                    // Amount
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: "Amount"),
                    ),
                    gap,

                    // Type
                    Row(
                      children: [
                        ChoiceTag(
                          label: "Expense",
                          icon: PhosphorIconsRegular.arrowUpRight,
                          selected: _type == TransactionType.debit,
                          onTap: () {
                            setState(() => _type = TransactionType.debit);
                          },
                        ),
                        const SizedBox(width: VestaSpace.sm),
                        ChoiceTag(
                          label: "Income",
                          icon: PhosphorIconsRegular.arrowDownLeft,
                          selected: _type == TransactionType.credit,
                          onTap: () {
                            setState(() => _type = TransactionType.credit);
                          },
                        ),
                      ],
                    ),
                    gap,

                    // Date
                    InkWell(
                      borderRadius: BorderRadius.circular(VestaRadius.md),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date.isAfter(DateTime.now()) ? DateTime.now() : _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          final now = DateTime.now();
                          setState(() {
                            _date = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              now.hour,
                              now.minute,
                            );
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Date",
                          suffixIcon: Icon(
                            PhosphorIconsRegular.calendarBlank,
                            color: context.vesta.accentInk,
                          ),
                        ),
                        child: Text(
                          "${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}",
                          style: bodyLarge,
                        ),
                      ),
                    ),
                    gap,

                    // Merchant
                    TextField(
                      controller: _merchantCtrl,
                      decoration: const InputDecoration(
                        labelText: "Merchant / From",
                      ),
                    ),
                    gap,

                    // Category
                    if (_categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        style: bodyLarge,
                        decoration: const InputDecoration(labelText: "Category"),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategory = val);
                        },
                      ),
                    if (_categories.isNotEmpty) gap,

                    // Note
                    TextField(
                      controller: _noteCtrl,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Note (optional)",
                      ),
                    ),
                    const SizedBox(height: VestaSpace.xl),

                    PrimaryButton(
                      label: 'Add transaction',
                      loading: _saving,
                      onPressed: () {
                        if (!_saving) {
                          _save();
                        }
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
