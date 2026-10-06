/**
 * The "cheers" post reaction used to be the beer-mug emoji (🍺) before the
 * app switched to a star (⭐). Existing PostReaction documents from before
 * that change still carry the old emoji, so they're invisible to the
 * current frontend (which only ever looks for ⭐). This converts them in
 * place — safe to run any number of times.
 *
 * Run once: node backend/scripts/migrate-beer-reactions-to-star.js
 */

require("dotenv").config({ path: require("path").resolve(__dirname, "../.env") });

const mongoose = require("mongoose");
const PostReaction = require("../models/PostReaction");

async function run() {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");

    const result = await PostReaction.updateMany(
        { emoji: "🍺" },
        { $set: { emoji: "⭐" } }
    );

    console.log(`✓ Converted ${result.modifiedCount} beer reaction(s) to star.`);
    await mongoose.disconnect();
    process.exit(0);
}

run().catch((error) => {
    console.error("Migration failed:", error);
    process.exit(1);
});
