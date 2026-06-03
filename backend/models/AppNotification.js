const mongoose = require('mongoose');

const appNotificationSchema = new mongoose.Schema({
  recipient:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  type:           { type: String, enum: ['poured', 'cheers', 'comment', 'request', 'accepted', 'group_active'], required: true },
  actorId:        { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  actorUsername:  { type: String, default: null },
  actorAvatarUrl:     { type: String, default: null },
  actorAvatarColor:   { type: String, default: null },
  actorAvatarInitial: { type: String, default: null },
  postId:         { type: mongoose.Schema.Types.ObjectId, ref: 'Post', default: null },
  postThumbPath:  { type: String, default: null },
  mutualCount:    { type: Number, default: 0 },
  read:           { type: Boolean, default: false },
}, { timestamps: true });

// Auto-delete after 30 days
appNotificationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

module.exports = mongoose.model('AppNotification', appNotificationSchema);
