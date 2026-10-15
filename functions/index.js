const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
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
  await batch.commit().catch((error) =>
    console.error(`Could not free the username or email of ${uid}:`, error));

  await db.recursiveDelete(userRef);

  await admin.storage().bucket().file(`profile_pictures/${uid}.jpg`)
    .delete().catch(() => null);

  console.log(`Deleted the data of ${uid}`);
  return null;
});
