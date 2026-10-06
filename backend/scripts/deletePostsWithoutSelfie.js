/**
 * Run once before deploying the selfie requirement update:
 *   node backend/scripts/deletePostsWithoutSelfie.js
 *
 * Deletes every Post document that lacks a selfieStoragePath, along with
 * its image file in Supabase and all associated Likes.
 */

require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });

const mongoose = require("mongoose");
const Post = require("../models/Post");
const Like = require("../models/Like");
const r2 = require("../config/r2");
const { DeleteObjectsCommand } = require("@aws-sdk/client-s3");

async function run() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("Connected to MongoDB");

    const stalePosts = await Post.find({
        $or: [
            { selfieStoragePath: { $exists: false } },
            { selfieStoragePath: null },
            { selfieStoragePath: "" },
        ],
    }).select("_id storagePath selfieStoragePath");

    console.log(`Found ${stalePosts.length} posts without a selfie`);

    if (stalePosts.length === 0) {
        console.log("Nothing to delete.");
        await mongoose.disconnect();
        return;
    }

    const storagePaths = stalePosts
        .map((p) => p.storagePath)
        .filter(Boolean);

    if (storagePaths.length > 0) {
        try {
            await r2.send(new DeleteObjectsCommand({
                Bucket: process.env.R2_POST_BUCKET,
                Delete: { Objects: storagePaths.map((Key) => ({ Key })), Quiet: true },
            }));
            console.log(`Removed ${storagePaths.length} image(s) from R2`);
        } catch (err) {
            console.error("R2 removal error (continuing anyway):", err.message);
        }
    }

    const postIds = stalePosts.map((p) => p._id);
    await Like.deleteMany({ post: { $in: postIds } });
    const { deletedCount } = await Post.deleteMany({ _id: { $in: postIds } });

    console.log(`Deleted ${deletedCount} post(s) and their likes`);
    await mongoose.disconnect();
}

run().catch((err) => {
    console.error(err);
    process.exit(1);
});
