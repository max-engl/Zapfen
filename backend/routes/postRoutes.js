const express = require("express");
const { v4: uuidv4 } = require("uuid");

const Post = require("../models/Post");
const Friend = require("../models/Friend");
const Like = require("../models/Like");
const PostReaction = require("../models/PostReaction");
const Comment = require("../models/Comment");
const CommentReaction = require("../models/CommentReaction");
const AppNotification = require("../models/AppNotification");
const supabase = require("../config/supabase");
const upload = require("../middleware/uploadMiddleware");
const authMiddleware = require("../middleware/authMiddleware");
const { sendToUsers, sendToUser, saveNotification, saveNotifications } = require("../services/notificationService");

const router = express.Router();
const ALLOWED_REACTIONS = new Set(["🍺", "🔥", "😍", "💀"]);

function getFileExtension(filename) {
    return filename.split(".").pop().toLowerCase();
}

async function createSignedPostUrl(storagePath) {
    const { data, error } = await supabase.storage
        .from(process.env.SUPABASE_POST_BUCKET)
        .createSignedUrl(storagePath, 60 * 60);

    if (error) {
        throw new Error(error.message);
    }

    return data.signedUrl;
}

async function getFriendIds(userId) {
    const friendships = await Friend.find({
        $or: [{ requester: userId }, { recipient: userId }],
        status: "accepted",
    }).select("requester recipient");

    return friendships.map((f) =>
        f.requester.toString() === userId.toString() ? f.recipient : f.requester
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
        createdAt: post.createdAt,
    };
    if (post.location && post.location.coordinates && post.location.coordinates.length === 2) {
        result.lat = post.location.coordinates[1];
        result.lng = post.location.coordinates[0];
    }
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
            const { caption, lat, lng, drinkName, drinkEmoji, rating } = req.body;
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

            const [{ error: imageUploadError }, { error: selfieUploadError }] = await Promise.all([
                supabase.storage
                    .from(process.env.SUPABASE_POST_BUCKET)
                    .upload(storagePath, imageFile.buffer, {
                        contentType: imageFile.mimetype,
                        upsert: false,
                    }),
                supabase.storage
                    .from(process.env.SUPABASE_POST_BUCKET)
                    .upload(selfieStoragePath, selfieFile.buffer, {
                        contentType: selfieFile.mimetype,
                        upsert: false,
                    }),
            ]);

            if (imageUploadError) {
                return res.status(500).json({
                    message: "Post image upload to Supabase failed",
                    error: imageUploadError.message,
                });
            }
            if (selfieUploadError) {
                await supabase.storage.from(process.env.SUPABASE_POST_BUCKET).remove([storagePath]);
                return res.status(500).json({
                    message: "Selfie upload to Supabase failed",
                    error: selfieUploadError.message,
                });
            }

            const parsedLat = parseFloat(lat);
            const parsedLng = parseFloat(lng);
            const hasLocation = !isNaN(parsedLat) && !isNaN(parsedLng);
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
                drink: {
                    name:  drinkName?.trim()  || "",
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
                const todayStart = new Date();
                todayStart.setUTCHours(0, 0, 0, 0);

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
            }).catch(() => {});
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

        const friendIds = await getFriendIds(req.user._id);

        const posts = await Post.find({ user: { $in: [...friendIds, req.user._id] } })
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
        const friendIds = await getFriendIds(req.user._id);
        const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

        const posts = await Post.find({
            user: { $in: [...friendIds, req.user._id] },
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
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });

        const existing = await Like.findOne({ user: req.user._id, post: post._id });
        let liked;
        if (existing) {
            await existing.deleteOne();
            post.stats.likes = Math.max(0, post.stats.likes - 1);
            liked = false;
        } else {
            await Like.create({ user: req.user._id, post: post._id });
            post.stats.likes += 1;
            liked = true;
        }
        await post.save();

        res.json({ liked, likes: post.stats.likes });
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
                post.stats.reactions = Math.max(0, (post.stats.reactions || 0) - 1);
            } else {
                existing.emoji = emoji;
                await existing.save();
                myReaction = emoji;
            }
        } else {
            await PostReaction.create({ post: post._id, user: req.user._id, emoji });
            post.stats.reactions = (post.stats.reactions || 0) + 1;
            myReaction = emoji;
        }
        await post.save();

        const allReactions = await PostReaction.find({ post: post._id });
        const counts = {};
        for (const r of allReactions) {
            counts[r.emoji] = (counts[r.emoji] || 0) + 1;
        }
        const reactions = Object.entries(counts).map(([e, count]) => ({ emoji: e, count }));

        res.json({ myReaction, reactions, totalReactions: post.stats.reactions || 0 });

        // Notify post owner when a reaction is added or changed (not removed), never self
        if (myReaction !== null && post.user.toString() !== req.user._id.toString()) {
            sendToUser(post.user, {
                title: `@${req.user.username} ${myReaction}`,
                body: "hat auf deinen Beitrag reagiert",
                data: { type: "post", postId: post._id.toString() },
            }).catch(() => {});
            saveNotification(post.user, {
                type: 'cheers',
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

// POST /posts/:id/view  —  increment view count
router.post("/:id/view", authMiddleware, async (req, res) => {
    try {
        const post = await Post.findByIdAndUpdate(
            req.params.id,
            { $inc: { "stats.views": 1 } },
            { new: true, select: "stats.views" }
        );
        if (!post) return res.status(404).json({ message: "Post not found" });
        res.json({ views: post.stats.views });
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

        const { error: deleteError } = await supabase.storage
            .from(process.env.SUPABASE_POST_BUCKET)
            .remove(pathsToDelete);

        if (deleteError) {
            return res.status(500).json({
                message: "Could not delete image(s) from storage",
                error: deleteError.message,
            });
        }

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
