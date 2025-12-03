import mongoose from 'mongoose';

const foodSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    description: String,
    price: { type: Number, required: true },
    image: String,
    category: { type: String, required: true },
    available: { type: Boolean, default: true },
    preparationTime: { type: Number, default: 15 }, // in minutes
    popularity: { type: Number, default: 0 },
    tags: [String],
    // Nutrition information
    nutrition: {
      calories: { type: Number, default: 0 },
      protein: { type: Number, default: 0 }, // in grams
      carbs: { type: Number, default: 0 }, // in grams
      fats: { type: Number, default: 0 }, // in grams
      fiber: { type: Number, default: 0 }, // in grams
      sodium: { type: Number, default: 0 }, // in mg
      sugar: { type: Number, default: 0 }, // in grams
    },
    ingredients: [String],
    allergens: [String],
    isHealthy: { type: Boolean, default: false },
    healthScore: { type: Number, min: 0, max: 100, default: 50 },
  },
  { timestamps: true }
);

export default mongoose.model('Food', foodSchema);
