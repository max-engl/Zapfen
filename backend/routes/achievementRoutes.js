const express = require("express");
const Post = require("../models/Post");
const PostReaction = require("../models/PostReaction");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// Each achievement with progress tracking
const ACHIEVEMENTS = [
    {
        id: "first",
        icon: "first",
        name: "First Round",
        blurb: "Logged your very first pour.",
        getProgress: (posts) => ({
            earned: posts.length >= 1,
            date: posts.length >= 1 ? posts[posts.length - 1].createdAt : null,
        }),
    },
    {
        id: "five_day_streak",
        icon: "streak",
        name: "5-day streak",
        blurb: "Logged a beer 5 days in a row.",
        getProgress: (posts) => {
            const streak = computeStreak(posts);
            return { earned: streak >= 5, have: streak, goal: 5 };
        },
    },
    {
        id: "first_beer_abroad",
        icon: "globe",
        name: "First beer abroad",
        blurb: "Logged your first beer outside Germany.",
        getProgress: (posts) => {
            const post = posts.find((p) => {
                if (p.location?.coordinates?.length !== 2) return false;
                const [lng, lat] = p.location.coordinates;
                return getCountryCode(lat, lng) !== "DE";
            });
            return { earned: Boolean(post), date: post?.createdAt ?? null, have: post ? 1 : 0, goal: 1 };
        },
    },
    {
        id: "century",
        icon: "century",
        name: "100 beers logged",
        blurb: "Logged 100 lifetime beers.",
        getProgress: (posts) => ({
            earned: posts.length >= 100,
            have: posts.length,
            goal: 100,
        }),
    },
    {
        id: "podium",
        icon: "trophy",
        name: "On the Podium",
        blurb: "Finished top 3 in your circle.",
        getProgress: () => ({
            earned: false,
            have: 0,
            goal: 1,
        }),
    },
    {
        id: "explorer",
        icon: "explorer",
        name: "Explorer",
        blurb: "Pour at 20 different spots.",
        getProgress: (posts) => {
            const uniqueSpots = countUniqueSpots(posts);
            return { earned: uniqueSpots >= 20, have: uniqueSpots, goal: 20 };
        },
    },
    {
        id: "magnet",
        icon: "magnet",
        name: "Cheers Magnet",
        blurb: "Receive 500 cheers on your pours.",
        getProgress: (posts) => {
            const totalCheers = posts.reduce((sum, p) => sum + (p.stats?.reactions || 0), 0);
            return { earned: totalCheers >= 500, have: totalCheers, goal: 500 };
        },
    },
    {
        id: "globe",
        icon: "globe",
        name: "Globetrotter",
        blurb: "Pour in 5 different countries.",
        getProgress: (posts) => {
            const countries = countUniqueCountries(posts);
            return { earned: countries >= 5, have: countries, goal: 5 };
        },
    },
    {
        id: "owl",
        icon: "owl",
        name: "Night Owl",
        blurb: "Log 10 pours after midnight.",
        getProgress: (posts) => {
            const nightPours = posts.filter(
                (p) => new Date(p.createdAt).getHours() >= 0 && new Date(p.createdAt).getHours() < 6
            ).length;
            return { earned: nightPours >= 10, have: nightPours, goal: 10 };
        },
    },
    {
        id: "legend",
        icon: "crown",
        name: "Local Legend",
        blurb: "Reach 250 lifetime pints.",
        getProgress: (posts) => ({
            earned: posts.length >= 250,
            have: posts.length,
            goal: 250,
        }),
    },
];

function computeStreak(posts) {
    if (!posts.length) return 0;

    const daySet = new Set(
        posts.map((p) => {
            const d = new Date(p.createdAt);
            return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
        })
    );

    const today = new Date();
    let streak = 0;
    for (let i = 0; i <= 365; i++) {
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
        if (daySet.has(key)) {
            streak++;
        } else if (i > 0) {
            break;
        }
    }
    return streak;
}

function countUniqueSpots(posts) {
    const spots = new Set();
    posts.forEach((p) => {
        if (p.location?.coordinates?.length === 2) {
            const [lng, lat] = p.location.coordinates;
            spots.add(`${(lat * 10).toFixed(0)},${(lng * 10).toFixed(0)}`);
        }
    });
    return spots.size;
}

function countUniqueCountries(posts) {
    const countries = new Set();
    posts.forEach((p) => {
        if (p.location?.coordinates?.length === 2) {
            const [lng, lat] = p.location.coordinates;
            countries.add(getCountryCode(lat, lng));
        }
    });
    return countries.size;
}

function getCountryCode(lat, lng) {
    // Simplified country detection based on coordinates
    if (lat >= 47 && lat <= 55 && lng >= 5 && lng <= 15) return "DE";
    if (lat >= 42.3 && lat <= 51.1 && lng >= 2.2 && lng <= 8.2) return "FR";
    if (lat >= 43.5 && lat <= 47 && lng >= 5 && lng <= 12) return "IT";
    if (lat >= 46 && lat <= 48.2 && lng >= 5.9 && lng <= 10.4) return "CH";
    if (lat >= 50 && lat <= 53 && lng >= -6 && lng <= 2) return "UK";
    if (lat >= 38 && lat <= 43.5 && lng >= -10 && lng <= 4) return "PT";
    if (lat >= 35.8 && lat <= 43.8 && lng >= -9.5 && lng <= 4) return "ES";
    return "OTHER";
}

// GET /achievements/me
router.get("/me", authMiddleware, async (req, res) => {
    try {
        const posts = await Post.find({ user: req.user._id })
            .select("createdAt location stats")
            .sort({ createdAt: -1 })
            .lean();

        const results = ACHIEVEMENTS.map((a) => {
            const progress = a.getProgress(posts);
            const achievement = {
                id: a.id,
                icon: a.icon,
                name: a.name,
                blurb: a.blurb,
                earned: progress.earned,
                have: progress.have || 0,
                goal: progress.goal || 1,
            };

            if (progress.earned && progress.date) {
                achievement.earnedDate = progress.date;
            }

            return achievement;
        });

        res.json({ achievements: results });
    } catch (error) {
        res.status(500).json({ message: "Could not fetch achievements", error: error.message });
    }
});

module.exports = router;
