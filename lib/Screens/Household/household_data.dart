import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Household features beyond the shared budget live on the household doc
// itself, next to `budget`, which every member can already update:
//   icon      'house-line' (an icon_picker key)
//   plan      {savings, necessities, luxuries}: percent of `budget`
//   bills     [{id, name, amount, dueDay, icon, split: {uid: amount}}]
//   savings   {shares: {uid: {amount, monthly}},
//              goals: [{id, title, icon, target, monthly, targetDate,
//                       contributions: {uid: amount}}],
//              months: {'YYYY-MM': {uid: amount}}}

final _db = FirebaseFirestore.instance;

DocumentReference<Map<String, dynamic>> _ref(String householdId) =>
    _db.collection('households').doc(householdId);

double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

Map<String, double> _amounts(Object? raw) => {
  if (raw is Map)
    for (final e in raw.entries) e.key.toString(): _d(e.value),
};

String _newId() => _db.collection('_').doc().id;

/// A fresh id for a bill or goal stored in a household list.
String newHouseholdItemId() => _newId();

/// This month's key in savings.months.
String monthKey([DateTime? when]) {
  final d = when ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

class HouseholdBill {
  HouseholdBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.icon,
    required this.split,
  });

  final String id;
  final String name;
  final double amount;
  final int dueDay;
  final String icon;

  /// Who pays how much of [amount], by uid.
  final Map<String, double> split;

  static HouseholdBill fromMap(Map<String, dynamic> m) => HouseholdBill(
    id: (m['id'] ?? _newId()).toString(),
    name: (m['name'] ?? 'Bill').toString(),
    amount: _d(m['amount']),
    dueDay: (m['dueDay'] as num?)?.toInt() ?? 1,
    icon: (m['icon'] ?? 'receipt').toString(),
    split: _amounts(m['split']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'dueDay': dueDay,
    'icon': icon,
    'split': split,
  };
}

class HouseholdGoal {
  HouseholdGoal({
    required this.id,
    required this.title,
    required this.icon,
    required this.target,
    required this.monthly,
    required this.targetDate,
    required this.contributions,
  });

  final String id;
  final String title;
  final String icon;
  final double target;
  final double monthly;
  final DateTime? targetDate;

  /// What each member has put in, by uid.
  final Map<String, double> contributions;

  double get saved => contributions.values.fold(0.0, (s, a) => s + a);

  static HouseholdGoal fromMap(Map<String, dynamic> m) => HouseholdGoal(
    id: (m['id'] ?? _newId()).toString(),
    title: (m['title'] ?? 'Goal').toString(),
    icon: (m['icon'] ?? 'piggy-bank').toString(),
    target: _d(m['target']),
    monthly: _d(m['monthly']),
    targetDate: m['targetDate'] is Timestamp
        ? (m['targetDate'] as Timestamp).toDate()
        : null,
    contributions: _amounts(m['contributions']),
  );
}

/// What a member has pledged to the household's savings.
typedef SavingsShare = ({double amount, double monthly});

class HouseholdSavings {
  HouseholdSavings(this.shares, this.goals, this.months);

  final Map<String, SavingsShare> shares;
  final List<HouseholdGoal> goals;
  final Map<String, Map<String, double>> months;

  static HouseholdSavings fromHousehold(Map<String, dynamic>? household) {
    final s = household?['savings'];
    final m = s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
    final rawShares = m['shares'] is Map ? m['shares'] as Map : const {};
    return HouseholdSavings(
      {
        for (final e in rawShares.entries)
          if (e.value is Map)
            e.key.toString(): (
              amount: _d((e.value as Map)['amount']),
              monthly: _d((e.value as Map)['monthly']),
            ),
      },
      [
        for (final g in (m['goals'] as List? ?? const []))
          if (g is Map) HouseholdGoal.fromMap(Map<String, dynamic>.from(g)),
      ],
      {
        if (m['months'] is Map)
          for (final e in (m['months'] as Map).entries)
            e.key.toString(): _amounts(e.value),
      },
    );
  }

  /// What [uid] has put into goals so far.
  double allocatedBy(String uid) =>
      goals.fold(0.0, (s, g) => s + (g.contributions[uid] ?? 0));

  /// What [uid] has pledged but not put into a goal yet.
  double freeFor(String uid) =>
      ((shares[uid]?.amount ?? 0) - allocatedBy(uid)).clamp(0, double.infinity);

  double get totalSaved => goals.fold(0.0, (s, g) => s + g.saved);

  double get monthlyPlan =>
      shares.values.fold(0.0, (s, share) => s + share.monthly);

  double savedIn(String month) =>
      (months[month] ?? const {}).values.fold(0.0, (s, a) => s + a);
}

List<HouseholdBill> householdBills(Map<String, dynamic>? household) => [
  for (final b in (household?['bills'] as List? ?? const []))
    if (b is Map) HouseholdBill.fromMap(Map<String, dynamic>.from(b)),
];

/// The savings / necessities / luxuries split of the household budget, in
/// percent, or null when none was set.
List<double>? householdPlan(Map<String, dynamic>? household) {
  final p = household?['plan'];
  if (p is! Map) return null;
  return [_d(p['savings']), _d(p['necessities']), _d(p['luxuries'])];
}

/// Read-modify-write of the household doc, so two members editing at once
/// don't overwrite each other.
Future<void> _update(
  String householdId,
  Map<String, dynamic> Function(Map<String, dynamic> data) change,
) {
  return _db.runTransaction((tx) async {
    final snap = await tx.get(_ref(householdId));
    final data = snap.data() ?? <String, dynamic>{};
    tx.update(_ref(householdId), change(data));
  });
}

Map<String, dynamic> _savingsMap(Map<String, dynamic> data) {
  final s = data['savings'];
  return s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
}

Future<void> saveHouseholdDetails(
  String householdId, {
  required String name,
  required String icon,
}) {
  return _ref(householdId).update({'householdName': name, 'icon': icon});
}

Future<void> saveHouseholdPlan(
  String householdId, {
  required double budget,
  required List<double> percents,
}) {
  return _ref(householdId).update({
    'budget': budget,
    'plan': {
      'savings': percents[0],
      'necessities': percents[1],
      'luxuries': percents[2],
    },
  });
}

/// Adds [bill], or replaces the one with its id.
Future<void> saveHouseholdBill(String householdId, HouseholdBill bill) {
  return _update(householdId, (data) {
    final bills = householdBills(data)..removeWhere((b) => b.id == bill.id);
    bills.add(bill);
    return {'bills': bills.map((b) => b.toMap()).toList()};
  });
}

Future<void> removeHouseholdBill(String householdId, String billId) {
  return _update(householdId, (data) {
    final bills = householdBills(data)..removeWhere((b) => b.id == billId);
    return {'bills': bills.map((b) => b.toMap()).toList()};
  });
}

/// How much the signed-in member shares in total, and plans to add a month.
Future<void> setMySavingsShare(
  String householdId, {
  required double amount,
  required double monthly,
}) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return _update(householdId, (data) {
    final savings = _savingsMap(data);
    final shares = Map<String, dynamic>.from(savings['shares'] as Map? ?? {});
    shares[uid] = {'amount': amount, 'monthly': monthly};
    savings['shares'] = shares;
    return {'savings': savings};
  });
}

Future<void> addHouseholdGoal(
  String householdId, {
  required String title,
  required String icon,
  required double target,
  required double monthly,
  required DateTime targetDate,
}) {
  return _update(householdId, (data) {
    final savings = _savingsMap(data);
    final goals = List<dynamic>.from(savings['goals'] as List? ?? const []);
    goals.add({
      'id': _newId(),
      'title': title,
      'icon': icon,
      'target': target,
      'monthly': monthly,
      'targetDate': Timestamp.fromDate(targetDate),
      'contributions': <String, double>{},
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
    });
    savings['goals'] = goals;
    return {'savings': savings};
  });
}

/// Removes a goal; what members had put in becomes free again.
Future<void> removeHouseholdGoal(String householdId, String goalId) {
  return _update(householdId, (data) {
    final savings = _savingsMap(data);
    final goals = List<dynamic>.from(savings['goals'] as List? ?? const [])
      ..removeWhere((g) => g is Map && g['id'] == goalId);
    savings['goals'] = goals;
    return {'savings': savings};
  });
}

/// Moves [delta] of the signed-in member's share into (or, when negative,
/// out of) a goal, and counts it toward this month's savings.
Future<void> contributeToHouseholdGoal(
  String householdId, {
  required String goalId,
  required double delta,
}) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return _update(householdId, (data) {
    final savings = _savingsMap(data);
    final goals = [
      for (final g in (savings['goals'] as List? ?? const []))
        if (g is Map) Map<String, dynamic>.from(g),
    ];
    for (final g in goals) {
      if (g['id'] != goalId) continue;
      final c = _amounts(g['contributions']);
      c[uid] = ((c[uid] ?? 0) + delta).clamp(0, double.infinity).toDouble();
      g['contributions'] = c;
    }
    final months = Map<String, dynamic>.from(savings['months'] as Map? ?? {});
    final thisMonth = _amounts(months[monthKey()]);
    thisMonth[uid] = (thisMonth[uid] ?? 0) + delta;
    months[monthKey()] = thisMonth;
    savings['goals'] = goals;
    savings['months'] = months;
    return {'savings': savings};
  });
}

/// Invites a Vesta user by username or email. Returns the name to show, or
/// throws a [StateError] with a message for the user.
Future<String> inviteToHousehold(
  String householdId, {
  required String householdName,
  required String query,
}) async {
  final me = FirebaseAuth.instance.currentUser;
  if (me == null) throw StateError('Log in again to invite someone.');
  final q = query.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
  if (q.isEmpty) throw StateError('Enter a username or email.');

  final lookup = await _db
      .collection(q.contains('@') ? 'emails' : 'usernames')
      .doc(q)
      .get();
  final uid = lookup.data()?['uid'] as String?;
  if (uid == null) throw StateError('No Vesta user goes by "$query".');
  if (uid == me.uid) throw StateError("That's you.");

  final household = await _ref(householdId).get();
  if (List<String>.from(household.data()?['members'] ?? []).contains(uid)) {
    throw StateError("They're already in this household.");
  }

  await _db.collection('invites').add({
    'householdId': householdId,
    'householdName': householdName,
    'inviterUid': me.uid,
    'inviterName': me.displayName ?? me.email,
    'inviteeUid': uid,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
  return (lookup.data()?['originalUsername'] ??
          lookup.data()?['originalEmail'] ??
          query)
      .toString();
}

/// Invites sent to the signed-in user by username or email.
Stream<QuerySnapshot<Map<String, dynamic>>> myPendingInvites(String uid) {
  return _db
      .collection('invites')
      .where('inviteeUid', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots();
}

/// Accepting hands the joining to the onInviteAccepted Cloud Function, the
/// same as an invite link.
Future<void> answerInvite(String inviteId, {required bool accept}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  return _db.collection('invites').doc(inviteId).update({
    'status': accept ? 'accepted' : 'declined',
    if (accept) 'acceptedByUid': uid,
  });
}
