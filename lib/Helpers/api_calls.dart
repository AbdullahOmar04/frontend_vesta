// ignore_for_file: avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "https://backend-vesta.onrender.com";

Future<void> syncAccounts({required String bankId, String? username, required String sandbox}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;
  String u = (username ?? '').trim();

  if (u.isEmpty) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final stored = doc.data()?['providers']?[bankId]?['username'];
    if (stored is String && stored.trim().isNotEmpty) u = stored.trim();
  }
  if (u.isEmpty) return;

  final url = Uri.parse(
    "$baseUrl/banks/$bankId/sync_accounts/$uid",
  ).replace(queryParameters: {"customer_id": u});

  await http.get(url);
}

Future<void> getTransactions({required String bankId}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  try {
    // Step 1: Get all accounts for the user from Firestore
    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .where('linked', isEqualTo: true)
        .where('provider', isEqualTo: bankId)
        .get();

    if (accountsSnap.docs.isEmpty) {
      print("⚠️ No accounts found in Firestore for this user");
      return;
    }

    // Step 2: Loop through each account and fetch transactions
    for (var doc in accountsSnap.docs) {
      final accountId = doc.id;
      final url = Uri.parse(
        "$baseUrl/banks/$bankId/get_transactions/$uid/$accountId",
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("✅ Synced transactions for account $accountId: $data");
        } else {
          print("❌ Failed for $accountId: ${response.body}");
        }
      } catch (e) {
        print("⚠️ Error fetching transactions for $accountId: $e");
      }
    }
  } catch (e) {
    print("⚠️ Error getting accounts from Firestore: $e");
  }
}

/// Call this once on login / app open
Future<void> handleBudgetCycleOnLogin() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final userRef = FirebaseFirestore.instance.collection("users").doc(uid);
  final userSnap = await userRef.get();
  final userData = userSnap.data();
  if (userData == null) return;

  final int dayOfMonth = userData["dayOfMonth"] ?? 26;
  final double income = (userData["totalIncome"] ?? 0).toDouble();
  final String currency = (userData["currency"] ?? "JOD").toString();

  final now = DateTime.now();

  int currentLabelYear;
  int currentLabelMonth;

  if (now.day >= dayOfMonth) {
    if (now.month == 12) {
      currentLabelYear = now.year + 1;
      currentLabelMonth = 1;
    } else {
      currentLabelYear = now.year;
      currentLabelMonth = now.month + 1;
    }
  } else {
    currentLabelYear = now.year;
    currentLabelMonth = now.month;
  }

  int prevLabelYear = currentLabelYear;
  int prevLabelMonth = currentLabelMonth - 1;
  if (prevLabelMonth == 0) {
    prevLabelMonth = 12;
    prevLabelYear -= 1;
  }

  String _monthId(int year, int month) =>
      "$year-${month.toString().padLeft(2, '0')}";

  final String currentMonthId = _monthId(currentLabelYear, currentLabelMonth);
  final String prevMonthId = _monthId(prevLabelYear, prevLabelMonth);

  // Helpers for cycle start/end (for a given LABEL month)
  DateTime _cycleStart(int year, int labelMonth, int day) {
    int startYear = year;
    int startMonth = labelMonth - 1;
    if (startMonth == 0) {
      startMonth = 12;
      startYear -= 1;
    }
    return DateTime(startYear, startMonth, day);
  }

  // End is exclusive: [start, end)
  DateTime _cycleEndExclusive(int year, int labelMonth, int day) {
    // This is the salary day of the label month at 00:00
    return DateTime(year, labelMonth, day);
  }

  final prevStart = _cycleStart(prevLabelYear, prevLabelMonth, dayOfMonth);
  final prevEndExclusive = _cycleEndExclusive(
    prevLabelYear,
    prevLabelMonth,
    dayOfMonth,
  );

  final currentStart = _cycleStart(
    currentLabelYear,
    currentLabelMonth,
    dayOfMonth,
  );
  final currentEndExclusive = _cycleEndExclusive(
    currentLabelYear,
    currentLabelMonth,
    dayOfMonth,
  );

  final budgetCol = userRef.collection("budget");

  // ---------- 2) FINALIZE PREVIOUS CYCLE (actualSpending / actualSavings) ----------

  final prevDocRef = budgetCol.doc(prevMonthId);
  final prevDocSnap = await prevDocRef.get();

  if (prevDocSnap.exists) {
    final totals = await _computeCycleTotals(uid, prevStart, prevEndExclusive);

    await prevDocRef.set({
      "actualSpending": totals.spending,
      "actualSavings": totals.savings,
      "startDate": Timestamp.fromDate(prevStart),
      "endDate": Timestamp.fromDate(
        prevEndExclusive.subtract(const Duration(seconds: 1)),
      ),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  final currentDocRef = budgetCol.doc(currentMonthId);
  final currentDocSnap = await currentDocRef.get();

  if (!currentDocSnap.exists) {
    double savingPct = 0;
    double spendingPct = 0;
    double luxuriesPct = 0;

    // Get last known plan (copy forward percentages)
    final lastPlanSnap = await budgetCol
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get();

    if (lastPlanSnap.docs.isNotEmpty) {
      final last = lastPlanSnap.docs.first.data();
      savingPct = (last["saving"] ?? savingPct).toDouble();
      spendingPct = (last["spending"] ?? spendingPct).toDouble();
      luxuriesPct = (last["luxuries"] ?? luxuriesPct).toDouble();
    }

    await currentDocRef.set({
      "income": income,
      "saving": savingPct,
      "spending": spendingPct,
      "luxuries": luxuriesPct,
      "currency": currency,
      "startDate": Timestamp.fromDate(currentStart),
      "endDate": Timestamp.fromDate(
        currentEndExclusive.subtract(const Duration(seconds: 1)),
      ),
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    print("📆 Created budget doc for cycle $currentMonthId");
  } else {
    print("✅ Budget already exists for cycle $currentMonthId");
  }
}

/// Small helper type
class _CycleTotals {
  final double spending;
  final double savings;

  _CycleTotals({required this.spending, required this.savings});
}

/// Reads all accounts / transactions and sums amounts for a given cycle
Future<_CycleTotals> _computeCycleTotals(
  String uid,
  DateTime start,
  DateTime endExclusive,
) async {
  final fire = FirebaseFirestore.instance;

  final accountsSnap = await fire
      .collection("users")
      .doc(uid)
      .collection("accounts")
      .get();

  double totalSpending = 0;
  double totalSavings = 0;

  const spendingCategories = {
    "Groceries",
    "Entertainment",
    "Food And Drinks",
    "Others",
  };
  const savingsCategory = "Savings";

  for (final account in accountsSnap.docs) {
    final txSnap = await fire
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .doc(account.id)
        .collection("transactions")
        .get();

    for (final doc in txSnap.docs) {
      final data = doc.data();

      // Parse date
      DateTime? date;
      if (data["date"] is String) {
        date = DateTime.tryParse(data["date"]);
      } else if (data["date"] is Timestamp) {
        date = (data["date"] as Timestamp).toDate();
      }
      if (date == null) continue;

      // Must be within [start, endExclusive)
      if (date.isBefore(start) || !date.isBefore(endExclusive)) continue;

      // Parse amount
      double amount = 0;
      if (data["amount"] != null) {
        amount = double.tryParse(data["amount"].toString()) ?? 0;
      }

      final category = data["category"] as String?;

      if (category == savingsCategory) {
        totalSavings += amount;
      } else if (category != null && spendingCategories.contains(category)) {
        totalSpending += amount;
      }
    }
  }

  return _CycleTotals(spending: totalSpending, savings: totalSavings);
}

Future<void> getSOSPs() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  try {
    // Step 1: Get all accounts for the user from Firestore
    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .where('linked', isEqualTo: true)
        .get();

    if (accountsSnap.docs.isEmpty) {
      print("⚠️ No accounts found in Firestore for this user");
      return;
    }

    for (var doc in accountsSnap.docs) {
      final accountId = doc.id;
      final url = Uri.parse("$baseUrl/get_sosps/$uid/$accountId");

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("✅ Synced SOSPs for account $accountId: $data");
        } else {
          print("❌ Failed for $accountId: ${response.body}");
        }
      } catch (e) {
        print("⚠️ Error fetching SOSPs for $accountId: $e");
      }
    }
  } catch (e) {
    print("⚠️ Error getting accounts from Firestore: $e");
  }
}


//////////////////////////////////////AHLI BANK//////////////////////////////////////


Future<String?> ahliStartAuth() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  final url = Uri.parse("$baseUrl/banks/ahli/auth/start/$uid");
  final res = await http.get(url);

  if (res.statusCode != 200) {
    print("❌ ahliStartAuth failed: ${res.body}");
    return null;
  }

  final data = jsonDecode(res.body);
  return (data["auth_url"] ?? data["url"])?.toString();
}

/// 2) Exchange authorization code -> access token (authorization_code)
/// Backend should also persist tokens (Firestore or server store).
Future<bool> ahliFinishAuth({required String code, required String state}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;

  final url = Uri.parse("$baseUrl/banks/ahli/auth/callback/$uid");
  final res = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"code": code, "state": state}),
  );

  if (res.statusCode != 200) {
    print("❌ ahliFinishAuth failed: ${res.body}");
    return false;
  }

  return true;
}

/// 3) Use stored tokens to fetch/sync accounts into:
/// users/{uid}/accounts/{accountId}
Future<void> ahliSyncAccounts() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final url = Uri.parse("$baseUrl/banks/ahli/sync_accounts/$uid");
  final res = await http.get(url);

  if (res.statusCode != 200) {
    print("❌ ahliSyncAccounts failed: ${res.body}");
  }
}

/// 4) Fetch transactions for all linked Ahli accounts (optional)
Future<void> ahliGetTransactions() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final url = Uri.parse("$baseUrl/banks/ahli/get_transactions/$uid");
  final res = await http.get(url);

  if (res.statusCode != 200) {
    print("❌ ahliGetTransactions failed: ${res.body}");
  }
}
