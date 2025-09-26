// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

Future<void> syncAccounts() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;
  const customerId = "IND_CUST_002"; // you can make this dynamic later
  const String baseUrl = "http://192.168.1.208:8000";


  final url = Uri.parse("$baseUrl/sync_accounts/$uid/$customerId");

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ Accounts synced: $data");
    } else {
      print("❌ Failed: ${response.body}");
    }
  } catch (e) {
    print("⚠️ Error calling sync_accounts: $e");
  }
}



String getBaseUrl() {
  if (Platform.isAndroid) {
    // Emulator vs physical Android
    return "http://10.0.2.2:8000"; // Android Emulator localhost
  } else if (Platform.isIOS) {
    // iOS simulator uses localhost directly
    return "http://127.0.0.1:8000";
  } else {
    // Physical device on LAN → change to your laptop IP
    return "http://192.168.1.133:8000"; 
  }
}
