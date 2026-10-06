/**
 * One-time migration: rewrite Supabase avatar URLs → R2 public URLs in MongoDB.
 * Run AFTER the backend is updated and R2_AVATAR_PUBLIC_BASE_URL is set in .env.
 *
 *   node backend/scripts/migrateAvatarUrlsToR2.js
 */

require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });

const mongoose = require("mongoose");
const User = require("../models/User");

const OLD_PREFIX = "https://rcrtfvuzckrrkcasouxw.supabase.co/storage/v1/object/public/avatars/";

async function run() {
    if (!process.env.R2_AVATAR_PUBLIC_BASE_URL) {
        console.error("R2_AVATAR_PUBLIC_BASE_URL is not set in .env");
        process.exit(1);
    }

    const NEW_PREFIX = process.env.R2_AVATAR_PUBLIC_BASE_URL.replace(/\/$/, "") + "/";

    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");

    const users = await User.find({
        avatarUrl: { $regex: "rcrtfvuzckrrkcasouxw\\.supabase\\.co" },
    }).select("_id avatarUrl");

    console.log(`Found ${users.length} user(s) with Supabase avatar URLs`);

    if (users.length === 0) {
        console.log("Nothing to migrate.");
        await mongoose.disconnect();
        return;
    }

    let updated = 0;
    let skipped = 0;
    for (const user of users) {
        if (!user.avatarUrl.startsWith(OLD_PREFIX)) {
            console.warn(`Unexpected URL format, skipping user ${user._id}: ${user.avatarUrl}`);
            skipped++;
            continue;
        }
        const storagePath = user.avatarUrl.slice(OLD_PREFIX.length);
        const newUrl = NEW_PREFIX + storagePath;
        await User.findByIdAndUpdate(user._id, { avatarUrl: newUrl });
        updated++;
    }

    console.log(`Done. Updated: ${updated}, Skipped: ${skipped}`);
    await mongoose.disconnect();
}

run().catch((err) => {
    console.error(err);
    process.exit(1);
});
