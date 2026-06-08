const express = require("express");
const { v4: uuidv4 } = require("uuid");

const User = require("../models/User");
const supabase = require("../config/supabase");
const upload = require("../middleware/uploadMiddleware");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

function getFileExtension(filename) {
    return filename.split(".").pop().toLowerCase();
}

// PATCH /users/me  —  update username
router.patch("/me", authMiddleware, async (req, res) => {
    try {
        const { username } = req.body;
        if (!username) {
            return res.status(400).json({ message: "Username is required" });
        }
        const trimmed = username.trim().toLowerCase();
        if (trimmed.length < 3 || trimmed.length > 16) {
            return res.status(400).json({ message: "Username must be 3–16 characters" });
        }
        if (!/^[a-z0-9_]+$/.test(trimmed)) {
            return res.status(400).json({ message: "Letters, numbers, and underscores only" });
        }
        const existing = await User.findOne({ username: trimmed, _id: { $ne: req.user._id } });
        if (existing) {
            return res.status(409).json({ message: `@${trimmed} is already taken.` });
        }
        const user = await User.findByIdAndUpdate(
            req.user._id,
            { username: trimmed },
            { new: true }
        ).select("-passwordHash");
        res.json({
            message: "Username updated",
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                role: user.role,
                avatarUrl: user.avatarUrl,
                avatarColor: user.avatarColor,
                avatarInitial: user.avatarInitial,
            },
        });
    } catch (error) {
        res.status(500).json({ message: "Could not update username", error: error.message });
    }
});

// DELETE /users/me/avatar  —  remove profile photo
router.delete("/me/avatar", authMiddleware, async (req, res) => {
    try {
        const user = await User.findByIdAndUpdate(
            req.user._id,
            { avatarUrl: null },
            { new: true }
        ).select("-passwordHash");
        res.json({
            message: "Avatar removed",
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                role: user.role,
                avatarUrl: user.avatarUrl,
                avatarColor: user.avatarColor,
                avatarInitial: user.avatarInitial,
            },
        });
    } catch (error) {
        res.status(500).json({ message: "Could not remove avatar", error: error.message });
    }
});

// GET /users/search?q=query  —  find users by username prefix
router.get("/search", authMiddleware, async (req, res) => {
    try {
        const q = (req.query.q || "").trim();
        if (q.length < 2) {
            return res.json({ users: [] });
        }
        const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        const users = await User.find({
            username: { $regex: `^${escaped}`, $options: "i" },
            _id: { $ne: req.user._id },
        })
            .select("_id username avatarUrl avatarColor avatarInitial")
            .limit(20);

        res.json({
            users: users.map((u) => ({
                id: u._id,
                username: u.username,
                avatarUrl: u.avatarUrl,
                avatarColor: u.avatarColor,
                avatarInitial: u.avatarInitial,
            })),
        });
    } catch (error) {
        res.status(500).json({ message: "Search failed", error: error.message });
    }
});

// PATCH /users/me/avatar
router.patch(
    "/me/avatar",
    authMiddleware,
    upload.single("image"),
    async (req, res) => {
        try {
            if (!req.file) {
                return res.status(400).json({
                    message: "No image uploaded",
                });
            }

            const extension = getFileExtension(req.file.originalname);

            const storagePath = `${req.user._id}/${uuidv4()}.${extension}`;

            const { error: uploadError } = await supabase.storage
                .from(process.env.SUPABASE_AVATAR_BUCKET)
                .upload(storagePath, req.file.buffer, {
                    contentType: req.file.mimetype,
                    upsert: false,
                });

            if (uploadError) {
                return res.status(500).json({
                    message: "Avatar upload failed",
                    error: uploadError.message,
                });
            }

            const { data } = supabase.storage
                .from(process.env.SUPABASE_AVATAR_BUCKET)
                .getPublicUrl(storagePath);

            if (!data?.publicUrl) {
                return res.status(500).json({ message: "Could not retrieve avatar URL from storage" });
            }

            const user = await User.findByIdAndUpdate(
                req.user._id,
                {
                    avatarUrl: data.publicUrl,
                },
                {
                    new: true,
                }
            ).select("-passwordHash");

            res.json({
                message: "Avatar updated successfully",
                user: {
                    id: user._id,
                    username: user.username,
                    email: user.email,
                    role: user.role,
                    avatarUrl: user.avatarUrl,
                    avatarColor: user.avatarColor,
                    avatarInitial: user.avatarInitial,
                },
            });
        } catch (error) {
            res.status(500).json({
                message: "Could not update avatar",
                error: error.message,
            });
        }
    }
);

// PUT /users/me/fcm-token  —  store the device FCM token for push notifications
router.put("/me/fcm-token", authMiddleware, async (req, res) => {
    try {
        const { fcmToken } = req.body;
        if (!fcmToken) {
            return res.status(400).json({ message: "fcmToken is required" });
        }
        await User.findByIdAndUpdate(req.user._id, { fcmToken });
        res.json({ message: "FCM token saved" });
    } catch (error) {
        res.status(500).json({ message: "Could not save FCM token", error: error.message });
    }
});

module.exports = router;