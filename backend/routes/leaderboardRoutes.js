const express = require('express');
const Post = require('../models/Post');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const { getFriendIds } = require('../utils/friends');

const router = express.Router();

function computeRankMap(items, field) {
  const sorted = [...items].sort((a, b) => (b[field] || 0) - (a[field] || 0));
  const map = {};
  sorted.forEach((item, i) => { map[item.userId] = i + 1; });
  return map;
}

async function buildEntries(userIds, callerId) {
  const now = new Date();
  const weekAgo      = new Date(now - 7  * 24 * 60 * 60 * 1000);
  const twoWeeksAgo  = new Date(now - 14 * 24 * 60 * 60 * 1000);
  const monthAgo     = new Date(now - 30 * 24 * 60 * 60 * 1000);
  const twoMonthsAgo = new Date(now - 60 * 24 * 60 * 60 * 1000);

  // All-time drinks
  const allTimeAgg = await Post.aggregate([
    { $match: { user: { $in: userIds } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const pintsMap = {};
  for (const a of allTimeAgg) pintsMap[a._id.toString()] = a.count;

  // Previous period all-time (for rank-change: exclude last 30 days)
  const prevPintsAgg = await Post.aggregate([
    { $match: { user: { $in: userIds }, createdAt: { $lt: monthAgo } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const prevPintsMap = {};
  for (const a of prevPintsAgg) prevPintsMap[a._id.toString()] = a.count;

  // This week's drinks
  const thisWkAgg = await Post.aggregate([
    { $match: { user: { $in: userIds }, createdAt: { $gte: weekAgo } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const drinksWkMap = {};
  for (const a of thisWkAgg) drinksWkMap[a._id.toString()] = a.count;

  // Previous week's drinks (for rank-change)
  const prevWkAgg = await Post.aggregate([
    { $match: { user: { $in: userIds }, createdAt: { $gte: twoWeeksAgo, $lt: weekAgo } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const prevDrinksWkMap = {};
  for (const a of prevWkAgg) prevDrinksWkMap[a._id.toString()] = a.count;

  // This month's drinks
  const thisMoAgg = await Post.aggregate([
    { $match: { user: { $in: userIds }, createdAt: { $gte: monthAgo } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const drinksMoMap = {};
  for (const a of thisMoAgg) drinksMoMap[a._id.toString()] = a.count;

  // Previous month's drinks (for rank-change)
  const prevMoAgg = await Post.aggregate([
    { $match: { user: { $in: userIds }, createdAt: { $gte: twoMonthsAgo, $lt: monthAgo } } },
    { $group: { _id: '$user', count: { $sum: 1 } } },
  ]);
  const prevDrinksMoMap = {};
  for (const a of prevMoAgg) prevDrinksMoMap[a._id.toString()] = a.count;

  const users = await User.find({ _id: { $in: userIds } }).select('username avatarUrl');

  const raw = users.map(u => ({
    userId: u._id.toString(),
    username: u.username,
    avatarUrl: u.avatarUrl || null,
    pints: pintsMap[u._id.toString()] || 0,
    prevPints: prevPintsMap[u._id.toString()] || 0,
    drinksWk: drinksWkMap[u._id.toString()] || 0,
    prevDrinksWk: prevDrinksWkMap[u._id.toString()] || 0,
    drinksMo: drinksMoMap[u._id.toString()] || 0,
    prevDrinksMo: prevDrinksMoMap[u._id.toString()] || 0,
    isYou: u._id.toString() === callerId.toString(),
  }));

  const currentPintsRanks = computeRankMap(raw, 'pints');
  const prevPintsRanks    = computeRankMap(raw.map(e => ({ userId: e.userId, pints: e.prevPints })), 'pints');
  const currentWkRanks    = computeRankMap(raw, 'drinksWk');
  const prevWkRanks       = computeRankMap(raw.map(e => ({ userId: e.userId, drinksWk: e.prevDrinksWk })), 'drinksWk');
  const currentMoRanks    = computeRankMap(raw, 'drinksMo');
  const prevMoRanks       = computeRankMap(raw.map(e => ({ userId: e.userId, drinksMo: e.prevDrinksMo })), 'drinksMo');

  return raw.map(e => ({
    userId: e.userId,
    username: e.username,
    avatarUrl: e.avatarUrl,
    pints: e.pints,
    drinksWk: e.drinksWk,
    drinksMo: e.drinksMo,
    pintMove: (prevPintsRanks[e.userId] || raw.length) - (currentPintsRanks[e.userId] || raw.length),
    wkMove:   (prevWkRanks[e.userId]    || raw.length) - (currentWkRanks[e.userId]    || raw.length),
    moMove:   (prevMoRanks[e.userId]    || raw.length) - (currentMoRanks[e.userId]    || raw.length),
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

    const callerInTop = topUserIds.some(id => id.toString() === userId.toString());
    const queryIds = callerInTop ? topUserIds : [...topUserIds, userId];

    const allEntries = await buildEntries(queryIds, userId);

    const topIdSet = new Set(topUserIds.map(id => id.toString()));
    const entries = allEntries.filter(e => topIdSet.has(e.userId));

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
