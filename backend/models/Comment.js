const mongoose = require("mongoose");

const commentSchema = new mongoose.Schema(
    {
        post: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Post",
            required: true,
            index: true,
        },
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        text: {
            type: String,
            required: true,
            maxlength: 500,
        },
        parent: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Comment",
            default: null,
        },
        reactionCounts: {
            type: Map,
            of: Number,
            default: {},
        },
    },
    { timestamps: true }
);

commentSchema.index({ post: 1, parent: 1, createdAt: 1 });

module.exports = mongoose.model("Comment", commentSchema);
