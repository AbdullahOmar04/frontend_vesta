import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

// Bills the user adds live in users/{uid}/bills/{billId}:
//   name         String
//   amount       num, what one payment costs
//   currency     String ('JOD')
//   dueDay       int 1–31, monthly; the last day when a month is shorter
//   subscription bool, counted in the subscriptions total
//   autopay      bool, paid automatically
//   accountId    String?, the account it comes out of
//   category     String?
//   createdAt / updatedAt
// They are reminders only: nothing here moves an account balance.
//
// Standing orders and scheduled payments (SOSPs) come from the bank sync
// into users/{uid}/accounts/{accountId}/sosps and are read-only here.

enum PaymentSource { bill, standingOrder }

/// A bill or a standing order, in one shape for the Bills screen and
/// Budgeting's upcoming payments.
class UpcomingPayment {
  const UpcomingPayment({
    required this.source,
    required this.title,
    required this.amount,
    required this.currency,
    required this.nextDate,
    this.billId,
    this.dueDay,
    this.accountId,
    this.accountName,
    this.category,
    this.autopay = false,
    this.subscription = false,
    this.incoming = false,
    this.frequency,
    this.status,
    this.remaining,
  });

  final PaymentSource source;
  final String title;
  final double amount;
  final String currency;

  /// When it is next due. Null for a standing order with no date.
  final DateTime? nextDate;

  // Bills only
  final String? billId;
  final int? dueDay;
  final String? accountId;
  final String? category;
  final bool subscription;

  final String? accountName;
  final bool autopay;

  // Standing orders only
  final bool incoming;
  final String? frequency;
  final String? status;
  final int? remaining;

  bool get isBill => source == PaymentSource.bill;

  /// This month's due date for a bill (clamped to the month's length).
  static DateTime dueDateIn(int year, int month, int dueDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, dueDay > lastDay ? lastDay : dueDay);
  }

  /// A bill's due date this month, or next month's once this one has gone.
  static DateTime nextDueDate(int dueDay, DateTime today) {
    final thisMonth = dueDateIn(today.year, today.month, dueDay);
    return thisMonth.isBefore(today)
        ? dueDateIn(today.year, today.month + 1, dueDay)
        : thisMonth;
  }

  factory UpcomingPayment.fromBill(
    String id,
    Map<String, dynamic> data,
    Map<String, String> accountNames,
    DateTime today,
  ) {
    final dueDay = ((data['dueDay'] as num?)?.toInt() ?? 1).clamp(1, 31);
    final accountId = data['accountId'] as String?;
    return UpcomingPayment(
      source: PaymentSource.bill,
      billId: id,
      title: (data['name'] ?? 'Bill').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] ?? 'JOD').toString(),
      dueDay: dueDay,
      nextDate: nextDueDate(dueDay, today),
      accountId: accountId,
      accountName: accountId == null ? null : accountNames[accountId],
      category: data['category'] as String?,
      autopay: data['autopay'] == true,
      subscription: data['subscription'] == true,
      frequency: 'monthly',
    );
  }

  /// Same fields the Budgeting screen has always shown for a SOSP.
  factory UpcomingPayment.fromSosp(
    Map<String, dynamic> sosp,
    String accountName,
  ) {
    final schedule = sosp['paymentSchedule'] as Map<String, dynamic>?;
    final next = schedule?['nextPaymentAmount'] as Map<String, dynamic>?;
    final nickname = (sosp['SOSPNickname'] ?? 'Scheduled payment').toString();
    return UpcomingPayment(
      source: PaymentSource.standingOrder,
      title:
          (sosp['SOSPBeneficiary']?['beneficiaryName']?['enName'] ?? nickname)
              .toString(),
      amount: (next?['amount'] as num?)?.toDouble() ?? 0,
      currency: (next?['currency'] ?? 'JOD').toString(),
      nextDate: DateTime.tryParse(
        '${schedule?['nextPaymentDateTime'] ?? ''}',
      )?.toLocal(),
      accountName: accountName,
      autopay: true,
      incoming: (sosp['SOSPType'] ?? 'departure').toString() == 'arrival',
      frequency: schedule?['frequencyInfo']?['frequency'] as String?,
      status: (sosp['SOSPStatus'] ?? 'unknown').toString(),
      remaining: schedule?['remainingPayments'] as int?,
    );
  }
}

CollectionReference<Map<String, dynamic>> _userCol(String uid, String name) =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection(name);

/// The user's bills and the standing orders on their linked accounts,
/// soonest first (anything without a date last).
Future<List<UpcomingPayment>> loadUpcomingPayments() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final accountsSnap = await _userCol(uid, 'accounts').get();
  final accountNames = <String, String>{};
  final payments = <UpcomingPayment>[];

  for (final account in accountsSnap.docs) {
    final data = account.data();
    accountNames[account.id] = AccountInfo(
      id: account.id,
      name: (data['nickname'] ?? data['accountName'] ?? data['name'] ??
              'Account ${account.id}')
          .toString(),
      type: data['accountTypeName'] as String?,
    ).label;

    if (data['linked'] != true) continue;
    final sosps = await account.reference.collection('sosps').get();
    for (final doc in sosps.docs) {
      payments.add(
        UpcomingPayment.fromSosp(doc.data(), accountNames[account.id]!),
      );
    }
  }

  final bills = await _userCol(uid, 'bills').get();
  for (final doc in bills.docs) {
    payments.add(
      UpcomingPayment.fromBill(doc.id, doc.data(), accountNames, today),
    );
  }

  payments.sort((a, b) {
    if (a.nextDate == null) return b.nextDate == null ? 0 : 1;
    if (b.nextDate == null) return -1;
    return a.nextDate!.compareTo(b.nextDate!);
  });
  return payments;
}

/// Adds a bill, or updates it when [billId] is given.
Future<void> saveBill({
  String? billId,
  required String name,
  required double amount,
  required int dueDay,
  required bool subscription,
  required bool autopay,
  String? accountId,
  String? category,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final fields = <String, dynamic>{
    'name': name,
    'amount': amount,
    'currency': 'JOD',
    'dueDay': dueDay,
    'subscription': subscription,
    'autopay': autopay,
    'accountId': accountId,
    'category': category,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  final col = _userCol(uid, 'bills');
  if (billId == null) {
    await col.add({...fields, 'createdAt': FieldValue.serverTimestamp()});
  } else {
    await col.doc(billId).set(fields, SetOptions(merge: true));
  }
}

Future<void> setBillAutopay(String billId, bool autopay) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await _userCol(uid, 'bills').doc(billId).update({
    'autopay': autopay,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> deleteBill(String billId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await _userCol(uid, 'bills').doc(billId).delete();
}

/// Accounts to pick from when adding a bill: id and "Bank · Type" label.
Future<List<(String, String)>> loadBillAccounts() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  final snap = await _userCol(uid, 'accounts').get();
  return [
    for (final d in snap.docs)
      (
        d.id,
        AccountInfo(
          id: d.id,
          name: (d.data()['accountName'] ?? d.id).toString(),
          type: d.data()['accountTypeName'] as String?,
        ).label,
      ),
  ];
}
