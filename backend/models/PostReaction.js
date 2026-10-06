const mongoose = require("mongoose");

const postReactionSchema = new mongoose.Schema(
    {
        post: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Post",
            required: true,
        },
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        emoji: {
            type: String,
            required: true,
        },
    },
    { timestamps: true }
);

postReactionSchema.index({ post: 1, user: 1 }, { unique: true });
postReactionSchema.index({ post: 1 });

module.exports = mongoose.model("PostReaction", postReactionSchema);
