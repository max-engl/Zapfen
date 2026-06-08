const Friend = require("../models/Friend");

async function getFriendIds(userId) {
    const friendships = await Friend.find({
        $or: [{ requester: userId }, { recipient: userId }],
        status: "accepted",
    }).select("requester recipient");

    return friendships.map((f) =>
        f.requester.toString() === userId.toString() ? f.recipient : f.requester
    );
}

// Returns users ranked by number of mutual friends, excluding existing friends/self/pending.
async function getRecommendations(userId, limit = 20) {
    const myFriendIds = await getFriendIds(userId);
    const myFriendSet = new Set(myFriendIds.map((id) => id.toString()));

    // Collect all pending relationships involving the current user
    const pending = await Friend.find({
        $or: [{ requester: userId }, { recipient: userId }],
        status: "pending",
    }).select("requester recipient");
    const pendingSet = new Set(
        pending.map((f) =>
            f.requester.toString() === userId.toString()
                ? f.recipient.toString()
                : f.requester.toString()
        )
    );

    // For each friend, get their friend IDs
    const mutualCount = {}; // candidateId → count
    for (const friendId of myFriendIds) {
        const theirFriendIds = await getFriendIds(friendId);
        for (const candidateId of theirFriendIds) {
            const cStr = candidateId.toString();
            if (cStr === userId.toString()) continue;
            if (myFriendSet.has(cStr)) continue;
            if (pendingSet.has(cStr)) continue;
            mutualCount[cStr] = (mutualCount[cStr] || 0) + 1;
        }
    }

    const sorted = Object.entries(mutualCount)
        .sort((a, b) => b[1] - a[1])
        .slice(0, limit);

    return sorted; // [ [userId, mutualCount], ... ]
}

module.exports = { getFriendIds, getRecommendations };
