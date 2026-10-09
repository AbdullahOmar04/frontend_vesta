import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

// Who can do what in a household:
//   the owner (createdBy) can remove members and delete the household;
//   any other member can only leave it.
// Nothing here writes another user's own doc except as a best effort: when
// that fails, healHouseholdIds() cleans up from that user's side the next
// time they open Shared finances.

final _db = FirebaseFirestore.instance;

/// The household's owner: whoever created it (older households fall back to
/// their first member).
String? householdOwner(Map<String, dynamic>? data) {
  final createdBy = data?['createdBy'] as String?;
  if (createdBy != null && createdBy.isNotEmpty) return createdBy;
  final members = List<String>.from(data?['members'] ?? const []);
  return members.isEmpty ? null : members.first;
}

bool isHouseholdOwner(Map<String, dynamic>? data) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  return uid != null && householdOwner(data) == uid;
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  return confirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: action,
    icon: switch (action) {
      'Leave' => PhosphorIconsRegular.signOut,
      'Remove' => PhosphorIconsRegular.userMinus,
      _ => PhosphorIconsRegular.trash,
    },
  );
}

void _fail(BuildContext context, String what, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Couldn't $what: $e"),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

/// Owner only. Deletes the household for everyone. Returns true when done.
Future<bool> deleteHousehold(
  BuildContext context, {
  required String householdId,
  required String name,
  required List<String> members,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  if (!await _confirm(
    context,
    title: 'Delete $name?',
    message:
        'The household and its shared budget are removed for every member. '
        'This cannot be undone.',
    action: 'Delete',
  )) {
    return false;
  }
  try {
    // Best effort for the others; their app drops it if this is refused
    for (final member in members.where((m) => m != uid)) {
      try {
        await _db.collection('users').doc(member).update({
          'householdIds': FieldValue.arrayRemove([householdId]),
        });
      } catch (e) {
        debugPrint('Could not update household list for $member: $e');
      }
    }
    await _db.collection('households').doc(householdId).delete();
    await _db.collection('users').doc(uid).update({
      'householdIds': FieldValue.arrayRemove([householdId]),
    });
    return true;
  } catch (e) {
    if (context.mounted) _fail(context, 'delete the household', e);
    return false;
  }
}

/// Members other than the owner. Removes the current user from the household.
Future<bool> leaveHousehold(
  BuildContext context, {
  required String householdId,
  required String name,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  if (!await _confirm(
    context,
    title: 'Leave $name?',
    message:
        "You'll stop seeing its budget and transactions. The owner can invite "
        'you again.',
    action: 'Leave',
  )) {
    return false;
  }
  try {
    final batch = _db.batch();
    batch.update(_db.collection('households').doc(householdId), {
      'members': FieldValue.arrayRemove([uid]),
    });
    batch.update(_db.collection('users').doc(uid), {
      'householdIds': FieldValue.arrayRemove([householdId]),
    });
    await batch.commit();
    return true;
  } catch (e) {
    if (context.mounted) _fail(context, 'leave the household', e);
    return false;
  }
}

/// Owner only. Takes another member out of the household.
Future<bool> removeHouseholdMember(
  BuildContext context, {
  required String householdId,
  required String memberUid,
  required String memberName,
}) async {
  if (!await _confirm(
    context,
    title: 'Remove $memberName?',
    message:
        "They'll lose access to this household. You can invite them again "
        'later.',
    action: 'Remove',
  )) {
    return false;
  }
  try {
    await _db.collection('households').doc(householdId).update({
      'members': FieldValue.arrayRemove([memberUid]),
    });
    // Best effort; their app drops it if this is refused
    try {
      await _db.collection('users').doc(memberUid).update({
        'householdIds': FieldValue.arrayRemove([householdId]),
      });
    } catch (e) {
      debugPrint('Could not update household list for $memberUid: $e');
    }
    return true;
  } catch (e) {
    if (context.mounted) _fail(context, 'remove $memberName', e);
    return false;
  }
}

/// Drops households the current user is no longer in (removed by the owner,
/// or deleted) from their own list. Returns the ids that are still valid.
Future<List<String>> healHouseholdIds(List<String> householdIds) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return householdIds;
  final valid = <String>[];
  final stale = <String>[];
  for (final id in householdIds) {
    try {
      final doc = await _db.collection('households').doc(id).get();
      final members = List<String>.from(doc.data()?['members'] ?? const []);
      if (doc.exists && members.contains(uid)) {
        valid.add(id);
      } else {
        stale.add(id);
      }
    } catch (_) {
      // Unreadable means we're no longer allowed in
      stale.add(id);
    }
  }
  if (stale.isNotEmpty) {
    try {
      await _db.collection('users').doc(uid).update({
        'householdIds': FieldValue.arrayRemove(stale),
      });
    } catch (e) {
      debugPrint('Could not tidy household list: $e');
    }
  }
  return valid;
}
