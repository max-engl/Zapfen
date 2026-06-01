const express = require("express");
const Drink = require("../models/Drink");
const authMiddleware = require("../middleware/authMiddleware");

module.exports = function drinkRoutes(defaultDrinks) {
    const router = express.Router();

    // GET /drinks  —  default drinks + caller's custom drinks
    router.get("/", authMiddleware, async (req, res) => {
        try {
            const [defaults, custom] = await Promise.all([
                Drink.find({ isDefault: true }).sort({ name: 1 }).lean(),
                Drink.find({ user: req.user._id, isDefault: false }).sort({ createdAt: -1 }).lean(),
            ]);

            res.json({ defaults, custom });
        } catch (error) {
            res.status(500).json({ message: "Could not fetch drinks", error: error.message });
        }
    });

    // POST /drinks  —  create a custom drink for the current user
    router.post("/", authMiddleware, async (req, res) => {
        try {
            const { name, emoji } = req.body;

            if (!name || !name.trim()) {
                return res.status(400).json({ message: "name is required" });
            }

            const drink = await Drink.create({
                name: name.trim(),
                emoji: emoji?.trim() || "🍺",
                user: req.user._id,
                isDefault: false,
            });

            res.status(201).json({ drink });
        } catch (error) {
            res.status(500).json({ message: "Could not create drink", error: error.message });
        }
    });

    // DELETE /drinks/:id  —  delete own custom drink
    router.delete("/:id", authMiddleware, async (req, res) => {
        try {
            const drink = await Drink.findById(req.params.id);

            if (!drink) {
                return res.status(404).json({ message: "Drink not found" });
            }
            if (drink.isDefault) {
                return res.status(403).json({ message: "Cannot delete a default drink" });
            }
            if (drink.user?.toString() !== req.user._id.toString()) {
                return res.status(403).json({ message: "Not your drink" });
            }

            await drink.deleteOne();
            res.json({ message: "Drink deleted" });
        } catch (error) {
            res.status(500).json({ message: "Could not delete drink", error: error.message });
        }
    });

    return router;
};
