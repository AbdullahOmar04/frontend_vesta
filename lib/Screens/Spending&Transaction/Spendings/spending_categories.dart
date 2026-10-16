import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icon_picker.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transactions.dart';
import 'package:frontend_vesta/Screens/pages/budget_summary.dart';

/// The prototype's "All categories": every category with this cycle's
/// spending, a filter and a sort, and how Necessities and Luxuries stand
/// against the budget plan.
class SpendingCategories extends StatefulWidget {
  const SpendingCategories({super.key});

  @override
  State<SpendingCategories> createState() => _SpendingCategoriesState();
}

enum _Sort { high, low, name, limit }

const _sortLabels = {
  _Sort.high: 'Highest spent',
  _Sort.low: 'Lowest spent',
  _Sort.name: 'Name (A–Z)',
  _Sort.limit: 'Closest to limit',
};

/// Which categories to show: a bucket ('essential', 'luxury', or null for
/// all) and two narrowing switches.
typedef _Filter = ({String? bucket, bool onlySpending, bool onlyOver});

const _noFilter = (bucket: null, onlySpending: false, onlyOver: false);

class _SpendingCategoriesState extends State<SpendingCategories> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loadingTotals = false;
  bool _removing = false;
  int _budgetResetDay = 28;
  // Per-cycle tracked totals per category name
  Map<String, double> _cycleTotals = {};

  /// This cycle's plan per bucket, for the two cards at the bottom.
  BudgetSummary? _summary;

  _Sort _sort = _Sort.high;
  _Filter _filter = _noFilter;

  @override
  void initState() {
    super.initState();
    _loadCycleTotals();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await loadBudgetSummary();
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      debugPrint('⚠️ Error loading the budget summary: $e');
    }
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

  // ---------------- NEW CATEGORY ----------------

  Future<void> _showCreateCategoryDialog() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _NewCategoryDialog(uid: uid, summary: _summary),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Category added')));
    }
  }

  // ---------------- DELETE CATEGORY + UNASSIGN ----------------

  Future<void> _confirmDeleteCategory(String categoryName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await confirmDialog(
      context,
      title: 'Delete "$categoryName"?',
      message: 'Its transactions keep their amounts but will have no category.',
      confirmLabel: 'Delete',
    );

    if (!confirmed) return;

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

  // ---------------- FILTER AND SORT ----------------

  /// A category's bucket: the stored one, else the same guess from the name
  /// that Spendings and the budget summary use.
  String _bucketOf(QueryDocumentSnapshot<Map<String, dynamic>> c) {
    final stored = c.data()['bucket'];
    return stored is String && stored.isNotEmpty
        ? stored
        : inferBucketFromCategoryName(c.id);
  }

  int get _filterCount =>
      (_filter.bucket != null ? 1 : 0) +
      (_filter.onlySpending ? 1 : 0) +
      (_filter.onlyOver ? 1 : 0);

  Future<void> _openFilter() async {
    final picked = await showModalBottomSheet<_Filter>(
      context: context,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (picked != null) setState(() => _filter = picked);
  }

  Future<void> _openSort() async {
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final v = sheetContext.vesta;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              VestaSpace.gutter,
              0,
              VestaSpace.gutter,
              VestaSpace.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sort by', style: headingStyle(18)),
                const SizedBox(height: VestaSpace.sm),
                for (final (i, s) in _Sort.values.indexed)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : Border(top: BorderSide(color: v.divider)),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.pop(sheetContext, s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(_sortLabels[s]!)),
                            if (s == _sort)
                              Icon(
                                PhosphorIconsRegular.check,
                                size: 18,
                                color: v.accentInk,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => _sort = picked);
  }

  /// The categories to show, filtered and sorted.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _visible(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> all,
  ) {
    double spent(QueryDocumentSnapshot<Map<String, dynamic>> c) =>
        _cycleTotals[c.id] ?? 0;
    double? limit(QueryDocumentSnapshot<Map<String, dynamic>> c) {
      final l = c.data()['limit'];
      return l is num && l > 0 ? l.toDouble() : null;
    }

    final shown = all.where((c) {
      final bucket = _bucketOf(c);
      final income = (c.data()['type'] ?? '') == 'income';
      if (_filter.bucket != null && (income || bucket != _filter.bucket)) {
        return false;
      }
      if (_filter.onlySpending && spent(c) <= 0) return false;
      if (_filter.onlyOver) {
        final l = limit(c);
        if (l == null || spent(c) <= l) return false;
      }
      return true;
    }).toList();

    int byName(
      QueryDocumentSnapshot<Map<String, dynamic>> a,
      QueryDocumentSnapshot<Map<String, dynamic>> b,
    ) => a.id.toLowerCase().compareTo(b.id.toLowerCase());

    shown.sort((a, b) {
      switch (_sort) {
        case _Sort.high:
          final c = spent(b).compareTo(spent(a));
          return c != 0 ? c : byName(a, b);
        case _Sort.low:
          final c = spent(a).compareTo(spent(b));
          return c != 0 ? c : byName(a, b);
        case _Sort.name:
          return byName(a, b);
        case _Sort.limit:
          // Nearest to (or furthest past) its limit first; no limit last
          final la = limit(a), lb = limit(b);
          if (la == null && lb == null) return byName(a, b);
          if (la == null) return 1;
          if (lb == null) return -1;
          return (spent(b) / lb).compareTo(spent(a) / la);
      }
    });
    return shown;
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
      appBar: const VestaAppBar(title: "All categories"),
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
            final shown = _visible(categories);

            return RefreshIndicator(
              onRefresh: () =>
                  Future.wait([_loadCycleTotals(), _loadSummary()]),
              child: ListView(
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
                        _ToolButton(
                          icon: PhosphorIconsRegular.funnelSimple,
                          label: _filterCount > 0
                              ? 'Filter · $_filterCount'
                              : 'Filter',
                          active: _filterCount > 0,
                          onTap: _openFilter,
                        ),
                        const SizedBox(width: VestaSpace.sm),
                        _ToolButton(
                          icon: PhosphorIconsRegular.sortAscending,
                          label: 'Sort',
                          onTap: _openSort,
                        ),
                        const Spacer(),
                        if (_loadingTotals)
                          const Padding(
                            padding: EdgeInsets.only(right: VestaSpace.sm),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
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
                  else if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          Text(
                            "No categories match this filter.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: v.muted),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _filter = _noFilter),
                            child: const Text('Clear filter'),
                          ),
                        ],
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
                          for (var i = 0; i < shown.length; i++)
                            _categoryRow(shown[i], first: i == 0),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  _bucketCards(),
                ],
              ),
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
    final bucket = bucketStyle(
      type.toLowerCase() == 'income' ? 'income' : _bucketOf(category),
      v,
    );

    final tracked = _cycleTotals[categoryName] ?? 0.0;
    final limit = data['limit'] is num
        ? (data['limit'] as num).toDouble()
        : 0.0;
    final over = limit > 0 && tracked > limit;

    return InkWell(
      onTap: _removing
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Transactions(showBack: true),
                settings: RouteSettings(
                  arguments: {'selectedCategory': categoryName},
                ),
              ),
            ),
      child: Container(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  tracked,
                  color: over
                      ? v.neg
                      : tracked == 0
                      ? v.muted
                      : null,
                ),
                if (limit > 0)
                  Text(
                    'of ${formatMoney(limit)}',
                    style: TextStyle(fontSize: 11, color: v.muted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The prototype's Necessities and Luxuries cards: spent this cycle
  /// against the plan, and what is left or over.
  Widget _bucketCards() {
    final v = context.vesta;
    final s = _summary;
    Widget card(String label, Color color, double spent, double budget) {
      final left = budget - spent;
      final over = budget > 0 && left < 0;
      return Expanded(
        child: VestaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 12, color: v.muted)),
                ],
              ),
              const SizedBox(height: VestaSpace.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: MoneyText(spent, size: 18),
              ),
              const SizedBox(height: VestaSpace.sm),
              VestaProgressBar(
                value: budget > 0 ? (spent / budget).clamp(0, 1).toDouble() : 0,
                height: 4,
                color: over ? v.neg : color,
              ),
              const SizedBox(height: VestaSpace.sm),
              Text(
                budget <= 0
                    ? 'No budget planned'
                    : over
                    ? '${formatMoney(-left)} over'
                    : '${formatMoney(left)} left',
                style: TextStyle(fontSize: 12, color: over ? v.neg : v.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card(
          'Necessities',
          v.bucketEssential,
          s?.essentialSpent ?? 0,
          s?.essentialBudget ?? 0,
        ),
        const SizedBox(width: VestaSpace.md),
        card(
          'Luxuries',
          v.bucketLuxury,
          s?.luxurySpent ?? 0,
          s?.luxuryBudget ?? 0,
        ),
      ],
    );
  }
}

/// A small outlined toolbar button, as the prototype's Filter and Sort.
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final fg = active ? v.accentInk : null;
    return Material(
      color: active ? v.accentWash : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.button),
        side: BorderSide(color: active ? v.accentInk : v.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of a row of equal-width choices.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// The selected border and text; the accent when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final c = color ?? v.accentInk;
    return Expanded(
      child: Material(
        color: selected ? c.withValues(alpha: 0.14) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VestaRadius.button),
          side: BorderSide(color: selected ? c : v.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: selected ? c : null),
            ),
          ),
        ),
      ),
    );
  }
}

/// The prototype's Filter sheet: type, and two "only" switches.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final _Filter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _bucket = widget.initial.bucket;
  late bool _onlySpending = widget.initial.onlySpending;
  late bool _onlyOver = widget.initial.onlyOver;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    Widget check(String label, bool value, ValueChanged<bool> onChanged) {
      return CheckboxListTile(
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        title: Text(label),
        onChanged: (x) => setState(() => onChanged(x ?? false)),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VestaSpace.gutter,
          0,
          VestaSpace.gutter,
          VestaSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Filter', style: headingStyle(20))),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIconsRegular.x, color: v.muted),
                ),
              ],
            ),
            const SizedBox(height: VestaSpace.sm),
            Text('Type', style: TextStyle(fontSize: 12, color: v.muted)),
            const SizedBox(height: VestaSpace.sm),
            Row(
              children: [
                _Choice(
                  label: 'All',
                  selected: _bucket == null,
                  onTap: () => setState(() => _bucket = null),
                ),
                const SizedBox(width: VestaSpace.sm),
                _Choice(
                  label: 'Necessities',
                  selected: _bucket == 'essential',
                  onTap: () => setState(() => _bucket = 'essential'),
                ),
                const SizedBox(width: VestaSpace.sm),
                _Choice(
                  label: 'Luxuries',
                  selected: _bucket == 'luxury',
                  onTap: () => setState(() => _bucket = 'luxury'),
                ),
              ],
            ),
            const SizedBox(height: VestaSpace.lg),
            Text('Show', style: TextStyle(fontSize: 12, color: v.muted)),
            const SizedBox(height: VestaSpace.sm),
            Container(
              decoration: BoxDecoration(
                color: v.raised,
                borderRadius: BorderRadius.circular(VestaRadius.md),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  check(
                    'Only categories with spending',
                    _onlySpending,
                    (x) => _onlySpending = x,
                  ),
                  Divider(height: 1, color: v.divider),
                  check(
                    'Only categories over their limit',
                    _onlyOver,
                    (x) => _onlyOver = x,
                  ),
                ],
              ),
            ),
            const SizedBox(height: VestaSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: 'Reset',
                    onPressed: () => Navigator.pop(context, _noFilter),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Show results',
                    onPressed: () => Navigator.pop(context, (
                      bucket: _bucket,
                      onlySpending: _onlySpending,
                      onlyOver: _onlyOver,
                    )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The prototype's "Add a new category": icon, name, Necessities or
/// Luxuries, and an optional monthly limit shown against that bucket's
/// budget.
class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog({required this.uid, required this.summary});

  final String uid;
  final BudgetSummary? summary;

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _name = TextEditingController();
  final _limit = TextEditingController();
  String _icon = 'tag';
  String _bucket = 'essential';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  double get _limitValue => double.tryParse(_limit.text.trim()) ?? 0;

  double get _bucketBudget => _bucket == 'essential'
      ? widget.summary?.essentialBudget ?? 0
      : widget.summary?.luxuryBudget ?? 0;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the category a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('categories')
          .doc(name);
      if ((await ref.get()).exists) {
        setState(() {
          _saving = false;
          _error = 'You already have a category called "$name".';
        });
        return;
      }
      await ref.set({
        'type': 'expense',
        'bucket': _bucket,
        'name': name,
        'icon': _icon,
        if (_limitValue > 0) 'limit': _limitValue,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't add the category: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final budget = _bucketBudget;
    final share = budget > 0 ? (_limitValue / budget * 100).round() : 0;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: VestaSpace.sm),
      child: Text(text, style: TextStyle(fontSize: 12, color: v.muted)),
    );

    return VestaDialog(
      title: 'Add a new category',
      cancelButton: false,
      confirmLabel: 'Add category',
      loading: _saving,
      onConfirm: _save,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(
                iconKey: _icon,
                size: 52,
                fallback: PhosphorIconsRegular.tag,
                onTap: () async {
                  final key = await showIconPicker(context, selected: _icon);
                  if (key != null) setState(() => _icon = key);
                },
              ),
              const SizedBox(width: VestaSpace.md),
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(
                    hintText: 'Category name',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.lg),
          label('Budget'),
          Row(
            children: [
              _Choice(
                label: 'Necessities',
                color: v.bucketEssential,
                selected: _bucket == 'essential',
                onTap: () => setState(() => _bucket = 'essential'),
              ),
              const SizedBox(width: VestaSpace.sm),
              _Choice(
                label: 'Luxuries',
                color: v.bucketLuxury,
                selected: _bucket == 'luxury',
                onTap: () => setState(() => _bucket = 'luxury'),
              ),
            ],
          ),
          const SizedBox(height: VestaSpace.lg),
          label('Monthly spending limit'),
          TextField(
            controller: _limit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              prefixIcon: CurrencyPrefix(),
              prefixIconConstraints: currencyPrefixConstraints,
              hintText: 'No limit',
            ),
          ),
          const SizedBox(height: VestaSpace.md),
          Container(
            padding: const EdgeInsets.all(VestaSpace.md),
            decoration: BoxDecoration(
              color: v.raised,
              borderRadius: BorderRadius.circular(VestaRadius.md),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _bucket == 'essential'
                            ? 'Necessities budget'
                            : 'Luxuries budget',
                        style: TextStyle(fontSize: 12, color: v.muted),
                      ),
                    ),
                    Text(
                      budget > 0 ? formatMoney(budget) : 'Not planned',
                      style: amountStyle(12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(
                      child: Text('This limit', style: TextStyle(fontSize: 12)),
                    ),
                    Text(
                      budget > 0 ? '$share% of budget' : '—',
                      style: TextStyle(
                        fontSize: 12,
                        color: share > 100 ? v.neg : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: VestaSpace.sm),
            Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
          ],
        ],
      ),
    );
  }
}
