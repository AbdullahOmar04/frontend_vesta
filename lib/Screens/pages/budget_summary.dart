import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';

/// This budget cycle's plan against what has gone out so far, per bucket.
/// Shared by the coach card and the Dashboard. Read-only.
class BudgetSummary {
  const BudgetSummary({
    required this.income,
    required this.essentialBudget,
    required this.luxuryBudget,
    required this.savingsBudget,
    required this.essentialSpent,
    required this.luxurySpent,
    required this.savingsMoved,
    required this.start,
    required this.end,
  });

  final double income;
  final double essentialBudget;
  final double luxuryBudget;
  final double savingsBudget;
  final double essentialSpent;
  final double luxurySpent;

  /// Money moved into savings categories this cycle.
  final double savingsMoved;

  /// First and last day of the cycle.
  final DateTime start;
  final DateTime end;

  bool get hasPlan => essentialBudget + luxuryBudget > 0;

  /// Necessities and luxuries: the money meant to be spent.
  double get flexBudget => essentialBudget + luxuryBudget;
  double get flexSpent => essentialSpent + luxurySpent;

  int get totalDays => end.difference(start).inDays + 1;

  /// Days left including today.
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (end.difference(today).inDays + 1).clamp(1, totalDays);
  }

  /// How far through the cycle today is, 0–1.
  double get progress => (totalDays - daysLeft + 1) / totalDays;
}

/// The plan comes from users/{uid}.totalIncome and this month's budget doc
/// (spending, luxuries and saving percentages); the cycle from the user's
/// dayOfMonth, as the Budgeting screen works it out; spending from linked
/// accounts' debits in each category's bucket.
Future<BudgetSummary?> loadBudgetSummary() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final now = DateTime.now();
  final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

  final userData = (await userRef.get()).data() ?? {};
  final budget =
      (await userRef.collection('budget').doc(monthId).get()).data() ?? {};

  final income = double.tryParse('${userData['totalIncome'] ?? 0}') ?? 0;
  double pct(String key) => double.tryParse('${budget[key] ?? 0}') ?? 0;

  final resetDay = (userData['dayOfMonth'] as num?)?.toInt() ?? 28;
  final DateTime start;
  final DateTime end;
  if (now.day >= resetDay) {
    start = DateTime(now.year, now.month, resetDay);
    end = DateTime(now.year, now.month + 1, resetDay)
        .subtract(const Duration(days: 1));
  } else {
    start = DateTime(now.year, now.month - 1, resetDay);
    end = DateTime(now.year, now.month, resetDay)
        .subtract(const Duration(days: 1));
  }
  final endOfCycle = DateTime(end.year, end.month, end.day, 23, 59, 59);

  final buckets = <String, String>{};
  for (final doc in (await userRef.collection('categories').get()).docs) {
    final raw = (doc.data()['bucket'] ?? '') as String;
    buckets[doc.id] = raw.isEmpty ? inferBucketFromCategoryName(doc.id) : raw;
  }

  var essentialSpent = 0.0;
  var luxurySpent = 0.0;
  var savingsMoved = 0.0;
  final accounts = await userRef
      .collection('accounts')
      .where('linked', isEqualTo: true)
      .get();
  for (final account in accounts.docs) {
    final txns = await account.reference.collection('transactions').get();
    for (final doc in txns.docs) {
      final data = doc.data();
      if ('${data['type'] ?? ''}'.toLowerCase() != 'debit') continue;
      final date = DateTime.tryParse('${data['date'] ?? ''}');
      if (date == null || date.isBefore(start) || date.isAfter(endOfCycle)) {
        continue;
      }
      final category = data['category'] as String?;
      if (category == null || category.isEmpty) continue;
      final bucket = buckets[category] ?? inferBucketFromCategoryName(category);
      final amount = (double.tryParse('${data['amount'] ?? 0}') ?? 0).abs();
      if (bucket == 'essential') essentialSpent += amount;
      if (bucket == 'luxury') luxurySpent += amount;
      if (bucket == 'savings') savingsMoved += amount;
    }
  }

  return BudgetSummary(
    income: income,
    essentialBudget: income * pct('spending') / 100,
    luxuryBudget: income * pct('luxuries') / 100,
    savingsBudget: income * pct('saving') / 100,
    essentialSpent: essentialSpent,
    luxurySpent: luxurySpent,
    savingsMoved: savingsMoved,
    start: start,
    end: end,
  );
}
