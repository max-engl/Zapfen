const express = require("express");
const archiver = require("archiver");
const bcrypt = require("bcrypt");
const { Resend } = require("resend");
const Post = require("../models/Post");
const Report = require("../models/Report");
const User = require("../models/User");
const Like = require("../models/Like");
const Comment = require("../models/Comment");
const PostReaction = require("../models/PostReaction");
const CommentReaction = require("../models/CommentReaction");
const Friend = require("../models/Friend");
const Block = require("../models/Block");
const AppNotification = require("../models/AppNotification");
const Drink = require("../models/Drink");
const DeletionRequest = require("../models/DeletionRequest");
const r2 = require("../config/r2");
const { DeleteObjectsCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const authMiddleware = require("../middleware/authMiddleware");
const adminMiddleware = require("../middleware/adminMiddleware");
const { sendToUsers } = require("../services/notificationService");

async function sendReportNotificationEmail(report, reporter, post) {
    const resend = new Resend(process.env.RESEND_API_KEY);
    const adminUrl = `${process.env.BASE_URL}/admin#reports`;
    const reportedUser = await require("../models/User").findById(post.user).select("username").lean();
    const reportedUsername = reportedUser?.username ?? post.user.toString();
    const reporterUsername = reporter.username ?? reporter._id.toString();
    const createdAt = new Date(report.createdAt).toLocaleString("de-DE", { timeZone: "Europe/Berlin" });

    await resend.emails.send({
        from: "Zapfen <noreply@zapfenapp.de>",
        to: "engl.devmail@gmail.com",
        subject: `🚩 Neuer Report von @${reporterUsername}`,
        html: `<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Neuer Report – Zapfen Admin</title>
</head>
<body style="margin:0;padding:0;background:#0F0F0F;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0F0F0F;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#1A1A1A;border-radius:24px;border:1px solid #2A2A2A;overflow:hidden;">
          <tr>
            <td style="padding:36px 36px 0;text-align:center;">
              <div style="display:inline-block;background:#C0392B;border-radius:18px;width:52px;height:52px;line-height:52px;font-size:28px;text-align:center;">🚩</div>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 36px 8px;text-align:center;">
              <div style="color:#FFFFFF;font-size:22px;font-weight:800;letter-spacing:-0.5px;">Neuer Report eingegangen</div>
              <div style="color:#888;font-size:13px;margin-top:6px;">${createdAt}</div>
            </td>
          </tr>
          <tr>
            <td style="padding:24px 36px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background:#242424;border-radius:14px;border:1px solid #2A2A2A;">
                <tr>
                  <td style="padding:16px 20px;border-bottom:1px solid #2A2A2A;">
                    <div style="color:#888;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Gemeldet von</div>
                    <div style="color:#FFF;font-size:15px;font-weight:600;">@${reporterUsername}</div>
                  </td>
                </tr>
                <tr>
                  <td style="padding:16px 20px;border-bottom:1px solid #2A2A2A;">
                    <div style="color:#888;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Gemeldeter Nutzer</div>
                    <div style="color:#FFF;font-size:15px;font-weight:600;">@${reportedUsername}</div>
                  </td>
                </tr>
                <tr>
                  <td style="padding:16px 20px;border-bottom:1px solid #2A2A2A;">
                    <div style="color:#888;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Post-ID</div>
                    <div style="color:#AAA;font-size:13px;font-family:monospace;">${post._id}</div>
                  </td>
                </tr>
                <tr>
                  <td style="padding:16px 20px;">
                    <div style="color:#888;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Grund</div>
                    <div style="color:#FFF;font-size:15px;line-height:1.5;">${report.reason.replace(/</g, "&lt;").replace(/>/g, "&gt;")}</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:0 36px 36px;text-align:center;">
              <a href="${adminUrl}" style="display:inline-block;background:#F6B733;color:#1A1A1A;font-weight:800;font-size:15px;text-decoration:none;padding:14px 32px;border-radius:14px;letter-spacing:-0.2px;">Im Admin-Panel ansehen →</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    });
}

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

        // Fire-and-forget — don't block the response on email delivery
        sendReportNotificationEmail(report, req.user, post).catch(err =>
            console.error("[report] email error:", err.message)
        );

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

        const [totalUsers, totalPosts, pendingReports, pendingDeletions, users] = await Promise.all([
            User.countDocuments(),
            Post.countDocuments(),
            Report.countDocuments({ status: "pending" }),
            DeletionRequest.countDocuments({ status: "pending" }),
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

        res.json({ totalUsers, totalPosts, pendingReports, pendingDeletions, users: usersWithCounts, page, limit });
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

// GET /admin/users/:userId/export — stream all photos + selfies as a ZIP
adminRouter.get("/users/:userId/export", async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).select("username").lean();
        if (!user) return res.status(404).json({ message: "User not found" });

        const posts = await Post.find({ user: req.params.userId })
            .select("storagePath selfieStoragePath createdAt")
            .sort({ createdAt: 1 })
            .lean();

        const safeUsername = (user.username || req.params.userId).replace(/[^a-z0-9_-]/gi, "_");
        res.setHeader("Content-Type", "application/zip");
        res.setHeader("Content-Disposition", `attachment; filename="${safeUsername}_photos.zip"`);

        const archive = archiver("zip", { zlib: { level: 1 } });
        archive.on("error", (err) => { if (!res.headersSent) res.status(500).end(); console.error("ZIP error:", err); });
        archive.pipe(res);

        for (let i = 0; i < posts.length; i++) {
            const post = posts[i];
            const dateStr = new Date(post.createdAt).toISOString().slice(0, 10);
            const n = String(i + 1).padStart(3, "0");
            const ext = (s) => (s?.split(".").pop()?.split("?")[0] || "jpg").toLowerCase();

            const photoRes = await r2.send(new GetObjectCommand({ Bucket: process.env.R2_POST_BUCKET, Key: post.storagePath }));
            archive.append(photoRes.Body, { name: `${n}_${dateStr}_photo.${ext(post.storagePath)}` });

            if (post.selfieStoragePath) {
                const selfieRes = await r2.send(new GetObjectCommand({ Bucket: process.env.R2_POST_BUCKET, Key: post.selfieStoragePath }));
                archive.append(selfieRes.Body, { name: `${n}_${dateStr}_selfie.${ext(post.selfieStoragePath)}` });
            }
        }

        await archive.finalize();
    } catch (error) {
        if (!res.headersSent) res.status(500).json({ message: "Export failed", error: error.message });
    }
});

// ── User deletion helper ────────────────────────────────────────────────────

async function deleteUserAccount(userId) {
    const userPosts = await Post.find({ user: userId }).select("storagePath selfieStoragePath").lean();
    const postIds = userPosts.map(p => p._id);

    if (userPosts.length > 0) {
        const pathsToDelete = [];
        for (const post of userPosts) {
            if (post.storagePath) pathsToDelete.push(post.storagePath);
            if (post.selfieStoragePath) pathsToDelete.push(post.selfieStoragePath);
        }
        try {
            await r2.send(new DeleteObjectsCommand({
                Bucket: process.env.R2_POST_BUCKET,
                Delete: { Objects: pathsToDelete.map(Key => ({ Key })), Quiet: true },
            }));
        } catch (r2Err) {
            console.error("R2 post deletion error:", r2Err.message);
        }
    }

    const commentIdsOnPosts = postIds.length > 0
        ? await Comment.find({ post: { $in: postIds } }).distinct("_id")
        : [];
    const commentIdsByUser = await Comment.find({ user: userId }).distinct("_id");
    const allCommentIds = [...new Set([
        ...commentIdsOnPosts.map(String),
        ...commentIdsByUser.map(String),
    ])];

    await Promise.all([
        User.deleteOne({ _id: userId }),
        Post.deleteMany({ user: userId }),
        Like.deleteMany({ $or: [{ user: userId }, ...(postIds.length ? [{ post: { $in: postIds } }] : [])] }),
        PostReaction.deleteMany({ $or: [{ user: userId }, ...(postIds.length ? [{ post: { $in: postIds } }] : [])] }),
        Comment.deleteMany({ $or: [{ user: userId }, ...(postIds.length ? [{ post: { $in: postIds } }] : [])] }),
        allCommentIds.length
            ? CommentReaction.deleteMany({ comment: { $in: allCommentIds } })
            : Promise.resolve(),
        Friend.deleteMany({ $or: [{ requester: userId }, { recipient: userId }] }),
        Block.deleteMany({ $or: [{ blocker: userId }, { blocked: userId }] }),
        AppNotification.deleteMany({ $or: [{ recipient: userId }, { actorId: userId }] }),
        Drink.deleteMany({ user: userId }),
        Report.updateMany({ reportedUser: userId }, { status: "reviewed" }),
    ]);
}

// ── Deletion request admin routes ───────────────────────────────────────────

// GET /admin/deletion-requests — list pending requests
adminRouter.get("/deletion-requests", async (req, res) => {
    try {
        const { status } = req.query;
        const filter = status ? { status } : { status: "pending" };
        const requests = await DeletionRequest.find(filter).sort({ createdAt: -1 }).lean();
        res.json(requests);
    } catch (error) {
        res.status(500).json({ message: "Fehler beim Laden der Anfragen", error: error.message });
    }
});

// POST /admin/deletion-requests/:id/execute — delete the user account and mark request done
adminRouter.post("/deletion-requests/:id/execute", async (req, res) => {
    try {
        const request = await DeletionRequest.findById(req.params.id);
        if (!request) return res.status(404).json({ message: "Anfrage nicht gefunden" });
        if (request.status !== "pending") return res.status(400).json({ message: "Anfrage bereits bearbeitet" });

        const user = await User.findOne({ email: request.email });
        if (user) {
            await deleteUserAccount(user._id);
        }

        await DeletionRequest.findByIdAndUpdate(req.params.id, { status: "completed" });
        res.json({ message: "Nutzerkonto gelöscht", userFound: !!user });
    } catch (error) {
        res.status(500).json({ message: "Fehler beim Löschen", error: error.message });
    }
});

// DELETE /admin/deletion-requests/:id — dismiss without deleting user
adminRouter.delete("/deletion-requests/:id", async (req, res) => {
    try {
        const request = await DeletionRequest.findByIdAndUpdate(
            req.params.id,
            { status: "dismissed" },
            { new: true }
        );
        if (!request) return res.status(404).json({ message: "Anfrage nicht gefunden" });
        res.json({ message: "Anfrage abgelehnt" });
    } catch (error) {
        res.status(500).json({ message: "Fehler", error: error.message });
    }
});

// PATCH /admin/users/:userId/password — admin set a user's password directly
adminRouter.patch("/users/:userId/password", async (req, res) => {
    try {
        const { password } = req.body;
        if (!password || password.length < 6) {
            return res.status(400).json({ message: "Passwort muss mindestens 6 Zeichen lang sein" });
        }
        const user = await User.findById(req.params.userId);
        if (!user) return res.status(404).json({ message: "Nutzer nicht gefunden" });
        user.passwordHash = await bcrypt.hash(password, 12);
        await user.save();
        res.json({ message: "Passwort aktualisiert" });
    } catch (error) {
        res.status(500).json({ message: "Fehler beim Aktualisieren des Passworts", error: error.message });
    }
});

// DELETE /admin/users/:userId — admin force-delete a user account
adminRouter.delete("/users/:userId", async (req, res) => {
    try {
        const user = await User.findById(req.params.userId);
        if (!user) return res.status(404).json({ message: "Nutzer nicht gefunden" });
        await deleteUserAccount(user._id);
        res.json({ message: "Nutzerkonto gelöscht" });
    } catch (error) {
        res.status(500).json({ message: "Fehler beim Löschen", error: error.message });
    }
});

// POST /admin/broadcast — send a push notification to all users with an FCM token
adminRouter.post("/broadcast", async (req, res) => {
    try {
        const { title, body } = req.body;
        if (!title?.trim() || !body?.trim()) {
            return res.status(400).json({ message: "Titel und Nachricht sind erforderlich" });
        }
        const recipients = await User.find({ fcmToken: { $exists: true, $ne: null } }).select("_id");
        const recipientIds = recipients.map((u) => u._id);
        if (!recipientIds.length) {
            return res.json({ message: "Keine Empfänger mit aktivierten Benachrichtigungen", sent: 0 });
        }
        sendToUsers(recipientIds, { title: title.trim(), body: body.trim(), data: { type: "broadcast" } })
            .catch((err) => console.error("[broadcast] sendToUsers error:", err.message));
        res.json({ message: "Broadcast gesendet", sent: recipientIds.length });
    } catch (error) {
        res.status(500).json({ message: "Fehler beim Senden", error: error.message });
    }
});

module.exports = { reportRouter, adminRouter };
