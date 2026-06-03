const express = require("express");
const crypto = require("crypto");

const Friend = require("../models/Friend");
const User = require("../models/User");
const authMiddleware = require("../middleware/authMiddleware");
const { sendToUser, saveNotification } = require("../services/notificationService");

const router = express.Router();

// POST /friends/request/:userId  —  send a friend request
router.post("/request/:userId", authMiddleware, async (req, res) => {
    try {
        const recipientId = req.params.userId;
        const requesterId = req.user._id.toString();

        if (recipientId === requesterId) {
            return res.status(400).json({ message: "Cannot send a friend request to yourself" });
        }

        const recipient = await User.findById(recipientId);
        if (!recipient) {
            return res.status(404).json({ message: "User not found" });
        }

        // Check if any relationship already exists in either direction
        const existing = await Friend.findOne({
            $or: [
                { requester: requesterId, recipient: recipientId },
                { requester: recipientId, recipient: requesterId },
            ],
        });

        if (existing) {
            const msg =
                existing.status === "accepted"
                    ? "You are already friends"
                    : "Friend request already exists";
            return res.status(409).json({ message: msg });
        }

        const friendship = await Friend.create({
            requester: requesterId,
            recipient: recipientId,
        });

        res.status(201).json({
            message: "Friend request sent",
            friendship: {
                id: friendship._id,
                recipient: recipientId,
                status: friendship.status,
            },
        });

        sendToUser(recipientId, {
            title: `@${req.user.username}`,
            body: "möchte mit dir befreundet sein",
            data: { type: "friend_request" },
        }).catch(() => {});
        saveNotification(recipientId, {
            type: 'request',
            actorId: req.user._id,
            actorUsername: req.user.username,
            actorAvatarUrl: req.user.avatarUrl ?? null,
            actorAvatarColor: req.user.avatarColor ?? null,
            actorAvatarInitial: req.user.avatarInitial ?? null,
        }).catch(() => {});
    } catch (error) {
        res.status(500).json({ message: "Could not send friend request", error: error.message });
    }
});

// POST /friends/accept/:userId  —  accept a pending request from userId
router.post("/accept/:userId", authMiddleware, async (req, res) => {
    try {
        const requesterId = req.params.userId;
        const recipientId = req.user._id.toString();

        const friendship = await Friend.findOne({
            requester: requesterId,
            recipient: recipientId,
            status: "pending",
        });

        if (!friendship) {
            return res.status(404).json({ message: "No pending friend request from this user" });
        }

        friendship.status = "accepted";
        await friendship.save();

        res.json({ message: "Friend request accepted" });

        sendToUser(requesterId, {
            title: `@${req.user.username}`,
            body: "hat deine Freundschaftsanfrage angenommen",
            data: { type: "friend_accepted" },
        }).catch(() => {});
        saveNotification(requesterId, {
            type: 'accepted',
            actorId: req.user._id,
            actorUsername: req.user.username,
            actorAvatarUrl: req.user.avatarUrl ?? null,
            actorAvatarColor: req.user.avatarColor ?? null,
            actorAvatarInitial: req.user.avatarInitial ?? null,
        }).catch(() => {});
    } catch (error) {
        res.status(500).json({ message: "Could not accept friend request", error: error.message });
    }
});

// DELETE /friends/:userId  —  decline a pending request OR remove an existing friend
router.delete("/:userId", authMiddleware, async (req, res) => {
    try {
        const otherId = req.params.userId;
        const meId = req.user._id.toString();

        const friendship = await Friend.findOneAndDelete({
            $or: [
                { requester: meId, recipient: otherId },
                { requester: otherId, recipient: meId },
            ],
        });

        if (!friendship) {
            return res.status(404).json({ message: "No friendship or request found" });
        }

        const msg = friendship.status === "accepted" ? "Friend removed" : "Friend request declined";
        res.json({ message: msg });
    } catch (error) {
        res.status(500).json({ message: "Could not remove friend", error: error.message });
    }
});

// GET /friends  —  list accepted friends
router.get("/", authMiddleware, async (req, res) => {
    try {
        const meId = req.user._id;

        const friendships = await Friend.find({
            $or: [{ requester: meId }, { recipient: meId }],
            status: "accepted",
        })
            .populate("requester", "username avatarUrl avatarColor avatarInitial")
            .populate("recipient", "username avatarUrl avatarColor avatarInitial");

        const friends = friendships.map((f) => {
            const isRequester = f.requester._id.toString() === meId.toString();
            return isRequester ? f.recipient : f.requester;
        });

        res.json({ friends });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch friends", error: error.message });
    }
});

// GET /friends/requests  —  list incoming pending requests
router.get("/requests", authMiddleware, async (req, res) => {
    try {
        const requests = await Friend.find({
            recipient: req.user._id,
            status: "pending",
        }).populate("requester", "username avatarUrl avatarColor avatarInitial");

        const incoming = requests.map((r) => ({
            id: r._id,
            from: r.requester,
            sentAt: r.createdAt,
        }));

        res.json({ requests: incoming });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch requests", error: error.message });
    }
});

// GET /friends/invite  —  get (or lazily create) the caller's invite token
router.get("/invite", authMiddleware, async (req, res) => {
    try {
        let user = req.user;
        if (!user.inviteToken) {
            user = await User.findByIdAndUpdate(
                user._id,
                { inviteToken: crypto.randomUUID() },
                { new: true }
            );
        }
        res.json({
            token: user.inviteToken,
            // HTTP URL so the camera app can scan it and open Safari → custom scheme
            link: `http://${req.headers.host}/invite/${user.inviteToken}`,
        });
    } catch (error) {
        res.status(500).json({ message: "Could not get invite token", error: error.message });
    }
});

// GET /friends/invite/:token  —  public: resolve a token to user info
router.get("/invite/:token", async (req, res) => {
    try {
        const user = await User.findOne({ inviteToken: req.params.token });
        if (!user) return res.status(404).json({ message: "Invite link not found" });
        res.json({
            userId: user._id,
            username: user.username,
            avatarUrl: user.avatarUrl ?? null,
            avatarColor: user.avatarColor,
            avatarInitial: user.avatarInitial,
        });
    } catch (error) {
        res.status(500).json({ message: "Could not resolve invite", error: error.message });
    }
});

// POST /friends/invite/:token/accept  —  send a friend request to the token's owner
router.post("/invite/:token/accept", authMiddleware, async (req, res) => {
    try {
        const inviter = await User.findOne({ inviteToken: req.params.token });
        if (!inviter) return res.status(404).json({ message: "Invite link not found" });

        const recipientId = inviter._id.toString();
        const requesterId = req.user._id.toString();

        if (recipientId === requesterId) {
            return res.status(400).json({ message: "Cannot send a friend request to yourself" });
        }

        const existing = await Friend.findOne({
            $or: [
                { requester: requesterId, recipient: recipientId },
                { requester: recipientId, recipient: requesterId },
            ],
        });

        if (existing) {
            const msg = existing.status === "accepted" ? "You are already friends" : "Friend request already exists";
            return res.status(409).json({ message: msg });
        }

        const friendship = await Friend.create({ requester: requesterId, recipient: recipientId });

        res.status(201).json({
            message: "Friend request sent",
            friendship: { id: friendship._id, recipient: recipientId, status: friendship.status },
        });

        sendToUser(recipientId, {
            title: `@${req.user.username}`,
            body: "möchte mit dir befreundet sein",
            data: { type: "friend_request" },
        }).catch(() => {});
        saveNotification(recipientId, {
            type: "request",
            actorId: req.user._id,
            actorUsername: req.user.username,
            actorAvatarUrl: req.user.avatarUrl ?? null,
            actorAvatarColor: req.user.avatarColor ?? null,
            actorAvatarInitial: req.user.avatarInitial ?? null,
        }).catch(() => {});
    } catch (error) {
        res.status(500).json({ message: "Could not accept invite", error: error.message });
    }
});

module.exports = router;
