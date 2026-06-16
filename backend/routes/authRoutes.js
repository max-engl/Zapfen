const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { Resend } = require("resend");

const User = require("../models/User");
const DeletionRequest = require("../models/DeletionRequest");
const authMiddleware = require("../middleware/authMiddleware");
const { generateAvatarColor, getAvatarInitial } = require("../utils/avatarUtil");

const router = express.Router();

const MIN_CLIENT_VERSION = '1.4';

const PATCH_NOTES = [
    'Bug fixes und co.',
    'Statistiken sind jetzt übersichtlicher.',
    'Die Post-Zeiten sind jetzt korrekt'
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

// POST /auth/logout  —  clear FCM token so the device stops receiving push notifications
router.post("/logout", authMiddleware, async (req, res) => {
    try {
        await User.findByIdAndUpdate(req.user._id, { $unset: { fcmToken: "" } });
        res.json({ message: "Logged out" });
    } catch (error) {
        res.status(500).json({ message: "Logout failed", error: error.message });
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

// POST /auth/forgot-password
router.post("/forgot-password", async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ message: "Email required" });

        // Always respond with the same message to prevent email enumeration
        const user = await User.findOne({ email: email.trim().toLowerCase() });
        if (!user) {
            return res.json({ message: "Falls diese E-Mail existiert, wurde ein Link gesendet." });
        }

        const token = crypto.randomBytes(32).toString("hex");
        user.passwordResetToken = token;
        user.passwordResetExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
        await user.save();

        const resend = new Resend(process.env.RESEND_API_KEY);
        const baseUrl = (process.env.API_BASE_URL || 'https://api.zapfenapp.de').replace(/\/$/, '');
        const resetUrl = `${baseUrl}/reset-password/${token}`;

        await resend.emails.send({
            from: "Zapfen <noreply@zapfenapp.de>",
            to: user.email,
            subject: "Passwort zurücksetzen",
            html: `<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Passwort zurücksetzen – Zapfen</title>
</head>
<body style="margin:0;padding:0;background:#0F0F0F;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0F0F0F;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#1A1A1A;border-radius:24px;border:1px solid #2A2A2A;overflow:hidden;">
          <!-- Header -->
          <tr>
            <td style="padding:36px 36px 0;text-align:center;">
              <div style="display:inline-block;background:#F6B733;border-radius:18px;width:52px;height:52px;line-height:52px;font-size:28px;text-align:center;">🍺</div>
            </td>
          </tr>
          <!-- Title -->
          <tr>
            <td style="padding:20px 36px 0;text-align:center;">
              <h1 style="margin:0;color:#FFFFFF;font-size:24px;font-weight:800;letter-spacing:-0.6px;line-height:1.15;">Passwort zurücksetzen</h1>
            </td>
          </tr>
          <!-- Body text -->
          <tr>
            <td style="padding:12px 36px 0;text-align:center;">
              <p style="margin:0;color:#888888;font-size:14px;line-height:1.6;">
                Hey @${user.username},<br>du hast eine Passwort-Zurücksetzung für dein Zapfen-Konto angefragt.
                Tippe auf den Button, um ein neues Passwort zu wählen.
              </p>
            </td>
          </tr>
          <!-- CTA Button -->
          <tr>
            <td style="padding:28px 36px 0;text-align:center;">
              <a href="${resetUrl}"
                 style="display:inline-block;background:#F6B733;color:#1A1000;text-decoration:none;border-radius:14px;padding:15px 36px;font-size:16px;font-weight:700;letter-spacing:-0.2px;">
                Passwort zurücksetzen
              </a>
            </td>
          </tr>
          <!-- Expiry note -->
          <tr>
            <td style="padding:18px 36px 0;text-align:center;">
              <p style="margin:0;color:#555555;font-size:12px;">
                Dieser Link ist <strong style="color:#888888;">1 Stunde</strong> gültig.
              </p>
            </td>
          </tr>
          <!-- Divider -->
          <tr>
            <td style="padding:24px 36px 0;">
              <div style="height:1px;background:#2A2A2A;"></div>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:20px 36px 32px;text-align:center;">
              <p style="margin:0;color:#444444;font-size:11px;line-height:1.6;">
                Falls du keine Zurücksetzung beantragt hast, kannst du diese E-Mail ignorieren –
                dein Konto ist sicher.<br><br>
                © Zapfen · <a href="https://zapfenapp.de" style="color:#555555;text-decoration:none;">zapfenapp.de</a>
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
        });

        res.json({ message: "Falls diese E-Mail existiert, wurde ein Link gesendet." });
    } catch (error) {
        console.error("[forgot-password]", error);
        res.status(500).json({ message: "Fehler beim Senden der E-Mail." });
    }
});

// POST /auth/reset-password
router.post("/reset-password", async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        if (!token || !newPassword) {
            return res.status(400).json({ message: "Token and new password required" });
        }
        if (newPassword.length < 8) {
            return res.status(400).json({ message: "Password must be at least 8 characters" });
        }

        const user = await User.findOne({
            passwordResetToken: token,
            passwordResetExpiry: { $gt: new Date() },
        });

        if (!user) {
            return res.status(400).json({ message: "Ungültiger oder abgelaufener Link." });
        }

        user.passwordHash = await bcrypt.hash(newPassword, 12);
        user.passwordResetToken = null;
        user.passwordResetExpiry = null;
        await user.save();

        res.json({ message: "Passwort erfolgreich zurückgesetzt." });
    } catch (error) {
        console.error("[reset-password]", error);
        res.status(500).json({ message: "Fehler beim Zurücksetzen des Passworts." });
    }
});

// POST /auth/deletion-request — public endpoint for account deletion requests
router.post("/deletion-request", async (req, res) => {
    try {
        const { email } = req.body;
        if (!email || typeof email !== "string" || !email.includes("@")) {
            return res.status(400).json({ message: "Gültige E-Mail-Adresse erforderlich" });
        }
        await DeletionRequest.create({ email: email.trim().toLowerCase() });
        res.status(201).json({ message: "Anfrage erfolgreich eingereicht" });
    } catch (error) {
        res.status(500).json({ message: "Fehler beim Einreichen der Anfrage" });
    }
});

module.exports = router;