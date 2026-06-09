const express = require('express');
const Friend = require('../models/Friend');
const authMiddleware = require('../middleware/authMiddleware');
const { buildBingoCardForUser } = require('../utils/bingo');

const router = express.Router();

async function canViewUser(viewerId, targetId) {
  if (targetId === viewerId) return true;
  const friendship = await Friend.findOne({
    $or: [
      { requester: viewerId, recipient: targetId },
      { requester: targetId, recipient: viewerId },
    ],
    status: 'accepted',
  });
  return Boolean(friendship);
}

// GET /bingo/card
router.get('/card', authMiddleware, async (req, res) => {
  try {
    res.set('Cache-Control', 'no-store');
    res.json(await buildBingoCardForUser(req.user._id));
  } catch (err) {
    res.status(500).json({ message: 'Bingo-Karte konnte nicht geladen werden.', error: err.message });
  }
});

// GET /bingo/user/:userId  — bingo card for a friend's profile
router.get('/user/:userId', authMiddleware, async (req, res) => {
  try {
    res.set('Cache-Control', 'no-store');
    const viewerId = req.user._id.toString();
    const targetId = req.params.userId;

    if (!await canViewUser(viewerId, targetId)) {
      return res.status(403).json({ message: 'You can only view bingo cards of your friends' });
    }

    res.json(await buildBingoCardForUser(targetId));
  } catch (err) {
    res.status(500).json({ message: 'Bingo-Karte konnte nicht geladen werden.', error: err.message });
  }
});

module.exports = router;
