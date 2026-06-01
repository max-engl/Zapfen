const mongoose = require("mongoose");

const commentReactionSchema = new mongoose.Schema(
    {
        comment: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Comment",
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

commentReactionSchema.index({ comment: 1, user: 1 }, { unique: true });
commentReactionSchema.index({ comment: 1 });

module.exports = mongoose.model("CommentReaction", commentReactionSchema);
