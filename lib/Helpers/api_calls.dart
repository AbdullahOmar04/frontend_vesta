// ignore_for_file: avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_vesta/Helpers/pinned_http_client.dart';
import 'package:http/http.dart' as http;

// A trailing slash in API_URL would turn every route into //banks/..., a 404
final String baseUrl = (dotenv.env['API_URL'] ?? '').replaceAll(RegExp(r'/+$'), '');

Future<Map<String, String>> _authHeaders([bool forceRefresh = false]) async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
  if (token == null) throw Exception('Not authenticated');
  return {'Authorization': 'Bearer $token'};
}

Future<void> syncAccounts([String? username]) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final uid = user.uid;

  String u = (username ?? '').trim();

  // If no username passed, read from Firestore
  if (u.isEmpty) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final stored = doc.data()?['providers']?['jopacc']?['username'];
    if (stored is String && stored.trim().isNotEmpty) {
      u = stored.trim();
    }
  }

  // If still empty, abort gracefully
  if (u.isEmpty) {
    // ignore or log
    return;
  }

  final url = Uri.parse(
    "$baseUrl/sync_accounts/$uid/${Uri.encodeComponent(u)}",
  );

  try {
    final resp = await getPinnedHttpClient().get(url, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      print("✅ Synced accounts: $data");
    } else {
      // print("❌ Failed: ${resp.body}");
    }
  } catch (e) {
    // print("⚠️ Error calling sync_accounts: $e");
  }
}

Future<void> getTransactions() async {
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

    // Step 2: Loop through each account and fetch transactions
    //         Route to the correct backend endpoint based on provider
    for (var doc in accountsSnap.docs) {
      final accountId = doc.id;
      final provider = (doc.data()['provider'] ?? '').toString();

      if (provider == hbtfProviderLabel) {
        // Housing Bank syncs by the bank's raw account number, not the doc id
        final accountNumber = doc.data()['accountNumber']?.toString() ?? '';
        if (accountNumber.isEmpty) {
          print("Skipping Housing Bank account $accountId: missing accountNumber");
          continue;
        }
        try {
          final synced = await hbtfSyncTransactions(accountNumber);
          print("Synced $synced Housing Bank transactions for $accountId");
        } on HbtfException catch (e) {
          print("Housing Bank transaction sync failed for $accountId: $e");
        }
        continue;
      }

      final Uri url;
      if (provider == 'Ahli') {
        url = Uri.parse("$baseUrl/banks/ahli/get_transactions/$uid/$accountId");
      } else if (provider == 'Capital') {
        url = Uri.parse("$baseUrl/banks/capital/get_transactions/$uid/$accountId");
      } else if (provider == 'Etihad') {
        // Etihad transactions are synced via sync_transactions endpoint;
        // get_transactions requires customer_id + account_number, so we
        // read them from the Firestore account doc.
        final accData = doc.data();
        final customerId = accData['customerId']?.toString() ?? '';
        final accountNumber = accData['accountNumber']?.toString() ?? '';
        if (customerId.isEmpty || accountNumber.isEmpty) {
          print("Skipping Etihad account $accountId: missing customerId or accountNumber");
          continue;
        }
        url = Uri.parse("$baseUrl/banks/etihad/get_transactions/$uid/$customerId/$accountNumber");
      } else {
        url = Uri.parse("$baseUrl/get_transactions/$uid/$accountId");
      }

      try {
        final response = await getPinnedHttpClient().get(url, headers: await _authHeaders());
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("✅ Synced transactions for account $accountId: $data");
        } else {
          print("❌ Failed for $accountId: ${response.statusCode} ${response.body}");
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

// ─── Ahli Bank (Comply / finX) ───

/// Initiates the Ahli OAuth link flow.
/// Returns a Map with { "authUrl": "...", "consentId": "..." } on success,
/// or null on failure.
Future<Map<String, dynamic>?> startAhliLink() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/ahli/start_link/${user.uid}");
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final headers = await _authHeaders();
    headers.forEach((k, v) => request.headers.set(k, v));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
  } catch (e) {
    print("Error starting Ahli link: $e");
  } finally {
    client.close();
  }
  return null;
}

/// Re-syncs Ahli accounts from the bank into Firestore.
Future<void> syncAhliAccounts() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final url = Uri.parse("$baseUrl/banks/ahli/sync_accounts/${user.uid}");
  try {
    final resp = await http.get(url, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      print("Synced Ahli accounts: $data");
    }
  } catch (e) {
    print("Error syncing Ahli accounts: $e");
  }
}

/// Fetches transactions for all linked Ahli accounts.
Future<void> getAhliTransactions() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  try {
    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .where('linked', isEqualTo: true)
        .where('provider', isEqualTo: 'Ahli')
        .get();

    for (var doc in accountsSnap.docs) {
      final accountId = doc.id;
      final url = Uri.parse("$baseUrl/banks/ahli/get_transactions/$uid/$accountId");
      try {
        final response = await http.get(url, headers: await _authHeaders());
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Synced Ahli transactions for $accountId: $data");
        }
      } catch (e) {
        print("Error fetching Ahli transactions for $accountId: $e");
      }
    }
  } catch (e) {
    print("Error getting Ahli accounts from Firestore: $e");
  }
}

// ─── Capital Bank (CBOJ) ───

/// Initiates the Capital Bank OAuth link flow.
/// Returns a Map with { "authUrl": "...", "consentRef": "..." } on success,
/// or null on failure.
Future<Map<String, dynamic>?> startCapitalLink() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/capital/start_link/${user.uid}");
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 60);
  try {
    final request = await client.getUrl(url);
    final headers = await _authHeaders();
    headers.forEach((k, v) => request.headers.set(k, v));
    final response = await request.close().timeout(const Duration(seconds: 120));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
  } catch (e) {
    print("Error starting Capital link: $e");
  } finally {
    client.close();
  }
  return null;
}

/// Re-syncs Capital Bank accounts from the bank into Firestore.
Future<void> syncCapitalAccounts() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final url = Uri.parse("$baseUrl/banks/capital/sync_accounts/${user.uid}");
  try {
    final resp = await http.get(url, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      print("Synced Capital accounts: $data");
    }
  } catch (e) {
    print("Error syncing Capital accounts: $e");
  }
}

/// Fetches transactions for all linked Capital Bank accounts.
Future<void> getCapitalTransactions() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  try {
    final accountsSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("accounts")
        .where('linked', isEqualTo: true)
        .where('provider', isEqualTo: 'Capital')
        .get();

    for (var doc in accountsSnap.docs) {
      final accountId = doc.id;
      final url = Uri.parse("$baseUrl/banks/capital/get_transactions/$uid/$accountId");
      try {
        final response = await http.get(url, headers: await _authHeaders());
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Synced Capital transactions for $accountId: $data");
        }
      } catch (e) {
        print("Error fetching Capital transactions for $accountId: $e");
      }
    }
  } catch (e) {
    print("Error getting Capital accounts from Firestore: $e");
  }
}

// ─── Etihad Bank (Bank Al Etihad) ───

/// Creates a sandbox test user on the Finto platform.
/// Returns {"status": "success", "data": {...}} on success.
Future<Map<String, dynamic>?> etihadCreateUser({
  required String username,
  required String password,
  required String email,
  required String firstName,
  required String lastName,
  required String phoneNumber,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/etihad/create_user");
  try {
    final resp = await http.post(
      url,
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      }),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    print("Etihad create_user failed: ${resp.statusCode} ${resp.body}");
    return {'error': resp.statusCode, 'detail': resp.body};
  } catch (e) {
    print("Error in etihadCreateUser: $e");
  }
  return null;
}

/// Step 1: Send username + password to backend → triggers OTP to user's phone.
/// Returns {"status": "otp_sent"} or {"status": "authenticated"} (no 2FA).
Future<Map<String, dynamic>?> etihadLoginInit(String username, String password) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/etihad/login_init/${user.uid}");
  try {
    final resp = await http.post(
      url,
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    print("Etihad login_init failed: ${resp.statusCode} ${resp.body}");
  } catch (e) {
    print("Error in etihadLoginInit: $e");
  }
  return null;
}

/// Step 2: Verify OTP code → completes login and links the bank.
/// Returns {"status": "success"} on success.
Future<Map<String, dynamic>?> etihadLoginComplete(String otp) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/etihad/login_complete/${user.uid}");
  try {
    final resp = await http.post(
      url,
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'otp': otp}),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    print("Etihad login_complete failed: ${resp.statusCode} ${resp.body}");
  } catch (e) {
    print("Error in etihadLoginComplete: $e");
  }
  return null;
}

/// Get all customers linked to this Etihad account.
/// Returns {"status": "success", "data": [...]} on success.
Future<Map<String, dynamic>?> etihadGetCustomers() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/etihad/get_customers/${user.uid}");
  try {
    final resp = await http.get(url, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    print("Etihad get_customers failed: ${resp.statusCode} ${resp.body}");
  } catch (e) {
    print("Error in etihadGetCustomers: $e");
  }
  return null;
}

/// Sync all accounts for a given customer into Firestore.
/// Creates a new account for a customer on the Etihad sandbox.
/// [currency] defaults to "JOD". Returns {"status": "success", "data": {...}}.
Future<Map<String, dynamic>?> etihadCreateAccount(
    String customerId, String name, {String currency = 'JOD'}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/etihad/create_account/${user.uid}/$customerId");
  try {
    final resp = await http.post(
      url,
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'currency': currency, 'name': name}),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    print("Etihad create_account failed: ${resp.statusCode} ${resp.body}");
    return {'error': resp.statusCode, 'detail': resp.body};
  } catch (e) {
    print("Error in etihadCreateAccount: $e");
  }
  return null;
}

Future<Map<String, dynamic>?> etihadSyncAccounts(String customerId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/etihad/sync_accounts/${user.uid}/$customerId");
  try {
    final resp = await http.post(url, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    print("Etihad sync_accounts failed: ${resp.statusCode} ${resp.body}");
  } catch (e) {
    print("Error in etihadSyncAccounts: $e");
  }
  return null;
}

/// Sync transactions for a specific account into Firestore.
Future<Map<String, dynamic>?> etihadSyncTransactions(String customerId, String accountNumber) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final url = Uri.parse("$baseUrl/banks/etihad/sync_transactions/${user.uid}/$customerId/$accountNumber");
  try {
    final resp = await http.post(url, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    print("Etihad sync_transactions failed: ${resp.statusCode} ${resp.body}");
  } catch (e) {
    print("Error in etihadSyncTransactions: $e");
  }
  return null;
}

// ─── Housing Bank (HBTF) ───

/// `provider` value the backend writes on Housing Bank account and transaction docs.
const String hbtfProviderLabel = 'Housing Bank';

/// The app has no business-account concept, so every consent is a retail one.
const String _hbtfCustomerType = 'RETAIL';

enum HbtfErrorKind {
  /// Customer hasn't approved the consent in Iskan yet. Keep waiting.
  pendingApproval,

  /// consent/token was called before consent/initiate for this uid.
  noConsent,

  /// No consent token on file. Show the "Link Housing Bank" call to action.
  notLinked,

  /// Consent token expired. HBTF has no refresh; the customer must re-link.
  consentExpired,

  /// Housing Bank (or our backend) is down or unreachable.
  unavailable,

  unknown,
}

/// A failed Housing Bank call. Holds only the classification, never the raw
/// backend `detail`, so nothing from the bank can leak into the UI.
class HbtfException implements Exception {
  final HbtfErrorKind kind;
  final int? statusCode;

  HbtfException(this.kind, [this.statusCode]);

  String get userMessage {
    switch (kind) {
      case HbtfErrorKind.pendingApproval:
        return "Housing Bank hasn't confirmed your approval yet. Approve the request in the Iskan app, then try again.";
      case HbtfErrorKind.noConsent:
      case HbtfErrorKind.notLinked:
        return 'Housing Bank is not linked yet. Link your account to continue.';
      case HbtfErrorKind.consentExpired:
        return 'Your Housing Bank access has expired. Reconnect to continue.';
      case HbtfErrorKind.unavailable:
        return 'Housing Bank is unavailable right now. Please try again later.';
      case HbtfErrorKind.unknown:
        return 'Something went wrong with Housing Bank. Please try again.';
    }
  }

  @override
  String toString() => 'HbtfException($kind, status: $statusCode)';
}

enum HbtfLinkState { notLinked, connected, expired }

/// Reads the link state from the `users/{uid}` doc. Only `linked` and
/// `tokens.expires_at` are looked at; the consent token itself is never read.
HbtfLinkState hbtfLinkState(Map<String, dynamic>? userData) {
  final providers = userData?['providers'];
  final hbtf = providers is Map ? providers['hbtf'] : null;
  if (hbtf is! Map || hbtf['linked'] != true) return HbtfLinkState.notLinked;

  final tokens = hbtf['tokens'];
  final expiresAt = tokens is Map
      ? DateTime.tryParse(tokens['expires_at']?.toString() ?? '')
      : null;
  if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
    return HbtfLinkState.expired;
  }
  return HbtfLinkState.connected;
}

String _hbtfDetail(http.Response resp) {
  try {
    final decoded = jsonDecode(resp.body);
    if (decoded is Map && decoded['detail'] != null) {
      return decoded['detail'].toString();
    }
  } catch (_) {
    // Non-JSON body, e.g. a gateway HTML error page
  }
  return '';
}

HbtfErrorKind _hbtfClassify(int status, String detail) {
  // A 5xx here means Housing Bank is down, even on the consent-token call
  if (status >= 500) return HbtfErrorKind.unavailable;
  if (detail.startsWith(
    'HBTF consent token failed (customer may not have approved yet)',
  )) {
    return HbtfErrorKind.pendingApproval;
  }
  if (detail.startsWith('No HBTF consent on file')) {
    return HbtfErrorKind.noConsent;
  }
  if (detail.startsWith('Housing Bank not linked yet')) {
    return HbtfErrorKind.notLinked;
  }
  if (status == 401 && detail.startsWith('Housing Bank consent expired')) {
    return HbtfErrorKind.consentExpired;
  }
  if (detail.startsWith('HBTF ')) return HbtfErrorKind.unavailable;
  return HbtfErrorKind.unknown;
}

/// POSTs to /banks/hbtf/{endpoint}/{uid}[/{accountNumber}] for the signed-in user.
/// Retries once with a force-refreshed ID token if the backend rejects the
/// Firebase token. Throws [HbtfException] on any failure.
Future<Map<String, dynamic>> _hbtfPost(
  String endpoint, {
  String? accountNumber,
  Map<String, dynamic>? body,
  Map<String, String>? query,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw HbtfException(HbtfErrorKind.unknown);

  var path = "$baseUrl/banks/hbtf/$endpoint/${user.uid}";
  if (accountNumber != null) path += "/${Uri.encodeComponent(accountNumber)}";
  var url = Uri.parse(path);
  if (query != null && query.isNotEmpty) {
    url = url.replace(queryParameters: query);
  }

  Future<http.Response> send(bool forceRefresh) async {
    return http
        .post(
          url,
          headers: {
            ...await _authHeaders(forceRefresh),
            if (body != null) 'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));
  }

  http.Response resp;
  try {
    resp = await send(false);
    if (resp.statusCode == 401 &&
        _hbtfDetail(resp) == 'Invalid or expired Firebase token') {
      resp = await send(true);
    }
  } on HbtfException {
    rethrow;
  } catch (e) {
    print("Housing Bank $endpoint request error: $e");
    throw HbtfException(HbtfErrorKind.unavailable);
  }

  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    print("Housing Bank $endpoint returned an unreadable success body");
    throw HbtfException(HbtfErrorKind.unknown, resp.statusCode);
  }

  final detail = _hbtfDetail(resp);
  if (resp.statusCode == 403 && detail == 'Not authenticated') {
    print("BUG: Housing Bank $endpoint sent without an Authorization header");
  }
  final kind = _hbtfClassify(resp.statusCode, detail);
  final preview = detail.length > 200 ? detail.substring(0, 200) : detail;
  print("Housing Bank $endpoint failed: ${resp.statusCode} $kind $preview");
  throw HbtfException(kind, resp.statusCode);
}

/// Step 1: start a consent. Returns the backend response
/// ({consent_id, consent_status, links, data}).
Future<Map<String, dynamic>> hbtfInitiateConsent() {
  return _hbtfPost(
    'consent/initiate',
    body: {
      'customer_type': _hbtfCustomerType,
      'device_type': Platform.isIOS ? 'IOS' : 'Android',
    },
  );
}

/// Picks the approval link for this platform and customer type,
/// falling back to the web link.
String? hbtfConsentLink(dynamic links) {
  if (links is! List) return null;
  final platform = Platform.isIOS ? 'ios' : 'android';
  final wanted = '$platform-${_hbtfCustomerType.toLowerCase()}';

  String? urlFor(String deviceType) {
    for (final link in links) {
      if (link is Map && link['deviceType'] == deviceType) {
        final url = link['url']?.toString() ?? '';
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }

  return urlFor(wanted) ?? urlFor('web');
}

/// Step 3: exchange the approved consent for a consent token.
/// Throws [HbtfException] with [HbtfErrorKind.pendingApproval] until the
/// customer approves in Iskan. Returns `expires_at`.
Future<String?> hbtfExchangeConsentToken() async {
  final resp = await _hbtfPost('consent/token');
  return resp['expires_at']?.toString();
}

Future<int> hbtfSyncAccounts() async {
  final resp = await _hbtfPost('sync_accounts');
  return (resp['accounts_synced'] as num?)?.toInt() ?? 0;
}

/// [accountNumber] is the bank's raw number (the account doc's `accountNumber`),
/// not the `hbtf_` Firestore doc id. Dates are RFC 3339.
Future<int> hbtfSyncTransactions(
  String accountNumber, {
  String? settlementDateFrom,
  String? settlementDateTo,
}) async {
  final resp = await _hbtfPost(
    'sync_transactions',
    accountNumber: accountNumber,
    query: {
      if (settlementDateFrom != null) 'settlement_date_from': settlementDateFrom,
      if (settlementDateTo != null) 'settlement_date_to': settlementDateTo,
    },
  );
  return (resp['transactions_synced'] as num?)?.toInt() ?? 0;
}

/// Syncs every Housing Bank account, then each account's transactions.
/// Returns how many accounts' transactions failed to sync. Account sync
/// failures and consent problems are thrown.
Future<int> hbtfSyncAll() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw HbtfException(HbtfErrorKind.unknown);

  await hbtfSyncAccounts();

  final accountsSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('accounts')
      .where('provider', isEqualTo: hbtfProviderLabel)
      .get();

  var failed = 0;
  for (final doc in accountsSnap.docs) {
    final accountNumber = doc.data()['accountNumber']?.toString() ?? '';
    if (accountNumber.isEmpty) continue;
    try {
      await hbtfSyncTransactions(accountNumber);
    } on HbtfException catch (e) {
      if (e.kind == HbtfErrorKind.consentExpired ||
          e.kind == HbtfErrorKind.notLinked) {
        rethrow;
      }
      failed++;
    }
  }
  return failed;
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
        final response = await getPinnedHttpClient().get(url, headers: await _authHeaders());
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
