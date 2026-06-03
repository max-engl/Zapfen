const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const os = require("os");
const authRoutes = require("./routes/authRoutes");
const postRoutes = require("./routes/postRoutes");
const userRoutes = require("./routes/userRoutes");
const friendRoutes = require("./routes/friendRoutes");
const drinkRoutes = require("./routes/drinkRoutes");
const { postRouter: commentPostRoutes, commentRouter } = require("./routes/commentRoutes");
const leaderboardRoutes = require("./routes/leaderboardRoutes");
const statsRoutes = require("./routes/statsRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const appNotificationRoutes = require("./routes/appNotificationRoutes");

// Edit this list to change the default drinks shown to all users.
const DEFAULT_DRINKS = [
    { name: "Bier", emoji: "🍺" },
    { name: "Weizen", emoji: "🍺" },
    { name: "Radler", emoji: "🍋" },
    { name: "Dunkles", emoji: "🍫" },

    { name: "Wein", emoji: "🍷" },
    { name: "Sekt", emoji: "🥂" },
    { name: "Weinschorle", emoji: "🍷" },

    { name: "Aperol Spritz", emoji: "🍊" },
    { name: "Hugo", emoji: "🌿" },
    { name: "Gin Tonic", emoji: "🌿" },
    { name: "Vodka Lemon", emoji: "🍋" },
    { name: "Rum Cola", emoji: "🥤" },

    { name: "Jägermeister", emoji: "🦌" },
    { name: "Korn", emoji: "🌾" },
    { name: "Obstler", emoji: "🍎" },
];

const app = express();

app.use(cors());
app.use(express.json());

// Cache middleware: set cache headers for GET requests
app.use((req, res, next) => {
    if (req.method === "GET") {
        // Cache feed and posts for 1 hour (3600 seconds)
        if (req.path.includes("/posts")) {
            res.set("Cache-Control", "public, max-age=3600");
        }
        // Default cache for other GET requests
        else {
            res.set("Cache-Control", "public, max-age=1800");
        }
    } else {
        // Don't cache POST/PUT/DELETE
        res.set("Cache-Control", "no-cache, no-store, must-revalidate");
    }
    next();
});

app.get("/", (req, res) => {
    res.json({ message: "API is running" });
});

// Public HTML invite landing page — scanned by the camera app, redirects to the custom scheme
app.get("/invite/:token", async (req, res) => {
    const User = require("./models/User");
    const token = req.params.token;
    try {
        const user = await User.findOne({ inviteToken: token });
        if (!user) {
            return res.status(404).send(`<!DOCTYPE html><html><head><meta charset="utf-8"><title>Zapfen</title></head><body style="font-family:-apple-system,sans-serif;background:#0F0F0F;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;text-align:center"><p>Einladungslink ungültig oder abgelaufen.</p></body></html>`);
        }

        const deepLink = `zapfen://invite/${encodeURIComponent(token)}`;
        const username = user.username.replace(/[<>"'&]/g, (c) => ({ "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;", "&": "&amp;" }[c]));

        res.setHeader("Content-Type", "text/html; charset=utf-8");
        res.send(`<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Zapfen – Einladung von @${username}</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#0F0F0F;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px}
    .card{background:#1A1A1A;border:1px solid #2A2A2A;border-radius:24px;padding:40px 28px;max-width:360px;width:100%;text-align:center}
    .beer{font-size:52px;margin-bottom:16px}
    h1{font-size:22px;font-weight:800;letter-spacing:-.4px;margin-bottom:10px}
    p{color:#888;font-size:14px;line-height:1.55;margin-bottom:28px}
    a.btn{display:block;background:#F6B733;color:#1A1000;text-decoration:none;border-radius:14px;padding:15px;font-size:16px;font-weight:700;letter-spacing:-.2px}
  </style>
</head>
<body>
  <div class="card">
    <div class="beer">🍺</div>
    <h1>Du wurdest eingeladen!</h1>
    <p>@${username} lädt dich ein, seinem Kreis auf Zapfen beizutreten.</p>
    <a class="btn" href="${deepLink}">Zapfen öffnen</a>
  </div>
  <script>window.location.href="${deepLink}";</script>
</body>
</html>`);
    } catch (e) {
        res.status(500).send("Internal server error");
    }
});

app.use("/auth", authRoutes);
app.use("/posts", postRoutes);
app.use("/posts", commentPostRoutes);
app.use("/comments", commentRouter);
app.use("/users", userRoutes);
app.use("/friends", friendRoutes);
app.use("/drinks", drinkRoutes(DEFAULT_DRINKS));
app.use("/leaderboard", leaderboardRoutes);
app.use("/stats", statsRoutes);
app.use("/notify", notificationRoutes);
app.use("/notifications", appNotificationRoutes);

const PORT = process.env.PORT || 3000;

async function syncDefaultDrinks() {
    const Drink = require("./models/Drink");
    await Drink.deleteMany({ isDefault: true });
    await Drink.insertMany(
        DEFAULT_DRINKS.map((d) => ({ ...d, isDefault: true, user: null }))
    );
    console.log(`Default drinks synced (${DEFAULT_DRINKS.length})`);
}

async function migrateAvatarFields() {
    const User = require("./models/User");
    const { generateAvatarColor, getAvatarInitial } = require("./utils/avatarUtil");
    const users = await User.find({
        $or: [
            { avatarColor: { $exists: false } },
            { avatarColor: null },
            { avatarColor: "#6A7C8C" },
            { avatarInitial: { $exists: false } },
            { avatarInitial: null },
            { avatarInitial: "U" },
        ],
    });
    let updated = 0;
    for (const user of users) {
        const needsColor = !user.avatarColor || user.avatarColor === "#6A7C8C";
        const needsInitial = !user.avatarInitial || user.avatarInitial === "U";
        if (needsColor) user.avatarColor = generateAvatarColor(user.username);
        if (needsInitial) user.avatarInitial = getAvatarInitial(user.username);
        if (needsColor || needsInitial) {
            await user.save();
            updated++;
        }
    }
    if (updated > 0) console.log(`Avatar migration: updated ${updated} users`);
}

function getLocalIPv4() {
    const interfaces = os.networkInterfaces();

    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === "IPv4" && !iface.internal) {
                return iface.address;
            }
        }
    }

    return "localhost";
}

async function startServer() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected");

        await syncDefaultDrinks();
        await migrateAvatarFields();

        const host = "0.0.0.0";
        const localIPv4 = getLocalIPv4();

        app.listen(PORT, host, () => {
            console.log(`Server running on:`);
            console.log(`Local:   http://localhost:${PORT}`);
            console.log(`Network: http://${localIPv4}:${PORT}`);
        });
    } catch (error) {
        console.error("Server start failed:", error.message);
        process.exit(1);
    }
}

startServer();