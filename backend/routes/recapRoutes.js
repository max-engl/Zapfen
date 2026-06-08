const express = require("express");
const cron = require("node-cron");
const Post = require("../models/Post");
const User = require("../models/User");
const authMiddleware = require("../middleware/authMiddleware");
const admin = require("../config/firebase");

const router = express.Router();

// Night session window: 2 PM (14:00) yesterday → 6 AM (06:00) today.
// This captures "a night out" for Central European timezones regardless of DST.
function getNightWindow(now) {
  const sessionEnd = new Date(now);
  sessionEnd.setHours(6, 0, 0, 0);

  const sessionStart = new Date(now);
  sessionStart.setDate(sessionStart.getDate() - 1);
  sessionStart.setHours(14, 0, 0, 0);

  return { sessionStart, sessionEnd };
}

async function buildRecap(userId, sessionStart, sessionEnd) {
  const posts = await Post.find({
    user: userId,
    createdAt: { $gte: sessionStart, $lt: sessionEnd },
  }).select("drink location stats createdAt");

  if (posts.length === 0) return null;

  // Aggregate drink counts
  const drinkMap = {};
  for (const post of posts) {
    const name = post.drink?.name || "Sonstiges";
    const emoji = post.drink?.emoji || "🍺";
    if (!drinkMap[name]) drinkMap[name] = { name, emoji, count: 0 };
    drinkMap[name].count++;
  }
  const drinks = Object.values(drinkMap).sort((a, b) => b.count - a.count);

  // Unique locations (rounded to ~100 m grid)
  const locationSet = new Set();
  for (const post of posts) {
    const coords = post.location?.coordinates;
    if (coords?.length === 2) {
      const key = `${Math.round(coords[1] * 1000)},${Math.round(coords[0] * 1000)}`;
      locationSet.add(key);
    }
  }
  const uniqueLocations = locationSet.size;

  // Total social activity (reactions + likes)
  const totalReactions = posts.reduce(
    (sum, p) => sum + (p.stats?.reactions || 0) + (p.stats?.likes || 0),
    0
  );

  return {
    totalDrinks: posts.length,
    drinks,
    uniqueLocations,
    totalReactions,
  };
}

// GET /recap/night — last-night recap for the authenticated user
router.get("/night", authMiddleware, async (req, res) => {
  try {
    const { sessionStart, sessionEnd } = getNightWindow(new Date());
    const recap = await buildRecap(req.user._id, sessionStart, sessionEnd);
    if (!recap) return res.json({ hasRecap: false });
    res.json({ hasRecap: true, ...recap });
  } catch (err) {
    res
      .status(500)
      .json({ message: "Rückblick konnte nicht geladen werden.", error: err.message });
  }
});

// Sends night-recap push notifications to all users who logged drinks last night.
// Called by the daily 9 AM cron job in server.js.
async function sendNightRecapNotifications() {
  const now = new Date();
  const { sessionStart, sessionEnd } = getNightWindow(now);

  const activeUserIds = await Post.distinct("user", {
    createdAt: { $gte: sessionStart, $lt: sessionEnd },
  });

  if (activeUserIds.length === 0) {
    console.log("[recap] No activity last night — skipping notifications");
    return;
  }

  const users = await User.find({
    _id: { $in: activeUserIds },
    fcmToken: { $exists: true, $ne: null },
  }).select("_id fcmToken");

  let sent = 0;
  for (const user of users) {
    try {
      const recap = await buildRecap(user._id, sessionStart, sessionEnd);
      if (!recap) continue;

      const topDrinks = recap.drinks
        .slice(0, 3)
        .map((d) => `${d.count > 1 ? `${d.count}x ` : ""}${d.name}`)
        .join(", ");

      const parts = [topDrinks];
      if (recap.uniqueLocations > 0)
        parts.push(
          `${recap.uniqueLocations} ${recap.uniqueLocations === 1 ? "Ort" : "Orte"}`
        );
      if (recap.totalReactions > 0)
        parts.push(
          `${recap.totalReactions} Reaktion${recap.totalReactions !== 1 ? "en" : ""}`
        );

      await admin.messaging().send({
        token: user.fcmToken,
        notification: {
          title: "Letzte Nacht 🌙",
          body: parts.join(" · "),
        },
        data: {
          type: "night_recap",
          totalDrinks: String(recap.totalDrinks),
          topDrinks,
          uniqueLocations: String(recap.uniqueLocations),
          totalReactions: String(recap.totalReactions),
        },
      });
      sent++;
    } catch (_) {
      // Per-user errors (stale token etc.) are non-fatal
    }
  }

  console.log(`[recap] Night recap sent to ${sent}/${users.length} user(s)`);
}

// Schedule daily 9 AM dispatch (server local time)
function scheduleNightRecap() {
  cron.schedule("0 9 * * *", () => {
    sendNightRecapNotifications().catch((err) =>
      console.error("[recap] Cron error:", err.message)
    );
  });
  console.log("[recap] Night recap cron scheduled (daily 09:00)");
}

module.exports = { router, scheduleNightRecap };
