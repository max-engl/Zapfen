const mongoose = require("mongoose");

const postSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },

        caption: {
            type: String,
            default: "",
            maxlength: 300,
        },

        storagePath: {
            type: String,
            required: true,
        },

        selfieStoragePath: {
            type: String,
            required: true,
        },

        location: {
            type: {
                type: String,
                enum: ["Point"],
            },
            coordinates: {
                type: [Number], // [longitude, latitude]
            },
        },

        drink: {
            name:  { type: String, default: "" },
            emoji: { type: String, default: "" },
        },

        stats: {
            likes: {
                type: Number,
                default: 0,
            },
            comments: {
                type: Number,
                default: 0,
            },
            reactions: {
                type: Number,
                default: 0,
            },
            views: {
                type: Number,
                default: 0,
            },
        },
    },
    { timestamps: true }
);

postSchema.index({ createdAt: -1 });
postSchema.index({ user: 1, createdAt: -1 });
postSchema.index({ location: "2dsphere" }, { sparse: true });

module.exports = mongoose.model("Post", postSchema);