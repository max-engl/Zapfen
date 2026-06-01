const admin = require("../config/firebase");
const User = require("../models/User");
const AppNotification = require("../models/AppNotification");

// FCM data payloads must be string-only values
function stringifyData(data) {
    return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]));
}

function buildMessage(token, title, body, data) {
    return {
        token,
        notification: { title, body },
        data: stringifyData(data),
        apns: { payload: { aps: { sound: "default" } } },
    };
}

/**
 * Send a push notification to one user by their MongoDB _id.
 * Silently no-ops if the user has no FCM token.
 */
async function sendToUser(userId, { title, body, data = {} }) {
    if (!userId) return;
    try {
        const user = await User.findById(userId).select("fcmToken");
        if (!user?.fcmToken) return;
        await admin.messaging().send(buildMessage(user.fcmToken, title, body, data));
    } catch (err) {
        console.error(`Notification to ${userId} failed:`, err.message);
    }
}

/**
 * Fan-out a notification to multiple users.
 * Batches in groups of 500 (FCM sendEach limit).
 */
async function sendToUsers(userIds, { title, body, data = {} }) {
    if (!userIds?.length) return;
    try {
        const users = await User.find({
            _id: { $in: userIds },
            fcmToken: { $ne: null },
        }).select("fcmToken");

        if (!users.length) return;

        const messages = users.map((u) => buildMessage(u.fcmToken, title, body, data));

        for (let i = 0; i < messages.length; i += 500) {
            await admin.messaging().sendEach(messages.slice(i, i + 500));
        }
    } catch (err) {
        console.error("Batch notification failed:", err.message);
    }
}

/**
 * Persist a notification for one recipient.
 */
async function saveNotification(recipientId, fields) {
    if (!recipientId) return;
    try {
        await AppNotification.create({ recipient: recipientId, ...fields });
    } catch (err) {
        console.error(`saveNotification failed:`, err.message);
    }
}

/**
 * Persist a notification for many recipients (fan-out).
 */
async function saveNotifications(recipientIds, fields) {
    if (!recipientIds?.length) return;
    try {
        await AppNotification.insertMany(
            recipientIds.map((id) => ({ recipient: id, ...fields }))
        );
    } catch (err) {
        console.error(`saveNotifications failed:`, err.message);
    }
}

module.exports = { sendToUser, sendToUsers, saveNotification, saveNotifications };
