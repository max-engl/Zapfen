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
    res.json({
        message: "API is running",
    });
});

app.use("/auth", authRoutes);
app.use("/posts", postRoutes);
app.use("/posts", commentPostRoutes);
app.use("/comments", commentRouter);
app.use("/users", userRoutes);
app.use("/friends", friendRoutes);
app.use("/drinks", drinkRoutes(DEFAULT_DRINKS));
app.use("/leaderboard", leaderboardRoutes);
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