const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
    {
        username: {
            type: String,
            required: [true, "Username is required"],
            unique: true,
            trim: true,
            lowercase: true,
            minlength: 3,
        },

        email: {
            type: String,
            required: [true, "Email is required"],
            unique: true,
            trim: true,
            lowercase: true,
        },

        passwordHash: {
            type: String,
            required: [true, "Password is required"],
        },

        role: {
            type: String,
            enum: ["user", "admin"],
            default: "user",
        },
        avatarUrl: {
            type: String,
            default: null,
        },
        avatarColor: {
            type: String,
            default: "#6A7C8C",
        },
        avatarInitial: {
            type: String,
            default: "U",
        },
        fcmToken: {
            type: String,
            default: null,
        },
        inviteToken: {
            type: String,
            default: null,
            unique: true,
            sparse: true,
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);