const express = require("express");
const admin = require("../config/firebase");
const authMiddleware = require("../middleware/authMiddleware");
const User = require("../models/User");

const router = express.Router();

// GET /notify/test?token=FCM_TOKEN  —  no auth, sends a test push to the given token
router.get("/test", async (req, res) => {
    const { token } = req.query;
    if (!token) {
        return res.status(400).json({ message: "token query param is required" });
    }

    try {
        const response = await admin.messaging().send({
            token,
            notification: {
                title: "Zapfen. 🍺",
                body: "Push notifications are working!",
            },
            data: {
                type: "test",
            },
        });
        res.json({ message: "Notification sent", messageId: response });
    } catch (error) {
        res.status(500).json({ message: "Failed to send notification", error: error.message });
    }
});

// POST /notify/send  —  authenticated, sends a push to a target user by userId
router.post("/send", authMiddleware, async (req, res) => {
    const { userId, title, body, data } = req.body;
    if (!userId || !title || !body) {
        return res.status(400).json({ message: "userId, title, and body are required" });
    }

    try {
        const target = await User.findById(userId).select("fcmToken");
        if (!target?.fcmToken) {
            return res.status(404).json({ message: "User has no FCM token registered" });
        }

        const response = await admin.messaging().send({
            token: target.fcmToken,
            notification: { title, body },
            data: data ?? {},
        });
        res.json({ message: "Notification sent", messageId: response });
    } catch (error) {
        res.status(500).json({ message: "Failed to send notification", error: error.message });
    }
});

module.exports = router;
