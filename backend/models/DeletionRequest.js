const mongoose = require("mongoose");

const deletionRequestSchema = new mongoose.Schema({
  email: { type: String, required: true, trim: true, lowercase: true },
  status: { type: String, enum: ["pending", "completed", "dismissed"], default: "pending" },
}, { timestamps: true });

module.exports = mongoose.model("DeletionRequest", deletionRequestSchema);
