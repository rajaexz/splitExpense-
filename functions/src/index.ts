import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Daily at 9 AM (Asia/Kolkata): Send settle-up reminders to all members of groups
 * that have settleUpDate set to today.
 */
export const sendSettleUpReminders = functions.pubsub
  .schedule("0 9 * * *")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const startOfToday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0));
    const endOfToday = new Date(startOfToday.getTime() + 24 * 60 * 60 * 1000);

    const groupsSnapshot = await db
      .collection("groups")
      .where("settleUpDate", ">=", admin.firestore.Timestamp.fromDate(startOfToday))
      .where("settleUpDate", "<", admin.firestore.Timestamp.fromDate(endOfToday))
      .get();

    for (const groupDoc of groupsSnapshot.docs) {
      const groupData = groupDoc.data();
      const groupName = groupData.name || "Group";
      const groupId = groupDoc.id;
      const members = (groupData.members || {}) as Record<string, { userId?: string }>;
      const memberIds = Object.keys(members);

      for (const userId of memberIds) {
        try {
          const notifRef = db.collection("notifications").doc(userId).collection("notifications").doc();
          await notifRef.set({
            id: notifRef.id,
            userId,
            type: "settle_up_reminder",
            title: "Settle up today!",
            body: `Reminder: ${groupName} - Time to settle up expenses.`,
            data: { groupId, groupName },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (err) {
          console.error(`Failed to create notification for ${userId}:`, err);
        }
      }
    }
  });

/**
 * When a notification is created in Firestore, send FCM push to the user.
 * Enables background/terminated app to receive notifications.
 */
export const onNotificationCreated = functions.firestore
  .document("notifications/{userId}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const userId = context.params.userId;

    const title = notification?.title || "New notification";
    const body = notification?.body || "";
    const data = notification?.data || {};
    const type = notification?.type || "";

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken as string | undefined;

    if (!fcmToken) return;

    const androidConfig: admin.messaging.AndroidConfig = {
      priority: "high",
      notification: {
        sound: "fuck_sound_effect",
        channelId: "high_importance_channel",
      },
    };

    const fcmData: Record<string, string> = {
      type: type || "",
      groupId: (data.groupId || "").toString(),
      groupName: (data.groupName || "").toString(),
    };
    if (type === "payment_reminder" && data.upiUri) {
      fcmData.upiUri = data.upiUri;
      fcmData.amount = String(data.amount ?? "");
      fcmData.currency = (data.currency || "").toString();
      fcmData.senderName = (data.senderName || "").toString();
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: fcmData,
      android: androidConfig,
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
    } catch (err) {
      console.error("FCM send error:", err);
    }
  });
