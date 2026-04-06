"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateGameContent = exports.onNotificationCreated = exports.sendSettleUpReminders = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
/**
 * Daily at 9 AM (Asia/Kolkata): Send settle-up reminders to all members of groups
 * that have settleUpDate set to today.
 */
exports.sendSettleUpReminders = functions.pubsub
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
        const members = (groupData.members || {});
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
            }
            catch (err) {
                console.error(`Failed to create notification for ${userId}:`, err);
            }
        }
    }
});
/**
 * When a notification is created in Firestore, send FCM push to the user.
 * Enables background/terminated app to receive notifications.
 */
exports.onNotificationCreated = functions.firestore
    .document("notifications/{userId}/notifications/{notificationId}")
    .onCreate(async (snap, context) => {
    var _a, _b;
    const notification = snap.data();
    const userId = context.params.userId;
    const title = (notification === null || notification === void 0 ? void 0 : notification.title) || "New notification";
    const body = (notification === null || notification === void 0 ? void 0 : notification.body) || "";
    const data = (notification === null || notification === void 0 ? void 0 : notification.data) || {};
    const type = (notification === null || notification === void 0 ? void 0 : notification.type) || "";
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
    if (!fcmToken)
        return;
    const androidConfig = {
        priority: "high",
        notification: {
            sound: "fuck_sound_effect",
            channelId: "high_importance_channel",
        },
    };
    const fcmData = {
        type: type || "",
        groupId: (data.groupId || "").toString(),
        groupName: (data.groupName || "").toString(),
    };
    if (type === "payment_reminder" && data.upiUri) {
        fcmData.upiUri = data.upiUri;
        fcmData.amount = String((_b = data.amount) !== null && _b !== void 0 ? _b : "");
        fcmData.currency = (data.currency || "").toString();
        fcmData.senderName = (data.senderName || "").toString();
    }
    if ((type === "game_turn" ||
        type === "game_payment" ||
        type === "game_poke" ||
        type === "game_winner" ||
        type === "game_complete") &&
        data.gameId) {
        fcmData.gameId = (data.gameId || "").toString();
    }
    const message = {
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
    }
    catch (err) {
        console.error("FCM send error:", err);
    }
});
var generateGameContent_1 = require("./generateGameContent");
Object.defineProperty(exports, "generateGameContent", { enumerable: true, get: function () { return generateGameContent_1.generateGameContent; } });
//# sourceMappingURL=index.js.map