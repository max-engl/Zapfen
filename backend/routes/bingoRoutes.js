const express = require('express');
const Post = require('../models/Post');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

const BINGO_POOL = [
  { id: 'after_2am', label: 'Nach 2 Uhr nachts', emoji: '🌙' },
  { id: 'before_4pm', label: 'Vor 16 Uhr', emoji: '☀️' },
  { id: 'three_types', label: '3 versch. Sorten', emoji: '🍻' },
  { id: 'monday', label: 'An einem Montag', emoji: '😮' },
  { id: 'friday', label: 'An einem Freitag', emoji: '🎉' },
  { id: 'saturday', label: 'An einem Samstag', emoji: '🕺' },
  { id: 'sunday', label: 'An einem Sonntag', emoji: '😴' },
  { id: 'five_in_week', label: '5 Biere in einer Woche', emoji: '🏆' },
  { id: 'after_10pm', label: 'Nach 22 Uhr', emoji: '🌆' },
  { id: 'weizen', label: 'Ein Weizen', emoji: '🍺' },
  { id: 'radler', label: 'Ein Radler', emoji: '🍋' },
  { id: 'with_caption', label: 'Mit Caption', emoji: '✍️' },
  { id: 'three_same_day', label: '3 Biere an einem Tag', emoji: '🎯' },
  { id: 'five_stars', label: '5 Sterne vergeben', emoji: '⭐' },
  { id: 'mittagsbier', label: 'Mittagsbier (12–14 Uhr)', emoji: '🌞' },
  { id: 'streak_5', label: '5 Tage in Folge', emoji: '🔥' },
  { id: 'aperol', label: 'Aperol Spritz', emoji: '🍊' },
  { id: 'wine', label: 'Einen Wein', emoji: '🍷' },
  { id: 'cocktail', label: 'Einen Cocktail', emoji: '🍹' },
  { id: 'thursday', label: 'An einem Donnerstag', emoji: '🍻' },
  { id: 'high_rating', label: '4+ Sterne', emoji: '✨' },
  { id: 'ten_total', label: '10 Biere diesen Monat', emoji: '💯' },
  { id: 'two_locations', label: '2 Orte an einem Tag', emoji: '🗺️' },
  { id: 'early_morning', label: 'Vor 10 Uhr morgens', emoji: '🌅' },
  { id: 'wednesday', label: 'An einem Mittwoch', emoji: '🐪' },
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

function checkCompletion(cellId, posts) {
  switch (cellId) {
    case 'after_2am':
      return posts.some(p => { const h = new Date(p.createdAt).getHours(); return h >= 2 && h < 6; });
    case 'before_4pm':
      return posts.some(p => new Date(p.createdAt).getHours() < 16);
    case 'three_types':
      return new Set(posts.map(p => p.drink?.name).filter(Boolean)).size >= 3;
    case 'monday':
      return posts.some(p => new Date(p.createdAt).getDay() === 1);
    case 'friday':
      return posts.some(p => new Date(p.createdAt).getDay() === 5);
    case 'saturday':
      return posts.some(p => new Date(p.createdAt).getDay() === 6);
    case 'sunday':
      return posts.some(p => new Date(p.createdAt).getDay() === 0);
    case 'five_in_week': {
      const weekMap = {};
      posts.forEach(p => {
        const d = new Date(p.createdAt);
        const yr = d.getFullYear();
        const wk = Math.floor((d - new Date(yr, 0, 1)) / 604800000);
        const key = `${yr}-${wk}`;
        weekMap[key] = (weekMap[key] || 0) + 1;
      });
      return Object.values(weekMap).some(v => v >= 5);
    }
    case 'after_10pm':
      return posts.some(p => new Date(p.createdAt).getHours() >= 22);
    case 'weizen':
      return posts.some(p => (p.drink?.name || '').toLowerCase().includes('weizen'));
    case 'radler':
      return posts.some(p => (p.drink?.name || '').toLowerCase().includes('radler'));
    case 'with_caption':
      return posts.some(p => p.caption && p.caption.trim().length > 0);
    case 'three_same_day': {
      const dayMap = {};
      posts.forEach(p => { const k = new Date(p.createdAt).toDateString(); dayMap[k] = (dayMap[k] || 0) + 1; });
      return Object.values(dayMap).some(v => v >= 3);
    }
    case 'five_stars':
      return posts.some(p => p.rating === 5);
    case 'mittagsbier':
      return posts.some(p => { const h = new Date(p.createdAt).getHours(); return h >= 12 && h < 14; });
    case 'streak_5': {
      const daySet = new Set(posts.map(p => new Date(p.createdAt).toDateString()));
      const days = [...daySet].map(d => new Date(d)).sort((a, b) => a - b);
      let streak = 1, max = 1;
      for (let i = 1; i < days.length; i++) {
        const diff = (days[i] - days[i - 1]) / 86400000;
        if (diff <= 1.5) { streak++; max = Math.max(max, streak); } else streak = 1;
      }
      return max >= 5;
    }
    case 'aperol':
      return posts.some(p => (p.drink?.name || '').toLowerCase().includes('aperol'));
    case 'wine':
      return posts.some(p => { const n = (p.drink?.name || '').toLowerCase(); return n.includes('wein') || n.includes('sekt') || n.includes('schorle'); });
    case 'cocktail':
      return posts.some(p => { const n = (p.drink?.name || '').toLowerCase(); return ['gin', 'vodka', 'rum', 'hugo', 'mojito', 'tonic', 'korn', 'whisky', 'whiskey', 'long', 'cocktail'].some(c => n.includes(c)); });
    case 'thursday':
      return posts.some(p => new Date(p.createdAt).getDay() === 4);
    case 'high_rating':
      return posts.some(p => p.rating >= 4);
    case 'ten_total':
      return posts.length >= 10;
    case 'two_locations': {
      const dayLocMap = {};
      posts.forEach(p => {
        if (p.location?.coordinates?.length === 2) {
          const key = new Date(p.createdAt).toDateString();
          if (!dayLocMap[key]) dayLocMap[key] = new Set();
          const [lng, lat] = p.location.coordinates;
          dayLocMap[key].add(`${(lat * 10).toFixed(0)},${(lng * 10).toFixed(0)}`);
        }
      });
      return Object.values(dayLocMap).some(s => s.size >= 2);
    }
    case 'early_morning':
      return posts.some(p => new Date(p.createdAt).getHours() < 10);
    case 'wednesday':
      return posts.some(p => new Date(p.createdAt).getDay() === 3);
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

// GET /bingo/card
router.get('/card', authMiddleware, async (req, res) => {
  try {
    res.set('Cache-Control', 'no-store');
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;

    const startOfMonth = new Date(year, month - 1, 1);
    const endOfMonth = new Date(year, month, 1);

    const posts = await Post.find({
      user: req.user._id,
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

    res.json({
      card: grid,
      completedLines,
      isBlackout,
      monthLabel: `${monthNames[month - 1]} ${year}`,
      totalDone: grid.filter(c => c.done).length,
    });
  } catch (err) {
    res.status(500).json({ message: 'Bingo-Karte konnte nicht geladen werden.', error: err.message });
  }
});

module.exports = router;
