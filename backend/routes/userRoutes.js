const express = require("express");
const { v4: uuidv4 } = require("uuid");
const bcrypt = require("bcrypt");

const User = require("../models/User");
const Post = require("../models/Post");
const Like = require("../models/Like");
const PostReaction = require("../models/PostReaction");
const Comment = require("../models/Comment");
const CommentReaction = require("../models/CommentReaction");
const Friend = require("../models/Friend");
const AppNotification = require("../models/AppNotification");
const Drink = require("../models/Drink");
const Report = require("../models/Report");
const Block = require("../models/Block");
const r2 = require("../config/r2");
const { PutObjectCommand, DeleteObjectsCommand } = require("@aws-sdk/client-s3");
const upload = require("../middleware/uploadMiddleware");
const sharp = require("sharp");
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

        const [blockedByMe, blockedMe] = await Promise.all([
            Block.find({ blocker: req.user._id }).distinct("blocked"),
            Block.find({ blocked: req.user._id }).distinct("blocker"),
        ]);
        const hiddenIds = [...new Set([...blockedByMe.map(String), ...blockedMe.map(String)])];

        const users = await User.find({
            username: { $regex: `^${escaped}`, $options: "i" },
            _id: { $ne: req.user._id, $nin: hiddenIds },
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

            const compressed = await sharp(req.file.buffer)
                .resize(512, 512, { fit: "inside", withoutEnlargement: true })
                .jpeg({ quality: 85, progressive: true })
                .toBuffer();

            const storagePath = `${req.user._id}/${uuidv4()}.jpg`;

            try {
                await r2.send(new PutObjectCommand({
                    Bucket: process.env.R2_AVATAR_BUCKET,
                    Key: storagePath,
                    Body: compressed,
                    ContentType: "image/jpeg",
                }));
            } catch (uploadErr) {
                return res.status(500).json({
                    message: "Avatar upload failed",
                    error: uploadErr.message,
                });
            }

            const publicUrl = `${process.env.R2_AVATAR_PUBLIC_BASE_URL}/${storagePath}`;

            const user = await User.findByIdAndUpdate(
                req.user._id,
                {
                    avatarUrl: publicUrl,
                    avatarCompressed: true,
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

// DELETE /users/me  —  permanently delete account and all associated data
router.delete("/me", authMiddleware, async (req, res) => {
    try {
        const { password } = req.body;
        if (!password) {
            return res.status(400).json({ message: "Password is required to delete your account" });
        }

        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        const passwordMatch = await bcrypt.compare(password, user.passwordHash);
        if (!passwordMatch) {
            return res.status(400).json({ message: "Falsches Passwort" });
        }

        const userId = user._id;

        const posts = await Post.find({ user: userId }).select("storagePath selfieStoragePath");
        const postIds = posts.map((p) => p._id);
        const storagePaths = [];
        for (const p of posts) {
            if (p.storagePath) storagePaths.push(p.storagePath);
            if (p.selfieStoragePath) storagePaths.push(p.selfieStoragePath);
        }
        if (storagePaths.length > 0) {
            await r2.send(new DeleteObjectsCommand({
                Bucket: process.env.R2_POST_BUCKET,
                Delete: { Objects: storagePaths.map((Key) => ({ Key })), Quiet: true },
            }));
        }

        if (user.avatarUrl) {
            const avatarPath = user.avatarUrl.replace(`${process.env.R2_AVATAR_PUBLIC_BASE_URL}/`, "");
            if (avatarPath && avatarPath !== user.avatarUrl) {
                await r2.send(new DeleteObjectsCommand({
                    Bucket: process.env.R2_AVATAR_BUCKET,
                    Delete: { Objects: [{ Key: avatarPath }], Quiet: true },
                }));
            }
        }

        // Get comment IDs authored by this user for CommentReaction cleanup
        const userCommentIds = await Comment.find({ user: userId }).distinct("_id");
        // Get comment IDs on this user's posts for full cleanup
        const postCommentIds = postIds.length > 0
            ? await Comment.find({ post: { $in: postIds } }).distinct("_id")
            : [];
        const allCommentIds = [...new Set([...userCommentIds.map(String), ...postCommentIds.map(String)])];

        await Promise.all([
            // Posts and their associated data
            Post.deleteMany({ user: userId }),
            Like.deleteMany({ $or: [{ user: userId }, { post: { $in: postIds } }] }),
            PostReaction.deleteMany({ $or: [{ user: userId }, { post: { $in: postIds } }] }),
            Comment.deleteMany({ $or: [{ user: userId }, { post: { $in: postIds } }] }),
            allCommentIds.length > 0
                ? CommentReaction.deleteMany({ $or: [{ user: userId }, { comment: { $in: allCommentIds } }] })
                : Promise.resolve(),
            // Social graph
            Friend.deleteMany({ $or: [{ requester: userId }, { recipient: userId }] }),
            // Notifications
            AppNotification.deleteMany({ $or: [{ recipient: userId }, { actorId: userId }] }),
            // User-created drinks
            Drink.deleteMany({ user: userId }),
            // Reports
            Report.deleteMany({ reporter: userId }),
        ]);

        await User.findByIdAndDelete(userId);

        res.json({ message: "Account deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: "Could not delete account", error: error.message });
    }
});

module.exports = router;