const express = require("express");
const { v4: uuidv4 } = require("uuid");

const Post = require("../models/Post");
const Friend = require("../models/Friend");
const Like = require("../models/Like");
const PostReaction = require("../models/PostReaction");
const Comment = require("../models/Comment");
const CommentReaction = require("../models/CommentReaction");
const AppNotification = require("../models/AppNotification");
const r2 = require("../config/r2");
const { PutObjectCommand, DeleteObjectsCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const upload = require("../middleware/uploadMiddleware");
const authMiddleware = require("../middleware/authMiddleware");
const { sendToUsers, sendToUser, saveNotification, saveNotifications } = require("../services/notificationService");
const { getFriendIds } = require("../utils/friends");
const Block = require("../models/Block");
const User = require("../models/User");
const { buildBingoCardForUser } = require("../utils/bingo");
const { getBerlinOffsetMinutes, localDayStart, toGermanLocalIso } = require("../utils/localTime");

const router = express.Router();
const ALLOWED_REACTIONS = new Set(["🍺", "🔥", "😍", "💀", "😂"]);

function getFileExtension(filename) {
    return filename.split(".").pop().toLowerCase();
}

async function createSignedPostUrl(storagePath) {
    return getSignedUrl(
        r2,
        new GetObjectCommand({ Bucket: process.env.R2_POST_BUCKET, Key: storagePath }),
        { expiresIn: 3600 }
    );
}

async function getLikedSet(userId, postIds) {
    const likes = await Like.find({ user: userId, post: { $in: postIds } }).select("post");
    return new Set(likes.map((l) => l.post.toString()));
}

async function getReactionData(userId, postIds) {
    const allReactions = await PostReaction.find({ post: { $in: postIds } });
    const map = {};
    for (const p of postIds) {
        map[p.toString()] = { myReaction: null, counts: {} };
    }
    for (const r of allReactions) {
        const pid = r.post.toString();
        if (!map[pid]) continue;
        map[pid].counts[r.emoji] = (map[pid].counts[r.emoji] || 0) + 1;
        if (r.user.toString() === userId.toString()) {
            map[pid].myReaction = r.emoji;
        }
    }
    for (const pid of Object.keys(map)) {
        map[pid].reactions = Object.entries(map[pid].counts)
            .map(([emoji, count]) => ({ emoji, count }));
        delete map[pid].counts;
    }
    return map;
}

function formatPost(post, imageUrl, selfieUrl, likedByMe = false, myReaction = null, reactions = []) {
    const result = {
        id: post._id,
        user: post.user,
        caption: post.caption,
        drink: post.drink ?? {},
        rating: post.rating ?? null,
        stats: post.stats,
        imageUrl,
        imagePath: post.storagePath,
        selfieUrl,
        selfiePath: post.selfieStoragePath,
        likedByMe,
        myReaction,
        reactions,
        createdAt: toGermanLocalIso(post.createdAt),
    };
    if (post.location && post.location.coordinates && post.location.coordinates.length === 2) {
        result.lat = post.location.coordinates[1];
        result.lng = post.location.coordinates[0];
    }
    if (post.country) result.country = post.country;
    return result;
}

async function formatPostWithUrls(post, likedSet, reactionDataMap) {
    const [imageUrl, selfieUrl] = await Promise.all([
        createSignedPostUrl(post.storagePath),
        post.selfieStoragePath ? createSignedPostUrl(post.selfieStoragePath) : Promise.resolve(null),
    ]);
    const pid = post._id.toString();
    const rd = reactionDataMap?.[pid] ?? { myReaction: null, reactions: [] };
    return formatPost(post, imageUrl, selfieUrl, likedSet.has(pid), rd.myReaction, rd.reactions);
}

async function checkBingoAfterPost(userId, username, avatarUrl, avatarColor, avatarInitial) {
    try {
        const card = await buildBingoCardForUser(userId);
        const now = new Date();
        const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        const user = await User.findById(userId).select('bingoLineCount bingoThisMonth');
        const prevLines = user.bingoThisMonth?.month === monthKey ? (user.bingoThisMonth.lines || 0) : 0;
        const delta = card.completedLines - prevLines;

        if (delta > 0) {
            await User.findByIdAndUpdate(userId, {
                $inc: { bingoLineCount: delta },
                bingoThisMonth: { month: monthKey, lines: card.completedLines },
            });

            const friendIds = await getFriendIds(userId);
            if (friendIds.length > 0) {
                const body = delta === 1 ? 'hat eine Bingo-Zeile komplett! 🎰' : `hat ${delta} neue Bingo-Zeilen! 🎰`;
                sendToUsers(friendIds, {
                    title: `@${username}`,
                    body,
                    data: { type: 'bingo_line' },
                });
                saveNotifications(friendIds, {
                    type: 'bingo_line',
                    actorId: userId,
                    actorUsername: username,
                    actorAvatarUrl: avatarUrl ?? null,
                    actorAvatarColor: avatarColor ?? null,
                    actorAvatarInitial: avatarInitial ?? null,
                });
            }
        } else if (user.bingoThisMonth?.month !== monthKey) {
            await User.findByIdAndUpdate(userId, {
                bingoThisMonth: { month: monthKey, lines: card.completedLines },
            });
        }
    } catch (err) {
        console.error('Bingo check after post failed:', err.message);
    }
}

// POST /posts/upload
router.post(
    "/upload",
    authMiddleware,
    upload.fields([
        { name: "image", maxCount: 1 },
        { name: "selfie", maxCount: 1 },
    ]),
    async (req, res) => {
        try {
            const { caption, lat, lng, country, drinkName, drinkEmoji, rating } = req.body;
            const imageFile = req.files?.["image"]?.[0];
            const selfieFile = req.files?.["selfie"]?.[0];

            if (!imageFile) {
                return res.status(400).json({ message: "No post image uploaded" });
            }
            if (!selfieFile) {
                return res.status(400).json({ message: "No selfie image uploaded" });
            }

            const imageExt = getFileExtension(imageFile.originalname);
            const selfieExt = getFileExtension(selfieFile.originalname);
            const storagePath = `${req.user._id}/${uuidv4()}.${imageExt}`;
            const selfieStoragePath = `${req.user._id}/selfie_${uuidv4()}.${selfieExt}`;

            try {
                await Promise.all([
                    r2.send(new PutObjectCommand({
                        Bucket: process.env.R2_POST_BUCKET,
                        Key: storagePath,
                        Body: imageFile.buffer,
                        ContentType: imageFile.mimetype,
                    })),
                    r2.send(new PutObjectCommand({
                        Bucket: process.env.R2_POST_BUCKET,
                        Key: selfieStoragePath,
                        Body: selfieFile.buffer,
                        ContentType: selfieFile.mimetype,
                    })),
                ]);
            } catch (uploadErr) {
                await r2.send(new DeleteObjectsCommand({
                    Bucket: process.env.R2_POST_BUCKET,
                    Delete: { Objects: [{ Key: storagePath }, { Key: selfieStoragePath }], Quiet: true },
                })).catch(() => { });
                return res.status(500).json({ message: "Image upload failed", error: uploadErr.message });
            }

            const parsedLat = parseFloat(lat);
            const parsedLng = parseFloat(lng);
            const hasLocation = !isNaN(parsedLat) && !isNaN(parsedLng);
            if (hasLocation && (parsedLat < -90 || parsedLat > 90 || parsedLng < -180 || parsedLng > 180)) {
                return res.status(400).json({ message: "Invalid coordinates: lat must be -90..90, lng must be -180..180" });
            }
            const parsedRating = Number.parseInt(rating, 10);
            const hasRating = rating !== undefined && rating !== null && rating !== "";
            if (hasRating && (!Number.isInteger(parsedRating) || parsedRating < 1 || parsedRating > 5)) {
                return res.status(400).json({ message: "Rating must be between 1 and 5" });
            }

            const post = await Post.create({
                user: req.user._id,
                caption: caption || "",
                storagePath,
                selfieStoragePath,
                rating: hasRating ? parsedRating : null,
                country: country?.trim() || null,
                drink: {
                    name: drinkName?.trim() || "",
                    emoji: drinkEmoji?.trim() || "",
                },
                ...(hasLocation && {
                    location: {
                        type: "Point",
                        coordinates: [parsedLng, parsedLat],
                    },
                }),
            });

            await post.populate("user", "username avatarUrl avatarColor avatarInitial");

            const [imageUrl, selfieUrl] = await Promise.all([
                createSignedPostUrl(storagePath),
                createSignedPostUrl(selfieStoragePath),
            ]);

            res.status(201).json({
                message: "Post uploaded successfully",
                post: formatPost(post, imageUrl, selfieUrl, false),
            });

            // Fan-out to friends (fire and forget — after response is sent)
            const actorUsername = req.user.username;
            const actorAvatarUrl = req.user.avatarUrl ?? null;
            const actorAvatarColor = req.user.avatarColor ?? null;
            const actorAvatarInitial = req.user.avatarInitial ?? null;

            checkBingoAfterPost(req.user._id, actorUsername, actorAvatarUrl, actorAvatarColor, actorAvatarInitial).catch(() => { });
            const postId = post._id.toString();
            getFriendIds(req.user._id).then(async (friendIds) => {
                if (!friendIds.length) return;

                sendToUsers(friendIds, {
                    title: `@${actorUsername} 🍺`,
                    body: "hat gerade gezapft!",
                    data: { type: "post", postId },
                });
                saveNotifications(friendIds, {
                    type: 'poured',
                    actorId: req.user._id,
                    actorUsername,
                    actorAvatarUrl,
                    actorAvatarColor,
                    actorAvatarInitial,
                    postId: post._id,
                    postThumbPath: storagePath,
                });

                // If 4+ friends have posted today, nudge the ones who haven't yet
                const todayStart = localDayStart(new Date(), getBerlinOffsetMinutes());

                const friendsWhoPostedToday = await Post.find({
                    user: { $in: friendIds },
                    createdAt: { $gte: todayStart },
                }).distinct("user");

                if (friendsWhoPostedToday.length >= 4) {
                    const postedSet = new Set(friendsWhoPostedToday.map(String));
                    const unpostedFriendIds = friendIds.filter((id) => !postedSet.has(id.toString()));

                    if (unpostedFriendIds.length > 0) {
                        const alreadyNotified = await AppNotification.find({
                            recipient: { $in: unpostedFriendIds },
                            type: "group_active",
                            createdAt: { $gte: todayStart },
                        }).distinct("recipient");

                        const alreadyNotifiedSet = new Set(alreadyNotified.map(String));
                        const toNotify = unpostedFriendIds.filter((id) => !alreadyNotifiedSet.has(id.toString()));

                        if (toNotify.length > 0) {
                            sendToUsers(toNotify, {
                                title: "🍺 Deine Crew zapft!",
                                body: `${friendsWhoPostedToday.length} deiner Freunde haben heute schon gezapft!`,
                                data: { type: "group_active" },
                            });
                            saveNotifications(toNotify, {
                                type: "group_active",
                                actorId: req.user._id,
                                actorUsername,
                                actorAvatarUrl,
                                actorAvatarColor,
                                actorAvatarInitial,
                                mutualCount: friendsWhoPostedToday.length,
                            });
                        }
                    }
                }
            }).catch((err) => console.error("Post fan-out failed:", err.message));
        } catch (error) {
            res.status(500).json({ message: "Post upload failed", error: error.message });
        }
    }
);

// GET /posts  —  feed: own posts + friends' posts, newest first
router.get("/", authMiddleware, async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 10));

        const [friendIds, blockedByMe, blockedMe] = await Promise.all([
            getFriendIds(req.user._id),
            Block.find({ blocker: req.user._id }).distinct("blocked"),
            Block.find({ blocked: req.user._id }).distinct("blocker"),
        ]);

        const hiddenUserIds = [...new Set([...blockedByMe.map(String), ...blockedMe.map(String)])];

        const posts = await Post.find({
            user: { $in: [...friendIds, req.user._id], $nin: hiddenUserIds },
        })
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit + 1)
            .populate("user", "username avatarUrl avatarColor avatarInitial");

        const hasMore = posts.length > limit;
        const pagePosts = hasMore ? posts.slice(0, limit) : posts;

        const postIds = pagePosts.map((p) => p._id);
        const [likedSet, reactionDataMap] = await Promise.all([
            getLikedSet(req.user._id, postIds),
            getReactionData(req.user._id, postIds),
        ]);

        const postsWithUrls = await Promise.all(
            pagePosts.map((post) => formatPostWithUrls(post, likedSet, reactionDataMap))
        );

        const activeSince = new Date(Date.now() - 2 * 60 * 60 * 1000);
        const activeUserIds = await Post.find({
            user: { $in: [...friendIds, req.user._id] },
            createdAt: { $gte: activeSince },
        }).distinct("user");
        const activeSet = new Set(activeUserIds.map(String));

        res.json({
            posts: postsWithUrls.map((post) => {
                const user = post.user.toObject?.() ?? post.user;
                return {
                    ...post,
                    user: {
                        ...user,
                        drinkingNow: activeSet.has((user._id ?? user.id).toString()),
                    },
                };
            }),
            hasMore,
        });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch feed", error: error.message });
    }
});

// GET /posts/me  —  current user's own posts
router.get("/me", authMiddleware, async (req, res) => {
    try {
        const posts = await Post.find({ user: req.user._id })
            .sort({ createdAt: -1 })
            .populate("user", "username avatarUrl avatarColor avatarInitial");

        const postIds = posts.map((p) => p._id);
        const [likedSet, reactionDataMap] = await Promise.all([
            getLikedSet(req.user._id, postIds),
            getReactionData(req.user._id, postIds),
        ]);

        const postsWithUrls = await Promise.all(
            posts.map((post) => formatPostWithUrls(post, likedSet, reactionDataMap))
        );

        res.json({ posts: postsWithUrls });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch your posts", error: error.message });
    }
});

// GET /posts/user/:userId  —  posts by a specific user (must be a friend)
router.get("/user/:userId", authMiddleware, async (req, res) => {
    try {
        const targetId = req.params.userId;
        const meId = req.user._id.toString();

        if (targetId === meId) {
            return res.redirect("/posts/me");
        }

        const friendship = await Friend.findOne({
            $or: [
                { requester: meId, recipient: targetId },
                { requester: targetId, recipient: meId },
            ],
            status: "accepted",
        });

        if (!friendship) {
            return res.status(403).json({ message: "You can only view posts of your friends" });
        }

        const posts = await Post.find({ user: targetId })
            .sort({ createdAt: -1 })
            .populate("user", "username avatarUrl avatarColor avatarInitial");

        const postIds = posts.map((p) => p._id);
        const [likedSet, reactionDataMap] = await Promise.all([
            getLikedSet(req.user._id, postIds),
            getReactionData(req.user._id, postIds),
        ]);

        const postsWithUrls = await Promise.all(
            posts.map((post) => formatPostWithUrls(post, likedSet, reactionDataMap))
        );

        res.json({ posts: postsWithUrls });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch posts", error: error.message });
    }
});

// GET /posts/map  —  friends' posts that have location, newest first (last 30 days)
router.get("/map", authMiddleware, async (req, res) => {
    try {
        const [friendIds, blockedByMe, blockedMe] = await Promise.all([
            getFriendIds(req.user._id),
            Block.find({ blocker: req.user._id }).distinct("blocked"),
            Block.find({ blocked: req.user._id }).distinct("blocker"),
        ]);

        const hiddenUserIds = [...new Set([...blockedByMe.map(String), ...blockedMe.map(String)])];
        const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

        const posts = await Post.find({
            user: { $in: [...friendIds, req.user._id], $nin: hiddenUserIds },
            "location.coordinates": { $exists: true },
            createdAt: { $gte: since },
        })
            .sort({ createdAt: -1 })
            .limit(200)
            .populate("user", "username avatarUrl avatarColor avatarInitial");

        const postIds = posts.map((p) => p._id);
        const [likedSet, reactionDataMap] = await Promise.all([
            getLikedSet(req.user._id, postIds),
            getReactionData(req.user._id, postIds),
        ]);

        const postsWithUrls = await Promise.all(
            posts.map((post) => formatPostWithUrls(post, likedSet, reactionDataMap))
        );

        res.json({ posts: postsWithUrls });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch map posts", error: error.message });
    }
});

// POST /posts/:id/like  —  toggle like/unlike
router.post("/:id/like", authMiddleware, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id).select("_id stats.likes");
        if (!post) return res.status(404).json({ message: "Post not found" });

        const existing = await Like.findOne({ user: req.user._id, post: post._id });
        let liked;
        let updated;
        if (existing) {
            await existing.deleteOne();
            updated = await Post.findByIdAndUpdate(
                post._id,
                { $inc: { "stats.likes": -1 } },
                { new: true, select: "stats.likes" }
            );
            liked = false;
        } else {
            await Like.create({ user: req.user._id, post: post._id });
            updated = await Post.findByIdAndUpdate(
                post._id,
                { $inc: { "stats.likes": 1 } },
                { new: true, select: "stats.likes" }
            );
            liked = true;
        }

        res.json({ liked, likes: Math.max(0, updated.stats.likes) });
    } catch (error) {
        res.status(500).json({ message: "Could not toggle like", error: error.message });
    }
});

// GET /posts/:id/reactions  —  list who reacted and with which emoji
router.get("/:id/reactions", authMiddleware, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id).select("user");
        if (!post) return res.status(404).json({ message: "Post not found" });

        const viewerId = req.user._id.toString();
        const ownerId = post.user.toString();

        if (viewerId !== ownerId) {
            const friendship = await Friend.findOne({
                $or: [
                    { requester: viewerId, recipient: ownerId, status: "accepted" },
                    { requester: ownerId, recipient: viewerId, status: "accepted" },
                ],
            });
            if (!friendship) return res.status(403).json({ message: "Access denied" });
        }

        const reactions = await PostReaction.find({ post: post._id })
            .populate("user", "username avatarUrl avatarColor avatarInitial")
            .sort({ createdAt: 1 });

        res.json(reactions.map((r) => ({
            emoji: r.emoji,
            userId: r.user._id,
            username: r.user.username,
            avatarUrl: r.user.avatarUrl ?? null,
            avatarColor: r.user.avatarColor ?? null,
            avatarInitial: r.user.avatarInitial ?? null,
        })));
    } catch (error) {
        res.status(500).json({ message: "Could not fetch reactions", error: error.message });
    }
});

// POST /posts/:id/reactions  —  toggle emoji reaction
router.post("/:id/reactions", authMiddleware, async (req, res) => {
    try {
        const { emoji } = req.body;
        if (!emoji) return res.status(400).json({ message: "emoji is required" });
        if (!ALLOWED_REACTIONS.has(emoji)) {
            return res.status(400).json({ message: "Unsupported reaction emoji" });
        }

        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });

        const existing = await PostReaction.findOne({ post: post._id, user: req.user._id });
        let myReaction = null;

        if (existing) {
            const oldEmoji = existing.emoji;
            if (oldEmoji === emoji) {
                await existing.deleteOne();
                await Post.findByIdAndUpdate(post._id, { $inc: { "stats.reactions": -1 } });
            } else {
                existing.emoji = emoji;
                await existing.save();
                myReaction = emoji;
            }
        } else {
            await PostReaction.create({ post: post._id, user: req.user._id, emoji });
            await Post.findByIdAndUpdate(post._id, { $inc: { "stats.reactions": 1 } });
            myReaction = emoji;
        }
        const updatedPost = await Post.findById(post._id).select("stats.reactions user");

        const allReactions = await PostReaction.find({ post: post._id });
        const counts = {};
        for (const r of allReactions) {
            counts[r.emoji] = (counts[r.emoji] || 0) + 1;
        }
        const reactions = Object.entries(counts).map(([e, count]) => ({ emoji: e, count }));

        res.json({ myReaction, reactions, totalReactions: Math.max(0, updatedPost.stats.reactions || 0) });

        // Notify post owner on first-ever reaction from this user — skip if they already got one
        if (myReaction !== null && updatedPost.user.toString() !== req.user._id.toString()) {
            AppNotification.findOne({ type: 'cheers', actorId: req.user._id, postId: updatedPost._id }).then((already) => {
                if (already) return;
                sendToUser(updatedPost.user, {
                    title: `@${req.user.username} ${myReaction}`,
                    body: "hat auf deinen Beitrag reagiert",
                    data: { type: "post", postId: updatedPost._id.toString() },
                }).catch(() => { });
                saveNotification(updatedPost.user, {
                    type: 'cheers',
                    actorId: req.user._id,
                    actorUsername: req.user.username,
                    actorAvatarUrl: req.user.avatarUrl ?? null,
                    actorAvatarColor: req.user.avatarColor ?? null,
                    actorAvatarInitial: req.user.avatarInitial ?? null,
                    postId: updatedPost._id,
                    postThumbPath: post.storagePath ?? null,
                }).catch(() => { });
            }).catch(() => { });
        }
    } catch (error) {
        res.status(500).json({ message: "Could not toggle reaction", error: error.message });
    }
});

// GET /posts/:id  —  single post (must be own or friend's)
router.get("/:id", authMiddleware, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id).populate("user", "username avatarUrl avatarColor avatarInitial");

        if (!post) {
            return res.status(404).json({ message: "Post not found" });
        }

        const meId = req.user._id.toString();
        const postOwnerId = post.user._id.toString();

        if (postOwnerId !== meId) {
            const friendship = await Friend.findOne({
                $or: [
                    { requester: meId, recipient: postOwnerId },
                    { requester: postOwnerId, recipient: meId },
                ],
                status: "accepted",
            });

            if (!friendship) {
                return res.status(403).json({ message: "You can only view posts of your friends" });
            }
        }

        const [likedSet, reactionDataMap] = await Promise.all([
            getLikedSet(req.user._id, [post._id]),
            getReactionData(req.user._id, [post._id]),
        ]);
        const formatted = await formatPostWithUrls(post, likedSet, reactionDataMap);

        res.json({ post: formatted });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch post", error: error.message });
    }
});

// POST /posts/:id/view  —  increment view count (viewer must be owner or friend)
router.post("/:id/view", authMiddleware, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id).select("user stats.views");
        if (!post) return res.status(404).json({ message: "Post not found" });

        if (post.user.toString() !== req.user._id.toString()) {
            const friendship = await Friend.findOne({
                $or: [
                    { requester: req.user._id, recipient: post.user },
                    { requester: post.user, recipient: req.user._id },
                ],
                status: "accepted",
            });
            if (!friendship) return res.status(403).json({ message: "Access denied" });
        }

        const updated = await Post.findByIdAndUpdate(
            post._id,
            { $inc: { "stats.views": 1 } },
            { new: true, select: "stats.views" }
        );
        res.json({ views: updated.stats.views });
    } catch (error) {
        res.status(500).json({ message: "Could not record view", error: error.message });
    }
});

// DELETE /posts/:id  —  delete own post
router.delete("/:id", authMiddleware, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);

        if (!post) {
            return res.status(404).json({ message: "Post not found" });
        }

        if (post.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: "You are not allowed to delete this post" });
        }

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
        ]);

        res.json({ message: "Post deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: "Could not delete post", error: error.message });
    }
});

module.exports = router;
