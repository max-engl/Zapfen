const mongoose = require("mongoose");

const drinkSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true,
            maxlength: 120,
        },
        emoji: {
            type: String,
            default: "🍺",
            trim: true,
            maxlength: 10,
        },
        // null for global defaults, userId for user-created drinks
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null,
            index: true,
        },
        isDefault: {
            type: Boolean,
            default: false,
            index: true,
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model("Drink", drinkSchema);
