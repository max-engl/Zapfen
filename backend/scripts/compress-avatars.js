/**
 * One-time migration: compress all existing user avatars stored in R2 to max 512x512 JPEG.
 * Downloads each avatar, resizes/compresses with sharp, and re-uploads to the same R2 key.
 *
 *   node backend/scripts/compress-avatars.js [--dry-run]
 *
 * Flags:
 *   --dry-run   Show what would be processed without uploading anything
 */

require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });

const mongoose = require("mongoose");
const sharp = require("sharp");
const { GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const r2 = require("../config/r2");
const User = require("../models/User");

const DRY_RUN = process.argv.includes("--dry-run");
const MAX_DIM = 512;
const JPEG_QUALITY = 85;

async function streamToBuffer(stream) {
    const chunks = [];
    for await (const chunk of stream) {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    }
    return Buffer.concat(chunks);
}

async function compressAvatar(key) {
    const getRes = await r2.send(new GetObjectCommand({
        Bucket: process.env.R2_AVATAR_BUCKET,
        Key: key,
    }));

    const original = await streamToBuffer(getRes.Body);

    const compressed = await sharp(original)
        .resize(MAX_DIM, MAX_DIM, { fit: "inside", withoutEnlargement: true })
        .jpeg({ quality: JPEG_QUALITY, progressive: true })
        .toBuffer();

    return { original, compressed };
}

async function run() {
    if (!process.env.R2_AVATAR_PUBLIC_BASE_URL || !process.env.R2_AVATAR_BUCKET) {
        console.error("R2_AVATAR_PUBLIC_BASE_URL and R2_AVATAR_BUCKET must be set in .env");
        process.exit(1);
    }

    const publicBase = process.env.R2_AVATAR_PUBLIC_BASE_URL.replace(/\/$/, "");

    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");

    const users = await User.find({ avatarUrl: { $ne: null } }).select("_id avatarUrl");
    console.log(`Found ${users.length} user(s) with an avatar`);

    if (DRY_RUN) {
        console.log("[dry-run] No uploads will be performed.\n");
    }

    let processed = 0;
    let skipped = 0;
    let errors = 0;

    for (const user of users) {
        const url = user.avatarUrl;

        if (!url.startsWith(publicBase + "/")) {
            console.warn(`  SKIP  ${user._id} — URL not in R2 public base: ${url}`);
            skipped++;
            continue;
        }

        const key = url.slice(publicBase.length + 1);

        try {
            const { original, compressed } = await compressAvatar(key);
            const savedBytes = original.length - compressed.length;
            const savedPct = ((savedBytes / original.length) * 100).toFixed(1);

            if (DRY_RUN) {
                console.log(`  DRY   ${user._id} — key=${key} original=${(original.length / 1024).toFixed(1)}KB → ${(compressed.length / 1024).toFixed(1)}KB (−${savedPct}%)`);
            } else {
                // Re-upload to the same key — URL in the DB stays unchanged
                await r2.send(new PutObjectCommand({
                    Bucket: process.env.R2_AVATAR_BUCKET,
                    Key: key,
                    Body: compressed,
                    ContentType: "image/jpeg",
                }));
                console.log(`  OK    ${user._id} — ${(original.length / 1024).toFixed(1)}KB → ${(compressed.length / 1024).toFixed(1)}KB (−${savedPct}%)`);
            }

            processed++;
        } catch (err) {
            console.error(`  ERROR ${user._id} — ${err.message}`);
            errors++;
        }
    }

    console.log(`\nDone. Processed: ${processed}, Skipped: ${skipped}, Errors: ${errors}`);
    await mongoose.disconnect();
}

run().catch((err) => {
    console.error(err);
    process.exit(1);
});
