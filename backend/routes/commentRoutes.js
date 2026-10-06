const express = require("express");
const Comment = require("../models/Comment");
const CommentReaction = require("../models/CommentReaction");
const Post = require("../models/Post");
const Friend = require("../models/Friend");
const authMiddleware = require("../middleware/authMiddleware");
const { sendToUser, saveNotification } = require("../services/notificationService");

// postRouter is mounted at /posts — handles /:postId/comments
const postRouter = express.Router();

// commentRouter is mounted at /comments — handles /:commentId/replies|reactions|DELETE
const commentRouter = express.Router();

async function canAccessPost(userId, post) {
    if (post.user._id.toString() === userId.toString()) return true;
    const friendship = await Friend.findOne({
        $or: [
            { requester: userId, recipient: post.user._id },
            { requester: post.user._id, recipient: userId },
        ],
        status: "accepted",
    });
    return !!friendship;
}

function formatComment(comment, myReaction = null) {
    const reactionCounts = comment.reactionCounts instanceof Map
        ? Object.fromEntries(comment.reactionCounts)
        : (comment.reactionCounts || {});

    const reactions = Object.entries(reactionCounts)
        .filter(([, count]) => count > 0)
        .map(([emoji, count]) => ({ emoji, count }));

    return {
        id: comment._id,
        postId: comment.post,
        user: comment.user,
        text: comment.text,
        parentId: comment.parent || null,
        myReaction,
        reactions,
        createdAt: comment.createdAt,
    };
}

// ── Post-level routes (mounted at /posts) ─────────────────────────────────────

// GET /posts/:postId/comments
postRouter.get("/:postId/comments", authMiddleware, async (req, res) => {
    try {
        const post = await Post.findById(req.params.postId).populate("user", "_id");
        if (!post) return res.status(404).json({ message: "Post not found" });

        if (!(await canAccessPost(req.user._id, post))) {
            return res.status(403).json({ message: "Access denied" });
        }

        const allComments = await Comment.find({ post: post._id })
            .sort({ createdAt: 1 })
            .populate("user", "username avatarUrl");

        const commentIds = allComments.map((c) => c._id);
        const myReactions = await CommentReaction.find({
            comment: { $in: commentIds },
            user: req.user._id,
        });
        const myReactionMap = {};
        for (const r of myReactions) {
            myReactionMap[r.comment.toString()] = r.emoji;
        }

        const replyMap = {};
        const topLevel = [];

        for (const c of allComments) {
            if (!c.parent) {
                const formatted = formatComment(c, myReactionMap[c._id.toString()] || null);
                formatted.replies = [];
                topLevel.push(formatted);
                replyMap[c._id.toString()] = formatted;
            }
        }

        for (const c of allComments) {
            if (c.parent) {
                const parentFormatted = replyMap[c.parent.toString()];
                if (parentFormatted) {
                    parentFormatted.replies.push(
                        formatComment(c, myReactionMap[c._id.toString()] || null)
                    );
                }
            }
        }

        res.json({ comments: topLevel });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch comments", error: error.message });
    }
});

// POST /posts/:postId/comments
postRouter.post("/:postId/comments", authMiddleware, async (req, res) => {
    try {
        const { text } = req.body;
        if (!text || !text.trim()) {
            return res.status(400).json({ message: "Comment text is required" });
        }

        const post = await Post.findById(req.params.postId).populate("user", "_id");
        if (!post) return res.status(404).json({ message: "Post not found" });

        if (!(await canAccessPost(req.user._id, post))) {
            return res.status(403).json({ message: "Access denied" });
        }

        const comment = await Comment.create({
            post: post._id,
            user: req.user._id,
            text: text.trim(),
        });

        await comment.populate("user", "username avatarUrl");
        post.stats.comments += 1;
        await post.save();

        res.status(201).json({ comment: formatComment(comment) });

        // Notify post owner (never self)
        if (post.user._id.toString() !== req.user._id.toString()) {
            sendToUser(post.user._id, {
                title: `@${req.user.username} 💬`,
                body: "hat deinen Beitrag kommentiert",
                data: { type: "post", postId: post._id.toString() },
            }).catch(() => {});
            saveNotification(post.user._id, {
                type: 'comment',
                actorId: req.user._id,
                actorUsername: req.user.username,
                actorAvatarUrl: req.user.avatarUrl ?? null,
                actorAvatarColor: req.user.avatarColor ?? null,
                actorAvatarInitial: req.user.avatarInitial ?? null,
                postId: post._id,
                postThumbPath: post.storagePath ?? null,
            }).catch(() => {});
        }
    } catch (error) {
        res.status(500).json({ message: "Could not add comment", error: error.message });
    }
});

// ── Individual comment routes (mounted at /comments) ─────────────────────────

// POST /comments/:commentId/replies
commentRouter.post("/:commentId/replies", authMiddleware, async (req, res) => {
    try {
        const { text } = req.body;
        if (!text || !text.trim()) {
            return res.status(400).json({ message: "Reply text is required" });
        }

        const parent = await Comment.findById(req.params.commentId);
        if (!parent) return res.status(404).json({ message: "Comment not found" });
        if (parent.parent) {
            return res.status(400).json({ message: "Cannot reply to a reply" });
        }

        const post = await Post.findById(parent.post).populate("user", "_id");
        if (!post) return res.status(404).json({ message: "Post not found" });

        if (!(await canAccessPost(req.user._id, post))) {
            return res.status(403).json({ message: "Access denied" });
        }

        const reply = await Comment.create({
            post: post._id,
            user: req.user._id,
            text: text.trim(),
            parent: parent._id,
        });

        await reply.populate("user", "username avatarUrl");
        post.stats.comments += 1;
        await post.save();

        res.status(201).json({ comment: formatComment(reply) });
    } catch (error) {
        res.status(500).json({ message: "Could not add reply", error: error.message });
    }
});

// DELETE /comments/:commentId
commentRouter.delete("/:commentId", authMiddleware, async (req, res) => {
    try {
        const comment = await Comment.findById(req.params.commentId);
        if (!comment) return res.status(404).json({ message: "Comment not found" });

        if (comment.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: "You can only delete your own comments" });
        }

        // Fetch reply IDs once; use same list for both the count and the cascade delete.
        const replyIds = await Comment.find({ parent: comment._id }).distinct("_id");
        const totalDeleted = 1 + replyIds.length;

        // Delete all documents first; only update the counter after successful deletion.
        await Promise.all([
            Comment.deleteMany({ parent: comment._id }),
            CommentReaction.deleteMany({ comment: { $in: [comment._id, ...replyIds] } }),
            comment.deleteOne(),
        ]);

        await Post.findByIdAndUpdate(comment.post, {
            $inc: { "stats.comments": -totalDeleted },
        });

        res.json({ message: "Comment deleted" });
    } catch (error) {
        res.status(500).json({ message: "Could not delete comment", error: error.message });
    }
});

// POST /comments/:commentId/reactions
commentRouter.post("/:commentId/reactions", authMiddleware, async (req, res) => {
    try {
        const { emoji } = req.body;
        if (!emoji) return res.status(400).json({ message: "emoji is required" });

        const comment = await Comment.findById(req.params.commentId);
        if (!comment) return res.status(404).json({ message: "Comment not found" });

        const existing = await CommentReaction.findOne({
            comment: comment._id,
            user: req.user._id,
        });

        let myReaction = null;

        if (existing) {
            const oldEmoji = existing.emoji;
            if (oldEmoji === emoji) {
                await existing.deleteOne();
                comment.reactionCounts.set(emoji, Math.max(0, (comment.reactionCounts.get(emoji) || 0) - 1));
            } else {
                comment.reactionCounts.set(oldEmoji, Math.max(0, (comment.reactionCounts.get(oldEmoji) || 0) - 1));
                comment.reactionCounts.set(emoji, (comment.reactionCounts.get(emoji) || 0) + 1);
                existing.emoji = emoji;
                await existing.save();
                myReaction = emoji;
            }
        } else {
            await CommentReaction.create({ comment: comment._id, user: req.user._id, emoji });
            comment.reactionCounts.set(emoji, (comment.reactionCounts.get(emoji) || 0) + 1);
            myReaction = emoji;
        }

        await comment.save();

        const reactions = Array.from(comment.reactionCounts.entries())
            .filter(([, count]) => count > 0)
            .map(([e, count]) => ({ emoji: e, count }));

        res.json({ myReaction, reactions });
    } catch (error) {
        res.status(500).json({ message: "Could not toggle reaction", error: error.message });
    }
});

module.exports = { postRouter, commentRouter };
