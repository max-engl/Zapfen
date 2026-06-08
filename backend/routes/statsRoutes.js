const express = require('express');
const Post = require('../models/Post');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const { getFriendIds } = require('../utils/friends');

const router = express.Router();

const DAY_NAMES = ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'];

function utcDay(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function buildTimeline(posts, range, now) {
  if (range === 'week') {
    const today = utcDay(now);
    const counts = Array(7).fill(0);
    const labels = [];
    const slotTimes = [];

    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setUTCDate(d.getUTCDate() - i);
      labels.push(DAY_NAMES[d.getUTCDay()]);
      slotTimes.push(d.getTime());
    }

    for (const post of posts) {
      const postDay = utcDay(post.createdAt).getTime();
      const idx = slotTimes.indexOf(postDay);
      if (idx >= 0) counts[idx]++;
    }

    return labels.map((label, i) => ({ label, count: counts[i] }));
  }

  if (range === 'month') {
    const today = utcDay(now);
    const counts = Array(4).fill(0);
    for (const post of posts) {
      const daysAgo = Math.round((today - utcDay(post.createdAt)) / 86400000);
      const weekIdx = Math.min(Math.floor(daysAgo / 7), 3);
      counts[3 - weekIdx]++;
    }
    return ['W1', 'W2', 'W3', 'W4'].map((label, i) => ({ label, count: counts[i] }));
  }

  // year — last 12 calendar months
  const counts = Array(12).fill(0);
  const labels = [];
  for (let i = 11; i >= 0; i--) {
    const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - i, 1));
    labels.push(['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][d.getUTCMonth()]);
  }
  for (const post of posts) {
    const monthDiff =
      (now.getUTCFullYear() - post.createdAt.getUTCFullYear()) * 12 +
      (now.getUTCMonth() - post.createdAt.getUTCMonth());
    const idx = 11 - monthDiff;
    if (idx >= 0 && idx < 12) counts[idx]++;
  }
  return labels.map((label, i) => ({ label, count: counts[i] }));
}

// GET /stats?scope=friends|global&range=week|month|year
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user._id;
    const scope = req.query.scope === 'global' ? 'global' : 'friends';
    const range = ['week', 'month', 'year'].includes(req.query.range) ? req.query.range : 'week';

    const now = new Date();
    let periodDays;
    if (range === 'week')       periodDays = 7;
    else if (range === 'month') periodDays = 30;
    else                        periodDays = 365;

    // Start from midnight (UTC) of the first day of the period so we
    // don't miss posts created before the current time of day.
    const periodStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - periodDays));
    const prevStart   = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - periodDays * 2));

    let userFilter = {};
    let totalUsers;

    if (scope === 'friends') {
      const friendIds = await getFriendIds(userId);
      const userIds = [...friendIds, userId];
      userFilter = { user: { $in: userIds } };
      totalUsers = userIds.length;
    } else {
      totalUsers = await User.countDocuments();
    }

    const [currentPosts, prevCount] = await Promise.all([
      Post.find({ ...userFilter, createdAt: { $gte: periodStart } })
        .select('createdAt drink user'),
      Post.countDocuments({ ...userFilter, createdAt: { $gte: prevStart, $lt: periodStart } }),
    ]);

    const total = currentPosts.length;
    const deltaPct = prevCount === 0
      ? (total > 0 ? 100 : 0)
      : Math.round(((total - prevCount) / prevCount) * 100);

    const timeline = buildTimeline(currentPosts, range, now);

    // Day-of-week (Mon=0 … Sun=6)
    const dow = Array(7).fill(0);
    for (const post of currentPosts) {
      dow[(post.createdAt.getDay() + 6) % 7]++;
    }

    // Peak hour + day
    const hourCounts = Array(24).fill(0);
    const hourDayCounts = Array.from({ length: 24 }, () => Array(7).fill(0));
    for (const post of currentPosts) {
      const h = post.createdAt.getHours();
      const d = post.createdAt.getDay();
      hourCounts[h]++;
      hourDayCounts[h][d]++;
    }
    let peakHour = '–';
    if (total > 0) {
      const h = hourCounts.indexOf(Math.max(...hourCounts));
      const d = hourDayCounts[h].indexOf(Math.max(...hourDayCounts[h]));
      peakHour = `${DAY_NAMES[d]} · ${h} Uhr`;
    }

    // Avg per head
    const avgPerHead = totalUsers > 0
      ? Math.round((total / totalUsers) * 10) / 10
      : 0;

    // Top drink styles
    const styleMap = {};
    for (const post of currentPosts) {
      const name = post.drink?.name || 'Sonstiges';
      styleMap[name] = (styleMap[name] || 0) + 1;
    }
    const sorted = Object.entries(styleMap).sort((a, b) => b[1] - a[1]);
    const top5 = sorted.slice(0, 5);
    const otherCount = sorted.slice(5).reduce((s, [, c]) => s + c, 0);
    const styleEntries = [...top5, ...(otherCount > 0 ? [['Sonstiges', otherCount]] : [])];
    const styles = styleEntries.map(([name, count]) => ({
      name,
      pct: total > 0 ? Math.round((count / total) * 100) : 0,
    }));

    res.json({ total, deltaPct, timeline, dow, peakHour, avgPerHead, styles, userCount: totalUsers });
  } catch (error) {
    res.status(500).json({ message: 'Statistiken konnten nicht geladen werden.', error: error.message });
  }
});

module.exports = router;
