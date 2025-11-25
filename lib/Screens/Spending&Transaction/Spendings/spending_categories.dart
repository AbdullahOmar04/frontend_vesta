import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SpendingCategories extends StatefulWidget {
  const SpendingCategories({super.key});

  @override
  State<SpendingCategories> createState() => _SpendingCategoriesState();
}

class _SpendingCategoriesState extends State<SpendingCategories> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loadingTotals = false;
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
              title: const Text("New Category"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Category Name",
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
                        labelText: "Budget Bucket",
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
                                child: Text("Essential"),
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
                        labelText: "Category Type",
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
                ElevatedButton(
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
          title: const Text("Delete Category"),
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
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
          backgroundColor: Colors.red,
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
    final scheme = Theme.of(context).colorScheme;
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("No logged-in user.")));
    }

    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        iconTheme: IconThemeData(color: scheme.surface),
        title: Text(
          "Spending Categories",
          style: TextStyle(color: scheme.surface, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        tooltip: "New Category",
        backgroundColor: scheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Manage Categories",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                "Create, remove, and organize how your spending is grouped.\n"
                "Tracked amounts are for the current budget cycle only.",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Expanded(
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
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No categories found. Create one!"),
                      );
                    }

                    final categories = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final data = category.data();
                        final categoryName = category.id;
                        final type = (data['type'] as String?) ?? 'expense';
                        final bucket =
                            (data['bucket'] as String?) ?? 'essential';

                        final bool isIncome = type.toLowerCase() == 'income';
                        final Color pillColor = isIncome
                            ? Colors.green[700]!
                            : Colors.red[700]!;

                        final tracked =
                            _cycleTotals[categoryName] ?? 0.0; // << key change

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            color: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                // ignore: deprecated_member_use
                                                color: pillColor.withOpacity(
                                                  0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                type,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: pillColor,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                bucket[0].toUpperCase() +
                                                    bucket.substring(
                                                      1,
                                                    ), // Essential / Luxury / ...
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "JOD ${tracked.toStringAsFixed(2)}",
                                              // ...
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDeleteCategory(categoryName),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_loadingTotals)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
