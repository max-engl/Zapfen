const express = require('express');
const Post = require('../models/Post');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const { getFriendIds } = require('../utils/friends');
const { getBerlinOffsetMinutes, localDayOf, localHour, localDow } = require('../utils/localTime');

const router = express.Router();

const DAY_NAMES = ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'];
const MONTH_ABBR = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

// Returns the Monday (as a UTC Date with local-midnight clock values) of the ISO week
// containing `localDate`, where `localDate`'s UTC fields represent local clock time.
function getISOMonday(localDate) {
    const d = new Date(localDate);
    const dow = d.getUTCDay(); // 0=Sun … 6=Sat
    d.setUTCDate(d.getUTCDate() - (dow === 0 ? 6 : dow - 1));
    return d;
}

// Returns { start, end } as UTC wall-clock Dates (start inclusive, end exclusive)
// where `localNow` has already been shifted by offsetMinutes so UTC fields = Berlin clock.
function getPeriodBounds(range, offset, localNow, offsetMinutes) {
    const y = localNow.getUTCFullYear();
    const mo = localNow.getUTCMonth();

    if (range === 'week') {
        const monday = getISOMonday(localNow);
        monday.setUTCDate(monday.getUTCDate() + offset * 7);
        const start = new Date(
            Date.UTC(monday.getUTCFullYear(), monday.getUTCMonth(), monday.getUTCDate())
            - offsetMinutes * 60 * 1000
        );
        return { start, end: new Date(start.getTime() + 7 * 86400000) };
    }

    if (range === 'month') {
        let year = y, month = mo + offset;
        while (month < 0) { month += 12; year--; }
        while (month > 11) { month -= 12; year++; }
        const start = new Date(Date.UTC(year, month, 1) - offsetMinutes * 60 * 1000);
        const end   = new Date(Date.UTC(year, month + 1, 1) - offsetMinutes * 60 * 1000);
        return { start, end };
    }

    // year
    const year = y + offset;
    const start = new Date(Date.UTC(year, 0, 1) - offsetMinutes * 60 * 1000);
    const end   = new Date(Date.UTC(year + 1, 0, 1) - offsetMinutes * 60 * 1000);
    return { start, end };
}

function buildTimeline(posts, range, offset, offsetMinutes) {
    const now = new Date();
    const localNow = new Date(now.getTime() + offsetMinutes * 60 * 1000);
    const y  = localNow.getUTCFullYear();
    const mo = localNow.getUTCMonth();

    // ── Week: Mon–Sun of the target ISO week ───────────────────────────────────
    if (range === 'week') {
        const monday = getISOMonday(localNow);
        monday.setUTCDate(monday.getUTCDate() + offset * 7);

        const counts    = Array(7).fill(0);
        const labels    = [];
        const slotTimes = [];

        for (let i = 0; i < 7; i++) {
            const d = new Date(monday);
            d.setUTCDate(d.getUTCDate() + i);
            labels.push(DAY_NAMES[d.getUTCDay()]);
            // Use UTC-midnight + local calendar date to match localDayOf() output
            slotTimes.push(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
        }

        for (const post of posts) {
            const postDay = localDayOf(post.createdAt, offsetMinutes).getTime();
            const idx     = slotTimes.indexOf(postDay);
            if (idx >= 0) counts[idx]++;
        }

        return labels.map((label, i) => ({ label, count: counts[i] }));
    }

    // ── Month: one bucket per calendar day ────────────────────────────────────
    if (range === 'month') {
        let year = y, month = mo + offset;
        while (month < 0)  { month += 12; year--; }
        while (month > 11) { month -= 12; year++; }

        const daysInMonth = new Date(Date.UTC(year, month + 1, 0)).getUTCDate();
        const counts = Array(daysInMonth).fill(0);

        for (const post of posts) {
            const pd = localDayOf(post.createdAt, offsetMinutes);
            if (pd.getUTCFullYear() === year && pd.getUTCMonth() === month) {
                counts[pd.getUTCDate() - 1]++;
            }
        }

        // Sparse x-axis: show day number every 5 days + first + last
        const labels = Array.from({ length: daysInMonth }, (_, i) => {
            const d = i + 1;
            return (d === 1 || d % 5 === 0 || d === daysInMonth) ? String(d) : '';
        });

        return labels.map((label, i) => ({ label, count: counts[i] }));
    }

    // ── Year: one bucket per 7-day block starting Jan 1 (52–53 buckets) ──────
    const year    = y + offset;
    const jan1    = new Date(Date.UTC(year, 0, 1));
    const isLeap  = new Date(Date.UTC(year, 1, 29)).getUTCDate() === 29;
    const total   = isLeap ? 366 : 365;
    const numWeeks = Math.ceil(total / 7);
    const counts  = Array(numWeeks).fill(0);

    for (const post of posts) {
        const pd       = localDayOf(post.createdAt, offsetMinutes);
        const dayOfYear = Math.round((pd - jan1) / 86400000);
        if (dayOfYear >= 0 && dayOfYear < total) {
            counts[Math.min(Math.floor(dayOfYear / 7), numWeeks - 1)]++;
        }
    }

    // Label: month abbreviation at the first bucket of each new month
    const labels = Array(numWeeks).fill('');
    let prevM = -1;
    for (let i = 0; i < numWeeks; i++) {
        const m = new Date(jan1.getTime() + i * 7 * 86400000).getUTCMonth();
        if (m !== prevM) { labels[i] = MONTH_ABBR[m]; prevM = m; }
    }

    return labels.map((label, i) => ({ label, count: counts[i] }));
}

// GET /stats?scope=friends|global&range=week|month|year&offset=0
router.get('/', authMiddleware, async (req, res) => {
    try {
        const userId = req.user._id;
        const scope  = req.query.scope === 'global' ? 'global' : 'friends';
        const range  = ['week', 'month', 'year'].includes(req.query.range) ? req.query.range : 'week';
        const offset = Math.min(0, parseInt(req.query.offset, 10) || 0);

        const offsetMinutes = getBerlinOffsetMinutes();
        const now      = new Date();
        const localNow = new Date(now.getTime() + offsetMinutes * 60 * 1000);

        const { start: periodStart, end: periodEnd } = getPeriodBounds(range, offset,     localNow, offsetMinutes);
        const { start: prevStart,   end: prevEnd   } = getPeriodBounds(range, offset - 1, localNow, offsetMinutes);

        let userFilter = {};
        let totalUsers;

        if (scope === 'friends') {
            const friendIds = await getFriendIds(userId);
            const userIds   = [...friendIds, userId];
            userFilter  = { user: { $in: userIds } };
            totalUsers  = userIds.length;
        } else {
            totalUsers = await User.countDocuments();
        }

        const [currentPosts, prevCount] = await Promise.all([
            Post.find({ ...userFilter, createdAt: { $gte: periodStart, $lt: periodEnd } })
                .select('createdAt drink user'),
            Post.countDocuments({ ...userFilter, createdAt: { $gte: prevStart, $lt: prevEnd } }),
        ]);

        const total    = currentPosts.length;
        const deltaPct = prevCount === 0
            ? (total > 0 ? 100 : 0)
            : Math.round(((total - prevCount) / prevCount) * 100);

        const timeline = buildTimeline(currentPosts, range, offset, offsetMinutes);

        // Day-of-week distribution (Mon=0 … Sun=6)
        const dow = Array(7).fill(0);
        for (const post of currentPosts) {
            dow[(localDow(post.createdAt, offsetMinutes) + 6) % 7]++;
        }

        // Peak hour + peak day
        const hourCounts    = Array(24).fill(0);
        const hourDayCounts = Array.from({ length: 24 }, () => Array(7).fill(0));
        for (const post of currentPosts) {
            const h = localHour(post.createdAt, offsetMinutes);
            const d = localDow(post.createdAt, offsetMinutes);
            hourCounts[h]++;
            hourDayCounts[h][d]++;
        }
        let peakHour = '–';
        if (total > 0) {
            const h = hourCounts.indexOf(Math.max(...hourCounts));
            const d = hourDayCounts[h].indexOf(Math.max(...hourDayCounts[h]));
            peakHour = `${DAY_NAMES[d]} · ${h} Uhr`;
        }

        const avgPerHead = totalUsers > 0
            ? Math.round((total / totalUsers) * 10) / 10
            : 0;

        // Top drink styles
        const styleMap = {};
        for (const post of currentPosts) {
            const name = post.drink?.name || 'Sonstiges';
            styleMap[name] = (styleMap[name] || 0) + 1;
        }
        const sorted     = Object.entries(styleMap).sort((a, b) => b[1] - a[1]);
        const otherCount = sorted.slice(5).reduce((s, [, c]) => s + c, 0);
        const styleEntries = [
            ...sorted.slice(0, 5),
            ...(otherCount > 0 ? [['Sonstiges', otherCount]] : []),
        ];
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
