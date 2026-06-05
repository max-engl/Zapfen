const express = require("express");
const Post = require("../models/Post");
const PostReaction = require("../models/PostReaction");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

const LOCATION_ACHIEVEMENTS = [

    {
        id: "bundestag",
        icon: "explorer",
        name: "Flüssige Demokratie",
        blurb: "Logge ein Bier im Umkreis von 500m um den Bundestag.",
        latitude: 52.5186,
        longitude: 13.3762,
        radiusMeters: 500,
        goal: 1,
    },
    {
        id: "zirkel",
        icon: "streak",
        name: "Im Kreis gedreht",
        blurb: "Logge ein Bier im Zirkel",
        latitude: 49.6025046,
        longitude: 11.0030489,
        radiusMeters: 50,
        goal: 1,
    },
].map(createLocationAchievement);

// Each achievement with progress tracking
const ACHIEVEMENTS = [
    {
        id: "first",
        icon: "first",
        name: "Erste Runde",
        blurb: "Du hast dein erstes Bier geloggt.",
        getProgress: (posts) => ({
            earned: posts.length >= 1,
            date: posts.length >= 1 ? posts[posts.length - 1].createdAt : null,
        }),
    },
    {
        id: "five_day_streak",
        icon: "streak",
        name: "Heiße Serie",
        blurb: "Logge an 5 Tagen hintereinander ein Bier.",
        getProgress: (posts) => {
            const streak = computeStreak(posts);
            return { earned: streak >= 5, have: streak, goal: 5 };
        },
    },
    {
        id: "first_beer_abroad",
        icon: "globe",
        name: "Erstes Auslandsbier",
        blurb: "Logge dein erstes Bier außerhalb Deutschlands.",
        getProgress: (posts) => {
            const post = posts.find((p) => {
                if (p.location?.coordinates?.length !== 2) return false;
                const [lng, lat] = p.location.coordinates;
                return getCountryCode(lat, lng) !== "DE";
            });
            return {
                earned: Boolean(post),
                date: post?.createdAt ?? null,
                have: post ? 1 : 0,
                goal: 1,
            };
        },
    },
    {
        id: "century",
        icon: "century",
        name: "100 Biere",
        blurb: "Logge insgesamt 100 Biere.",
        getProgress: (posts) => ({
            earned: posts.length >= 100,
            have: posts.length,
            goal: 100,
        }),
    },
    {
        id: "podium",
        icon: "trophy",
        name: "Auf dem Podium",
        blurb: "Beende die Woche in deinem Kreis unter den Top 3.",
        getProgress: () => ({
            earned: false,
            have: 0,
            goal: 1,
        }),
    },
    {
        id: "explorer",
        icon: "explorer",
        name: "Entdecker",
        blurb: "Logge Bier an 20 verschiedenen Orten.",
        getProgress: (posts) => {
            const uniqueSpots = countUniqueSpots(posts);
            return { earned: uniqueSpots >= 20, have: uniqueSpots, goal: 20 };
        },
    },
    {
        id: "magnet",
        icon: "magnet",
        name: "Cheers-Magnet",
        blurb: "Erhalte 500 Cheers auf deine Posts.",
        getProgress: (posts) => {
            const totalCheers = posts.reduce(
                (sum, p) => sum + (p.stats?.reactions || 0),
                0,
            );
            return { earned: totalCheers >= 500, have: totalCheers, goal: 500 };
        },
    },
    {
        id: "globe",
        icon: "globe",
        name: "Weltenbummler",
        blurb: "Logge Bier in 5 verschiedenen Ländern.",
        getProgress: (posts) => {
            const countries = countUniqueCountries(posts);
            return { earned: countries >= 5, have: countries, goal: 5 };
        },
    },
    {
        id: "owl",
        icon: "owl",
        name: "Nachteule",
        blurb: "Logge 10 Biere nach Mitternacht.",
        getProgress: (posts) => {
            const nightPours = posts.filter(
                (p) =>
                    new Date(p.createdAt).getHours() >= 0 &&
                    new Date(p.createdAt).getHours() < 6,
            ).length;
            return { earned: nightPours >= 10, have: nightPours, goal: 10 };
        },
    },
    {
        id: "legend",
        icon: "crown",
        name: "Lokale Legende",
        blurb: "Erreiche 250 geloggte Biere.",
        getProgress: (posts) => ({
            earned: posts.length >= 250,
            have: posts.length,
            goal: 250,
        }),
    },
    ...LOCATION_ACHIEVEMENTS,
];

function computeStreak(posts) {
    if (!posts.length) return 0;

    const daySet = new Set(
        posts.map((p) => {
            const d = new Date(p.createdAt);
            return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
        }),
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

function createLocationAchievement(config) {
    const {
        id,
        icon = "explorer",
        name,
        blurb,
        latitude,
        longitude,
        radiusMeters,
        goal = 1,
    } = config;

    if (!id || !name || !blurb) {
        throw new Error("Location achievements need id, name, and blurb.");
    }

    if (
        !Number.isFinite(latitude) ||
        !Number.isFinite(longitude) ||
        !Number.isFinite(radiusMeters) ||
        radiusMeters <= 0 ||
        !Number.isFinite(goal) ||
        goal <= 0
    ) {
        throw new Error(
            `Location achievement "${id}" needs valid latitude, longitude, radiusMeters, and goal.`,
        );
    }

    return {
        id,
        icon,
        name,
        blurb,
        mapTarget: {
            latitude,
            longitude,
            radiusMeters,
        },
        getProgress: (posts) => {
            const matchingPosts = posts.filter((post) =>
                isPostWithinRadius(post, latitude, longitude, radiusMeters),
            );

            return {
                earned: matchingPosts.length >= goal,
                have: matchingPosts.length,
                goal,
                date:
                    matchingPosts.length > 0
                        ? matchingPosts[matchingPosts.length - 1].createdAt
                        : null,
            };
        },
    };
}

function isPostWithinRadius(post, targetLat, targetLng, radiusMeters) {
    if (post.location?.coordinates?.length !== 2) return false;
    const [lng, lat] = post.location.coordinates;
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
    return distanceMeters(lat, lng, targetLat, targetLng) <= radiusMeters;
}

function distanceMeters(latA, lngA, latB, lngB) {
    const earthRadiusMeters = 6371000;
    const dLat = degreesToRadians(latB - latA);
    const dLng = degreesToRadians(lngB - lngA);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(degreesToRadians(latA)) *
        Math.cos(degreesToRadians(latB)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function degreesToRadians(degrees) {
    return (degrees * Math.PI) / 180;
}

// GET /achievements/location-targets
router.get("/location-targets", authMiddleware, async (req, res) => {
    try {
        res.set("Cache-Control", "no-store");
        const posts = await Post.find({ user: req.user._id })
            .select("createdAt location stats")
            .sort({ createdAt: -1 })
            .lean();

        const targets = LOCATION_ACHIEVEMENTS.map((a) => {
            const progress = a.getProgress(posts);
            const target = {
                id: a.id,
                icon: a.icon,
                name: a.name,
                blurb: a.blurb,
                latitude: a.mapTarget.latitude,
                longitude: a.mapTarget.longitude,
                radiusMeters: a.mapTarget.radiusMeters,
                earned: progress.earned,
                have: progress.have || 0,
                goal: progress.goal || 1,
            };
            target.statusLabel = buildStatusLabel(target, progress.date);
            return target;
        });

        res.json({ targets });
    } catch (error) {
        res.status(500).json({
            message: "Erfolgsorte konnten nicht geladen werden.",
            error: error.message,
        });
    }
});

// GET /achievements/me
router.get("/me", authMiddleware, async (req, res) => {
    try {
        res.set("Cache-Control", "no-store");
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
            achievement.statusLabel = buildStatusLabel(achievement, progress.date);

            if (progress.earned && progress.date) {
                achievement.earnedDate = progress.date;
            }

            return achievement;
        });

        res.json({ achievements: results });
    } catch (error) {
        res.status(500).json({
            message: "Erfolge konnten nicht geladen werden.",
            error: error.message,
        });
    }
});

function buildStatusLabel(achievement, earnedDate) {
    if (!achievement.earned) {
        const remaining = Math.max(achievement.goal - achievement.have, 0);
        return `Noch ${remaining} · ${Math.min(achievement.have, achievement.goal)}/${achievement.goal}`;
    }

    if (!earnedDate) return "Erhalten";

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const date = new Date(earnedDate);
    const earnedDay = new Date(
        date.getFullYear(),
        date.getMonth(),
        date.getDate(),
    );
    const days = Math.floor((today - earnedDay) / (24 * 60 * 60 * 1000));

    if (days <= 0) return "Erhalten · heute";
    if (days === 1) return "Erhalten · gestern";
    if (days < 7) return `Erhalten · vor ${days}T`;
    if (days < 56) return `Erhalten · vor ${Math.floor(days / 7)}W`;
    return "Erhalten";
}

// GET /achievements/user/:userId  — achievements for a friend's profile
router.get("/user/:userId", authMiddleware, async (req, res) => {
    try {
        res.set("Cache-Control", "no-store");
        const targetId = req.params.userId;

        const posts = await Post.find({ user: targetId })
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
            achievement.statusLabel = buildStatusLabel(achievement, progress.date);
            if (progress.earned && progress.date) {
                achievement.earnedDate = progress.date;
            }
            return achievement;
        });

        res.json({ achievements: results });
    } catch (error) {
        res.status(500).json({
            message: "Erfolge konnten nicht geladen werden.",
            error: error.message,
        });
    }
});

module.exports = router;
