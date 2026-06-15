const Post = require('../models/Post');
const { getBerlinOffsetMinutes, localHour, localDow, localDayKey } = require('./localTime');

// Returns the Berlin local date as a Date whose UTC fields hold the local year/month/day.
function berlinDateOf(date) {
  const d = new Date(date);
  const offset = getBerlinOffsetMinutes(d);
  const local = new Date(d.getTime() + offset * 60 * 1000);
  return new Date(Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate()));
}

function berlinHour(date) {
  const d = new Date(date);
  return localHour(d, getBerlinOffsetMinutes(d));
}

function berlinDow(date) {
  const d = new Date(date);
  return localDow(d, getBerlinOffsetMinutes(d));
}

function berlinDayKeyOf(date) {
  const d = new Date(date);
  return localDayKey(d, getBerlinOffsetMinutes(d));
}

// Returns the UTC timestamp for midnight on the first of year/month in Europe/Berlin.
function berlinMonthStart(year, month) {
  const approx = new Date(Date.UTC(year, month - 1, 1));
  return new Date(approx.getTime() - getBerlinOffsetMinutes(approx) * 60 * 1000);
}

const BINGO_POOL = [
  { id: 'friday', label: 'An einem Freitag', emoji: '🎉' },
  { id: 'saturday', label: 'An einem Samstag', emoji: '🕺' },
  { id: 'sunday', label: 'An einem Sonntag', emoji: '😴' },
  { id: 'after_10pm', label: 'Nach 22 Uhr', emoji: '🌆' },
  { id: 'with_caption', label: 'Mit Caption', emoji: '✍️' },
  { id: 'with_location', label: 'Mit Standort', emoji: '📍' },
  { id: 'high_rating', label: '4+ Sterne vergeben', emoji: '✨' },
  { id: 'double_day', label: '2 Biere an einem Tag', emoji: '🍺' },
  { id: 'monday', label: 'An einem Montag', emoji: '😮' },
  { id: 'wednesday', label: 'An einem Mittwoch', emoji: '🐪' },
  { id: 'thursday', label: 'An einem Donnerstag', emoji: '🍻' },
  { id: 'before_4pm', label: 'Vor 16 Uhr', emoji: '☀️' },
  { id: 'mittagsbier', label: 'Mittagsbier (12–14 Uhr)', emoji: '🌞' },
  { id: 'same_spot_twice', label: '2 Tage am selben Ort', emoji: '🏠' },
  { id: 'story_caption', label: 'Story-Caption (50+ Zeichen)', emoji: '📝' },
  { id: 'two_locations', label: '2 Orte an einem Tag', emoji: '🗺️' },
  { id: 'three_types', label: '3 verschiedene Sorten', emoji: '🍻' },
  { id: 'full_weekend', label: 'Fr, Sa & So in einer Woche', emoji: '🎊' },
  { id: 'after_2am', label: 'Nach 2 Uhr nachts', emoji: '🌙' },
  { id: 'three_same_day', label: '3 Biere an einem Tag', emoji: '🎯' },
  { id: 'five_in_week', label: '5 Biere in einer Woche', emoji: '🏆' },
  { id: 'three_locations', label: '3 Orte im Monat', emoji: '🧭' },
  { id: 'far_apart', label: '5 km Abstand', emoji: '🚶' },
  { id: 'five_types', label: '5 verschiedene Sorten', emoji: '🍺' },
  { id: 'early_morning', label: 'Vor 10 Uhr morgens', emoji: '🌅' },
  { id: 'streak_5', label: '5 Tage in Folge', emoji: '🔥' },
  { id: 'ten_total', label: '10 Biere diesen Monat', emoji: '💯' },
  { id: 'streak_7', label: '7 Tage in Folge', emoji: '🔥' },
  { id: 'fifteen_total', label: '15 Biere diesen Monat', emoji: '🏅' },
];

function seededShuffle(arr, seed) {
  const a = [...arr];
  let s = seed >>> 0;
  for (let i = a.length - 1; i > 0; i--) {
    s = ((s * 1664525) + 1013904223) >>> 0;
    const j = s % (i + 1);
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

const FREE_CELL = { id: 'free', label: 'Frei', emoji: '⭐' };

function getMonthCard(year, month) {
  const seed = (year * 100 + month) >>> 0;
  const picked = seededShuffle(BINGO_POOL, seed).slice(0, 24);
  return [...picked.slice(0, 12), FREE_CELL, ...picked.slice(12)];
}

function hasCoordinates(post) {
  return post.location?.coordinates?.length === 2;
}

function getSpotKey(post) {
  if (!hasCoordinates(post)) return null;
  const [lng, lat] = post.location.coordinates;
  return `${(lat * 10).toFixed(0)},${(lng * 10).toFixed(0)}`;
}

function distanceMeters(a, b) {
  const [lngA, latA] = a.location.coordinates;
  const [lngB, latB] = b.location.coordinates;
  const toRad = degrees => (degrees * Math.PI) / 180;
  const dLat = toRad(latB - latA);
  const dLng = toRad(lngB - lngA);
  const h = Math.sin(dLat / 2) ** 2
    + Math.cos(toRad(latA)) * Math.cos(toRad(latB)) * Math.sin(dLng / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

function checkCompletion(cellId, posts) {
  switch (cellId) {
    case 'after_2am':
      return posts.some(p => { const h = berlinHour(p.createdAt); return h >= 2 && h < 6; });
    case 'before_4pm':
      return posts.some(p => berlinHour(p.createdAt) < 16);
    case 'three_types':
      return new Set(posts.map(p => p.drink?.name).filter(Boolean)).size >= 3;
    case 'monday':
      return posts.some(p => berlinDow(p.createdAt) === 1);
    case 'friday':
      return posts.some(p => berlinDow(p.createdAt) === 5);
    case 'saturday':
      return posts.some(p => berlinDow(p.createdAt) === 6);
    case 'sunday':
      return posts.some(p => berlinDow(p.createdAt) === 0);
    case 'five_in_week': {
      const weekMap = {};
      posts.forEach(p => {
        const bd = berlinDateOf(p.createdAt);
        const yr = bd.getUTCFullYear();
        const startOfYear = new Date(Date.UTC(yr, 0, 1));
        const wk = Math.floor((bd - startOfYear) / 604800000);
        weekMap[`${yr}-${wk}`] = (weekMap[`${yr}-${wk}`] || 0) + 1;
      });
      return Object.values(weekMap).some(v => v >= 5);
    }
    case 'after_10pm':
      return posts.some(p => berlinHour(p.createdAt) >= 22);
    case 'with_location':
      return posts.some(hasCoordinates);
    case 'with_caption':
      return posts.some(p => p.caption && p.caption.trim().length > 0);
    case 'three_same_day': {
      const dayMap = {};
      posts.forEach(p => { const k = berlinDayKeyOf(p.createdAt); dayMap[k] = (dayMap[k] || 0) + 1; });
      return Object.values(dayMap).some(v => v >= 3);
    }
    case 'five_stars':
      return posts.some(p => p.rating === 5);
    case 'mittagsbier':
      return posts.some(p => { const h = berlinHour(p.createdAt); return h >= 12 && h < 14; });
    case 'streak_5': {
      const daySet = new Set(posts.map(p => berlinDayKeyOf(p.createdAt)));
      const days = [...daySet].map(k => new Date(k + 'T00:00:00Z')).sort((a, b) => a - b);
      let streak = 1, max = 1;
      for (let i = 1; i < days.length; i++) {
        const diff = (days[i] - days[i - 1]) / 86400000;
        if (diff <= 1.5) { streak++; max = Math.max(max, streak); } else streak = 1;
      }
      return max >= 5;
    }
    case 'three_locations':
      return new Set(posts.map(getSpotKey).filter(Boolean)).size >= 3;
    case 'same_spot_twice': {
      const spotDays = {};
      posts.forEach(p => {
        const spot = getSpotKey(p);
        if (!spot) return;
        if (!spotDays[spot]) spotDays[spot] = new Set();
        spotDays[spot].add(berlinDayKeyOf(p.createdAt));
      });
      return Object.values(spotDays).some(s => s.size >= 2);
    }
    case 'far_apart': {
      const locatedPosts = posts.filter(hasCoordinates);
      for (let i = 0; i < locatedPosts.length; i++) {
        for (let j = i + 1; j < locatedPosts.length; j++) {
          if (distanceMeters(locatedPosts[i], locatedPosts[j]) >= 5000) return true;
        }
      }
      return false;
    }
    case 'thursday':
      return posts.some(p => berlinDow(p.createdAt) === 4);
    case 'high_rating':
      return posts.some(p => p.rating >= 4);
    case 'ten_total':
      return posts.length >= 10;
    case 'two_locations': {
      const dayLocMap = {};
      posts.forEach(p => {
        if (p.location?.coordinates?.length === 2) {
          const key = berlinDayKeyOf(p.createdAt);
          if (!dayLocMap[key]) dayLocMap[key] = new Set();
          const [lng, lat] = p.location.coordinates;
          dayLocMap[key].add(`${(lat * 10).toFixed(0)},${(lng * 10).toFixed(0)}`);
        }
      });
      return Object.values(dayLocMap).some(s => s.size >= 2);
    }
    case 'early_morning':
      return posts.some(p => berlinHour(p.createdAt) < 10);
    case 'wednesday':
      return posts.some(p => berlinDow(p.createdAt) === 3);
    case 'story_caption':
      return posts.some(p => (p.caption || '').trim().length >= 50);
    case 'double_day': {
      const dayMap = {};
      posts.forEach(p => { const k = berlinDayKeyOf(p.createdAt); dayMap[k] = (dayMap[k] || 0) + 1; });
      return Object.values(dayMap).some(v => v >= 2);
    }
    case 'five_types':
      return new Set(posts.map(p => p.drink?.name).filter(Boolean)).size >= 5;
    case 'full_weekend': {
      const weekends = {};
      posts.forEach(p => {
        const day = berlinDow(p.createdAt);
        if (day !== 5 && day !== 6 && day !== 0) return;
        const bd = berlinDateOf(p.createdAt);
        const anchor = new Date(bd);
        if (day === 6) anchor.setUTCDate(bd.getUTCDate() - 1);
        if (day === 0) anchor.setUTCDate(bd.getUTCDate() - 2);
        const key = anchor.toISOString().slice(0, 10);
        if (!weekends[key]) weekends[key] = new Set();
        weekends[key].add(day);
      });
      return Object.values(weekends).some(days => days.has(5) && days.has(6) && days.has(0));
    }
    case 'streak_7': {
      const daySet = new Set(posts.map(p => berlinDayKeyOf(p.createdAt)));
      const days = [...daySet].map(k => new Date(k + 'T00:00:00Z')).sort((a, b) => a - b);
      let streak = 1, max = 1;
      for (let i = 1; i < days.length; i++) {
        const diff = (days[i] - days[i - 1]) / 86400000;
        if (diff <= 1.5) { streak++; max = Math.max(max, streak); } else streak = 1;
      }
      return max >= 7;
    }
    case 'fifteen_total':
      return posts.length >= 15;
    default:
      return false;
  }
}

function countCompletedLines(grid) {
  const done = grid.map(c => c.done);
  let count = 0;
  for (let r = 0; r < 5; r++) {
    if ([0, 1, 2, 3, 4].every(c => done[r * 5 + c])) count++;
  }
  for (let c = 0; c < 5; c++) {
    if ([0, 1, 2, 3, 4].every(r => done[r * 5 + c])) count++;
  }
  if ([0, 1, 2, 3, 4].every(i => done[i * 5 + i])) count++;
  if ([0, 1, 2, 3, 4].every(i => done[i * 5 + (4 - i)])) count++;
  return count;
}

async function buildBingoCardForUser(userId) {
  const bd = berlinDateOf(new Date());
  const year = bd.getUTCFullYear();
  const month = bd.getUTCMonth() + 1;

  const startOfMonth = berlinMonthStart(year, month);
  const endOfMonth = berlinMonthStart(year, month + 1);

  const posts = await Post.find({
    user: userId,
    createdAt: { $gte: startOfMonth, $lt: endOfMonth },
  }).select('createdAt drink caption rating location').lean();

  const card = getMonthCard(year, month);
  const grid = card.map(cell => ({
    id: cell.id,
    label: cell.label,
    emoji: cell.emoji,
    done: cell.id === 'free' || checkCompletion(cell.id, posts),
  }));

  const completedLines = countCompletedLines(grid);
  const isBlackout = grid.every(c => c.done);
  const monthNames = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

  return {
    card: grid,
    completedLines,
    isBlackout,
    monthLabel: `${monthNames[month - 1]} ${year}`,
    totalDone: grid.filter(c => c.done).length,
  };
}

module.exports = { buildBingoCardForUser };
