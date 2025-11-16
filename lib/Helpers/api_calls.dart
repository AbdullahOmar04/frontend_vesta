// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "https://backend-vesta.onrender.com";

Future<void> syncAccounts([String? username]) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final uid = user.uid;

  String u = (username ?? '').trim();

  // If no username passed, read from Firestore
  if (u.isEmpty) {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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

  final url = Uri.parse("$baseUrl/sync_accounts/$uid/${Uri.encodeComponent(u)}");

  try {
    final resp = await http.get(url);
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
        .get();

    if (accountsSnap.docs.isEmpty) {
      print("⚠️ No accounts found in Firestore for this user");
      return;
    }

    // Step 2: Loop through each account and fetch transactions
    for (var doc in accountsSnap.docs) {
      final accountId = doc.id;
      final url = Uri.parse("$baseUrl/get_transactions/$uid/$accountId");

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


Future<void> checkMonthlyResetOnLogin() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final userDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .get();
  final userData = userDoc.data();
  if (userData == null) return;

  final int dayOfMonth = userData["dayOfMonth"] ?? 28;
  final now = DateTime.now();
  final String monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

  // Step 1: Check if a budget doc for this month already exists
  final monthDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .collection("budget")
      .doc(monthId)
      .get();

  if (!monthDoc.exists && now.day >= dayOfMonth) {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "totalIncome": 0.0,
      "totalExpense": 0.0,
    });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("budget")
        .doc(monthId)
        .set({
          "income": 0,
          "spending": 0,
          "luxuries": 0,
          "saving": 0,
          "totalExpense": 0,
          "createdAt": Timestamp.now(),
        });

    print("📆 Budget reset for new month: $monthId");
  } else {
    print(
      "✅ Budget already created for this month or reset day not reached yet.",
    );
  }
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
