const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const functionsV1 = require("firebase-functions/v1");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const admin = require("firebase-admin");

admin.initializeApp();

// --- PUSH NOTIFICATIONS ---
// Each signed-in phone keeps its FCM token in users/{uid}/devices/{token}
// (lib/Helpers/notifications.dart). Messages go out in the user doc's
// `language` and only when its switch under Preferences is on; the
// defaults here must match preferences.dart. The data `type` tells the app
// which screen a tap opens.

/** Which Preferences switch allows a message, and its Android channel. */
const REQUIRED_ACTIONS = {
  group: "notifications", key: "requiredActions", fallback: true, channel: "updates",
};
const MOTIVATIONAL = {
  group: "notifications", key: "motivational", fallback: true, channel: "updates",
};
const UPCOMING_PAYMENTS = {
  group: "reminders", key: "upcoming", fallback: true, channel: "reminders",
};

const money = (amount) => Number(amount || 0).toLocaleString("en-US", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

// The app's own wording lives in lib/l10n/app_{en,ar}.arb; these are the
// only texts written here. Digits stay Western in Arabic, as in the app.
const MESSAGES = {
  en: {
    someone: "Someone",
    aFriend: "A friend",
    aHousehold: "a household",
    inviteTitle: "Household invite",
    inviteBody: (inviter, household) => `${inviter} invited you to join ${household}.`,
    acceptedTitle: "Invite accepted",
    acceptedBody: (name, household) => `${name} joined ${household}.`,
    referralTitle: "A friend joined Vesta",
    referralBody: (name, points) =>
      `${name} signed up with your code. You earned ${points} points.`,
    amount: (n) => `JOD ${money(n)}`,
    when: (days) => (days === 1 ? "tomorrow" : `in ${days} days`),
    billTitle: (when) => `Payment due ${when}`,
    subscriptionTitle: (when) => `Subscription renews ${when}`,
    manyTitle: (count, when) => `${count} payments due ${when}`,
    list: (names, more) => names.join(", ") + (more > 0 ? ` and ${more} more` : ""),
    total: (amount) => `${amount} in total`,
  },
  ar: {
    someone: "أحدهم",
    aFriend: "صديق",
    aHousehold: "منزل مشترك",
    inviteTitle: "دعوة إلى منزل مشترك",
    inviteBody: (inviter, household) => `دعاك ${inviter} للانضمام إلى ${household}.`,
    acceptedTitle: "قُبلت الدعوة",
    acceptedBody: (name, household) => `انضم ${name} إلى ${household}.`,
    referralTitle: "انضم صديق إلى Vesta",
    referralBody: (name, points) =>
      `سجّل ${name} برمز دعوتك. ربحت ${points} نقطة.`,
    amount: (n) => `${money(n)} د.أ`,
    when: (days) => (days === 1 ? "غدًا" : days === 2 ? "بعد يومين" :
      days <= 10 ? `بعد ${days} أيام` : `بعد ${days} يومًا`),
    billTitle: (when) => `دفعة مستحقة ${when}`,
    subscriptionTitle: (when) => `اشتراك يتجدد ${when}`,
    manyTitle: (count, when) => (count === 2 ? `دفعتان مستحقتان ${when}` :
      count <= 10 ? `${count} دفعات مستحقة ${when}` : `${count} دفعة مستحقة ${when}`),
    list: (names, more) => names.join("، ") + (more > 0 ? " وغيرها" : ""),
    total: (amount) => `المجموع ${amount}`,
  },
};

const messagesFor = (userData) =>
  MESSAGES[userData && userData.language === "ar" ? "ar" : "en"];

/** Whether the user's switch for this kind of message is on. */
function allows(userData, kind) {
  const value = ((userData && userData[kind.group]) || {})[kind.key];
  return typeof value === "boolean" ? value : kind.fallback;
}

/**
 * Sends one message to every phone in [devices] (a devices query snapshot)
 * and deletes the tokens FCM says are gone (app uninstalled, data cleared).
 */
async function sendToDevices(devices, notification, data, kind, tag) {
  if (devices.empty) return;
  const response = await getMessaging().sendEachForMulticast({
    tokens: devices.docs.map((d) => d.id),
    notification,
    data,
    android: {
      priority: "high",
      notification: {
        channelId: kind.channel,
        icon: "ic_notification",
        color: "#6B43F7",
        ...(tag ? { tag } : {}),
      },
    },
  });
  const gone = [];
  response.responses.forEach((r, i) => {
    const code = r.error && r.error.code;
    if (code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token") {
      gone.push(devices.docs[i].ref.delete());
    } else if (code) {
      console.error(`FCM send failed (${code}):`, r.error.message);
    }
  });
  await Promise.all(gone);
}

/**
 * Sends [build](messages, userData) => {title, body} to [uid]'s phones, in
 * their language, when their switch allows it. Never throws: a message is
 * never worth failing the function that sends it.
 */
async function notifyUser(uid, kind, build, data, tag) {
  try {
    const userRef = getFirestore().collection("users").doc(uid);
    const [user, devices] = await Promise.all([
      userRef.get(),
      userRef.collection("devices").get(),
    ]);
    if (!user.exists || devices.empty || !allows(user.data(), kind)) return;
    const notification = build(messagesFor(user.data()), user.data());
    await sendToDevices(devices, notification, data, kind, tag);
    console.log(`Notified ${uid}: ${data.type}`);
  } catch (error) {
    console.error(`Could not notify ${uid} (${data.type}):`, error);
  }
}

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
      await notifyInviteAccepted(afterData, householdId, newMemberUid);
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
  const rewarded = await db.runTransaction(async (tx) => {
    // Firestore can deliver an event twice; the record makes it count once
    const [existing, referrer] = await Promise.all([
      tx.get(referralRef),
      tx.get(referrerRef),
    ]);
    if (existing.exists) return false;

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
    return referrer.exists;
  });
  console.log(`Referral: ${uid} signed up with ${referrerUid}'s code ${code}`);
  if (rewarded) {
    await notifyUser(referrerUid, MOTIVATIONAL, (m) => ({
      title: m.referralTitle,
      body: m.referralBody(data.username || m.aFriend, REFERRAL_REWARD),
    }), { type: "referral" });
  }
  return null;
});

/**
 * Household invite sent by username or email: tells the person invited.
 * Link invites have no invitee until someone opens the link.
 */
exports.onInviteCreated = onDocumentCreated({
  region: "me-central1",
  document: "invites/{inviteId}",
}, async (event) => {
  const invite = event.data && event.data.data();
  if (!invite || typeof invite.inviteeUid !== "string" || invite.status !== "pending") {
    return null;
  }
  await notifyUser(invite.inviteeUid, REQUIRED_ACTIONS, (m) => ({
    title: m.inviteTitle,
    body: m.inviteBody(invite.inviterName || m.someone, invite.householdName || m.aHousehold),
  }), { type: "invite" });
  return null;
});

/** After onInviteAccepted has joined them: tells whoever sent the invite. */
async function notifyInviteAccepted(invite, householdId, newMemberUid) {
  if (!invite.inviterUid || invite.inviterUid === newMemberUid) return;
  let name = null;
  try {
    const member = await getFirestore().collection("users").doc(newMemberUid).get();
    name = member.get("username") || null;
  } catch (_) {
    // Fall back to "Someone"
  }
  await notifyUser(invite.inviterUid, REQUIRED_ACTIONS, (m) => ({
    title: m.acceptedTitle,
    body: m.acceptedBody(name || m.someone, invite.householdName || m.aHousehold),
  }), { type: "inviteAccepted", householdId: String(householdId) });
}

// Bills: users/{uid}/bills/{id} with a monthly dueDay (1-31, the last day
// in shorter months), as in lib/Screens/Bills/bills_data.dart.

const AMMAN = "Asia/Amman";

/** Today's date in Amman as a UTC midnight Date. */
function ammanToday() {
  const [y, m, d] = new Intl.DateTimeFormat("en-CA", {
    timeZone: AMMAN, year: "numeric", month: "2-digit", day: "2-digit",
  }).format(new Date()).split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

/** The day a monthly bill falls on in that month (UTC midnight). */
function dueDateIn(year, monthIndex, dueDay) {
  const lastDay = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();
  return new Date(Date.UTC(year, monthIndex, Math.min(dueDay, lastDay)));
}

/** Bills of [uid] due exactly [days] days after [today], or none. */
async function billsDue(uid, today, days) {
  const target = new Date(today.getTime() + days * 86400000);
  const bills = await getFirestore().collection("users").doc(uid).collection("bills").get();
  return bills.docs.map((d) => d.data()).filter((bill) => {
    const raw = Number(bill.dueDay);
    const dueDay = Number.isFinite(raw) ? Math.min(Math.max(Math.trunc(raw), 1), 31) : 1;
    const due = dueDateIn(target.getUTCFullYear(), target.getUTCMonth(), dueDay);
    return due.getTime() === target.getTime();
  });
}

/** One message for everything [uid] has due on their chosen day. */
async function remindAboutBills(uid, devices, today) {
  const user = await getFirestore().collection("users").doc(uid).get();
  if (!user.exists || !allows(user.data(), UPCOMING_PAYMENTS)) return false;
  const chosen = Number((user.get("reminders") || {}).upcomingDays);
  const days = [1, 3, 7].includes(chosen) ? chosen : 3;
  const due = await billsDue(uid, today, days);
  if (due.length === 0) return false;

  const m = messagesFor(user.data());
  const when = m.when(days);
  const names = due.map((b) => String(b.name || "").trim() || "?");
  const total = due.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);
  const notification = due.length === 1 ?
    {
      title: due[0].subscription === true ? m.subscriptionTitle(when) : m.billTitle(when),
      body: `${names[0]} · ${m.amount(total)}`,
    } :
    {
      title: m.manyTitle(due.length, when),
      body: `${m.list(names.slice(0, 3), names.length - 3)} · ${m.total(m.amount(total))}`,
    };
  // The tag replaces an older reminder still in the shade
  await sendToDevices(devices, notification, { type: "bill" }, UPCOMING_PAYMENTS, "bills");
  return true;
}

/**
 * Every evening at 18:00 Amman time: reminds each user with a phone signed
 * in about bills and subscriptions due in 1, 3 or 7 days (their choice under
 * Preferences > Reminders and alerts, 3 by default).
 */
exports.sendBillReminders = onSchedule({
  region: "me-central1",
  schedule: "0 18 * * *",
  timeZone: AMMAN,
}, async () => {
  const today = ammanToday();
  const devices = await getFirestore().collectionGroup("devices").get();
  const byUser = new Map();
  for (const d of devices.docs) {
    const userRef = d.ref.parent.parent;
    if (!userRef || userRef.parent.id !== "users") continue;
    if (!byUser.has(userRef.id)) byUser.set(userRef.id, []);
    byUser.get(userRef.id).push(d);
  }

  let sent = 0;
  for (const [uid, docs] of byUser) {
    try {
      // The same shape sendToDevices takes from a query
      if (await remindAboutBills(uid, { empty: false, docs }, today)) sent++;
    } catch (error) {
      console.error(`Bill reminder failed for ${uid}:`, error);
    }
  }
  console.log(`Bill reminders: ${sent} of ${byUser.size} users with a phone`);
});
