import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';

/// How a transaction moves its account balance: a debit takes money out,
/// a credit puts it back in.
double balanceDelta(TransactionType type, double amount) =>
    type == TransactionType.debit ? -amount : amount;

DocumentReference<Map<String, dynamic>> _accountRef(String uid, String accountId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(accountId);

/// Writes the transaction and moves the account balance in one batch, so a
/// balance can never drift away from the transactions that explain it.
Future<void> saveTransactionAndApplyBalance({
  required String uid,
  required String accountId,
  required TransactionModel txn,
}) async {
  final accountRef = _accountRef(uid, accountId);
  final batch = FirebaseFirestore.instance.batch();

  batch.set(accountRef.collection('transactions').doc(txn.id), txn.toMap());
  batch.set(accountRef, {
    'balanceAmount': FieldValue.increment(balanceDelta(txn.type, txn.amount)),
    'balanceUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await batch.commit();
}

/// Deletes the transaction and gives the amount back to the account.
Future<void> deleteTransactionAndRevertBalance({
  required String uid,
  required String accountId,
  required String transactionId,
  required TransactionType type,
  required double amount,
}) async {
  final accountRef = _accountRef(uid, accountId);
  final batch = FirebaseFirestore.instance.batch();

  batch.delete(accountRef.collection('transactions').doc(transactionId));
  batch.set(accountRef, {
    'balanceAmount': FieldValue.increment(-balanceDelta(type, amount)),
    'balanceUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await batch.commit();
}

/// Removes an account along with every transaction filed under it.
Future<void> deleteAccountAndTransactions({
  required String uid,
  required String accountId,
}) async {
  final fire = FirebaseFirestore.instance;
  final accountRef = _accountRef(uid, accountId);
  final txSnap = await accountRef.collection('transactions').get();

  // Firestore batches cap at 500 writes, so commit in slices
  final refs = [...txSnap.docs.map((d) => d.reference), accountRef];
  for (var i = 0; i < refs.length; i += 400) {
    final batch = fire.batch();
    for (final ref in refs.skip(i).take(400)) {
      batch.delete(ref);
    }
    await batch.commit();
  }

  await fire.collection('users').doc(uid).set({
    'linkedAccountIds': FieldValue.arrayRemove([accountId]),
  }, SetOptions(merge: true));
}

/// Writes [values] to [ref] only when one of them differs from what is stored.
/// Screens recompute totals every time they open, and each write to the user
/// doc makes Firestore re-diff the views listening to it, which stalled Home and
/// Profile for seconds at a time. [FieldValue] entries such as server
/// timestamps are written along with a real change but never count as one.
Future<void> updateIfChanged(
  DocumentReference<Map<String, dynamic>> ref,
  Map<String, Object> values,
) async {
  final stored = (await ref.get()).data() ?? const <String, dynamic>{};
  final changed = values.entries.any(
    (e) => e.value is! FieldValue && stored[e.key] != e.value,
  );
  if (!changed) return;
  await ref.set(values, SetOptions(merge: true));
}
