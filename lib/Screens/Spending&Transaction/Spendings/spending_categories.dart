import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

class SpendingCategories extends StatefulWidget {
  const SpendingCategories({super.key});

  @override
  State<SpendingCategories> createState() => _SpendingCategoriesState();
}

class _SpendingCategoriesState extends State<SpendingCategories> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loadingTotals = false;
  bool _removing = false;
  int _budgetResetDay = 28;
  // Per-cycle tracked totals per category name
  Map<String, double> _cycleTotals = {};

  @override
  void initState() {
    super.initState();
    _loadCycleTotals();
  }

  // ---------------- HELPERS ----------------

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  double _parseAmount(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  // ---------------- LOAD TOTALS FOR CURRENT CYCLE ----------------

  Future<void> _loadCycleTotals() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loadingTotals = true);

    try {
      final userRef = _db.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? {};

      _budgetResetDay = (userData['dayOfMonth'] ?? 28) as int;

      final now = DateTime.now();
      DateTime startDate;
      DateTime endExclusive;

      // Same logic you use elsewhere: 26→26 style cycle
      if (now.day >= _budgetResetDay) {
        startDate = DateTime(now.year, now.month, _budgetResetDay);
        final nextMonth = DateTime(now.year, now.month + 1, _budgetResetDay);
        endExclusive = nextMonth;
      } else {
        startDate = DateTime(now.year, now.month - 1, _budgetResetDay);
        final thisMonth = DateTime(now.year, now.month, _budgetResetDay);
        endExclusive = thisMonth;
      }

      // Load category types (expense / income)
      final catSnap = await userRef
          .collection('categories')
          .get(); // one-time read
      final Map<String, String> catTypes = {};
      for (final doc in catSnap.docs) {
        final data = doc.data();
        catTypes[doc.id] = (data['type'] ?? 'expense') as String;
      }

      final accountsSnap = await userRef
          .collection('accounts')
          .where('linked', isEqualTo: true)
          .get();

      final Map<String, double> totals = {};

      for (final accDoc in accountsSnap.docs) {
        final txSnap = await accDoc.reference.collection('transactions').get();

        for (final txDoc in txSnap.docs) {
          final data = txDoc.data();
          final String? cat = data['category'] as String?;
          if (cat == null || cat.isEmpty) continue;

          final date = _parseDate(data['date']);
          if (date == null) continue;

          // must be inside current cycle [startDate, endExclusive)
          if (date.isBefore(startDate) || !date.isBefore(endExclusive)) {
            continue;
          }

          final double amount = _parseAmount(data['amount']);
          if (amount == 0) continue;

          final txType = (data['type'] ?? '').toString().toLowerCase();
          final catType = (catTypes[cat] ?? 'expense').toLowerCase();

          bool include = false;
          if (catType == 'expense' && txType == 'debit') include = true;
          if (catType == 'income' && txType == 'credit') include = true;

          if (!include) continue;

          totals[cat] = (totals[cat] ?? 0.0) + amount.abs();
        }
      }

      if (!mounted) return;
      setState(() {
        _cycleTotals = totals;
        _loadingTotals = false;
      });
    } catch (e) {
      debugPrint('⚠️ Error loading category totals: $e');
      if (!mounted) return;
      setState(() => _loadingTotals = false);
    }
  }

  // ---------------- CREATE CATEGORY DIALOG ----------------

  Future<void> _showCreateCategoryDialog() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String selectedType = 'expense';
    String selectedBucket = 'essential';

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("New category"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType == 'income'
                          ? 'income'
                          : selectedBucket,
                      decoration: const InputDecoration(
                        labelText: "Budget bucket",
                      ),
                      items: selectedType == 'income'
                          ? const [
                              DropdownMenuItem(
                                value: 'income',
                                child: Text("Income"),
                              ),
                            ]
                          : const [
                              DropdownMenuItem(
                                value: 'essential',
                                child: Text("Necessity"),
                              ),
                              DropdownMenuItem(
                                value: 'luxury',
                                child: Text("Luxury"),
                              ),
                              DropdownMenuItem(
                                value: 'savings',
                                child: Text("Savings"),
                              ),
                            ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          if (selectedType == 'income') {
                            selectedBucket = 'income';
                          } else {
                            selectedBucket = value;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Type",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text("Expense"),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text("Income"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final categoryName = nameController.text.trim();

                      try {
                        // For income categories, force bucket = income
                        final bucketToSave = selectedType == 'income'
                            ? 'income'
                            : selectedBucket;

                        await _db
                            .collection('users')
                            .doc(uid)
                            .collection('categories')
                            .doc(categoryName)
                            .set({
                              'type': selectedType, // expense | income
                              'bucket':
                                  bucketToSave, // essential | luxury | savings | income
                              'name': categoryName,
                            });

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        // ...
                      }
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- DELETE CATEGORY + UNASSIGN ----------------

  Future<void> _confirmDeleteCategory(String categoryName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete category"),
          content: Text(
            'Delete "$categoryName"?\n\n'
            "Existing transactions will keep their amounts, "
            "but this category will be unassigned.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: context.vesta.neg),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final userRef = _db.collection('users').doc(uid);

      // 1) delete category doc
      await userRef.collection('categories').doc(categoryName).delete();

      // 2) unassign from all transactions that used this category
      await _unassignCategoryFromTransactions(uid, categoryName);

      // 3) drop from local totals map
      setState(() {
        _cycleTotals.remove(categoryName);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$categoryName" deleted and unassigned.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting category: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _unassignCategoryFromTransactions(
    String uid,
    String categoryName,
  ) async {
    final userRef = _db.collection('users').doc(uid);
    final accountsSnap = await userRef.collection('accounts').get();

    for (final accDoc in accountsSnap.docs) {
      final txQuery = await accDoc.reference
          .collection('transactions')
          .where('category', isEqualTo: categoryName)
          .get();

      if (txQuery.docs.isEmpty) continue;

      WriteBatch batch = _db.batch();
      int opCount = 0;

      for (final txDoc in txQuery.docs) {
        batch.update(txDoc.reference, {'category': null});
        opCount++;
        if (opCount >= 450) {
          await batch.commit();
          batch = _db.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }
    }
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("No logged-in user.")));
    }

    final v = context.vesta;

    return Scaffold(
      appBar: const VestaAppBar(title: "Categories"),
      body: VestaBackground(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('users')
              .doc(uid)
              .collection('categories')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final categories = snapshot.hasData
                ? snapshot.data!.docs
                : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                VestaSpace.xs,
                VestaSpace.gutter,
                VestaSpace.xl,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: VestaSpace.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Amounts are for the current budget cycle.",
                          style: TextStyle(fontSize: 13, color: v.muted),
                        ),
                      ),
                      if (_loadingTotals)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      AddRemoveButtons(
                        onAdd: _showCreateCategoryDialog,
                        addTooltip: "New category",
                        removing: _removing,
                        canRemove: categories.isNotEmpty,
                        removeTooltip: "Remove a category",
                        onToggleRemove: () =>
                            setState(() => _removing = !_removing),
                      ),
                    ],
                  ),
                ),
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      "No categories yet. Tap + to create one.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: v.muted),
                    ),
                  )
                else
                  VestaCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VestaSpace.lg,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < categories.length; i++)
                          _categoryRow(categories[i], first: i == 0),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _categoryRow(
    QueryDocumentSnapshot<Map<String, dynamic>> category, {
    required bool first,
  }) {
    final v = context.vesta;
    final data = category.data();
    final categoryName = category.id;
    final type = (data['type'] as String?) ?? 'expense';
    final bucketName = (data['bucket'] as String?) ?? 'essential';
    final bucket = bucketStyle(
      type.toLowerCase() == 'income' ? 'income' : bucketName,
      v,
    );

    final tracked = _cycleTotals[categoryName] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: v.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (_removing) ...[
            RemoveBadge(onTap: () => _confirmDeleteCategory(categoryName)),
            const SizedBox(width: VestaSpace.md),
          ],
          IconBadge(
            categoryIcon(categoryName),
            size: 40,
            circle: false,
            color: bucket.color,
          ),
          const SizedBox(width: VestaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: VestaSpace.xs),
                TagChip(bucket.label, color: bucket.color),
              ],
            ),
          ),
          MoneyText(tracked),
        ],
      ),
    );
  }
}
