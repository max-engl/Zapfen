const express = require('express');
const AppNotification = require('../models/AppNotification');
const r2 = require('../config/r2');
const { GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

async function resolveThumbUrls(notifications) {
    const paths = notifications
        .map((n) => n.postThumbPath)
        .filter(Boolean);

    if (!paths.length) return {};

    try {
        const signedUrls = await Promise.all(
            paths.map((p) =>
                getSignedUrl(r2, new GetObjectCommand({ Bucket: process.env.R2_POST_BUCKET, Key: p }), { expiresIn: 3600 })
                    .catch(() => null)
            )
        );
        const map = {};
        for (let i = 0; i < paths.length; i++) {
            if (signedUrls[i]) map[paths[i]] = signedUrls[i];
        }
        return map;
    } catch {
        return {};
    }
}

// GET /notifications  — most recent 50 for the current user
router.get('/', authMiddleware, async (req, res) => {
    try {
        const raw = await AppNotification.find({ recipient: req.user._id })
            .sort({ createdAt: -1 })
            .limit(50)
            .lean();

        const thumbMap = await resolveThumbUrls(raw);

        const notifications = raw.map((n) => ({
            id: n._id,
            type: n.type,
            actorId: n.actorId,
            actorUsername: n.actorUsername,
            actorAvatarUrl: n.actorAvatarUrl,
            actorAvatarColor: n.actorAvatarColor,
            actorAvatarInitial: n.actorAvatarInitial,
            postId: n.postId,
            postThumbUrl: n.postThumbPath ? (thumbMap[n.postThumbPath] ?? null) : null,
            mutualCount: n.mutualCount,
            read: n.read,
            createdAt: n.createdAt,
        }));

        res.json({ notifications });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// PUT /notifications/read-all
router.put('/read-all', authMiddleware, async (req, res) => {
    try {
        await AppNotification.updateMany({ recipient: req.user._id, read: false }, { read: true });
        res.json({ ok: true });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// PUT /notifications/:id/read
router.put('/:id/read', authMiddleware, async (req, res) => {
    try {
        await AppNotification.findOneAndUpdate(
            { _id: req.params.id, recipient: req.user._id },
            { read: true }
        );
        res.json({ ok: true });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
