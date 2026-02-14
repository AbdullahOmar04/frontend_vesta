const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
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

