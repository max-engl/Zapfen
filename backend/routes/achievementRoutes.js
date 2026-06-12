const express = require("express");
const fs = require("fs");
const path = require("path");
const Post = require("../models/Post");
const PostReaction = require("../models/PostReaction");
const User = require("../models/User");
const authMiddleware = require("../middleware/authMiddleware");
const { getFriendIds } = require("../utils/friends");
const { getTzOffset, localDayKey, localHour, localDow } = require("../utils/localTime");

const router = express.Router();

// Overpass API cache: cacheKey -> { result: boolean, expiresAt: number }
const OSM_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const OSM_CACHE_FILE = path.join(__dirname, "../cache/osm_cache.json");

function loadOsmCache() {
    try {
        const raw = fs.readFileSync(OSM_CACHE_FILE, "utf8");
        const entries = JSON.parse(raw);
        const map = new Map();
        const now = Date.now();
        for (const [k, v] of Object.entries(entries)) {
            if (v.expiresAt > now) map.set(k, v);
        }
        return map;
    } catch {
        return new Map();
    }
}

function saveOsmCache(map) {
    try {
        fs.mkdirSync(path.dirname(OSM_CACHE_FILE), { recursive: true });
        const obj = Object.fromEntries(map);
        fs.writeFileSync(OSM_CACHE_FILE, JSON.stringify(obj), "utf8");
    } catch (err) {
        console.error("OSM cache write failed:", err.message);
    }
}

const osmCache = loadOsmCache();
const osmInflight = new Map(); // in-flight promise deduplication

async function isNearOSMFeature(lat, lng, osmKey, osmValue, radiusMeters) {
    const cacheKey = `${lat.toFixed(3)},${lng.toFixed(3)},${osmKey},${osmValue},${radiusMeters}`;
    const cached = osmCache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) return cached.result;

    // Reuse an already-in-flight request for the same key
    if (osmInflight.has(cacheKey)) return osmInflight.get(cacheKey);

    const filter = osmValue ? `["${osmKey}"="${osmValue}"]` : `["${osmKey}"]`;
    const query = [
        `[out:json][timeout:10];`,
        `(`,
        `  node${filter}(around:${radiusMeters},${lat},${lng});`,
        `  way${filter}(around:${radiusMeters},${lat},${lng});`,
        `  relation${filter}(around:${radiusMeters},${lat},${lng});`,
        `);`,
        `out count;`,
    ].join("");

    const promise = (async () => {
        try {
            const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;
            const response = await fetch(url, {
                signal: AbortSignal.timeout(15000),
                headers: { "Accept": "application/json" },
            });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const data = await response.json();
            const result = parseInt(data.elements?.[0]?.tags?.total ?? "0", 10) > 0;
            osmCache.set(cacheKey, { result, expiresAt: Date.now() + OSM_CACHE_TTL_MS });
            saveOsmCache(osmCache);
            return result;
        } catch (err) {
            console.error(`OSM query failed (${lat},${lng}):`, err.message);
            // Cache the failure for 1 hour so we don't hammer Overpass while blocked
            osmCache.set(cacheKey, { result: false, expiresAt: Date.now() + 60 * 60 * 1000 });
            saveOsmCache(osmCache);
            return false;
        } finally {
            osmInflight.delete(cacheKey);
        }
    })();

    osmInflight.set(cacheKey, promise);
    return promise;
}

function createOSMAchievement({ id, icon, name, blurb, osmKey, osmValue, radiusMeters = 500, goal = 1 }) {
    return {
        id,
        icon,
        name,
        blurb,
        getProgress: async (posts) => {
            const located = posts.filter((p) => p.location?.coordinates?.length === 2);
            const matches = [];
            for (const post of located) {
                if (matches.length >= goal) break;
                const [lng, lat] = post.location.coordinates;
                if (await isNearOSMFeature(lat, lng, osmKey, osmValue, radiusMeters)) {
                    matches.push(post);
                }
            }
            return {
                earned: matches.length >= goal,
                have: Math.min(matches.length, goal),
                goal,
                date: matches.length > 0 ? matches[matches.length - 1].createdAt : null,
            };
        },
    };
}

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
    {
        id: "maseven",
        icon: "streak",
        name: "Maseven drink",
        blurb: "Logge ein Bier im Maseven",
        latitude: 50.0981172,
        longitude: 8.6430633,
        radiusMeters: 300,
        goal: 1,
    },
].map(createLocationAchievement);

// Each achievement with progress tracking
const ACHIEVEMENTS = [
    {
        id: "first",
        icon: "first",
        name: "Erste Runde",
        blurb: "Du hast deinen ersten Drink geloggt.",
        getProgress: (posts) => ({
            earned: posts.length >= 1,
            date: posts.length >= 1 ? posts[posts.length - 1].createdAt : null,
        }),
    },
    {
        id: "five_day_streak",
        icon: "streak",
        name: "Heiße Serie",
        blurb: "Logge an 5 Tagen hintereinander einen Drink.",
        getProgress: (posts, offsetMinutes = 0) => {
            const streak = computeStreak(posts, offsetMinutes);
            return { earned: streak >= 5, have: streak, goal: 5 };
        },
    },
    {
        id: "first_beer_abroad",
        icon: "globe",
        name: "Erstes Auslandsbier",
        blurb: "Logge deinen ersten Drink außerhalb Deutschlands.",
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
        name: "100 Drinks",
        blurb: "Logge insgesamt 100 Drinks.",
        getProgress: (posts) => ({
            earned: posts.length >= 100,
            have: posts.length,
            goal: 100,
        }),
    },
    {
        id: "explorer",
        icon: "explorer",
        name: "Entdecker",
        blurb: "Logge Drinks an 20 verschiedenen Orten.",
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
        blurb: "Logge Drinks in 5 verschiedenen Ländern.",
        getProgress: (posts) => {
            const countries = countUniqueCountries(posts);
            return { earned: countries >= 5, have: countries, goal: 5 };
        },
    },
    {
        id: "owl",
        icon: "owl",
        name: "Nachteule",
        blurb: "Logge 10 Drinks nach Mitternacht.",
        getProgress: (posts, offsetMinutes = 0) => {
            const nightPours = posts.filter((p) => {
                const h = localHour(new Date(p.createdAt), offsetMinutes);
                return h >= 0 && h < 6;
            }).length;
            return { earned: nightPours >= 10, have: nightPours, goal: 10 };
        },
    },
    {
        id: "legend",
        icon: "crown",
        name: "Lokale Legende",
        blurb: "Erreiche 250 geloggte Drinks.",
        getProgress: (posts) => ({
            earned: posts.length >= 250,
            have: posts.length,
            goal: 250,
        }),
    },
    ...LOCATION_ACHIEVEMENTS,

];

const HIDDEN_ACHIEVEMENTS = [
    {
        id: "hidden_all_week",
        icon: "secret",
        name: "Sieben-Tage-Woche",
        blurb: "Du hast an allen 7 Wochentagen mindestens einmal geloggt.",
        getProgress: (posts, offsetMinutes = 0) => {
            const days = new Set(posts.map((p) => localDow(new Date(p.createdAt), offsetMinutes)));
            return { earned: days.size === 7 };
        },
    },
    {
        id: "hidden_midnight",
        icon: "secret",
        name: "Geisterstunde",
        blurb: "Geloggt genau zwischen 00:00 und 00:05 Uhr.",
        getProgress: (posts, offsetMinutes = 0) => ({
            earned: posts.some((p) => {
                const d = new Date(p.createdAt.getTime() + offsetMinutes * 60 * 1000);
                return d.getUTCHours() === 0 && d.getUTCMinutes() < 5;
            }),
        }),
    },
    {
        id: "hidden_monday_morning",
        icon: "secret",
        name: "Montagsfrühstück",
        blurb: "Geloggt vor 9 Uhr morgens an einem Montag.",
        getProgress: (posts, offsetMinutes = 0) => ({
            earned: posts.some((p) => {
                return localDow(new Date(p.createdAt), offsetMinutes) === 1 &&
                       localHour(new Date(p.createdAt), offsetMinutes) < 9;
            }),
        }),
    },
    {
        id: "hidden_rainbow",
        icon: "secret",
        name: "Regenbogen",
        blurb: "7 verschiedene Sorten an einem einzigen Tag geloggt.",
        getProgress: (posts, offsetMinutes = 0) => {
            const byDay = {};
            posts.forEach((p) => {
                const key = localDayKey(new Date(p.createdAt), offsetMinutes);
                if (!byDay[key]) byDay[key] = new Set();
                if (p.drink?.name) byDay[key].add(p.drink.name);
            });
            return { earned: Object.values(byDay).some((s) => s.size >= 7) };
        },
    },
    {
        id: "hidden_loyal",
        icon: "secret",
        name: "Stammgast",
        blurb: "An demselben Ort an mindestens 5 verschiedenen Tagen geloggt.",
        getProgress: (posts, offsetMinutes = 0) => {
            const spotDays = {};
            posts.forEach((p) => {
                if (p.location?.coordinates?.length === 2) {
                    const [lng, lat] = p.location.coordinates;
                    const spot = `${(lat * 10).toFixed(0)},${(lng * 10).toFixed(0)}`;
                    if (!spotDays[spot]) spotDays[spot] = new Set();
                    spotDays[spot].add(localDayKey(new Date(p.createdAt), offsetMinutes));
                }
            });
            return { earned: Object.values(spotDays).some((s) => s.size >= 5) };
        },
    },
];

function computeStreak(posts, offsetMinutes = 0) {
    if (!posts.length) return 0;

    const daySet = new Set(posts.map((p) => localDayKey(new Date(p.createdAt), offsetMinutes)));

    let streak = 0;
    for (let i = 0; i <= 365; i++) {
        const key = localDayKey(new Date(Date.now() - i * 86400000), offsetMinutes);
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
        const offsetMinutes = getTzOffset(req);
        const posts = await Post.find({ user: req.user._id })
            .select("createdAt location stats")
            .sort({ createdAt: -1 })
            .lean();

        const targets = await Promise.all(LOCATION_ACHIEVEMENTS.map(async (a) => {
            const progress = await a.getProgress(posts, offsetMinutes);
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
            target.statusLabel = buildStatusLabel(target, progress.date, offsetMinutes);
            return target;
        }));

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
        const offsetMinutes = getTzOffset(req);
        const posts = await Post.find({ user: req.user._id })
            .select("createdAt location stats")
            .sort({ createdAt: -1 })
            .lean();

        const results = [];
        for (const a of ACHIEVEMENTS) {
            const progress = await a.getProgress(posts, offsetMinutes);
            const achievement = {
                id: a.id,
                icon: a.icon,
                name: a.name,
                blurb: a.blurb,
                earned: progress.earned,
                have: progress.have || 0,
                goal: progress.goal || 1,
            };
            achievement.statusLabel = buildStatusLabel(achievement, progress.date, offsetMinutes);
            if (progress.earned && progress.date) {
                achievement.earnedDate = progress.date;
            }
            results.push(achievement);
        }

        const hiddenResults = await Promise.all(HIDDEN_ACHIEVEMENTS.map(async (a) => {
            const progress = await a.getProgress(posts, offsetMinutes);
            if (!progress.earned) {
                return {
                    id: a.id,
                    icon: "secret",
                    name: "???",
                    blurb: "Ein geheimes Achievement wartet auf dich.",
                    earned: false,
                    hidden: true,
                    have: 0,
                    goal: 1,
                    statusLabel: "???",
                };
            }
            return {
                id: a.id,
                icon: a.icon,
                name: a.name,
                blurb: a.blurb,
                earned: true,
                hidden: true,
                have: 1,
                goal: 1,
                statusLabel: buildStatusLabel({ earned: true, have: 1, goal: 1 }, null, offsetMinutes),
            };
        }));

        res.json({ achievements: [...results, ...hiddenResults] });
    } catch (error) {
        res.status(500).json({
            message: "Erfolge konnten nicht geladen werden.",
            error: error.message,
        });
    }
});

function buildStatusLabel(achievement, earnedDate, offsetMinutes = 0) {
    if (!achievement.earned) {
        const remaining = Math.max(achievement.goal - achievement.have, 0);
        return `Noch ${remaining} · ${Math.min(achievement.have, achievement.goal)}/${achievement.goal}`;
    }

    if (!earnedDate) return "Erhalten";

    const todayKey = localDayKey(new Date(), offsetMinutes);
    const earnedKey = localDayKey(new Date(earnedDate), offsetMinutes);
    const todayMs = new Date(todayKey).getTime();
    const earnedMs = new Date(earnedKey).getTime();
    const days = Math.floor((todayMs - earnedMs) / 86400000);

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
        const offsetMinutes = getTzOffset(req);
        const targetId = req.params.userId;

        const posts = await Post.find({ user: targetId })
            .select("createdAt location stats")
            .sort({ createdAt: -1 })
            .lean();

        const results = [];
        for (const a of ACHIEVEMENTS) {
            const progress = await a.getProgress(posts, offsetMinutes);
            const achievement = {
                id: a.id,
                icon: a.icon,
                name: a.name,
                blurb: a.blurb,
                earned: progress.earned,
                have: progress.have || 0,
                goal: progress.goal || 1,
            };
            achievement.statusLabel = buildStatusLabel(achievement, progress.date, offsetMinutes);
            if (progress.earned && progress.date) {
                achievement.earnedDate = progress.date;
            }
            results.push(achievement);
        }

        res.json({ achievements: results });
    } catch (error) {
        res.status(500).json({
            message: "Erfolge konnten nicht geladen werden.",
            error: error.message,
        });
    }
});

// GET /achievements/:achievementId/friends — how friends (+ self) are doing on one achievement
router.get("/:achievementId/friends", authMiddleware, async (req, res) => {
    try {
        const { achievementId } = req.params;

        const allDefs = [...ACHIEVEMENTS, ...HIDDEN_ACHIEVEMENTS];
        const def = allDefs.find((a) => a.id === achievementId);
        if (!def) {
            return res.status(404).json({ message: "Achievement nicht gefunden." });
        }

        const friendIds = await getFriendIds(req.user._id);
        const allUserIds = [req.user._id, ...friendIds];

        const users = await User.find({ _id: { $in: allUserIds } })
            .select("_id username avatarColor avatarInitial avatarUrl")
            .lean();

        const standings = [];
        for (const user of users) {
            const posts = await Post.find({ user: user._id })
                .select("createdAt location stats drink")
                .sort({ createdAt: -1 })
                .lean();

            const progress = await def.getProgress(posts);
            const isSelf = user._id.toString() === req.user._id.toString();
            const goal = progress.goal ?? 1;
            const have = progress.have ?? (progress.earned ? goal : 0);

            standings.push({
                userId: user._id,
                username: user.username,
                avatarColor: user.avatarColor ?? "#F6B733",
                avatarInitial: user.avatarInitial ?? "?",
                avatarUrl: user.avatarUrl ?? null,
                isSelf,
                earned: Boolean(progress.earned),
                earnedDate: progress.earned && progress.date ? progress.date : null,
                have: Math.min(have, goal),
                goal,
            });
        }

        standings.sort((a, b) => {
            if (a.earned !== b.earned) return a.earned ? -1 : 1;
            const aRatio = a.goal > 0 ? a.have / a.goal : 0;
            const bRatio = b.goal > 0 ? b.have / b.goal : 0;
            return bRatio - aRatio;
        });

        res.json({ standings });
    } catch (error) {
        res.status(500).json({
            message: "Freundes-Standings konnten nicht geladen werden.",
            error: error.message,
        });
    }
});

module.exports = router;
