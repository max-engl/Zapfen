const mongoose = require("mongoose");

const selfieReactionSchema = new mongoose.Schema(
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
        storagePath: {
            type: String,
            required: true,
        },
        emoji: {
            type: String,
            default: null,
        },
    },
    { timestamps: true }
);

selfieReactionSchema.index({ post: 1, user: 1 }, { unique: true });
selfieReactionSchema.index({ post: 1, createdAt: 1 });

module.exports = mongoose.model("SelfieReaction", selfieReactionSchema);
