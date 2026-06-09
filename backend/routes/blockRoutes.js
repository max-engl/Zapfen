const express = require("express");
const mongoose = require("mongoose");

const Block = require("../models/Block");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// POST /blocks/:userId  —  block a user
router.post("/:userId", authMiddleware, async (req, res) => {
    try {
        const targetId = req.params.userId;

        if (!mongoose.Types.ObjectId.isValid(targetId)) {
            return res.status(400).json({ message: "Invalid user ID" });
        }

        if (targetId === req.user._id.toString()) {
            return res.status(400).json({ message: "You cannot block yourself" });
        }

        await Block.findOneAndUpdate(
            { blocker: req.user._id, blocked: targetId },
            { blocker: req.user._id, blocked: targetId },
            { upsert: true, new: true },
        );

        res.json({ message: "User blocked" });
    } catch (error) {
        res.status(500).json({ message: "Could not block user", error: error.message });
    }
});

// DELETE /blocks/:userId  —  unblock a user
router.delete("/:userId", authMiddleware, async (req, res) => {
    try {
        const targetId = req.params.userId;

        if (!mongoose.Types.ObjectId.isValid(targetId)) {
            return res.status(400).json({ message: "Invalid user ID" });
        }

        await Block.deleteOne({ blocker: req.user._id, blocked: targetId });

        res.json({ message: "User unblocked" });
    } catch (error) {
        res.status(500).json({ message: "Could not unblock user", error: error.message });
    }
});

// GET /blocks  —  list of user IDs the current user has blocked
router.get("/", authMiddleware, async (req, res) => {
    try {
        const blocks = await Block.find({ blocker: req.user._id }).select("blocked");
        const blockedIds = blocks.map((b) => b.blocked.toString());
        res.json({ blockedIds });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch blocks", error: error.message });
    }
});

module.exports = router;
