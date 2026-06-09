const express = require("express");
const Post = require("../models/Post");
const Report = require("../models/Report");
const User = require("../models/User");
const Like = require("../models/Like");
const Comment = require("../models/Comment");
const PostReaction = require("../models/PostReaction");
const CommentReaction = require("../models/CommentReaction");
const r2 = require("../config/r2");
const { DeleteObjectsCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const authMiddleware = require("../middleware/authMiddleware");
const adminMiddleware = require("../middleware/adminMiddleware");

// User-facing: submit a report
const reportRouter = express.Router();

// POST /reports/posts/:postId
reportRouter.post("/posts/:postId", authMiddleware, async (req, res) => {
    try {
        const { reason } = req.body;
        if (!reason || reason.trim().length === 0) {
            return res.status(400).json({ message: "Reason is required" });
        }

        const post = await Post.findById(req.params.postId);
        if (!post) return res.status(404).json({ message: "Post not found" });

        if (post.user.toString() === req.user._id.toString()) {
            return res.status(400).json({ message: "You cannot report your own post" });
        }

        const report = await Report.create({
            reporter: req.user._id,
            post: post._id,
            reportedUser: post.user,
            reason: reason.trim(),
        });

        res.status(201).json({ message: "Report submitted", reportId: report._id });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(409).json({ message: "You already reported this post" });
        }
        res.status(500).json({ message: "Could not submit report", error: error.message });
    }
});

// Admin routes
const adminRouter = express.Router();
adminRouter.use(authMiddleware, adminMiddleware);

// GET /admin/stats — overview: total users, total posts, paginated users list
adminRouter.get("/stats", async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 50));

        const [totalUsers, totalPosts, pendingReports, users] = await Promise.all([
            User.countDocuments(),
            Post.countDocuments(),
            Report.countDocuments({ status: "pending" }),
            User.find()
                .select("username email role avatarColor avatarInitial createdAt")
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit)
                .lean(),
        ]);

        // Fetch post counts per user
        const postCounts = await Post.aggregate([
            { $group: { _id: "$user", count: { $sum: 1 } } },
        ]);
        const postCountMap = {};
        for (const p of postCounts) postCountMap[p._id.toString()] = p.count;

        const usersWithCounts = users.map((u) => ({
            ...u,
            postCount: postCountMap[u._id.toString()] || 0,
        }));

        res.json({ totalUsers, totalPosts, pendingReports, users: usersWithCounts, page, limit });
    } catch (error) {
        res.status(500).json({ message: "Could not load stats", error: error.message });
    }
});

// GET /admin/reports — list all reports (newest first, with population)
adminRouter.get("/reports", async (req, res) => {
    try {
        const { status } = req.query;
        const filter = status ? { status } : {};

        const reports = await Report.find(filter)
            .sort({ createdAt: -1 })
            .populate("reporter", "username avatarColor avatarInitial")
            .populate("reportedUser", "username avatarColor avatarInitial")
            .populate({
                path: "post",
                select: "caption drink storagePath selfieStoragePath stats location createdAt",
            })
            .lean();

        // Attach signed image URLs for main + selfie
        const withUrls = await Promise.all(
            reports.map(async (r) => {
                if (!r.post) return { ...r, postImageUrl: null, postSelfieUrl: null };
                try {
                    const paths = [r.post.storagePath];
                    if (r.post.selfieStoragePath) paths.push(r.post.selfieStoragePath);
                    const signedUrls = await Promise.all(
                        paths.map((p) => getSignedUrl(r2, new GetObjectCommand({ Bucket: process.env.R2_POST_BUCKET, Key: p }), { expiresIn: 3600 }))
                    );
                    return {
                        ...r,
                        postImageUrl: signedUrls[0] ?? null,
                        postSelfieUrl: signedUrls[1] ?? null,
                    };
                } catch {
                    return { ...r, postImageUrl: null, postSelfieUrl: null };
                }
            })
        );

        res.json(withUrls);
    } catch (error) {
        res.status(500).json({ message: "Could not load reports", error: error.message });
    }
});

// PUT /admin/reports/:id — update report status
adminRouter.put("/reports/:id", async (req, res) => {
    try {
        const { status } = req.body;
        if (!["pending", "reviewed", "dismissed"].includes(status)) {
            return res.status(400).json({ message: "Invalid status" });
        }
        const report = await Report.findByIdAndUpdate(
            req.params.id,
            { status },
            { new: true }
        );
        if (!report) return res.status(404).json({ message: "Report not found" });
        res.json(report);
    } catch (error) {
        res.status(500).json({ message: "Could not update report", error: error.message });
    }
});

// DELETE /admin/reports/:id — delete a report record
adminRouter.delete("/reports/:id", async (req, res) => {
    try {
        const report = await Report.findByIdAndDelete(req.params.id);
        if (!report) return res.status(404).json({ message: "Report not found" });
        res.json({ message: "Report deleted" });
    } catch (error) {
        res.status(500).json({ message: "Could not delete report", error: error.message });
    }
});

// DELETE /admin/posts/:postId — admin force-delete any post
adminRouter.delete("/posts/:postId", async (req, res) => {
    try {
        const post = await Post.findById(req.params.postId);
        if (!post) return res.status(404).json({ message: "Post not found" });

        const pathsToDelete = [post.storagePath];
        if (post.selfieStoragePath) pathsToDelete.push(post.selfieStoragePath);

        await r2.send(new DeleteObjectsCommand({
            Bucket: process.env.R2_POST_BUCKET,
            Delete: { Objects: pathsToDelete.map((Key) => ({ Key })), Quiet: true },
        }));

        const commentIds = await Comment.find({ post: post._id }).distinct("_id");
        await Promise.all([
            post.deleteOne(),
            Like.deleteMany({ post: post._id }),
            PostReaction.deleteMany({ post: post._id }),
            Comment.deleteMany({ post: post._id }),
            CommentReaction.deleteMany({ comment: { $in: commentIds } }),
            Report.updateMany({ post: post._id }, { status: "reviewed" }),
        ]);

        res.json({ message: "Post deleted by admin" });
    } catch (error) {
        res.status(500).json({ message: "Could not delete post", error: error.message });
    }
});

module.exports = { reportRouter, adminRouter };
