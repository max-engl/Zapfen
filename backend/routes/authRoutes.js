const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const User = require("../models/User");
const authMiddleware = require("../middleware/authMiddleware");
const { generateAvatarColor, getAvatarInitial } = require("../utils/avatarUtil");

const router = express.Router();

const MIN_CLIENT_VERSION = '1.1';

const PATCH_NOTES = [
    'Beer-Bingo mit deinem Freundeskreis',
];

function parseVersion(v) {
    return String(v || '0').split('.').map(n => parseInt(n, 10) || 0);
}

function isOutdated(clientVersion) {
    const client = parseVersion(clientVersion);
    const min = parseVersion(MIN_CLIENT_VERSION);
    const len = Math.max(client.length, min.length);
    for (let i = 0; i < len; i++) {
        const c = client[i] ?? 0;
        const m = min[i] ?? 0;
        if (c < m) return true;
        if (c > m) return false;
    }
    return false;
}

function createToken(user) {
    const raw = process.env.JWT_EXPIRES_IN || "7d";
    // If purely numeric, treat as seconds (not ms); otherwise pass as-is (e.g. "30d")
    const expiresIn = /^\d+$/.test(raw) ? parseInt(raw, 10) : raw;
    return jwt.sign(
        {
            userId: user._id,
            role: user.role,
        },
        process.env.JWT_SECRET,
        { expiresIn }
    );
}

// POST /auth/register
router.post("/register", async (req, res) => {
    try {
        const { username, email, password, clientVersion } = req.body;

        if (!username || !email || !password) {
            return res.status(400).json({
                message: "Username, email and password are required",
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                message: "Password must be at least 6 characters long",
            });
        }

        const existingUser = await User.findOne({
            $or: [{ email: email.toLowerCase() }, { username: username.toLowerCase() }],
        });

        if (existingUser) {
            return res.status(409).json({
                message: "User already exists",
            });
        }

        const passwordHash = await bcrypt.hash(password, 12);

        const user = await User.create({
            username,
            email,
            passwordHash,
            avatarColor: generateAvatarColor(username),
            avatarInitial: getAvatarInitial(username),
        });

        const token = createToken(user);

        res.status(201).json({
            message: "User registered successfully",
            token,
            updateRequired: isOutdated(clientVersion),
            patchNotes: PATCH_NOTES,
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                role: user.role,
                avatarUrl: user.avatarUrl,
                avatarColor: user.avatarColor,
                avatarInitial: user.avatarInitial,
            },
        });
    } catch (error) {
        res.status(500).json({
            message: "Register failed",
            error: error.message,
        });
    }
});

// POST /auth/login
router.post("/login", async (req, res) => {
    try {
        const { emailOrUsername, password, clientVersion } = req.body;

        if (!emailOrUsername || !password) {
            return res.status(400).json({
                message: "Email/username and password are required",
            });
        }

        const loginValue = emailOrUsername.toLowerCase();

        const user = await User.findOne({
            $or: [{ email: loginValue }, { username: loginValue }],
        });

        if (!user) {
            return res.status(401).json({
                message: "Invalid credentials",
            });
        }

        const passwordIsValid = await bcrypt.compare(password, user.passwordHash);

        if (!passwordIsValid) {
            return res.status(401).json({
                message: "Invalid credentials",
            });
        }

        const token = createToken(user);

        res.json({
            message: "Login successful",
            token,
            updateRequired: isOutdated(clientVersion),
            patchNotes: PATCH_NOTES,
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                role: user.role,
                avatarUrl: user.avatarUrl,
                avatarColor: user.avatarColor,
                avatarInitial: user.avatarInitial,
            },
        });
    } catch (error) {
        res.status(500).json({
            message: "Login failed",
            error: error.message,
        });
    }
});

// GET /auth/me
router.get("/me", authMiddleware, async (req, res) => {
    res.json({
        updateRequired: isOutdated(req.query.v),
        patchNotes: PATCH_NOTES,
        user: {
            id: req.user._id,
            username: req.user.username,
            email: req.user.email,
            role: req.user.role,
            avatarUrl: req.user.avatarUrl ?? null,
            avatarColor: req.user.avatarColor,
            avatarInitial: req.user.avatarInitial,
            createdAt: req.user.createdAt,
            bingoLineCount: req.user.bingoLineCount ?? 0,
        },
    });
});

// PUT /auth/password  —  change password (requires current password)
router.put("/password", authMiddleware, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: "Current and new password are required" });
        }
        if (newPassword.length < 8) {
            return res.status(400).json({ message: "New password must be at least 8 characters" });
        }
        const user = await User.findById(req.user._id);
        const valid = await bcrypt.compare(currentPassword, user.passwordHash);
        if (!valid) {
            return res.status(401).json({ message: "Current password is incorrect" });
        }
        if (currentPassword === newPassword) {
            return res.status(400).json({ message: "New password must differ from current" });
        }
        user.passwordHash = await bcrypt.hash(newPassword, 12);
        await user.save();
        res.json({ message: "Password updated successfully" });
    } catch (error) {
        res.status(500).json({ message: "Could not update password", error: error.message });
    }
});

module.exports = router;