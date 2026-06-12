const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcrypt");
const path = require("path");
require("dotenv").config();

const os = require("os");
const authRoutes = require("./routes/authRoutes");
const postRoutes = require("./routes/postRoutes");
const userRoutes = require("./routes/userRoutes");
const friendRoutes = require("./routes/friendRoutes");
const drinkRoutes = require("./routes/drinkRoutes");
const {
  postRouter: commentPostRoutes,
  commentRouter,
} = require("./routes/commentRoutes");
const leaderboardRoutes = require("./routes/leaderboardRoutes");
const statsRoutes = require("./routes/statsRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const appNotificationRoutes = require("./routes/appNotificationRoutes");
const achievementRoutes = require("./routes/achievementRoutes");
const { reportRouter, adminRouter } = require("./routes/reportRoutes");
const { router: recapRouter, scheduleNightRecap } = require("./routes/recapRoutes");
const bingoRouter = require("./routes/bingoRoutes");
const blockRoutes = require("./routes/blockRoutes");

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

// Cache middleware: set cache headers for GET requests (only on successful responses)
app.use((req, res, next) => {
  if (req.method !== "GET") {
    res.set("Cache-Control", "no-cache, no-store, must-revalidate");
    return next();
  }
  const origJson = res.json.bind(res);
  res.json = function (data) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (req.path.includes("/posts")) {
        res.set("Cache-Control", "public, max-age=3600");
      } else {
        res.set("Cache-Control", "public, max-age=1800");
      }
    } else {
      res.set("Cache-Control", "no-store");
    }
    return origJson(data);
  };
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
      return res
        .status(404)
        .send(
          `<!DOCTYPE html><html><head><meta charset="utf-8"><title>Zapfen</title></head><body style="font-family:-apple-system,sans-serif;background:#0F0F0F;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;text-align:center"><p>Einladungslink ungültig oder abgelaufen.</p></body></html>`,
        );
    }

    const deepLink = `zapfen://invite/${encodeURIComponent(token)}`;
    const username = user.username.replace(
      /[<>"'&]/g,
      (c) =>
        ({
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#39;",
          "&": "&amp;",
        })[c],
    );

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

// GET /reset-password/:token — email link lands here, redirects to deep link
app.get("/reset-password/:token", (req, res) => {
  console.log(`[reset-password] GET hit — token: ${req.params.token}`);
  const token = req.params.token.replace(/[<>"'&]/g, (c) => ({ "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;", "&": "&amp;" })[c]);
  const deepLink = `zapfen://reset-password/${encodeURIComponent(req.params.token)}`;
  console.log(`[reset-password] redirecting to deep link: ${deepLink}`);
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.send(`<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Zapfen – Passwort zurücksetzen</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#0F0F0F;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px}
    .card{background:#1A1A1A;border:1px solid #2A2A2A;border-radius:24px;padding:40px 28px;max-width:360px;width:100%;text-align:center}
    .icon{font-size:48px;margin-bottom:16px}
    h1{font-size:22px;font-weight:800;letter-spacing:-.4px;margin-bottom:10px}
    p{color:#888;font-size:14px;line-height:1.55;margin-bottom:28px}
    a.btn{display:block;background:#F6B733;color:#1A1000;text-decoration:none;border-radius:14px;padding:15px;font-size:16px;font-weight:700;letter-spacing:-.2px}
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">🔑</div>
    <h1>Passwort zurücksetzen</h1>
    <p>Tippe auf den Button, um die Zapfen-App zu öffnen und ein neues Passwort zu wählen.</p>
    <a class="btn" href="${deepLink}">In Zapfen öffnen</a>
  </div>
  <script>window.location.href="${deepLink}";</script>
</body>
</html>`);
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
app.use("/achievements", achievementRoutes);
app.use("/reports", reportRouter);
app.use("/recap", recapRouter);
app.use("/bingo", bingoRouter);
app.use("/blocks", blockRoutes);
app.use("/admin", express.static(path.join(__dirname, "admin-panel/dist")));
app.use("/admin", adminRouter);

const PORT = process.env.PORT || 3000;

async function syncDefaultDrinks() {
  const Drink = require("./models/Drink");
  await Drink.deleteMany({ isDefault: true });
  await Drink.insertMany(
    DEFAULT_DRINKS.map((d) => ({ ...d, isDefault: true, user: null })),
  );
  console.log(`Default drinks synced (${DEFAULT_DRINKS.length})`);
}

async function migrateAvatarFields() {
  const User = require("./models/User");
  const {
    generateAvatarColor,
    getAvatarInitial,
  } = require("./utils/avatarUtil");
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

async function migrateInviteTokenIndex() {
  const User = require("./models/User");

  await User.updateMany({ inviteToken: null }, { $unset: { inviteToken: "" } });

  const indexes = await User.collection.indexes();
  const inviteTokenIndex = indexes.find(
    (index) => index.name === "inviteToken_1",
  );
  const hasPartialStringFilter =
    inviteTokenIndex?.partialFilterExpression?.inviteToken?.$type === "string";

  if (inviteTokenIndex && !hasPartialStringFilter) {
    await User.collection.dropIndex("inviteToken_1");
  }

  await User.collection.createIndex(
    { inviteToken: 1 },
    {
      name: "inviteToken_1",
      unique: true,
      partialFilterExpression: { inviteToken: { $type: "string" } },
    },
  );
}

async function compressExistingAvatars() {
  if (!process.env.R2_AVATAR_BUCKET || !process.env.R2_AVATAR_PUBLIC_BASE_URL) return;

  const User = require("./models/User");
  const sharp = require("sharp");
  const { GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
  const r2 = require("./config/r2");

  const publicBase = process.env.R2_AVATAR_PUBLIC_BASE_URL.replace(/\/$/, "");
  const users = await User.find({ avatarUrl: { $ne: null }, avatarCompressed: { $ne: true } }).select("_id avatarUrl");

  if (users.length === 0) return;
  console.log(`Avatar compression: processing ${users.length} uncompressed avatar(s)...`);

  let ok = 0;
  let failed = 0;
  for (const user of users) {
    if (!user.avatarUrl.startsWith(publicBase + "/")) {
      await User.findByIdAndUpdate(user._id, { avatarCompressed: true });
      continue;
    }
    const key = user.avatarUrl.slice(publicBase.length + 1);
    try {
      const getRes = await r2.send(new GetObjectCommand({ Bucket: process.env.R2_AVATAR_BUCKET, Key: key }));
      const chunks = [];
      for await (const chunk of getRes.Body) chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
      const original = Buffer.concat(chunks);
      const compressed = await sharp(original)
        .resize(512, 512, { fit: "inside", withoutEnlargement: true })
        .jpeg({ quality: 85, progressive: true })
        .toBuffer();
      await r2.send(new PutObjectCommand({ Bucket: process.env.R2_AVATAR_BUCKET, Key: key, Body: compressed, ContentType: "image/jpeg" }));
      await User.findByIdAndUpdate(user._id, { avatarCompressed: true });
      ok++;
    } catch (err) {
      console.warn(`Avatar compression failed for user ${user._id}: ${err.message}`);
      failed++;
    }
  }
  console.log(`Avatar compression: done (${ok} compressed, ${failed} failed)`);
}

async function migrateAvatarUrlsToR2() {
  if (!process.env.R2_AVATAR_PUBLIC_BASE_URL) return;
  const User = require("./models/User");
  const OLD_PREFIX = "https://rcrtfvuzckrrkcasouxw.supabase.co/storage/v1/object/public/avatars/";
  const NEW_PREFIX = process.env.R2_AVATAR_PUBLIC_BASE_URL.replace(/\/$/, "") + "/";
  const users = await User.find({ avatarUrl: { $regex: "rcrtfvuzckrrkcasouxw\\.supabase\\.co" } }).select("_id avatarUrl");
  if (users.length === 0) return;
  let updated = 0;
  for (const user of users) {
    if (!user.avatarUrl.startsWith(OLD_PREFIX)) continue;
    await User.findByIdAndUpdate(user._id, { avatarUrl: NEW_PREFIX + user.avatarUrl.slice(OLD_PREFIX.length) });
    updated++;
  }
  console.log(`Avatar URL migration: updated ${updated} user(s) to R2`);
}

async function syncAdminUser() {
  const User = require("./models/User");
  const {
    generateAvatarColor,
    getAvatarInitial,
  } = require("./utils/avatarUtil");

  const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD;
  if (!email || !password) {
    console.log("Admin sync skipped: ADMIN_EMAIL or ADMIN_PASSWORD missing");
    return;
  }

  const rawUsername =
    process.env.ADMIN_USERNAME || email.split("@")[0] || "admin";
  const username = rawUsername
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, "")
    .slice(0, 32);
  const safeUsername = username.length >= 3 ? username : "admin";
  const passwordHash = await bcrypt.hash(password, 12);
  const existing = await User.findOne({ email });

  if (existing) {
    existing.role = "admin";
    existing.passwordHash = passwordHash;
    if (!existing.avatarColor)
      existing.avatarColor = generateAvatarColor(existing.username);
    if (!existing.avatarInitial)
      existing.avatarInitial = getAvatarInitial(existing.username);
    await existing.save();
    console.log(`Admin user synced: ${email}`);
    return;
  }

  const usernameTaken = await User.exists({ username: safeUsername });
  const adminUsername = usernameTaken
    ? `admin${Date.now().toString().slice(-6)}`
    : safeUsername;

  await User.create({
    username: adminUsername,
    email,
    passwordHash,
    role: "admin",
    avatarColor: generateAvatarColor(adminUsername),
    avatarInitial: getAvatarInitial(adminUsername),
  });
  console.log(`Admin user created: ${email}`);
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
    await migrateAvatarUrlsToR2();
    await compressExistingAvatars();
    await migrateInviteTokenIndex();
    await syncAdminUser();
    scheduleNightRecap();

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
