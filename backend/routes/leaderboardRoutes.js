const express = require('express');
const Post = require('../models/Post');
const PostReaction = require('../models/PostReaction');
const Friend = require('../models/Friend');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

async function getFriendIds(userId) {
  const friendships = await Friend.find({
    $or: [{ requester: userId }, { recipient: userId }],
    status: 'accepted',
  }).select('requester recipient');
  return friendships.map(f =>
    f.requester.toString() === userId.toString() ? f.recipient : f.requester
  );
}

function computeRankMap(items, field) {
  const sorted = [...items].sort((a, b) => (b[field] || 0) - (a[field] || 0));
  const map = {};
  sorted.forEach((item, i) => { map[item.userId] = i + 1; });
  return map;
}

async function buildEntries(userIds, callerId) {
  const now = new Date();
  const weekAgo   = new Date(now - 7  * 24 * 60 * 60 * 1000);
  const twoWeeksAgo = new Date(now - 14 * 24 * 60 * 60 * 1000);
  const monthAgo  = new Date(now - 30 * 24 * 60 * 60 * 1000);

  // All-time pints (total post count per user)
  const allTimeAgg = await Post.aggregate([
    { $match: { user: { $in: userIds } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const pintsMap = {};
  for (const a of allTimeAgg) pintsMap[a._id.toString()] = a.count;

  // Previous period pints (posts before last 30 days) for rank-change calc
  const prevPintsAgg = await Post.aggregate([
    { $match: { user: { $in: userIds }, createdAt: { $lt: monthAgo } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const prevPintsMap = {};
  for (const a of prevPintsAgg) prevPintsMap[a._id.toString()] = a.count;

  // CheersWk: reactions received on posts created this week
  const thisWeekPosts = await Post.find({ user: { $in: userIds }, createdAt: { $gte: weekAgo } }).select('_id user');
  const thisPostToUser = {};
  for (const p of thisWeekPosts) thisPostToUser[p._id.toString()] = p.user.toString();
  const thisReactions = await PostReaction.find({ post: { $in: thisWeekPosts.map(p => p._id) } }).select('post');
  const cheersWkMap = {};
  for (const r of thisReactions) {
    const uid = thisPostToUser[r.post.toString()];
    if (uid) cheersWkMap[uid] = (cheersWkMap[uid] || 0) + 1;
  }

  // Previous-week reactions for rank-change calc
  const prevWeekPosts = await Post.find({ user: { $in: userIds }, createdAt: { $gte: twoWeeksAgo, $lt: weekAgo } }).select('_id user');
  const prevPostToUser = {};
  for (const p of prevWeekPosts) prevPostToUser[p._id.toString()] = p.user.toString();
  const prevReactions = await PostReaction.find({ post: { $in: prevWeekPosts.map(p => p._id) } }).select('post');
  const prevCheersMap = {};
  for (const r of prevReactions) {
    const uid = prevPostToUser[r.post.toString()];
    if (uid) prevCheersMap[uid] = (prevCheersMap[uid] || 0) + 1;
  }

  const users = await User.find({ _id: { $in: userIds } }).select('username avatarUrl');

  const raw = users.map(u => ({
    userId: u._id.toString(),
    username: u.username,
    avatarUrl: u.avatarUrl || null,
    pints: pintsMap[u._id.toString()] || 0,
    prevPints: prevPintsMap[u._id.toString()] || 0,
    cheersWk: cheersWkMap[u._id.toString()] || 0,
    prevCheersWk: prevCheersMap[u._id.toString()] || 0,
    isYou: u._id.toString() === callerId.toString(),
  }));

  const currentPintsRanks  = computeRankMap(raw, 'pints');
  const prevPintsRanks     = computeRankMap(raw.map(e => ({ userId: e.userId, pints: e.prevPints })), 'pints');
  const currentCheersRanks = computeRankMap(raw, 'cheersWk');
  const prevCheersRanks    = computeRankMap(raw.map(e => ({ userId: e.userId, cheersWk: e.prevCheersWk })), 'cheersWk');

  return raw.map(e => ({
    userId: e.userId,
    username: e.username,
    avatarUrl: e.avatarUrl,
    pints: e.pints,
    cheersWk: e.cheersWk,
    pintMove:   (prevPintsRanks[e.userId]  || raw.length) - (currentPintsRanks[e.userId]  || raw.length),
    cheersMove: (prevCheersRanks[e.userId] || raw.length) - (currentCheersRanks[e.userId] || raw.length),
    isNew: e.prevPints === 0 && e.pints > 0,
    isYou: e.isYou,
  }));
}

// GET /leaderboard/friends  —  caller + accepted friends
router.get('/friends', authMiddleware, async (req, res) => {
  try {
    const userId = req.user._id;
    const friendIds = await getFriendIds(userId);
    const userIds = [...friendIds, userId];
    const entries = await buildEntries(userIds, userId);
    res.json({ entries });
  } catch (error) {
    res.status(500).json({ message: 'Could not fetch leaderboard', error: error.message });
  }
});

// GET /leaderboard/global  —  top 50 globally + caller's rank
router.get('/global', authMiddleware, async (req, res) => {
  try {
    const userId = req.user._id;

    const topAgg = await Post.aggregate([
      { $group: { _id: '$user', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 50 },
    ]);
    const topUserIds = topAgg.map(a => a._id);

    // Always include the caller so their isYou flag is set
    const callerInTop = topUserIds.some(id => id.toString() === userId.toString());
    const queryIds = callerInTop ? topUserIds : [...topUserIds, userId];

    const allEntries = await buildEntries(queryIds, userId);

    // Expose only the top-50 entries in the response (caller may be extra)
    const topIdSet = new Set(topUserIds.map(id => id.toString()));
    const entries = allEntries.filter(e => topIdSet.has(e.userId));

    // Caller's global rank by all-time pints
    const yourPints = allEntries.find(e => e.isYou)?.pints ?? 0;
    const aboveResult = await Post.aggregate([
      { $group: { _id: '$user', count: { $sum: 1 } } },
      { $match: { count: { $gt: yourPints } } },
      { $count: 'total' },
    ]);
    const yourRank = (aboveResult[0]?.total ?? 0) + 1;
    const totalUsers = await User.countDocuments();
    const pct = totalUsers > 0 ? Math.ceil((yourRank / totalUsers) * 100) : 100;
    const yourPercentile = `top ${pct}%`;

    res.json({ entries, yourRank, yourPercentile, totalUsers });
  } catch (error) {
    res.status(500).json({ message: 'Could not fetch global leaderboard', error: error.message });
  }
});

module.exports = router;
