/**
 * Migration script to add avatar colors and initials to existing users
 * Run this once after deploying the avatar feature
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const { generateAvatarColor, getAvatarInitial } = require('../utils/avatarUtil');

async function migrateUsers() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find all users that don't have avatarColor or avatarInitial
    const usersToUpdate = await User.find({
      $or: [
        { avatarColor: { $exists: false } },
        { avatarColor: null },
        { avatarInitial: { $exists: false } },
        { avatarInitial: null },
      ],
    });

    console.log(`Found ${usersToUpdate.length} users to update`);

    let updated = 0;
    for (const user of usersToUpdate) {
      if (!user.avatarColor || !user.avatarInitial) {
        user.avatarColor = user.avatarColor || generateAvatarColor(user.username);
        user.avatarInitial = user.avatarInitial || getAvatarInitial(user.username);
        await user.save();
        updated++;
        if (updated % 10 === 0) {
          console.log(`Updated ${updated}/${usersToUpdate.length} users...`);
        }
      }
    }

    console.log(`✓ Migration complete. Updated ${updated} users`);
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrateUsers();
