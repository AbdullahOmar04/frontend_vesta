const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const functionsV1 = require("firebase-functions/v1");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when an /invites document is updated.
 * This function securely joins a user to a household using v2 syntax.
 */
exports.onInviteAccepted = onDocumentUpdated({
    region: "me-central1",
    document: "invites/{inviteId}",
  }, async (event) => {
  // Get the data *before* and *after* the change
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  // We only care about the change from "pending" to "accepted"
  if (beforeData.status === "pending" && afterData.status === "accepted") {
    const householdId = afterData.householdId;
    const newMemberUid = afterData.acceptedByUid;
    const inviteId = event.params.inviteId;

    console.log(
      `Processing invite: ${inviteId} for user ${newMemberUid} to household ${householdId}`,
    );

    // Get references to the documents we need to update
    const db = getFirestore(); // Use v2 getFirestore()
    const householdRef = db.collection("households").doc(householdId);
    const userRef = db.collection("users").doc(newMemberUid);

    // Use a batch write to do both updates at once
    try {
      const batch = db.batch();

      // 1. Add the new member to the household's 'members' array
      batch.update(householdRef, {
        members: FieldValue.arrayUnion(newMemberUid), // Use FieldValue
      });

      // 2. Add the household ID to the user's 'householdIds' array
      batch.update(userRef, {
        householdIds: FieldValue.arrayUnion(householdId), // Use FieldValue
      });

      // Commit the batch
      await batch.commit();
      
      // (Optional) Delete the invite so it can't be used again
      await db.collection("invites").doc(inviteId).delete();

      console.log("Successfully joined household!");
      return null;
      
    } catch (error) {
      console.error("Error joining household:", error);
      return null;
    }
  } else {
    // Not the change we care about, do nothing.
    console.log("No change in status or not the correct status change.");
    return null;
  }
});

/**
 * Runs when a Firebase Auth user is deleted (the app's Delete account).
 * The app deletes what the security rules let it; this removes the rest
 * with admin rights: the user doc and everything under it, their username
 * and email reservations, their households (deleted when they created them,
 * left otherwise), and their profile picture.
 */
exports.onUserDeleted = functionsV1.auth.user().onDelete(async (user) => {
  const db = getFirestore();
  const uid = user.uid;
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  const data = snap.exists ? snap.data() : {};

  for (const id of data.householdIds || []) {
    try {
      const ref = db.collection("households").doc(id);
      const household = await ref.get();
      if (!household.exists) continue;
      const h = household.data();
      const members = h.members || [];
      const owner = h.createdBy || members[0];
      if (owner === uid) {
        for (const m of members.filter((x) => x !== uid)) {
          await db.collection("users").doc(m).update({
            householdIds: FieldValue.arrayRemove(id),
          }).catch(() => null);
        }
        await db.recursiveDelete(ref);
      } else {
        await ref.update({ members: FieldValue.arrayRemove(uid) });
      }
    } catch (error) {
      console.error(`Could not clear household ${id} for ${uid}:`, error);
    }
  }

  const batch = db.batch();
  if (data.username) {
    batch.delete(db.collection("usernames").doc(String(data.username).toLowerCase()));
  }
  const email = String(data.email || user.email || "").toLowerCase();
  if (email) batch.delete(db.collection("emails").doc(email));
  if (data.referralCode) {
    batch.delete(db.collection("referralCodes").doc(String(data.referralCode)));
  }
  await batch.commit().catch((error) =>
    console.error(`Could not free the username, email or code of ${uid}:`, error));

  await db.recursiveDelete(userRef);

  await admin.storage().bucket().file(`profile_pictures/${uid}.jpg`)
    .delete().catch(() => null);

  console.log(`Deleted the data of ${uid}`);
  return null;
});

// Points for a sign-up with a referral code. Must match referralReward and
// referralWelcome in lib/Helpers/referral_codes.dart.
const REFERRAL_REWARD = 250;
const REFERRAL_WELCOME = 100;

/**
 * Runs when a user doc is created at sign-up. When it names a friend's code
 * in referredBy, the friend gets REFERRAL_REWARD points and the new user
 * REFERRAL_WELCOME, once. The rules keep points out of the app's reach, so
 * this is the only place they are given. Every referral is also kept in
 * referrals/{newUid} for reporting.
 */
exports.onUserCreated = onDocumentCreated({
  region: "me-central1",
  document: "users/{uid}",
}, async (event) => {
  const data = event.data && event.data.data();
  const code = data && data.referredBy;
  if (typeof code !== "string" || !code) return null;

  const db = getFirestore();
  const uid = event.params.uid;
  const codeSnap = await db.collection("referralCodes").doc(code).get();
  const referrerUid = codeSnap.exists ? codeSnap.get("uid") : null;
  if (!referrerUid || referrerUid === uid) {
    console.log(`Ignoring referral code ${code} on ${uid}`);
    return null;
  }

  const referralRef = db.collection("referrals").doc(uid);
  const referrerRef = db.collection("users").doc(referrerUid);
  await db.runTransaction(async (tx) => {
    // Firestore can deliver an event twice; the record makes it count once
    const [existing, referrer] = await Promise.all([
      tx.get(referralRef),
      tx.get(referrerRef),
    ]);
    if (existing.exists) return;

    tx.create(referralRef, {
      referrerUid,
      refereeUid: uid,
      code,
      referrerPoints: referrer.exists ? REFERRAL_REWARD : 0,
      refereePoints: REFERRAL_WELCOME,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(db.collection("users").doc(uid), {
      referralPoints: FieldValue.increment(REFERRAL_WELCOME),
    }, { merge: true });
    if (referrer.exists) {
      tx.set(referrerRef, {
        referralPoints: FieldValue.increment(REFERRAL_REWARD),
        referralCount: FieldValue.increment(1),
      }, { merge: true });
      // What the friend's Referrals screen lists
      tx.set(referrerRef.collection("referrals").doc(uid), {
        name: data.username || "Friend",
        joinedAt: FieldValue.serverTimestamp(),
        points: REFERRAL_REWARD,
      });
    }
  });
  console.log(`Referral: ${uid} signed up with ${referrerUid}'s code ${code}`);
  return null;
});
