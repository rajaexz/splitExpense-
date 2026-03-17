"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onNotificationCreated = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
/**
 * When a notification is created in Firestore, send FCM push to the user.
 * Enables background/terminated app to receive notifications.
 */
exports.onNotificationCreated = functions.firestore
    .document("notifications/{userId}/notifications/{notificationId}")
    .onCreate(async (snap, context) => {
    var _a;
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
    const message = {
        token: fcmToken,
        notification: {
            title,
            body,
        },
        data: {
            type: type || "",
            groupId: (data.groupId || "").toString(),
            groupName: (data.groupName || "").toString(),
        },
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
//# sourceMappingURL=index.js.map